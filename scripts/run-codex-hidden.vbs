' ===========================================================================
'  Codex Desktop - console-hiding launcher wrapper
'
'  The desktop shortcut runs this file with wscript.exe:
'    1) derive the folder from this script's own path -- NO hard-coded user
'       path, so it works on any machine after copying the folder
'    2) run start-codex-proxy.cmd from the same folder with window style 0
'       (fully hidden)
'
'  Why: cmd.exe flashes a console window that disappears immediately, which
'  looks like an error. WScript.Shell.Run with style 0 hides it completely.
'
'  NOTE: this file is deliberately ASCII-only for the same reason as
'  start-codex-proxy.cmd (OEM code page parsing).
' ===========================================================================

Option Explicit

Dim fso, sh, base, cmdPath, cmdline

Set fso = CreateObject("Scripting.FileSystemObject")
Set sh  = CreateObject("WScript.Shell")

' ScriptFullName is this file's absolute path; its parent folder holds the .cmd
base = fso.GetParentFolderName(WScript.ScriptFullName)
cmdPath = base & "\start-codex-proxy.cmd"

If Not fso.FileExists(cmdPath) Then
    sh.Popup "start-codex-proxy.cmd was not found next to this file:" & vbCrLf & _
             base & vbCrLf & vbCrLf & _
             "Please keep the 4 scripts in one folder.", _
             0, "Codex Proxy Launcher", 48
    WScript.Quit 1
End If

sh.CurrentDirectory = base

' Chr(34) is a double quote - build the quotes this way to avoid escaping hell.
cmdline = "cmd.exe /c " & Chr(34) & Chr(34) & cmdPath & Chr(34) & Chr(34)

' Args: command line, window style (0 = hidden), wait for exit (False)
sh.Run cmdline, 0, False

WScript.Quit 0
