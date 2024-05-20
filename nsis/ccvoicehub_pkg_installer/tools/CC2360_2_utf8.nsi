
!addIncludeDir .       ; 将当前路径添加到 头文件索引目录
!addplugindir Plugins  ; 将相应路径添加到 插件索引目录
!addplugindir  .

; 引入的头文件
!include "nsDialogs.nsh"
!include "FileFunc.nsh"
!include  MUI.nsh
!include  LogicLib.nsh
!include  WinMessages.nsh
!include "MUI2.nsh"
!include "WordFunc.nsh"
!include "Library.nsh"
;!include "basehelp.nsh"

; 选择压缩方式
SetCompressor  /FINAL lzma
; 引入的dll
ReserveFile "${NSISDIR}\Plugins\nsTBCIASkinEngine.dll" ; 调用我们的皮肤插件
ReserveFile "${NSISDIR}\Plugins\System.dll"
ReserveFile "${NSISDIR}\Plugins\FindProcDLL.dll"
ReserveFile "${NSISDIR}\Plugins\KillProcDLL.dll"
ReserveFile "${NSISDIR}\Plugins\nsDialogs.dll"
ReserveFile "${NSISDIR}\Plugins\nsExec.dll"
ReserveFile "${NSISDIR}\Plugins\InstallOptions.dll"
 

; 名称宏定义
; 将被打包的源文件位置 ;;
!define SOURCE_DIR "..\bin"

; CC 安装信息设置
!define PRODUCT_NAME "CC 开黑"
!define PRODUCT_DETAIL "CC 开黑"
!define PRODUCT_PUBLISHER "网易互动娱乐有限公司"
!define PRODUCT_WEB_SITE "http://CC.163.com"
!define PRODUCT_VERSION           "1.0.0.1"
!define PRODUCT_NAME_EN           "CCVoiceHub"

!define PRODUCT_DIR_KEY "Software\Microsoft\Windows\CurrentVersion\App Paths\CCVoicehubLauncher.exe"
!define PRODUCT_DIR_ROOT_KEY "HKLM"

!define PRODUCT_UNINST_ROOT_KEY "HKLM"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME_EN}"

!define PRODUCT_AUTORUN_ROOT_KEY "HKCU"
!define PRODUCT_AUTORUN_KEY "Software\Microsoft\Windows\CurrentVersion\Run"
!define PRODUCT_AUTORUN_VALUE "CCVoiceHub"

!define PRODUCT_SUB_KEY           "SOFTWARE\360\360Safe"
!define PRODUCT_MAIN_EXE          "CCVoicehubLauncher.exe"
!define SETUP_MUTEX_NAME          "NeteaseCCInstaller" ;  old"{50A3E52E-6F7F-4411-9791-63BD15BBF2C2}"

!define PRODUCT_LOCALDATA_ROOT_KEY "HKCU"
!define PRODUCT_LOCALDATA_KEY "Software\Netease\CCVoiceHub"
!define PRODUCT_LOCALDATA_INSTDIR_KEY "InstallLocation"
!define PRODUCT_LOCALDATA_AGREEMENT "Agree"

!define PRODUCT_LOCAL_KEY "Software\Netease\CCVoiceHub\Local"
!define PRODUCT_LOCAL_INSTDIR_KEY "T"

!define UPDATE_EXE_NAME "UpdateExec.exe"

; CC 网站通道相关注册表
!define PRODUCT_CLASSES_ROOT_KEY "HKCR"
!define PRODUCT_CLASSES_ROOT_URL_KEY "CCVoiceHub"
!define PRODUCT_CLASSES_ROOT_URL_VALUE "URL:CCVoiceHub Protocol"
!define PRODUCT_CLASSES_ROOT_PROTOCOL_VALUE ""
!define PRODUCT_CLASSES_ROOT_COMMAND_KEY "CCVoiceHub\shell\open\command"
!define PRODUCT_CLASSES_ROOT_COMMAND_VALUE "$\"$INSTDIR\CCVoicehubLauncher.exe$\" /url $\"%1$\""

!define MUI_ICON                  ".\CC res\install.ico"    ;安装icon
!define MUI_UNICON                ".\CC res\uninstall.ico"  ;卸载icon

; 快捷方式
!define CC_FINISHPAGE_RUN "$\"$INSTDIR\CCVoicehubLauncher.exe$\""
!define CC_LINK_NAME "CC 开黑.lnk"

!define ID_YES  "6"
!define ID_NO   "7"
!define NO_SAVE_ACCOUNT "4"

!define SetEnvironmentVariable "Kernel32::SetEnvironmentVariable(t, t)i"

; 一些重复度较高代码 作成 宏
!macro MutexCheck _mutexname _outvar _handle
System::Call 'kernel32::CreateMutexA(i 0, i 0, t "${_mutexname}" ) i.r1 ?e'
StrCpy ${_handle} $1
Pop ${_outvar}
!macroend
!insertmacro GetTime
 ;MACRO get option state
!macro GETOPSTATE  vdialog vcontrol vcontrolstate
    nsTBCIASkinEngine::TBCIASendMessage ${vdialog} WM_TBCIAOPTIONSTATE ${vcontrol} ""
    Pop $0
   ${If} $0 == "1"
     StrCpy ${vcontrolstate} "1"
   ${Else}
     StrCpy ${vcontrolstate} "0"
   ${EndIf}
!macroend

; 变量定义
Var Dialog
Var MessageBoxHandle
Var DesktopIconState
Var FastIconState
Var FreeSpaceSize
Var installPath


Var RunNow
Var InstallState
Var LocalPath
Var CCtemp

; 第零页
Var vOpAgreeLicence
Var boolShowLicence ;点击显示用户协议的按钮
Var Skip_Flag
; 第一页
Var vOpCreateDeskIcon
Var vOpAddQuickLaunch
; 第二页
Var timerID
; 第三页
Var vOpRunCC
Var vOpRunAuto
Var boolShowCharacter
Var InstallOptions

;-----卸载----------
Var opSaveAccount
;----------卸载原因--------
Var opNoFav      ;语音质量差
Var opAppCrash    ;语音不流畅
Var opBotherOperation ;语音太嘈杂
Var opHighCpu         ;没有找到感兴趣的房间
Var opBadMultiplyMedia ;没找到志同道合的好友
Var opNoSmooth          ;社区氛围不够活跃
Var opAdvertising          ;社区充斥大量​广告
Var opOther          ;其它
Var postParamater
Var postJson

;获取当前磁盘剩余容量 MB
Var diskFreeMB
;Languages
!insertmacro MUI_LANGUAGE "SimpChinese"

Name      "${PRODUCT_DETAIL}"              ;提示对话框的标题 - "CC 开黑"
OutFile   "../ccvoice_pkg_installer.exe"    ;输出安装包名

InstallDir "$PROGRAMFILES\Netease\CCVoiceHub\"                   ;Default installation folder

;InstallDirRegKey ${PRODUCT_LOCALDATA_ROOT_KEY} "${PRODUCT_LOCALDATA_KEY}" "${PRODUCT_LOCALDATA_INSTDIR_KEY}"
                   ;  HKCU                        Software\Netease\CCVoiceHub         InstallLocation


;Request application privileges for Windows Vista
RequestExecutionLevel admin
;--------------------------------------------------------------------------------------------------------------------------------------------------------------

