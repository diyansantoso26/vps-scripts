' run-watchdog-hidden.vbs - GTG COMPUTER
' Menjalankan watchdog AutoCAD tanpa jendela CMD sama sekali.
' Dipakai sebagai action scheduled task via wscript.exe (windowless).
Dim sh, ps1
Set sh = CreateObject("WScript.Shell")
ps1 = sh.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\GTG\autocad-watchdog.ps1"
sh.Run "powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File " & Chr(34) & ps1 & Chr(34), 0, False
