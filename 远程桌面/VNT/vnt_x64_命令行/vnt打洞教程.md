# vnt 打洞教程

# 文件简述
- run_vnt_cli.vbs 
    - 实现开机启动 vnt-cli.exe 并且 vnt-cli.exe 自动运行
    - 守护vnt-cli.exe 重启时间可在run_vnt_cli.vbs中 wait_time 变量中修改
    - # 需要你手动修改 vnt-cli 的参数 #
- vn-link-cli.exe
    - vnt-cli.exe 无法运行时才会使用该程序
- vnt-cli.exe
    - 打洞 内网穿透核心软件

# vnt-cli.exe 简要教程
- 示例 `vnt-cli -k token -n cejian -w password -W `
    - ## token : token  name : cejian  password : password ##
    - 双方 必须要 * token *  相同 才能看得到
    - 如果使用 -w 必须使用 相同的密码才能连接 
    - 参数含义 详情在命令行中使用` vnt-cli.exe -h `查看
        - -k <token>          使用相同的token,就能组建一个局域网络
        - -n <name>           给设备一个名字,便于区分不同设备,默认使用系统版本
        - -w <password>       使用该密码生成的密钥对客户端数据进行加密,并且服务端无法解密,使用相同密码的客户端才能通信
        - -W                  加密当前客户端和服务端通信的数据,请留意服务端指纹是否正确