;Installer Sections
Section "Dummy Section" SecDummy
  ; 复制要发布的安装文件
  ;MessageBox MB_OK "$INSTDIR"
  SetOutPath "$INSTDIR"
  ;MessageBox MB_OK "section SecDummy"
  SetOverWrite on
  File /r /x ".svn" "${SOURCE_DIR}\*.*"   ; File /r /x ".svn" "${SOURCE_DIR}\*.*"
  SetOverWrite on
  SetRebootFlag false
  
  Call BuildShortCut

SectionEnd

Section -Post
  ;MessageBox MB_OK "section -post"
    ; 在注册表中记录安装路径
    WriteRegStr ${PRODUCT_LOCALDATA_ROOT_KEY} "${PRODUCT_LOCALDATA_KEY}" "${PRODUCT_LOCALDATA_INSTDIR_KEY}" "$\"$INSTDIR$\""
	 ;  在注册表中创建local
	  WriteRegStr ${PRODUCT_LOCALDATA_ROOT_KEY} "${PRODUCT_LOCAL_KEY}" "${PRODUCT_LOCAL_INSTDIR_KEY}" "1"

    ; 在“添加或删除程序”中显示“CC 开黑”
    WriteUninstaller "$INSTDIR\uninstall.exe"
    WriteRegStr ${PRODUCT_DIR_ROOT_KEY} "${PRODUCT_DIR_KEY}" "" "$\"$INSTDIR\CCVoicehubLauncher.exe$\""
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayName" "${PRODUCT_NAME}"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$\"$INSTDIR\CCVoicehubLauncher.exe$\""
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"

    ; 开机自动运行 在按装完成后设置
    ; WriteRegStr ${PRODUCT_AUTORUN_ROOT_KEY} "${PRODUCT_AUTORUN_KEY}" "${PRODUCT_AUTORUN_VALUE}" "$\"$INSTDIR\CCVoicehubLauncher.exe$\""

    ; 网站通道
    ; WriteRegStr ${PRODUCT_CLASSES_ROOT_KEY} "${PRODUCT_CLASSES_ROOT_URL_KEY}" "" "${PRODUCT_CLASSES_ROOT_URL_VALUE}"
    ; WriteRegStr ${PRODUCT_CLASSES_ROOT_KEY} "${PRODUCT_CLASSES_ROOT_URL_KEY}" "URL Protocol" "${PRODUCT_CLASSES_ROOT_PROTOCOL_VALUE}"
    ; WriteRegStr ${PRODUCT_CLASSES_ROOT_KEY} "${PRODUCT_CLASSES_ROOT_COMMAND_KEY}" "" "${PRODUCT_CLASSES_ROOT_COMMAND_VALUE}"

    ; 协议更新
    WriteRegStr ${PRODUCT_LOCALDATA_ROOT_KEY} "${PRODUCT_LOCALDATA_KEY}" "${PRODUCT_LOCALDATA_AGREEMENT}" "1"


SectionEnd

;--------------------------------------------------------------------------------------------------------------------------------------------------------------

;Uninstaller Section
!include "uninstall.nsh"

Section "Uninstall"
    ClearErrors

   BEGIN_UNINSTALLATION:


    ; 删除各处的快捷方式
    Delete "$SMPROGRAMS\CC 开黑\Uninstall.lnk"
    Delete "$STARTMENU\CC 开黑.lnk"
    Delete "$DESKTOP\CC 开黑.lnk"
    Delete "$SMPROGRAMS\CC 开黑\CC 开黑.lnk"
    Delete "$QUICKLAUNCH\CC 开黑.lnk"
    RMDir /REBOOTOK /r "$SMPROGRAMS\CC 开黑"

	; 删除程序生成日志和更新数据
    RMDir /r "$INSTDIR\UpdateTemp"
    RMDir /r "$INSTDIR\Temp"
    RMDir /r "$INSTDIR\Start"
    RMDir /r "$INSTDIR\UpdateExec"
    Delete "$INSTDIR\Trace_Log.txt"

	; 按照安装日志删除
    ; !insertmacro MacroUninstallByLog
	; 删除卸载程序
    Delete "$INSTDIR\uninstall.exe"

    ; 提示用户是否保留消息历史等用户信息

    ; 删除用户的消息历史等私有信息
    ${If} $opSaveAccount == ${NO_SAVE_ACCOUNT}  ; 未勾选保存用户信息
		    DeleteRegKey ${PRODUCT_LOCALDATA_ROOT_KEY} "${PRODUCT_LOCALDATA_KEY}"
		    RMDir /REBOOTOK /r "$INSTDIR\Users"
	  ${EndIf}

SKIP_USERS_DIR:
    ; 如果安装目录已空，删除安装目录
    ; Push $INSTDIR
    ; Call un.RMDirIfEmpty2
    ;直接删除安装目录
    RMDir /r "$INSTDIR"
    ; 清理注册表
    DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"
    DeleteRegKey ${PRODUCT_DIR_ROOT_KEY} "${PRODUCT_DIR_KEY}"
    DeleteRegValue ${PRODUCT_AUTORUN_ROOT_KEY} "${PRODUCT_AUTORUN_KEY}" "${PRODUCT_AUTORUN_VALUE}"
    
SectionEnd

;--------------------------------------------------------------------------------------------------------------------------------------------------------------
; 安装和卸载界面
Page         custom     CC
Page         instfiles  "" InstallShow


UninstPage   custom     un.CCUninstall
UninstPage   instfiles  "" un.UninstallShow un.AfterUnistall
;--------------------------------------------------------------------------------------------------------------------------------------------------------------

