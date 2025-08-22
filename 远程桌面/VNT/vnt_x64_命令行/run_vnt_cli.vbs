' �ļ�����RunVntCli.vbs
Option Explicit
Dim objShell, fso, currentPath, startupFolder, shortcutPath
Dim wait_time, is_enable_log, cmd_str

' ��ʼ������
wait_time = 120 ' �����ʱ��(��)
is_enable_log = 0 ' 0=������־, 1=������־
cmd_str = "vnt-cli -k token -n cejian -w password -W"
Set objShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
currentPath = Replace(WScript.ScriptFullName, WScript.ScriptName, "")
objShell.CurrentDirectory = currentPath

' ȷ����ǰ·���Է�б�ܽ�β
If Right(currentPath, 1) <> "\" Then
    currentPath = currentPath & "\"
End If

WriteLog "�ű������ڣ�" & Now
WriteLog "��ǰ����Ŀ¼��" & currentPath

' ��������������
On Error Resume Next
Set startupFolder = objShell.SpecialFolders("Startup")
If Err.Number <> 0 Then
    ' ����޷���ȡStartup�ļ��У�ʹ�þ���·��
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
    WriteLog "�Ѵ���������������ݷ�ʽ��" & shortcutPath
Else
    WriteLog "���������������ã���������"
End If

' ���ű��Ƿ���������
If AppPrevInstance() Then
    WriteLog "�ű��������У��˳���ʵ��"
    WScript.Quit
Else
    WriteLog "���ظ�ʵ��������ִ��"
End If

' �����ѭ��
Do While True
    WriteLog "��ʼ��� vnt-cli.exe ����״̬..."
    
    If IsProcessRunning("vnt-cli.exe") Then
        WriteLog "vnt-cli.exe �������У����������"
    Else
        WriteLog "vnt-cli.exe δ���У�����������"
        objShell.Run cmd_str , 0, False
        WriteLog "��ִ���������vnt-cli -k zm_work -n cejian -w zm_work -W"
        
        ' ��֤�Ƿ������ɹ�
        WScript.Sleep 5000
        If IsProcessRunning("vnt-cli.exe") Then
            WriteLog "vnt-cli.exe �����ɹ�"
        Else
            WriteLog "���棺vnt-cli.exe ����ʧ�ܣ������´μ��ʱ����"
        End If
    End If
    
    WriteLog "�����ɣ��ȴ� " & wait_time & " ������¼��"
    WScript.Sleep wait_time * 1000  ' ���趨������
Loop

' �������Ƿ����
Function IsProcessRunning(processName)
    On Error Resume Next
    Dim wmi, processes
    IsProcessRunning = False
    Set wmi = GetObject("winmgmts:\\.\root\cimv2")
    Set processes = wmi.ExecQuery("SELECT * FROM Win32_Process WHERE Name='" & processName & "'")
    If Err.Number = 0 Then
        If processes.Count > 0 Then IsProcessRunning = True
    Else
        WriteLog "���̼�����" & Err.Description
        Err.Clear
    End If
End Function

' ��ֹ�࿪���
Function AppPrevInstance()
    On Error Resume Next
    AppPrevInstance = False
    If Not IsObject(GetObject("winmgmts:\\.\root\cimv2:Win32_Process.Handle='" & CreateObject("Scriptlet.TypeLib").Guid & "'")) Then Exit Function
    AppPrevInstance = True
End Function

' ��־��¼����
Sub WriteLog(message)
    ' ���������־��ֻ�����������
    If is_enable_log = 0 Then
        ' WScript.Echo "[" & Now & "] " & message
        Exit Sub
    End If
    
    Dim logFilePath, logStream
    logFilePath = currentPath & "RunVntCli.log"
    
    On Error Resume Next
    Set logStream = fso.OpenTextFile(logFilePath, 8, True)  ' 8=׷��ģʽ
    If Err.Number = 0 Then
        logStream.WriteLine "[" & Now & "] " & message
        logStream.Close
    Else
        ' ����޷���¼���ļ��������������
        WScript.Echo "[" & Now & "] ��־����: " & Err.Description
        Err.Clear
    End If
    On Error GoTo 0
    
    ' ͬʱ��ʾ��������
    ' WScript.Echo "[" & Now & "] " & message
End Sub