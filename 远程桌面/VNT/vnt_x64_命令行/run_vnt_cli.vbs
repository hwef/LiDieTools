' 文件名：RunVntCli.vbs
Option Explicit
Dim objShell, fso, currentPath, startupFolder, shortcutPath
Dim wait_time, is_enable_log, cmd_str

' 初始化变量
wait_time = 120 ' 检测间隔时间(秒)
is_enable_log = 0 ' 0=禁用日志, 1=启用日志
cmd_str = "vnt-cli -k token -n cejian -w password -W"
Set objShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
currentPath = Replace(WScript.ScriptFullName, WScript.ScriptName, "")
objShell.CurrentDirectory = currentPath

' 确保当前路径以反斜杠结尾
If Right(currentPath, 1) <> "\" Then
    currentPath = currentPath & "\"
End If

WriteLog "脚本启动于：" & Now
WriteLog "当前工作目录：" & currentPath

' 开机自启动设置
On Error Resume Next
Set startupFolder = objShell.SpecialFolders("Startup")
If Err.Number <> 0 Then
    ' 如果无法获取Startup文件夹，使用绝对路径
    startupFolder = objShell.ExpandEnvironmentStrings("%APPDATA%") & "\Microsoft\Windows\Start Menu\Programs\Startup"
    Err.Clear
End If
On Error GoTo 0

shortcutPath = startupFolder & "\RunVntCli.lnk"
If Not fso.FileExists(shortcutPath) Then
    Dim shortcut
    Set shortcut = objShell.CreateShortcut(shortcutPath)
    shortcut.TargetPath = WScript.ScriptFullName
    shortcut.WorkingDirectory = currentPath
    shortcut.Save
    WriteLog "已创建开机自启动快捷方式：" & shortcutPath
Else
    WriteLog "开机自启动已配置，跳过创建"
End If

' 检查脚本是否已在运行
If AppPrevInstance() Then
    WriteLog "脚本已在运行，退出新实例"
    WScript.Quit
Else
    WriteLog "无重复实例，继续执行"
End If

' 主监控循环
Do While True
    WriteLog "开始检测 vnt-cli.exe 进程状态..."
    
    If IsProcessRunning("vnt-cli.exe") Then
        WriteLog "vnt-cli.exe 正在运行（无需操作）"
    Else
        WriteLog "vnt-cli.exe 未运行，将重新启动"
        objShell.Run cmd_str , 0, False
        WriteLog "已执行启动命令：vnt-cli -k zm_work -n cejian -w zm_work -W"
        
        ' 验证是否启动成功
        WScript.Sleep 5000
        If IsProcessRunning("vnt-cli.exe") Then
            WriteLog "vnt-cli.exe 启动成功"
        Else
            WriteLog "警告：vnt-cli.exe 启动失败，将在下次检测时重试"
        End If
    End If
    
    WriteLog "检测完成，等待 " & wait_time & " 秒后重新检测"
    WScript.Sleep wait_time * 1000  ' 按设定间隔检测
Loop

' 检测进程是否存在
Function IsProcessRunning(processName)
    On Error Resume Next
    Dim wmi, processes
    IsProcessRunning = False
    Set wmi = GetObject("winmgmts:\\.\root\cimv2")
    Set processes = wmi.ExecQuery("SELECT * FROM Win32_Process WHERE Name='" & processName & "'")
    If Err.Number = 0 Then
        If processes.Count > 0 Then IsProcessRunning = True
    Else
        WriteLog "进程检测错误：" & Err.Description
        Err.Clear
    End If
End Function

' 防止多开检测
Function AppPrevInstance()
    On Error Resume Next
    AppPrevInstance = False
    If Not IsObject(GetObject("winmgmts:\\.\root\cimv2:Win32_Process.Handle='" & CreateObject("Scriptlet.TypeLib").Guid & "'")) Then Exit Function
    AppPrevInstance = True
End Function

' 日志记录函数
Sub WriteLog(message)
    ' 如果禁用日志，只输出到命令行
    If is_enable_log = 0 Then
        ' WScript.Echo "[" & Now & "] " & message
        Exit Sub
    End If
    
    Dim logFilePath, logStream
    logFilePath = currentPath & "RunVntCli.log"
    
    On Error Resume Next
    Set logStream = fso.OpenTextFile(logFilePath, 8, True)  ' 8=追加模式
    If Err.Number = 0 Then
        logStream.WriteLine "[" & Now & "] " & message
        logStream.Close
    Else
        ' 如果无法记录到文件，输出到命令行
        WScript.Echo "[" & Now & "] 日志错误: " & Err.Description
        Err.Clear
    End If
    On Error GoTo 0
    
    ' 同时显示在命令行
    ' WScript.Echo "[" & Now & "] " & message
End Sub