Function CC

  ;初始化窗口
   nsTBCIASkinEngine::InitTBCIASkinEngine /NOUNLOAD "CC_InstallXml1.xml" "WizardTab"    ;duilib.xml  CC_InstallXml.xml    InstallPackages.xml
   Pop $Dialog
   ;初始化MessageBox窗口
   nsTBCIASkinEngine::InitTBCIAMessageBox  "MessageBox_0.xml" "MessageBox_1.xml" "MessageBox_2.xml" "MessageBox_3.xml" "MessageBox_4.xml" "TitleLab" "TextLab" "CloseBtn" "YESBtn" "NOBtn"
   Pop $MessageBoxHandle
  nsTBCIASkinEngine::SetControlData "op_agree_licence" "true" "selected"
  nsTBCIASkinEngine::SetControlData "btn_quick_install" "true" "visible"
  StrCpy $vOpAgreeLicence 1

  nsTBCIASkinEngine::FindControl "Wizard_CloseBtn0"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have Wizard_CloseBtn0 button"
   ${Else}
	GetFunctionAddress $0 OnGlobalCancelFunc
	nsTBCIASkinEngine::OnControlBindNSISScript "Wizard_CloseBtn0" $0
   ${EndIf}
   
   ;快速安装 按钮绑 定函数
   nsTBCIASkinEngine::FindControl "btn_quick_install"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have btn_quick_install button"
   ${Else}
	    GetFunctionAddress $0 OnBtnInstallNow
    	nsTBCIASkinEngine::OnControlBindNSISScript "btn_quick_install" $0
   ${EndIf}

   ; Option - 同意CC 开黑的用户许可协议
   nsTBCIASkinEngine::FindControl "op_agree_licence"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have op_agree_licence button"
   ${Else}
	    GetFunctionAddress $0 OnOpAgreeLicence
    	nsTBCIASkinEngine::OnControlBindNSISScript "op_agree_licence" $0
   ${EndIf}
   
   ; Button - 用户许可协议
  nsTBCIASkinEngine::FindControl "btn_show_licence"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have op_agree_licence button"
   ${Else}
      Strcpy $boolShowLicence 0
	    GetFunctionAddress $0 OnBtnShowLicence
    	nsTBCIASkinEngine::OnControlBindNSISScript "btn_show_licence" $0
   ${EndIf}

   ; Button - 网易CC 开黑隐私政策
   nsTBCIASkinEngine::FindControl "btn_show_audio_privacy"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have op_agree_licence button"
   ${Else}
	    GetFunctionAddress $0 OnBtnShowAudioPrivacy
    	nsTBCIASkinEngine::OnControlBindNSISScript "btn_show_audio_privacy" $0
   ${EndIf}

   ; Button - 第三方服务共享清单
   nsTBCIASkinEngine::FindControl "btn_show_share"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have op_agree_licence button"
   ${Else}
      Strcpy $boolShowLicence 0
	    GetFunctionAddress $0 OnBtnShowShare
    	nsTBCIASkinEngine::OnControlBindNSISScript "btn_show_share" $0
   ${EndIf}

   ; Button - 网易CC 开黑儿童个人信息保护规则及监护人须知
   nsTBCIASkinEngine::FindControl "btn_show_child"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have op_agree_licence button"
   ${Else}
      Strcpy $boolShowLicence 0
	    GetFunctionAddress $0 OnBtnShowChild
    	nsTBCIASkinEngine::OnControlBindNSISScript "btn_show_child" $0
   ${EndIf}
   
   ; 显示license
  nsTBCIASkinEngine::FindControl "LicenceRichEdit"
  Pop $0
   ${If} $0 == "-1"
	MessageBox MB_OK "Do not have LicenceRichEdit button"
	 ${Else}
	nsTBCIASkinEngine::ShowLicense "LicenceRichEdit" "Licencea.txt"  ; "许可协议控件名字"
	${EndIf}
   
  ; 关闭 协议框按钮
   nsTBCIASkinEngine::FindControl "btn_close_licence"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have btn_close_licence button"
   ${Else}
	GetFunctionAddress $0 OnBtnCloseLicenceFunc
	nsTBCIASkinEngine::OnControlBindNSISScript "btn_close_licence" $0
   ${EndIf}
   
   ;自定义安装按钮绑定函数
   nsTBCIASkinEngine::FindControl "btn_custom_install"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have btn_custom_install button"
   ${Else}
	     GetFunctionAddress $0 onBtnCustInstallFunc
	     nsTBCIASkinEngine::OnControlBindNSISScript "btn_custom_install" $0
   ${EndIf}
   
  ; -----------------------------第一个页面 ----------------------------------------
  ; 关闭按钮
   nsTBCIASkinEngine::FindControl "Wizard_CloseBtn1"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have Wizard_CloseBtn1 button"
   ${Else}
	GetFunctionAddress $0 OnGlobalCancelFunc
	nsTBCIASkinEngine::OnControlBindNSISScript "Wizard_CloseBtn1" $0
   ${EndIf}
  StrCpy $vOpCreateDeskIcon 1
  ; Option - 创建桌面图标
  nsTBCIASkinEngine::FindControl "op_create_deskicon"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have op_agree_licence button"
   ${Else}
	    GetFunctionAddress $0 OnOpCreateDeskIcon
    	nsTBCIASkinEngine::OnControlBindNSISScript "op_create_deskicon" $0
   ${EndIf}
   ;创建桌面图标后面的文案按钮点击
   nsTBCIASkinEngine::FindControl "btn_create_deskicon"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have btn_create_deskicon button"
   ${Else}
	    GetFunctionAddress $0 OnBtnCreateDeskIcon
    	nsTBCIASkinEngine::OnControlBindNSISScript "btn_create_deskicon" $0
   ${EndIf}

  ; Option - 添加到快捷启动栏
  Strcpy $vOpAddQuickLaunch 1
  nsTBCIASkinEngine::FindControl "op_add_quick_launch"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have op_agree_licence button"
   ${Else}
	    GetFunctionAddress $0 OnOpAddQuickLaunch
    	nsTBCIASkinEngine::OnControlBindNSISScript "op_add_quick_launch" $0
   ${EndIf}
   
   ;快速启动栏按钮
  nsTBCIASkinEngine::FindControl "btn_quick_lanuch"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have btn_quick_lanuch button"
   ${Else}
	    GetFunctionAddress $0 OnBtnAddQuickLaunch
    	nsTBCIASkinEngine::OnControlBindNSISScript "btn_quick_lanuch" $0
   ${EndIf}
      ;可用磁盘空间设定数据
   nsTBCIASkinEngine::FindControl "freespace"
   Pop $0
   ${If} $0 == "-1"
	MessageBox MB_OK "Do not have freespace button"
   ${Else}
	nsTBCIASkinEngine::SetControlData "freespace"  $diskFreeMB  "spacetext"
   ${EndIf}   
   ; 立即安装 按钮
   nsTBCIASkinEngine::FindControl "btn_install_now"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have btn_install_now"
   ${Else}
	   GetFunctionAddress $0 OnStartInstallBtnFunc
	nsTBCIASkinEngine::OnControlBindNSISScript "btn_install_now" $0
   ${EndIf}
   
   ; 返回 按钮
   nsTBCIASkinEngine::FindControl "btn_back"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have btn_back"
   ${Else}
		GetFunctionAddress $0 OnBackBtnFunc
		nsTBCIASkinEngine::OnControlBindNSISScript "btn_back" $0
	${EndIf}
	
	;安装路径编辑框设定数据
  nsTBCIASkinEngine::FindControl "edit_path"
   Pop $0
   ${If} $0 == "-1"
	MessageBox MB_OK "Do not have Wizard_InstallPathBtn4Page2 button"
   ${Else}
	;nsTBCIASkinEngine::SetText2Control "edit_path"  $installPath
	nsTBCIASkinEngine::SetControlData "edit_path"  $installPath "text"

	GetFunctionAddress $0 OnTextChangeFunc
	nsTBCIASkinEngine::OnControlBindNSISScript "edit_path" $0
   ${EndIf}
   
   ;安装路径浏览按钮绑定函数
    nsTBCIASkinEngine::FindControl "btn_browser"
   Pop $0
   ${If} $0 == "-1"
	MessageBox MB_OK "Do not have btn_browser button"
   ${Else}
	GetFunctionAddress $0 OnInstallPathBrownBtnFunc
        nsTBCIASkinEngine::OnControlBindNSISScript "btn_browser"  $0
   ${EndIf}

    ;-----------------------------第二个页面 ----------------------------------------
    ; 关闭按钮
   nsTBCIASkinEngine::FindControl "Wizard_CloseBtn2"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have Wizard_CloseBtn2 button"
   ${Else}
	GetFunctionAddress $0 OnGlobalCancelFunc
	nsTBCIASkinEngine::OnControlBindNSISScript "Wizard_CloseBtn2" $0
   ${EndIf}
   
     ; -----------------------------第三个页面 ----------------------------------------

   ; 关闭按钮
   nsTBCIASkinEngine::FindControl "Wizard_CloseBtn3"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have Wizard_CloseBtn3 button"
   ${Else}
	GetFunctionAddress $0 OnBtnInstallComplete
	nsTBCIASkinEngine::OnControlBindNSISScript "Wizard_CloseBtn3" $0
   ${EndIf}
   ;
   StrCpy $vOpRunCC 1
   ; Option 运行CC 开黑
   nsTBCIASkinEngine::FindControl "op_run_cc"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have op_run_cc button"
   ${Else}
	    GetFunctionAddress $0 OnOpRunCC
    	nsTBCIASkinEngine::OnControlBindNSISScript "op_run_cc" $0
   ${EndIf}
   
   ; Option 开机自动启动
   StrCpy $vOpRunAuto 1
    nsTBCIASkinEngine::FindControl "op_run_auto"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have op_run_auto button"
   ${Else}
	    GetFunctionAddress $0 OnOpRunAuto
    	nsTBCIASkinEngine::OnControlBindNSISScript "op_run_auto" $0
   ${EndIf}

   nsTBCIASkinEngine::FindControl "btn_run_auto"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have btn_run_auto button"
   ${Else}
	    GetFunctionAddress $0 OnBtnRunAuto
    	nsTBCIASkinEngine::OnControlBindNSISScript "btn_run_auto" $0
   ${EndIf}

   ; "显示新特性" 按钮
   nsTBCIASkinEngine::FindControl "btn_show_character"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have btn_show_character button"
   ${Else}
	GetFunctionAddress $0 OnBtnShowCharacter
	nsTBCIASkinEngine::OnControlBindNSISScript "btn_show_character" $0
	Strcpy $boolShowCharacter 0
   ${EndIf}

   ; 关闭新特性 按钮
   nsTBCIASkinEngine::FindControl "btn_close_character"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have btn_close_character button"
   ${Else}
	GetFunctionAddress $0 OnBtnCloseCharacter
	nsTBCIASkinEngine::OnControlBindNSISScript "btn_close_character" $0
   ${EndIf}
   
  ; 显示Character
  nsTBCIASkinEngine::FindControl "CharacterRichEdit"
  Pop $0
   ${If} $0 == "-1"
	MessageBox MB_OK "Do not have CharacterRichEdit button"
	 ${Else}
	nsTBCIASkinEngine::ShowNewCharacter "CharacterRichEdit" "NewCharacter.txt"  ; "许可协议控件名字"
	${EndIf}

   ; "立即体验" 按钮
   nsTBCIASkinEngine::FindControl "btn_start_now"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have btn_start_now button"
   ${Else}
	GetFunctionAddress $0 OnBtnStartNow
	nsTBCIASkinEngine::OnControlBindNSISScript "btn_start_now" $0	
   ${EndIf}   
   
   ; "完成安装" 按钮
   nsTBCIASkinEngine::FindControl "btn_install_complete"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have btn_install_complete button"
   ${Else}
	GetFunctionAddress $0 OnBtnInstallCompleteRunChecked
	nsTBCIASkinEngine::OnControlBindNSISScript "btn_install_complete" $0
   ${EndIf}   
   
  ; ----------------------显示-------------------------------------------------

  nsTBCIASkinEngine::ShowPage
