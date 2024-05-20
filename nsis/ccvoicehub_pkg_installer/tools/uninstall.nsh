; 按照自己定义的日志文件执行卸载
;
; 原著：苏甦
; 改编：傻鱼
; NSIS 编译器版本： 2.45

;日志文件为一行一条日志 d:path 代表目录 f:path代表文件 path为相对安装目录路径
;使用
;打开安装日志
;Section "-LogSetOn"
;  LogSet on
;SectionEnd
;插入卸载宏
;!insertmacro MacroUninstallByLog

!include "LogicLib.nsh"
!include "TextFunc.nsh"
!include "FileFunc.nsh"

!insertmacro un.TrimNewLines

!macro MacroUninstallByLog
;  ClearErrors
  Push "$INSTDIR"
  Push "$INSTDIR\filelist.txt"
  Call un.UninstallByLog
  Delete "$INSTDIR\filelist.txt"
!macroend

Var ErrorOccured

; UninstallByLog install dir, install log
Function un.UninstallByLog
  ; swap stack parameter with r0, r1
  Exch $R1 ; install log
  Exch
  Exch $R0 ; install dir
  Exch
  Push $R2 ; log line
  Push $R3 ; log type
  Push $R4 ; log path
  Push $R5 ; temp 1
  
  StrCpy $ErrorOccured "0"
  IfErrors 0 +2
    StrCpy $ErrorOccured "1"

  IfFileExists $R1 +3 0
  MessageBox MB_OK "can not found install log"
  Goto Exit_UninstallByLog

  FileOpen $R1 $R1 r
  ${Do}
    ; 之前有错误，先记下来
    IfErrors 0 +2
      StrCpy $ErrorOccured "1"

    ; read line
    FileRead $R1 $R2
    ; 清除读文件的错误
    ClearErrors
	; end of file
    ${IfThen} $R2 == "" ${|} ${ExitDo} ${|}
    ; trim newlines
    ${un.TrimNewLines} "$R2" $R2
	; format "f/d:path"
    StrCpy $R3 $R2 2 0
    StrCpy $R4 $R2 "" 2	
	; full path
    StrCpy $R4 $R0\$R4
	; file
    ${If} $R3 == "f:"
      Delete /REBOOTOK $R4
    ${EndIf}
	; dir
    ${If} $R3 == "d:"
      Push $R4
	    Call un.RMDirIfEmpty2
    ${EndIf}
  ${Loop}

  FileClose $R1

Exit_UninstallByLog:
  ; 
  StrCmp $ErrorOccured "1" 0 +2
    SetErrors

  Pop $R5
  Pop $R4
  Pop $R3
  Pop $R2
  Pop $R1
  Pop $R0
FunctionEnd

;Function un.RMDirIfEmpty
;  Exch $R0 ; dir
;  Push $R1 ; path found
;  Push $R2 ; handle
;  ; find . and ..
;  FindFirst $R2 $R1 "$R0\*.*"
;  StrCmp $R1 "." 0 NoDelete
;  FindNext $R2 $R1
;  StrCmp $R1 ".." 0 NoDelete
;  ; find any
;  ClearErrors
;  FindNext $R2 $R1
;  IfErrors 0 NoDelete
;  FindClose $R2
;  ; RMDir
;  RMDir $R0
;  Goto Exit_RMDirIfEmpty
;NoDelete:
;  FindClose $R2
;Exit_RMDirIfEmpty:
;  Pop $R2
;  Pop $R1
;  Pop $R0
;FunctionEnd

Function un.RmDirIfEmpty2
  Exch $R0
  Push $R1
  ${DirState} "$R0" $R1
  StrCmp $R1 "0" 0 +2
  RMDir $R0
  Pop $R1
  Pop $R0
FunctionEnd