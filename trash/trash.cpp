// trash.cpp : 带强制选项和智能确认的回收站工具
// 编译命令: cl /std:c++17 /EHsc /SUBSYSTEM:CONSOLE trash.cpp shell32.lib ole32.lib

#include <windows.h>
#include <shellapi.h>
#include <shlobj.h>
#include <vector>
#include <string>
#include <iostream>
#include <algorithm>

// 宽字符串转窄字符串（适配系统编码）
std::string wstring_to_string(const std::wstring& wstr) {
    int bufferSize = WideCharToMultiByte(CP_ACP, 0, wstr.c_str(), -1, NULL, 0, NULL, NULL);
    std::string str(bufferSize, 0);
    WideCharToMultiByte(CP_ACP, 0, wstr.c_str(), -1, &str[0], bufferSize, NULL, NULL);
    return str;
}

// 初始化控制台
void initConsole() {
    if (!AttachConsole(ATTACH_PARENT_PROCESS)) {
        AllocConsole();
    }
    
    // 重定向标准输出
    FILE* fDummy;
    freopen_s(&fDummy, "CONOUT$", "w", stdout);
    freopen_s(&fDummy, "CONOUT$", "w", stderr);
}

// 处理通配符
std::vector<std::wstring> expandWildcards(const std::wstring& pattern) {
    std::vector<std::wstring> result;
    WIN32_FIND_DATAW findData;
    
    HANDLE hFind = FindFirstFileW(pattern.c_str(), &findData);
    if (hFind == INVALID_HANDLE_VALUE) {
        // 如果不是通配符，直接返回原路径
        if (pattern.find(L'*') == std::wstring::npos && 
            pattern.find(L'?') == std::wstring::npos) {
            result.push_back(pattern);
        }
        return result;
    }

    do {
        // 跳过.和..
        if (wcscmp(findData.cFileName, L".") == 0 || 
            wcscmp(findData.cFileName, L"..") == 0) {
            continue;
        }

        // 构建完整路径
        size_t lastSlash = pattern.find_last_of(L"/\\");
        std::wstring dir = (lastSlash != std::wstring::npos) ? 
                          pattern.substr(0, lastSlash + 1) : L"";
        result.push_back(dir + findData.cFileName);

    } while (FindNextFileW(hFind, &findData) != 0);

    FindClose(hFind);
    return result;
}

// 获取用户确认（根据文件数量和强制参数决定是否需要确认）
bool confirmOperation(size_t fileCount, bool force) {
    // 强制模式直接跳过所有确认
    if (force) {
        return true;
    }
    
    // 单个文件/文件夹无需确认
    if (fileCount == 1) {
        return true;
    }
    
    // 少量文件（2-150个）一次确认
    if (fileCount <= 150) {
        std::cout << "确定要将 " << fileCount << " 个项目移至回收站吗? [y/N] ";
        std::string response;
        std::getline(std::cin, response);
        std::transform(response.begin(), response.end(), response.begin(), ::tolower);
        return (response == "y" || response == "yes");
    } 
    // 大量文件（>150个）二次确认
    else {
        std::cout << "警告: 您正在尝试删除 " << fileCount << " 个项目（数量较多）\n";
        std::cout << "首次确认: 输入 'confirm' 继续: ";
        std::string response1;
        std::getline(std::cin, response1);
        
        if (response1 != "confirm") {
            std::cout << "操作已取消\n";
            return false;
        }
        
        std::cout << "二次确认: 再次输入 'confirm' 确认删除: ";
        std::string response2;
        std::getline(std::cin, response2);
        if (response2 != "confirm") {
            std::cout << "操作已取消\n";
            return false;
        }
        return true;
    }
}

int wmain(int argc, wchar_t* argv[]) {
    initConsole();

    // 解析参数：分离选项(-f)和文件路径
    bool force = false;
    std::vector<std::wstring> args;
    
    for (int i = 1; i < argc; ++i) {
        std::wstring arg = argv[i];
        if (arg == L"-f" || arg == L"--force") {
            force = true;
        } else {
            args.push_back(arg);
        }
    }

    if (args.empty()) {
        std::cout << "用法: trash [选项] <文件或目录> [...]\n";
        std::cout << "选项:\n";
        std::cout << "  -f, --force   强制删除，跳过所有确认提示\n";
        std::cout << "示例:\n";
        std::cout << "  trash file.txt          删除单个文件（无需确认）\n";
        std::cout << "  trash folder/           删除单个文件夹（无需确认）\n";
        std::cout << "  trash *.log             删除多个文件（需要确认）\n";
        std::cout << "  trash -f *              强制删除所有文件（无确认）\n";
        return 1;
    }

    // 处理所有文件参数和通配符
    std::vector<std::wstring> files;
    for (const auto& arg : args) {
        auto expanded = expandWildcards(arg);
        files.insert(files.end(), expanded.begin(), expanded.end());
    }

    if (files.empty()) {
        std::cerr << "错误: 没有找到匹配的文件或目录\n";
        return 1;
    }

    // 显示待删除文件列表（仅前10个）
    std::cout << "即将移至回收站的项目 (" << files.size() << " 个):\n";
        size_t displayCount = std::min<size_t>(10, files.size());
    for (size_t i = 0; i < displayCount; ++i) {
        std::cout << " - " << wstring_to_string(files[i]) << "\n";
    }
    if (files.size() > 10) {
        std::cout << " - ... 还有 " << (files.size() - 10) << " 个项目未显示\n";
    }

    // 请求用户确认（根据规则自动判断是否需要交互）
    if (!confirmOperation(files.size(), force)) {
        return 1;
    }

    // 构建多字符串（双null结尾）
    std::wstring pathStr;
    for (const auto& file : files) {
        pathStr += file;
        pathStr += L'\0';
    }
    pathStr += L'\0';

    // 执行删除操作
    SHFILEOPSTRUCTW fileOp = {0};
    fileOp.wFunc = FO_DELETE;
    fileOp.pFrom = pathStr.c_str();
    fileOp.fFlags = FOF_ALLOWUNDO |    // 放入回收站
                    FOF_NOCONFIRMATION;      // 不显示系统确认框

    int result = SHFileOperationW(&fileOp);

    // 输出结果
    if (result == 0 && !fileOp.fAnyOperationsAborted) {
        std::cout << "\n成功将 " << files.size() << " 个项目移至回收站。\n";
        return 0;
    } else {
        std::cerr << "\n操作失败";
        if (fileOp.fAnyOperationsAborted) {
            std::cerr << ": 部分操作被中止";
        }
        std::cerr << " (错误代码: " << result << ")\n";
        return 1;
    }
}