FunctionEnd



; -函数定义-------------------------------------------------------
Function un.CCUninstall
  GetTempFileName $0
  StrCpy $CCtemp $0
  Delete $0
  SetOutPath $temp\${PRODUCT_NAME_EN}Setup\res
  File ".\CC res\NewCharacter.txt"
   ;初始化窗口                                                                    ;      CC_Uninstall
   nsTBCIASkinEngine::InitTBCIASkinEngine /NOUNLOAD "CC_Uninstall.xml" "WizardTab"
   Pop $Dialog

   ;初始化MessageBox窗口
   nsTBCIASkinEngine::InitTBCIAMessageBox "MessageBox_0.xml" "MessageBox_1.xml" "MessageBox_2.xml" "MessageBox_3.xml" "MessageBox_4.xml" "TitleLab" "TextLab" "CloseBtn" "YESBtn" "NOBtn"
   Pop $MessageBoxHandle

   StrCpy $opNoFav "0"
   StrCpy $opAppCrash "0"
   StrCpy $opBotherOperation "0"
   StrCpy $opHighCpu "0"
   StrCpy $opBadMultiplyMedia "0"
   StrCpy $opNoSmooth "0"
   StrCpy $opAdvertising "0"
   StrCpy $opOther "0"
   nsTBCIASkinEngine::FindControl "op_noFavPly"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have op_noFavPly checkbox"
   ${Else}
	    GetFunctionAddress $0 un.OnNoFavOp
    	nsTBCIASkinEngine::OnControlBindNSISScript "op_noFavPly" $0
   ${EndIf}

   nsTBCIASkinEngine::FindControl "btn_noFavPly"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have btn_noFavPly checkbox"
   ${Else}
	    GetFunctionAddress $0 un.OnBtnNoFavOp
    	nsTBCIASkinEngine::OnControlBindNSISScript "btn_noFavPly" $0
   ${EndIf}

   nsTBCIASkinEngine::FindControl "op_crash"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have op_crash checkbox"
   ${Else}
	    GetFunctionAddress $0 un.OnAppCrash
    	nsTBCIASkinEngine::OnControlBindNSISScript "op_crash" $0
   ${EndIf}

      nsTBCIASkinEngine::FindControl "btn_crash"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have btn_crash checkbox"
   ${Else}
	    GetFunctionAddress $0 un.OnBtnAppCrash
    	nsTBCIASkinEngine::OnControlBindNSISScript "btn_crash" $0
   ${EndIf}

   nsTBCIASkinEngine::FindControl "op_noFun"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have op_noFun checkbox"
   ${Else}
	    GetFunctionAddress $0 un.OnBotherOperation
    	nsTBCIASkinEngine::OnControlBindNSISScript "op_noFun" $0
   ${EndIf}

   nsTBCIASkinEngine::FindControl "btn_noFun"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have btn_noFun checkbox"
   ${Else}
	    GetFunctionAddress $0 un.OnBtnBotherOperation
    	nsTBCIASkinEngine::OnControlBindNSISScript "btn_noFun" $0
   ${EndIf}

   nsTBCIASkinEngine::FindControl "op_highLoad"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have op_highLoad checkbox"
   ${Else}
	GetFunctionAddress $0 un.OnHighCpu
    	nsTBCIASkinEngine::OnControlBindNSISScript "op_highLoad" $0
   ${EndIf}

      nsTBCIASkinEngine::FindControl "btn_highLoad"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have btn_highLoad checkbox"
   ${Else}
	    GetFunctionAddress $0 un.OnBtnHighCpu
    	nsTBCIASkinEngine::OnControlBindNSISScript "btn_highLoad" $0
   ${EndIf}

   nsTBCIASkinEngine::FindControl "op_badImage"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have op_badImage checkbox"
   ${Else}
	    GetFunctionAddress $0 un.OnBadMultiplyMedia
    	nsTBCIASkinEngine::OnControlBindNSISScript "op_badImage" $0
   ${EndIf}
   
   nsTBCIASkinEngine::FindControl "op_advertising"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have op_advertising checkbox"
   ${Else}
	    GetFunctionAddress $0 un.OnAdvertisingMedia
    	nsTBCIASkinEngine::OnControlBindNSISScript "op_advertising" $0
   ${EndIf}

   nsTBCIASkinEngine::FindControl "op_other"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have op_other checkbox"
   ${Else}
	    GetFunctionAddress $0 un.OnOtherMedia
    	nsTBCIASkinEngine::OnControlBindNSISScript "op_other" $0
   ${EndIf}

   nsTBCIASkinEngine::FindControl "btn_badImage"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have btn_badImage checkbox"
   ${Else}
	    GetFunctionAddress $0 un.OnBtnBadMultiplyMedia
    	nsTBCIASkinEngine::OnControlBindNSISScript "btn_badImage" $0
   ${EndIf}

   nsTBCIASkinEngine::FindControl "op_noSmooth"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have op_noSmooth checkbox"
   ${Else}
	    GetFunctionAddress $0 un.OnNoSmooth
    	nsTBCIASkinEngine::OnControlBindNSISScript "op_noSmooth" $0
   ${EndIf}

   nsTBCIASkinEngine::FindControl "btn_noSmooth"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have btn_noSmooth checkbox"
   ${Else}
	    GetFunctionAddress $0 un.OnBtnNoSmooth
    	nsTBCIASkinEngine::OnControlBindNSISScript "btn_noSmooth" $0
   ${EndIf}

   nsTBCIASkinEngine::FindControl "btn_advertising"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have btn_advertising checkbox"
   ${Else}
	    GetFunctionAddress $0 un.OnAdvertising
    	nsTBCIASkinEngine::OnControlBindNSISScript "btn_advertising" $0
   ${EndIf}

   nsTBCIASkinEngine::FindControl "btn_other"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have btn_other checkbox"
   ${Else}
	    GetFunctionAddress $0 un.OnOther
    	nsTBCIASkinEngine::OnControlBindNSISScript "btn_other" $0
   ${EndIf}

   ;全部按钮绑定函数
   ; "卸载" 按钮绑定函数
   nsTBCIASkinEngine::FindControl "Btn_Uninstall"
   Pop $0
   ${If} $0 == "-1"
    	MessageBox MB_OK "Do not have Btn_Uninstall button"
   ${Else}
     GetFunctionAddress $0 un.OnStartUninstallBtnFunc
	   nsTBCIASkinEngine::OnControlBindNSISScript "Btn_Uninstall" $0
   ${EndIf}

  ;"给多次机会" 按钮 绑定函数
   nsTBCIASkinEngine::FindControl "Btn_MoreChance"
   Pop $0
   ${If} $0 == "-1"
	MessageBox MB_OK "Do not have min button"
   ${Else}
  GetFunctionAddress $0 un.OnBtnMoreChanceFunc
	nsTBCIASkinEngine::OnControlBindNSISScript "Btn_MoreChance" $0
   ${EndIf}
   
   ;关闭按钮绑定函数
   nsTBCIASkinEngine::FindControl "Btn_Close0"
   Pop $0
   ${If} $0 == "-1"
	MessageBox MB_OK "Do not have close button"
   ${Else}
	GetFunctionAddress $0 un.OnGlobalCancelFunc
	nsTBCIASkinEngine::OnControlBindNSISScript "Btn_Close0" $0
   ${EndIf}
   ;-------------------------------------确定卸载页面------------------------------------
   ;关闭按钮绑定函数
   nsTBCIASkinEngine::FindControl "Btn_Close1"
   Pop $0
   ${If} $0 == "-1"
	MessageBox MB_OK "Do not have Btn_Close1 button"
   ${Else}
	GetFunctionAddress $0 un.OnGlobalCancelFunc
	nsTBCIASkinEngine::OnControlBindNSISScript "Btn_Close1" $0
   ${EndIf}
   
    ;--------------------------------卸载完成页面----------------------------------------
    ;关闭按钮绑定函数 --- 右上角
   nsTBCIASkinEngine::FindControl "Btn_Close2"
   Pop $0
   ${If} $0 == "-1"
	MessageBox MB_OK "Do not have Btn_Close2 button"
   ${Else}
	GetFunctionAddress $0 un.OnUninstallFinishedBtnFunc
	nsTBCIASkinEngine::OnControlBindNSISScript "Btn_Close2" $0
   ${EndIf}
   
    ;关闭按钮绑定函数
   nsTBCIASkinEngine::FindControl "Btn_UninstallComplete"
   Pop $0
   ${If} $0 == "-1"
	MessageBox MB_OK "Do not have Btn_Close2 button"
   ${Else}
	GetFunctionAddress $0 un.OnUninstallFinishedBtnFunc
	nsTBCIASkinEngine::OnControlBindNSISScript "Btn_UninstallComplete" $0
   ${EndIf}

   nsTBCIASkinEngine::ShowPage

FunctionEnd

Function .onInit

  GetTempFileName $0
  StrCpy $CCtemp $0
  Delete $0
  SetOutPath $temp\${PRODUCT_NAME_EN}Setup\res
  File ".\CC res\NewCharacter.txt"


  StrCpy $installPath "$PROGRAMFILES\Netease\CCVoiceHub\"     ; old  StrCpy $installPath "$PROGRAMFILES\CCVoiceHub\${PRODUCT_NAME_EN}"
  
  Call UpdateFreeSpace 
  ; 判断mutex 知道是否还有安装卸载程序在运行
  !insertmacro MutexCheck "${SETUP_MUTEX_NAME}" $0 $9
  StrCmp $0 0 TEST_CC_RUNNING   ; old :StrCmp $0 0 launch
  MessageBox MB_OK|MB_ICONEXCLAMATION "${PRODUCT_NAME}安装程序已经在运行。"
  Abort
  StrLen $0 "$(^Name)"
  IntOp $0 $0 + 1

  TEST_CC_RUNNING:
    ; 若检测到 CC 客户端程序正在运行，提示用户先关闭运行中的 CC
    FindProcDll::FindProc "${PRODUCT_MAIN_EXE}"
    IntCmp $R0 1 PROMPT_CLOSING 0
    FindProcDll::FindProc "${UPDATE_EXE_NAME}"
    IntCmp $R0 1 PROMPT_CLOSING BEGIN_INSTALLATION

PROMPT_CLOSING:
    MessageBox \
        MB_ICONINFORMATION|MB_RETRYCANCEL \
        "安装程序检测到${PRODUCT_NAME}正在运行，请先关闭当前运行的${PRODUCT_NAME}后重新尝试。" \
        IDRETRY TEST_CC_RUNNING

    Abort
 
  BEGIN_INSTALLATION:

  SectionGetSize ${SecDummy} $1

  ${GetRoot} $CCtemp $0
  System::Call kernel32::GetDiskFreeSpaceEx(tr0,*l,*l,*l.r0)
  System::Int64Op $0 / 1024
  Pop $2
  IntCmp $2 $1 "" "" +3
  ;nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIACANCEL "1" "安装目录空间不足"
  pop $0
  Quit
FunctionEnd

Function .onGUIEnd

  RMDir /r $CCtemp\${PRODUCT_NAME_EN}Temp
  IfFileExists $CCtemp\${PRODUCT_NAME_EN}Temp 0 +2
  RMDir /r /REBOOTOK $CCtemp\${PRODUCT_NAME_EN}Temp 
  IfFileExists $temp\${PRODUCT_NAME_EN}Setup 0 +2
  RMDir /r $temp\${PRODUCT_NAME_EN}Setup
FunctionEnd

Function UpdateFreeSpace
  ${GetRoot} $INSTDIR $0
  StrCpy $1 "Bytes"

  System::Call kernel32::GetDiskFreeSpaceEx(tr0,*l,*l,*l.r0)
   ${If} $0 > 1024
   ${OrIf} $0 < 0
      System::Int64Op $0 / 1024
      Pop $0
      StrCpy $1 "KB"
      ${If} $0 > 1024
      ${OrIf} $0 < 0
	 System::Int64Op $0 / 1024
	 Pop $0
	 StrCpy $diskFreeMB  $0
	 StrCpy $1 "MB"
	 ${If} $0 > 1024
	 ${OrIf} $0 < 0
	    System::Int64Op $0 / 1024
	    Pop $0
	    StrCpy $1 "GB"
	 ${EndIf}
      ${EndIf}
   ${EndIf}

   StrCpy $FreeSpaceSize  "$0$1"
FunctionEnd

Function OnGlobalMinFunc
   nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIAMIN
FunctionEnd

Function OnGlobalCancelFunc
     nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIACANCEL "3" '您确定要退出“CC 开黑”安装程序吗？'
     Pop $0
     
     ${If} $0 == ${ID_YES}
       nsTBCIASkinEngine::ExitTBCIASkinEngine
     ${EndIf}
FunctionEnd

Function InstallShow
   nsTBCIASkinEngine::FindControl "Wizard_InstallProgress"
   Pop $0
   ${If} $0 == "-1"
    	MessageBox MB_OK "Do not have Wizard_InstallProgress button"
   ${Else}
	    nsTBCIASkinEngine::StartInstall  Wizard_InstallProgress
   ${EndIf}
FunctionEnd

;------------------第零个页面
Function OnOpAgreeLicence
 !insertmacro GETOPSTATE $Dialog "op_agree_licence"  $vOpAgreeLicence
FunctionEnd

; handle Option "agree licence"
Function OnBtnShowLicence
    ; Messagebox MB_OK "OnBtnShowLicence" URL开头只是能http
    nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIAOPENURL "http://cc.163.com/act/m/daily/audio_user_agreement/index.html"
FunctionEnd

Function OnBtnShowAudioPrivacy
    nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIAOPENURL "http://cc.163.com/act/m/daily/audio_user_agreement/privacy.html"
FunctionEnd

Function OnBtnShowShare
    ; Messagebox MB_OK "OnBtnShowShare"
    nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIAOPENURL "http://cc.163.com/act/m/daily/policy-license-sdk/index.html?ccvoice=1"
FunctionEnd

Function OnBtnShowChild
    ; Messagebox MB_OK "OnBtnShowChild"
    nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIAOPENURL "http://cc.163.com/act/m/daily/audio_user_agreement/minors_protection.html"
FunctionEnd

; 关闭licence 按钮
Function OnBtnCloseLicenceFunc
   IntOp $boolShowLicence $boolShowLicence - 1
    nsTBCIASkinEngine::SetControlData "LicenceRichEdit" "false" "visible"
    nsTBCIASkinEngine::SetControlData "btn_close_licence" "false" "visible"
    nsTBCIASkinEngine::SetControlData "lbl_licence_edit_bk" "false" "visible"
FunctionEnd

Function onBtnCustInstallFunc
   ; Messagebox MB_OK "op $vOpAgreeLicence"
   ${If} $vOpAgreeLicence == 0
      ;Messagebox MB_OK " please read and select the Licence"
      nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIACANCEL "1" "请先阅读并勾选用户协议"
   ${Else}
	  ;Messagebox MB_OK "1 $vOpAgreeLicence"
      nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIANEXT
   ${EndIf}
FunctionEnd
;------------------第一个页面
Function OnNextBtnFunc

      nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIANEXT
   
FunctionEnd

; "立即安装" 按钮 绑定函数"
Function OnBtnInstallNow
 ${If} $vOpAgreeLicence == 0
   ;Messagebox MB_OK " please read and select the Licence"
   nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIACANCEL "1" "请先阅读并勾选用户协议"
 ${Else}
   Call OnNextBtnFunc
   Call OnStartInstallBtnFunc 
 ${EndIf}
FunctionEnd

; handle Option "create desktop icon"
Function OnOpCreateDeskIcon
 !insertmacro GETOPSTATE $Dialog "op_create_deskicon"  $vOpCreateDeskIcon
FunctionEnd

;handle button create desktop icon
Function OnBtnCreateDeskIcon
nsTBCIASkinEngine::SetControlData "op_create_deskicon" "false" "optioncheck"
 ${If} $vOpCreateDeskIcon == 0
       StrCpy $vOpCreateDeskIcon 1
 ${Else}
       StrCpy $vOpCreateDeskIcon 0
 ${EndIf}
FunctionEnd

; handle Option "add quick launch"
Function OnOpAddQuickLaunch
 !insertmacro GETOPSTATE $Dialog "op_add_quick_launch"  $vOpAddQuickLaunch
FunctionEnd

;handle button add quick lanuch
Function OnBtnAddQuickLaunch
nsTBCIASkinEngine::SetControlData "op_add_quick_launch" "false" "optioncheck"
 ${If} $vOpAddQuickLaunch == 0
       StrCpy $vOpAddQuickLaunch 1
 ${Else}
       StrCpy $vOpAddQuickLaunch 0
 ${EndIf}
FunctionEnd


Function OnBtnStartNow
 ;MessageBox MB_OK "btn_start_now"
 Call OnLeaveCompletePage
 nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIAFINISHEDINSTALL
FunctionEnd

Function OnLeaveCompletePage
  ; 开机自动启动
 ; Exec '"$INSTDIR\CC.exe" -installlog -autorun $vOpRunAuto -runccnow $vOpRunCC'
 StrCmp $vOpRunAuto "1" "" +2
 WriteRegStr ${PRODUCT_AUTORUN_ROOT_KEY} "${PRODUCT_AUTORUN_KEY}" "${PRODUCT_AUTORUN_VALUE}" "$\"$INSTDIR\CCVoicehubLauncher.exe$\""
 StrCpy $InstallOptions "-autorun $vOpRunAuto -runccnow $vOpRunCC"
 System::Call '${SetEnvironmentVariable}("ccvoice_install_options", "$InstallOptions").r0'
FunctionEnd

; Handle Option "运行CC 开黑"
Function OnOpRunCC
 !insertmacro GETOPSTATE $Dialog "op_run_cc"  $vOpRunCC
 ${If} $vOpRunCC == 1
     nsTBCIASkinEngine::SetControlData "btn_start_now" "true" "visible"   ; 显示
     nsTBCIASkinEngine::SetControlData "btn_install_complete" "false" "visible"   ; 显示
     Exec CC_FINISHPAGE_RUN
 ${Else}
     nsTBCIASkinEngine::SetControlData "btn_start_now" "false" "visible"   ; 显示
     nsTBCIASkinEngine::SetControlData "btn_install_complete" "true" "visible"   ; 显示
  ${EndIf}
FunctionEnd

; Handle Option "开机自动启动"
Function OnOpRunAuto
 !insertmacro GETOPSTATE $Dialog "op_run_auto"  $vOpRunAuto

FunctionEnd

; Handle Option "开机自动启动"
Function OnBtnRunAuto
nsTBCIASkinEngine::SetControlData "op_run_auto" "false" "optioncheck"
 ${If} $vOpRunAuto == 0
       StrCpy $vOpRunAuto 1
 ${Else}
       StrCpy $vOpRunAuto 0
 ${EndIf}
FunctionEnd

Function OnBtnInstallComplete
  ; Exec '"$INSTDIR\CC.exe" -installlog -autorun $vOpRunAuto -runccnow $vOpRunCC'
  StrCmp $vOpRunAuto "1" "" +2
 WriteRegStr ${PRODUCT_AUTORUN_ROOT_KEY} "${PRODUCT_AUTORUN_KEY}" "${PRODUCT_AUTORUN_VALUE}" "$\"$INSTDIR\CCVoicehubLauncher.exe$\""
 nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIAFINISHEDINSTALL
  StrCpy $InstallOptions "-autorun $vOpRunAuto -runccnow $vOpRunCC -installreport"
 System::Call '${SetEnvironmentVariable}("ccvoice_install_options", "$InstallOptions").r0'
FunctionEnd

Function OnBtnInstallCompleteRunChecked
 Call OnBtnInstallComplete
 Call OnRunChecked
FunctionEnd

; btn 显示新特性
Function OnBtnShowCharacter
  ${If} $boolShowCharacter == 0
    IntOp $boolShowCharacter $boolShowCharacter + 1
    nsTBCIASkinEngine::SetControlData "lbl_character_edit_bk" "true" "visible"
    nsTBCIASkinEngine::SetControlData "CharacterRichEdit" "true" "visible"   ; 此句必须放在上一句的后面，否则关闭按钮会被遮挡
    nsTBCIASkinEngine::SetControlData "btn_close_character" "true" "visible"
  ${EndIf}
FunctionEnd

Function OnBtnCloseCharacter
${If} $boolShowCharacter == 1
    IntOp $boolShowCharacter $boolShowCharacter - 1
    nsTBCIASkinEngine::SetControlData "btn_close_character" "false" "visible"
    nsTBCIASkinEngine::SetControlData "CharacterRichEdit" "false" "visible"
    nsTBCIASkinEngine::SetControlData "lbl_character_edit_bk" "false" "visible"
${EndIf}
FunctionEnd


Function OnTextChangeFunc
   ; 改变可用磁盘大小
   nsTBCIASkinEngine::GetControlData edit_path "text"
   Pop $0
   StrCpy $INSTDIR $0

   ;重新获取磁盘空间
   Call UpdateFreeSpace

      ;更新磁盘空间文本显示
   nsTBCIASkinEngine::FindControl "freespace"
   Pop $0
   ${If} $0 == "-1"
	MessageBox MB_OK "Do not have freespace button"
   ${Else}
	;nsTBCIASkinEngine::SetText2Control "Wizard_UsableSpaceLab4Page2"  $FreeSpaceSize
	nsTBCIASkinEngine::SetControlData "freespace"  $diskFreeMB  "spacetext"
   ${EndIf}

FunctionEnd

Function OnInstallPathBrownBtnFunc
   nsTBCIASkinEngine::SelectFolderDialog "请选择安装路径"
   Pop $installPath
   StrCpy $0 $installPath
   ${If} $0 == "-1"
   ${Else}
      StrCpy $INSTDIR "$installPath\${PRODUCT_NAME_EN}"
      ;设置安装路径编辑框文本
      nsTBCIASkinEngine::FindControl "edit_path"
      Pop $0
      ${If} $0 == "-1"
	       MessageBox MB_OK "Do not have edit_path button"
      ${Else}
	 ;nsTBCIASkinEngine::SetText2Control "Wizard_InstallPathEdit4Page2"  $installPath
	 StrCpy $installPath $INSTDIR
	 nsTBCIASkinEngine::SetControlData "edit_path"  $installPath  "text"
      ${EndIf}
   ${EndIf}

   ;重新获取磁盘空间
   Call UpdateFreeSpace
   ;更新磁盘空间文本显示
   nsTBCIASkinEngine::FindControl "freespace"
   Pop $0
   ${If} $0 == "-1"
	MessageBox MB_OK "Do not have freespace button"
   ${Else}
	;nsTBCIASkinEngine::SetText2Control "Wizard_UsableSpaceLab4Page2"  $FreeSpaceSize
	nsTBCIASkinEngine::SetControlData "freespace"  $diskFreeMB  "spacetext"
   ${EndIf} 

   ${If} $FreeSpaceSize == "0Bytes"
    nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIACANCEL "2" "目录空间不足。"
  ;nsTBCIASkinEngine::SetControlData "Wizard_StartInstallBtn4Page2" "false" "enable"
   ${Else}
   ;MessageBox MB_OK "valide path, FreeSapce: $FreeSpaceSize"
	;nsTBCIASkinEngine::SetControlData "Wizard_StartInstallBtn4Page2" "true" "enable"
   ${EndIf}

FunctionEnd

Function OnDesktopIconStateFunc
   nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIAOPTIONSTATE "Wizard_ShortCutBtn4Page2" ""
   Pop $0
   ${If} $0 == "1"
     StrCpy $DesktopIconState "1"
   ${Else}
     StrCpy $DesktopIconState "0"
   ${EndIf}
FunctionEnd

Function OnFastIconStateFunc
   nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIAOPTIONSTATE "Wizard_QuickLaunchBarBtn4Page2" ""
   Pop $1
   ${If} $1 == "1"
      StrCpy $FastIconState "1"
   ${Else}
      StrCpy $FastIconState "0"
   ${EndIf}
FunctionEnd



Function OnBackBtnFunc
   nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIABACK
FunctionEnd

Function OnStartInstallBtnFunc
   nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIASTARTINSTALL
FunctionEnd

Function BuildShortCut
    ; 开始菜单
    CreateDirectory "$SMPROGRAMS\CC 开黑"
    CreateShortCut "$SMPROGRAMS\CC 开黑\CC 开黑.lnk" "$\"$INSTDIR\CCVoicehubLauncher.exe$\""
    CreateShortCut "$SMPROGRAMS\CC 开黑\卸载CC 开黑.lnk" "$\"$INSTDIR\uninstall.exe$\""
    CreateShortCut "$STARTMENU\CC 开黑.lnk" "$\"$INSTDIR\CCVoicehubLauncher.exe$\""

    ;桌面快捷方式
    StrCmp $vOpCreateDeskIcon "1" "" +2
    Call OnDesktopShortcutChecked

    ;快速启动
    StrCmp $vOpAddQuickLaunch "1" "" +2
    Call OnQuickLaunchChecked
FunctionEnd

;------------------第三个页面
; 运行CC
Function OnRunChecked
	Exec "${CC_FINISHPAGE_RUN}"
FunctionEnd

; 桌面快捷方式
Function OnDesktopShortcutChecked
    CreateShortCut "$DESKTOP\${CC_LINK_NAME}" "${CC_FINISHPAGE_RUN}"
FunctionEnd

; 快速启动
Function OnQuickLaunchChecked
    CreateShortCut "$QUICKLAUNCH\${PRODUCT_NAME}.lnk" "$INSTDIR\${PRODUCT_MAIN_EXE}"
FunctionEnd

Function un.UninstallShow
   ;进度条绑定函数?
   nsTBCIASkinEngine::FindControl "Wizard_UninstallProgress"
   Pop $0
   ${If} $0 == "-1"
	MessageBox MB_OK "Do not have Wizard_InstallProgress button"
   ${Else}
	nsTBCIASkinEngine::StartUninstall  Wizard_UninstallProgress
   ${EndIf}
FunctionEnd

Function un.OnGlobalCancelFunc
   nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIACANCEL "3" "你确实要退出CC 开黑卸载程序?"
   Pop $0
   ${If} $0 == ${ID_YES}
     nsTBCIASkinEngine::ExitTBCIASkinEngine
   ${EndIf}
FunctionEnd

Function un.OnBtnUninstall
   nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIACANCEL "3" "系统将卸载本机安装的 CC 开黑，是否继续？"
FunctionEnd

Function un.OnStartUninstallBtnFunc
  ;messagebox MB_OK "start uninstall"
  nsTBCIASkinEngine::TBCIASendMessage $Dialog  WM_TBCIACANCEL "4" "系统将卸载本机安装的 CC 开黑，是否继续？"
  pop $0
  ${If} $0 == ${ID_NO}
      nsTBCIASkinEngine::ExitTBCIASkinEngine 
  ${Else}
	  KillProcDLL::KillProc "QDesktopTips.exe"
      StrCpy $opSaveAccount $0 ; 返回值：3- 选中， 4- 未选中
      
      ClearErrors
 
    unTEST_CC_RUNNING:
    ; 若检测到 CC 客户端程序正在运行，提示用户先关闭运行中的 CC
    FindProcDll::FindProc "${PRODUCT_MAIN_EXE}"
    IntCmp $R0 1 unPROMPT_CLOSING 0
    FindProcDll::FindProc "${UPDATE_EXE_NAME}"
    IntCmp $R0 1 unPROMPT_CLOSING BEGIN_UNINSTALLATION

    unPROMPT_CLOSING:
    nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIACANCEL "0" "卸载程序检测到${PRODUCT_NAME}正在运行，请先关闭当前运行的${PRODUCT_NAME}后重新尝试"
    pop $0
    ${If} $0 == ${ID_YES}
        pop $R0
        ${If} $R0 != 0
          goto unTEST_CC_RUNNING
         ${EndIf}
    ${Else}
        Abort
    ${EndIF}
    BEGIN_UNINSTALLATION: 
      nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIASTARTUNINSTALL
  ${EndIf}
   ${GetTime} "" "L" $0 $1 $2 $3 $4 $5 $6
   StrCpy $postJson "%7b%22noFavourite%22%3a$opNoFav%2c%22appCrash%22%3a$opAppCrash%2c%22noFun%22%3a$opBotherOperation%2c%22highCpu%22%3a$opHighCpu%2c%22badMedia%22%3a$opBadMultiplyMedia%2c%22noSmooth%22%3a$opNoSmooth%2c%22uninstallTime%22%3a%22$2-$1-$0%20$4%3a$5%3a$6%22%2c%22opAdvertising%22%3a$opAdvertising%2c%22opOther%22%3a$opOther%7d"
   ;MessageBox MB_OK $postJson
    StrCpy $postParamater "json=$postJson"
   ;inetc::get   "http://log.cc.netease.com/bi/Uninstall?$postParamater" /END
   Pop $0
FunctionEnd

Function un.OnbtnMoreChanceFunc
  nsTBCIASkinEngine::ExitTBCIASkinEngine
FunctionEnd


Function un.OnUninstallFinishedBtnFunc
   nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIAFINISHEDINSTALL
FunctionEnd

Function un.AfterUnistall
	IfErrors 0 QUERY_REBOOT
	       nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIACANCEL "1" "部分文件删除失败，可能需要手动删除。"
	QUERY_REBOOT:
   IfRebootFlag 0 NO_REBOOT
	    nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIACANCEL "3" "部分项目将在重启后删除，是否现在重启计算机？"
	
	    Pop $0
	    ${If} $0 == ${ID_YES}
	      ReBoot
	    ${EndIf}
   	NO_REBOOT:
	      return

FunctionEnd

Function un.onGUIEnd
 
  IfFileExists $temp\${PRODUCT_NAME_EN}Setup 0 +2
  RMDir /r $temp\${PRODUCT_NAME_EN}Setup
FunctionEnd


Function un.OnNoFavOp
 !insertmacro GETOPSTATE $Dialog "op_noFavPly"  $opNoFav
FunctionEnd

Function un.OnBtnNoFavOp
 nsTBCIASkinEngine::SetControlData "op_noFavPly" "false" "optioncheck"
 ${If} $opNoFav == 0
       StrCpy $opNoFav 1
 ${Else}
       StrCpy $opNoFav 0
 ${EndIf}
FunctionEnd

Function un.OnAppCrash
 !insertmacro GETOPSTATE $Dialog "op_crash"  $opAppCrash
FunctionEnd

Function un.OnBtnAppCrash
 nsTBCIASkinEngine::SetControlData "op_crash" "false" "optioncheck"
 ${If} $opAppCrash == 0
       StrCpy $opAppCrash 1
 ${Else}
       StrCpy $opAppCrash 0
 ${EndIf}
FunctionEnd

Function un.OnBotherOperation
 !insertmacro GETOPSTATE $Dialog "op_noFun"  $opBotherOperation
FunctionEnd


Function un.OnBtnBotherOperation
 nsTBCIASkinEngine::SetControlData "op_noFun" "false" "optioncheck"
 ${If} $opBotherOperation == 0
       StrCpy $opBotherOperation 1
 ${Else}
       StrCpy $opBotherOperation 0
 ${EndIf}
FunctionEnd

Function un.OnHighCpu
 !insertmacro GETOPSTATE $Dialog "op_highLoad"  $opHighCpu
FunctionEnd

Function un.OnBtnHighCpu
 nsTBCIASkinEngine::SetControlData "op_highLoad" "false" "optioncheck"
 ${If} $opHighCpu == 0
       StrCpy $opHighCpu 1
 ${Else}
       StrCpy $opHighCpu 0
 ${EndIf}
FunctionEnd

Function un.OnBadMultiplyMedia
 !insertmacro GETOPSTATE $Dialog "op_badImage"  $opBadMultiplyMedia
FunctionEnd

Function un.OnAdvertisingMedia
 !insertmacro GETOPSTATE $Dialog "op_advertising"  $opAdvertising
FunctionEnd

Function un.OnOtherMedia
 !insertmacro GETOPSTATE $Dialog "op_other"  $opOther
FunctionEnd

Function un.OnBtnBadMultiplyMedia
  nsTBCIASkinEngine::SetControlData "op_badImage" "false" "optioncheck"
 ${If} $opBadMultiplyMedia == 0
       StrCpy $opBadMultiplyMedia 1
 ${Else}
       StrCpy $opBadMultiplyMedia 0
 ${EndIf}
FunctionEnd

Function un.OnNoSmooth
 !insertmacro GETOPSTATE $Dialog "op_noSmooth"  $opNoSmooth 
FunctionEnd

Function un.OnBtnNoSmooth
  nsTBCIASkinEngine::SetControlData "op_noSmooth" "false" "optioncheck"
 ${If} $opNoSmooth == 0
       StrCpy $opNoSmooth 1
 ${Else}
       StrCpy $opNoSmooth 0
 ${EndIf}
FunctionEnd

Function un.OnAdvertising
  nsTBCIASkinEngine::SetControlData "op_advertising" "false" "optioncheck"
 ${If} $opAdvertising == 0
       StrCpy $opAdvertising 1
 ${Else}
       StrCpy $opAdvertising 0
 ${EndIf}
FunctionEnd

Function un.OnOther
  nsTBCIASkinEngine::SetControlData "op_other" "false" "optioncheck"
 ${If} $opOther == 0
       StrCpy $opOther 1
 ${Else}
       StrCpy $opOther 0
 ${EndIf}
FunctionEnd
