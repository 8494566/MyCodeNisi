; ѡ��ѹ����ʽ
SetCompressor /SOLID LZMA

!addIncludeDir .

; �����ͷ�ļ�
!include "nsDialogs.nsh"
!include "FileFunc.nsh"
!include  MUI.nsh
!include  LogicLib.nsh
!include  WinMessages.nsh
!include "MUI2.nsh"
!include "WordFunc.nsh"
!include "Library.nsh"
!include "basehelp.nsh"



!addplugindir Plugins
!addplugindir  .

; �����dll
ReserveFile "${NSISDIR}\Plugins\system.dll"
ReserveFile "${NSISDIR}\Plugins\nsDialogs.dll"
ReserveFile "${NSISDIR}\Plugins\nsExec.dll"
ReserveFile "${NSISDIR}\Plugins\InstallOptions.dll"
;ReserveFile "Plugins\nsTBCIASkinEngine.dll" ; �������ǵ�Ƥ�����



; ���ƺ궨��
; ���������Դ�ļ�λ�� ;;
!define SOURCE_DIR ".\bin"

; CC ��װ��Ϣ����
!define PRODUCT_NAME "����CC"
!define PRODUCT_DETAIL "����CC"
!define PRODUCT_PUBLISHER "���׻����������޹�˾"
!define PRODUCT_WEB_SITE "http://CC.163.com"
!define PRODUCT_VERSION           "1.0.0.1"
!define PRODUCT_NAME_EN           "CC"

!define PRODUCT_DIR_KEY "Software\Microsoft\Windows\CurrentVersion\App Paths\CC.exe"
!define PRODUCT_DIR_ROOT_KEY "HKLM"

!define PRODUCT_UNINST_ROOT_KEY "HKLM"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"

!define PRODUCT_AUTORUN_ROOT_KEY "HKCU"
!define PRODUCT_AUTORUN_KEY "Software\Microsoft\Windows\CurrentVersion\Run"
!define PRODUCT_AUTORUN_VALUE "CC"

!define PRODUCT_SUB_KEY           "SOFTWARE\360\360Safe"
!define PRODUCT_MAIN_EXE          "CC.exe"
!define PRODUCT_MAIN_EXE_MUTEX    "{3D3CB097-93A1-440a-954F-6D253C50CE32}"
!define SETUP_MUTEX_NAME          "NeteaseCCInstaller" ;  old"{50A3E52E-6F7F-4411-9791-63BD15BBF2C2}"

!define PRODUCT_LOCALDATA_ROOT_KEY "HKCU"
!define PRODUCT_LOCALDATA_KEY "Software\Netease\CC"
!define PRODUCT_LOCALDATA_INSTDIR_KEY "InstallLocation"
!define PRODUCT_LOCALDATA_AGREEMENT "Agree"

!define PRODUCT_LOCAL_KEY "Software\Netease\CC\Local"
!define PRODUCT_LOCAL_INSTDIR_KEY "T"

!define MAIN_EXE_NAME "cc.exe"
!define UPDATE_EXE_NAME "UpdateExec.exe"

; CC ��վͨ�����ע���
!define PRODUCT_CLASSES_ROOT_KEY "HKCR"
!define PRODUCT_CLASSES_ROOT_URL_KEY "cc"
!define PRODUCT_CLASSES_ROOT_URL_VALUE "URL:cc Protocol"
!define PRODUCT_CLASSES_ROOT_PROTOCOL_VALUE ""
!define PRODUCT_CLASSES_ROOT_COMMAND_KEY "cc\shell\open\command"
!define PRODUCT_CLASSES_ROOT_COMMAND_VALUE "$\"$INSTDIR\Start.exe$\" /url $\"%1$\""

!define MUI_ICON                  ".\CC res\install.ico"    ;��װicon
!define MUI_UNICON                ".\CC res\uninstall.ico"  ;ж��icon

; ��ݷ�ʽ
!define CC_FINISHPAGE_RUN "$\"$INSTDIR\Start.exe$\""
!define CC_LINK_NAME "����CC.lnk"



!define ID_YES  "6"
!define ID_NO   "7"

!macro MutexCheck _mutexname _outvar _handle
System::Call 'kernel32::CreateMutexA(i 0, i 0, t "${_mutexname}" ) i.r1 ?e'
StrCpy ${_handle} $1
Pop ${_outvar}
!macroend

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


;Languages
!insertmacro MUI_LANGUAGE "SimpChinese"

Var Dialog
Var MessageBoxHandle
Var DesktopIconState
Var FastIconState
Var FreeSpaceSize
Var installPath
Var timerID
Var timerID4Uninstall
Var changebkimageIndex
Var changebkimage4UninstallIndex
Var RunNow
Var InstallState
Var LocalPath
Var CCtemp

; ����ҳ
Var vOpAgreeLicence
Var boolShowLicence ;�����ʾ�û�Э��İ�ť
Var Skip_Flag
; ��һҳ
Var vOpCreateDeskIcon
Var vOpAddQuickLaunch
; �ڶ�ҳ
; ����ҳ
Var vOpRunCC
Var vOpRunAuto
Var boolShowCharacter

Name      "${PRODUCT_DETAIL}"              ;��ʾ�Ի���ı��� - "����CC"
OutFile   "${PRODUCT_NAME_EN}Setup.exe"    ;�����װ����

InstallDir "$PROGRAMFILES\Netease\CC\"                   ;Default installation folder
;InstallDirRegKey ${PRODUCT_ROOT_KEY} ${PRODUCT_SUB_KEY} "installDir"   ;Get installation folder from registry if available
                 ;   HKLM            SOFTWARE\360\360Safe
InstallDirRegKey ${PRODUCT_LOCALDATA_ROOT_KEY} "${PRODUCT_LOCALDATA_KEY}" "${PRODUCT_LOCALDATA_INSTDIR_KEY}"
                   ;  HKCU                        Software\Netease\CC         InstallLocation


;Request application privileges for Windows Vista
RequestExecutionLevel admin

;--------------------------------------------------------------------------------------------------------------------------------------------------------------

;Installer Sections
Section "Dummy Section" SecDummy
  ; ����Ҫ�����İ�װ�ļ�
  SetOutPath "$INSTDIR"
  MessageBox MB_OK "section SecDummy"
  SetOverWrite on
  File /r /x .svn   ".\360Safe\*.*"
  SetOverWrite on
  SetRebootFlag false
  
  Call BuildShortCut

SectionEnd

Section -Post
  MessageBox MB_OK "section -post"
    ; ��ע����м�¼��װ·��
    WriteRegStr ${PRODUCT_LOCALDATA_ROOT_KEY} "${PRODUCT_LOCALDATA_KEY}" "${PRODUCT_LOCALDATA_INSTDIR_KEY}" "$\"$INSTDIR$\""
	 ;  ��ע����д���local
	  WriteRegStr ${PRODUCT_LOCALDATA_ROOT_KEY} "${PRODUCT_LOCAL_KEY}" "${PRODUCT_LOCAL_INSTDIR_KEY}" "1"

    ; �ڡ���ӻ�ɾ����������ʾ������CC��
    WriteUninstaller "$INSTDIR\uninstall.exe"
    WriteRegStr ${PRODUCT_DIR_ROOT_KEY} "${PRODUCT_DIR_KEY}" "" "$\"$INSTDIR\CC.exe$\""
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayName" "${PRODUCT_NAME}"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$\"$INSTDIR\CC.exe$\""
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"

    ; �����Զ�����
    WriteRegStr ${PRODUCT_AUTORUN_ROOT_KEY} "${PRODUCT_AUTORUN_KEY}" "${PRODUCT_AUTORUN_VALUE}" "$\"$INSTDIR\Start.exe$\""

    ; ��վͨ��
    WriteRegStr ${PRODUCT_CLASSES_ROOT_KEY} "${PRODUCT_CLASSES_ROOT_URL_KEY}" "" "${PRODUCT_CLASSES_ROOT_URL_VALUE}"
    WriteRegStr ${PRODUCT_CLASSES_ROOT_KEY} "${PRODUCT_CLASSES_ROOT_URL_KEY}" "URL Protocol" "${PRODUCT_CLASSES_ROOT_PROTOCOL_VALUE}"
    WriteRegStr ${PRODUCT_CLASSES_ROOT_KEY} "${PRODUCT_CLASSES_ROOT_COMMAND_KEY}" "" "${PRODUCT_CLASSES_ROOT_COMMAND_VALUE}"

    ; Э�����
    WriteRegStr ${PRODUCT_LOCALDATA_ROOT_KEY} "${PRODUCT_LOCALDATA_KEY}" "${PRODUCT_LOCALDATA_AGREEMENT}" "1"
    Exec '"$INSTDIR\CC.exe" -installlog'

SectionEnd

;--------------------------------------------------------------------------------------------------------------------------------------------------------------

;Uninstaller Section
!include "uninstall.nsh"

Section "Uninstall"
    ClearErrors

    unTEST_CC_RUNNING:
    ; ����⵽ CC �ͻ��˳����������У���ʾ�û��ȹر������е� CC
    FindProcDll::FindProc "${MAIN_EXE_NAME}"
    IntCmp $R0 1 unPROMPT_CLOSING 0
    FindProcDll::FindProc "${UPDATE_EXE_NAME}"
    IntCmp $R0 1 unPROMPT_CLOSING BEGIN_UNINSTALLATION

    unPROMPT_CLOSING:
    nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIACANCEL "0" "the ${PRODUCT_NAME} is running,please clode the running ${PRODUCT_NAME} and retry"
    pop $0
    ${If} $0 == ${ID_YES}
        goto unTEST_CC_RUNNING
    ${Else}
        Abort
    ${EndIF}
;    MessageBox \
;        MB_ICONINFORMATION|MB_RETRYCANCEL \
;        "��װ�����⵽${PRODUCT_NAME}�������У����ȹرյ�ǰ���е�${PRODUCT_NAME}�����³��ԡ�" \
;        IDRETRY TEST_POPO_RUNNING

;    Abort

   BEGIN_UNINSTALLATION:



    ; ɾ�������Ŀ�ݷ�ʽ
    Delete "$SMPROGRAMS\����CC\Uninstall.lnk"
    Delete "$STARTMENU\����CC.lnk"
    Delete "$DESKTOP\����CC.lnk"
    Delete "$SMPROGRAMS\����CC\����CC.lnk"
    Delete "$QUICKLAUNCH\����CC.lnk"
    RMDir /REBOOTOK /r "$SMPROGRAMS\����CC"

	; ɾ������������־�͸�������
    RMDir /r "$INSTDIR\UpdateTemp"
    RMDir /r "$INSTDIR\Temp"
    RMDir /r "$INSTDIR\Start"
    RMDir /r "$INSTDIR\UpdateExec"
    Delete "$INSTDIR\Trace_Log.txt"

	; ���հ�װ��־ɾ��
    !insertmacro MacroUninstallByLog

	; ɾ��ж�س���
    Delete "$INSTDIR\uninstall.exe"

    ; ��ʾ�û��Ƿ�����Ϣ��ʷ���û���Ϣ
    MessageBox \
        MB_ICONQUESTION|MB_YESNO|MB_DEFBUTTON1 \
        "save CC account and the Chat Message?" \
        IDYES SKIP_USERS_DIR

    ; ɾ���û�����Ϣ��ʷ��˽����Ϣ
    DeleteRegKey ${PRODUCT_LOCALDATA_ROOT_KEY} "${PRODUCT_LOCALDATA_KEY}"
    RMDir /REBOOTOK /r "$INSTDIR\Users"

SKIP_USERS_DIR:
    ; �����װĿ¼�ѿգ�ɾ����װĿ¼
    Push $INSTDIR
    Call un.RMDirIfEmpty2
    ; ����ע���
    DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"
    DeleteRegKey ${PRODUCT_DIR_ROOT_KEY} "${PRODUCT_DIR_KEY}"
    DeleteRegValue ${PRODUCT_AUTORUN_ROOT_KEY} "${PRODUCT_AUTORUN_KEY}" "${PRODUCT_AUTORUN_VALUE}"

    IfErrors 0 QUERY_REBOOT
    nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIACANCEL "0" "some files can not be deleted,please delete it by yourself"

QUERY_REBOOT:
    ; �� Reboot ��־�����ã���ʾ�û����������
;    IfRebootFlag 0 NO_REBOOT
;    nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIACANCEL "1" "some project will be cleared after reboot, Reboot Now?"
    ;MessageBox MB_YESNO "some project will be cleared after reboot, Reboot Now?" IDYES FORYES IDNO NO_REBOOT

;    Pop $0
;    ${If} $0 == ${ID_YES}
;      ReBoot
;    ${Else}
;      goto NO_REBOOT
;    ${EndIf}
;NO_REBOOT:
SectionEnd

;--------------------------------------------------------------------------------------------------------------------------------------------------------------
; ��װ��ж�ؽ���
Page         custom     CC
Page         instfiles  "" InstallShow


UninstPage   custom     un.CCUninstall
UninstPage   instfiles  "" un.UninstallShow un.AfterUnistall
;--------------------------------------------------------------------------------------------------------------------------------------------------------------

Function CC
  
  nsTBCIASkinEngine::FindControl "Wizard_CloseBtn0"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have Wizard_CloseBtn0 button"
   ${Else}
	GetFunctionAddress $0 OnGlobalCancelFunc
	nsTBCIASkinEngine::OnControlBindNSISScript "Wizard_CloseBtn0" $0
   ${EndIf}
   
   ;���ٰ�װ ��ť�� ������
   nsTBCIASkinEngine::FindControl "btn_quick_install"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have btn_quick_install button"
   ${Else}
	    GetFunctionAddress $0 OnBtnInstallNow
    	nsTBCIASkinEngine::OnControlBindNSISScript "btn_quick_install" $0
   ${EndIf}
   
   ; Option - ͬ������CC���û����Э��
  nsTBCIASkinEngine::FindControl "op_agree_licence"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have op_agree_licence button"
   ${Else}
	    GetFunctionAddress $0 OnOpAgreeLicence
    	nsTBCIASkinEngine::OnControlBindNSISScript "op_agree_licence" $0
   ${EndIf}
   Strcpy $vOpAgreeLicence 0
   
   ; Button - �û����Э��
  nsTBCIASkinEngine::FindControl "btn_show_licence"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have op_agree_licence button"
   ${Else}
      Strcpy $boolShowLicence 0
	    GetFunctionAddress $0 OnBtnShowLicence
    	nsTBCIASkinEngine::OnControlBindNSISScript "btn_show_licence" $0
   ${EndIf}
   
   ; ��ʾlicense
  nsTBCIASkinEngine::FindControl "LicenceRichEdit"
  Pop $0
   ${If} $0 == "-1"
	MessageBox MB_OK "Do not have LicenceRichEdit button"
	 ${Else}
	nsTBCIASkinEngine::ShowLicense "LicenceRichEdit" "Licencea.txt"  ; "���Э��ؼ�����"
	${EndIf}
   
  ; �ر� Э���ť
   nsTBCIASkinEngine::FindControl "btn_close_licence"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have btn_close_licence button"
   ${Else}
	GetFunctionAddress $0 OnBtnCloseLicenceFunc
	nsTBCIASkinEngine::OnControlBindNSISScript "btn_close_licence" $0
   ${EndIf}
   
   ;�Զ��尲װ��ť�󶨺���
   nsTBCIASkinEngine::FindControl "btn_custom_install"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have btn_custom_install button"
   ${Else}
	     GetFunctionAddress $0 onBtnCustInstallFunc
	     nsTBCIASkinEngine::OnControlBindNSISScript "btn_custom_install" $0
   ${EndIf}
   
  ; -----------------------------��һ��ҳ�� ----------------------------------------
  ; �رհ�ť
   nsTBCIASkinEngine::FindControl "Wizard_CloseBtn1"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have Wizard_CloseBtn1 button"
   ${Else}
	GetFunctionAddress $0 OnGlobalCancelFunc
	nsTBCIASkinEngine::OnControlBindNSISScript "Wizard_CloseBtn1" $0
   ${EndIf}

  ; Option - ��������ͼ��
  nsTBCIASkinEngine::FindControl "op_create_deskicon"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have op_agree_licence button"
   ${Else}
	    GetFunctionAddress $0 OnOpCreateDeskIcon
    	nsTBCIASkinEngine::OnControlBindNSISScript "op_create_deskicon" $0
   ${EndIf}

  ; Option - ��ӵ����������
  nsTBCIASkinEngine::FindControl "op_add_quick_launch"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have op_agree_licence button"
   ${Else}
	    GetFunctionAddress $0 OnOpAddQuickLaunch
    	nsTBCIASkinEngine::OnControlBindNSISScript "op_add_quick_launch" $0
   ${EndIf}
   
   ; ������װ ��ť
   nsTBCIASkinEngine::FindControl "btn_install_now"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have btn_install_now"
   ${Else}
	   GetFunctionAddress $0 OnStartInstallBtnFunc
	nsTBCIASkinEngine::OnControlBindNSISScript "btn_install_now" $0
   ${EndIf}
   
   ; ���� ��ť
   nsTBCIASkinEngine::FindControl "btn_back"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have btn_back"
   ${Else}
	GetFunctionAddress $0 OnBackBtnFunc
	nsTBCIASkinEngine::OnControlBindNSISScript "btn_back" $0
	${EndIf}
	
	;��װ·���༭���趨����
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
   
   ;��װ·�������ť�󶨺���
    nsTBCIASkinEngine::FindControl "btn_browser"
   Pop $0
   ${If} $0 == "-1"
	MessageBox MB_OK "Do not have btn_browser button"
   ${Else}
	GetFunctionAddress $0 OnInstallPathBrownBtnFunc
        nsTBCIASkinEngine::OnControlBindNSISScript "btn_browser"  $0
   ${EndIf}

    ;-----------------------------�ڶ���ҳ�� ----------------------------------------
    ; �رհ�ť
   nsTBCIASkinEngine::FindControl "Wizard_CloseBtn2"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have Wizard_CloseBtn2 button"
   ${Else}
	GetFunctionAddress $0 OnGlobalCancelFunc
	nsTBCIASkinEngine::OnControlBindNSISScript "Wizard_CloseBtn2" $0
   ${EndIf}
   
     ; -----------------------------������ҳ�� ----------------------------------------

   ; �رհ�ť
   nsTBCIASkinEngine::FindControl "Wizard_CloseBtn3"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have Wizard_CloseBtn3 button"
   ${Else}
	GetFunctionAddress $0 OnBtnInstallComplete
	nsTBCIASkinEngine::OnControlBindNSISScript "Wizard_CloseBtn3" $0
   ${EndIf}

   ; Option ��������CC
   nsTBCIASkinEngine::FindControl "op_run_cc"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have op_run_cc button"
   ${Else}
	    GetFunctionAddress $0 OnOpRunCC
    	nsTBCIASkinEngine::OnControlBindNSISScript "op_run_cc" $0
   ${EndIf}
   
   ; Option �����Զ�����
    nsTBCIASkinEngine::FindControl "op_run_auto"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have op_run_auto button"
   ${Else}
	    GetFunctionAddress $0 OnOpRunAuto
    	nsTBCIASkinEngine::OnControlBindNSISScript "op_run_auto" $0
   ${EndIf}

   ; "��ʾ������" ��ť
   nsTBCIASkinEngine::FindControl "btn_show_character"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have btn_show_character button"
   ${Else}
	GetFunctionAddress $0 OnBtnShowCharacter
	nsTBCIASkinEngine::OnControlBindNSISScript "btn_show_character" $0
	Strcpy $boolShowCharacter 0
   ${EndIf}

   ; �ر������� ��ť
   nsTBCIASkinEngine::FindControl "btn_close_character"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have btn_close_character button"
   ${Else}
	GetFunctionAddress $0 OnBtnCloseCharacter
	nsTBCIASkinEngine::OnControlBindNSISScript "btn_close_character" $0
   ${EndIf}
   
  ; ��ʾCharacter
  nsTBCIASkinEngine::FindControl "CharacterRichEdit"
  Pop $0
   ${If} $0 == "-1"
	MessageBox MB_OK "Do not have CharacterRichEdit button"
	 ${Else}
	nsTBCIASkinEngine::ShowLicense "CharacterRichEdit" "NewCharacter.txt"  ; "���Э��ؼ�����"
	${EndIf}

   ; "��������" ��ť
   nsTBCIASkinEngine::FindControl "btn_start_now"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have btn_start_now button"
   ${Else}
	GetFunctionAddress $0 OnBtnStartNow
	nsTBCIASkinEngine::OnControlBindNSISScript "btn_start_now" $0
   ${EndIf}
   
   ; "��ɰ�װ" ��ť
   nsTBCIASkinEngine::FindControl "btn_install_complete"
   Pop $0
   ${If} $0 == "-1"
	    MessageBox MB_OK "Do not have btn_install_complete button"
   ${Else}
	GetFunctionAddress $0 OnBtnInstallComplete
	nsTBCIASkinEngine::OnControlBindNSISScript "btn_install_complete" $0
   ${EndIf}
   
   ; ��װ·���༭���趨����
   ; ���ô��̿ռ��趨����
    ; ��װ·�������ť�󶨺���
    ; ���������ݷ�ʽ�󶨰�ť
    ; ��ӵ������ݷ�ʽ�󶨰�ť
    ; ��ӵ�����������󶨺���
    ; ��һ����ť�󶨺���
    ; ��ʼ��װ��ť�󶨺���
    ; ȡ����ť�󶨺���
  ; ----------------------��ʾ-------------------------------------------------

  nsTBCIASkinEngine::ShowPage
FunctionEnd



; -��������-------------------------------------------------------
Function un.CCUninstall
   ;��ʼ������                                                                    ;      CC_Uninstall
   nsTBCIASkinEngine::InitTBCIASkinEngine /NOUNLOAD "$temp\${PRODUCT_NAME_EN}Setup\res" "CC_Uninstall.xml" "WizardTab"
   Pop $Dialog

   ;��ʼ��MessageBox����
   nsTBCIASkinEngine::InitTBCIAMessageBox "MessageBox_2.xml" "MessageBox_3.xml" "TitleLab" "TextLab" "CloseBtn" "YESBtn" "NOBtn"
   Pop $MessageBoxHandle


   ;ȫ����ť�󶨺���
   ; "ж��" ��ť�󶨺���
   nsTBCIASkinEngine::FindControl "Btn_Uninstall"
   Pop $0
   ${If} $0 == "-1"
    	MessageBox MB_OK "Do not have Btn_Uninstall button"
   ${Else}
     messageBox MB_OK "----------------btn_uninstall"
     GetFunctionAddress $0 un.OnStartUninstallBtnFunc
	   nsTBCIASkinEngine::OnControlBindNSISScript "Btn_Uninstall" $0
   ${EndIf}

  ;"����λ���" ��ť �󶨺���
   nsTBCIASkinEngine::FindControl "Btn_MoreChance"
   Pop $0
   ${If} $0 == "-1"
	MessageBox MB_OK "Do not have min button"
   ${Else}
  GetFunctionAddress $0 un.OnBtnMoreChanceFunc
	nsTBCIASkinEngine::OnControlBindNSISScript "Btn_MoreChance" $0
   ${EndIf}
   
   ;�رհ�ť�󶨺���
   nsTBCIASkinEngine::FindControl "Btn_Close0"
   Pop $0
   ${If} $0 == "-1"
	MessageBox MB_OK "Do not have close button"
   ${Else}
	GetFunctionAddress $0 un.OnGlobalCancelFunc
	nsTBCIASkinEngine::OnControlBindNSISScript "Btn_Close0" $0
   ${EndIf}
   ;-------------------------------------ȷ��ж��ҳ��------------------------------------
   ;�رհ�ť�󶨺���
   nsTBCIASkinEngine::FindControl "Btn_Close1"
   Pop $0
   ${If} $0 == "-1"
	MessageBox MB_OK "Do not have Btn_Close1 button"
   ${Else}
	GetFunctionAddress $0 un.OnGlobalCancelFunc
	nsTBCIASkinEngine::OnControlBindNSISScript "Btn_Close1" $0
   ${EndIf}

    ;--------------------------------ж�����ҳ��----------------------------------------
    ;�رհ�ť�󶨺��� --- ���Ͻ�
   nsTBCIASkinEngine::FindControl "Btn_Close2"
   Pop $0
   ${If} $0 == "-1"
	MessageBox MB_OK "Do not have Btn_Close2 button"
   ${Else}
	GetFunctionAddress $0 un.OnUninstallFinishedBtnFunc
	nsTBCIASkinEngine::OnControlBindNSISScript "Btn_Close2" $0
   ${EndIf}
   
    ;�رհ�ť�󶨺���
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
  ;��ʼ������
   nsTBCIASkinEngine::InitTBCIASkinEngine /NOUNLOAD "$temp\${PRODUCT_NAME_EN}Setup\res" "CC_InstallXml.xml" "WizardTab"    ;duilib.xml  CC_InstallXml.xml    InstallPackages.xml
   Pop $Dialog

   ;��ʼ��MessageBox����
   nsTBCIASkinEngine::InitTBCIAMessageBox  "MessageBox_0.xml" "MessageBox_1.xml"  "TitleLab" "TextLab" "CloseBtn" "YESBtn" "NOBtn"
   Pop $MessageBoxHandle
  GetTempFileName $0
  StrCpy $CCtemp $0
  Delete $0
  SetOutPath $temp\${PRODUCT_NAME_EN}Setup\res
  File ".\CC res\*.png"
  File ".\CC res\*.txt"
  File ".\CC res\*.xml"


  StrCpy $installPath "$PROGRAMFILES\Netease\CC\"     ; old  StrCpy $installPath "$PROGRAMFILES\CC\${PRODUCT_NAME_EN}"
  Call UpdateFreeSpace

  ; �ж�mutex ֪���Ƿ��а�װж�س���������
  !insertmacro MutexCheck "${SETUP_MUTEX_NAME}" $0 $9
  StrCmp $0 0 TEST_CC_RUNNING   ; old :StrCmp $0 0 launch
  MessageBox MB_OK|MB_ICONEXCLAMATION "${PRODUCT_NAME}��װ�����Ѿ������С�"        ; "���Ѿ�������ж�ذ�װ����"
  Abort
  StrLen $0 "$(^Name)"
  IntOp $0 $0 + 1

  TEST_CC_RUNNING:
    ; ����⵽ CC �ͻ��˳����������У���ʾ�û��ȹر������е� CC
    FindProcDll::FindProc "${MAIN_EXE_NAME}"
    IntCmp $R0 1 PROMPT_CLOSING 0
    FindProcDll::FindProc "${UPDATE_EXE_NAME}"
    IntCmp $R0 1 PROMPT_CLOSING BEGIN_INSTALLATION

   PROMPT_CLOSING:
    ;nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIACANCEL "0" "the ${PRODUCT_NAME} is running,please clode the running ${PRODUCT_NAME} and retry"
    pop $0
    ${If} $0 == ${ID_YES}
        goto TEST_CC_RUNNING
    ${Else}
        Abort
    ${EndIF}
;    MessageBox \
;        MB_ICONINFORMATION|MB_RETRYCANCEL \
;        "��װ�����⵽${PRODUCT_NAME}�������У����ȹرյ�ǰ���е�${PRODUCT_NAME}�����³��ԡ�" \
;        IDRETRY TEST_POPO_RUNNING

;    Abort

  BEGIN_INSTALLATION:

  SectionGetSize ${SecDummy} $1

  ${GetRoot} $CCtemp $0
  System::Call kernel32::GetDiskFreeSpaceEx(tr0,*l,*l,*l.r0)
  System::Int64Op $0 / 1024
  Pop $2
  IntCmp $2 $1 "" "" +3
  ;nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIACANCEL "0" "the temp dirtory has not enough volumn"
  pop $0
  Quit
FunctionEnd

Function .onGUIEnd
  RMDir /r $CCtemp\${PRODUCT_NAME_EN}Temp
  IfFileExists $CCtemp\${PRODUCT_NAME_EN}Temp 0 +2
  RMDir /r /REBOOTOK $CCtemp\${PRODUCT_NAME_EN}Temp
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
   ;nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIACANCEL "0" "Are you sure to cancel the Installtion Process?"
;   Pop $0
;   ${If} $0 == "0"
;     nsTBCIASkinEngine::ExitTBCIASkinEngine
;   ${EndIf}   WM_TBCIACLOSE
     nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIACANCEL "0" "Are you sure to cancel the Installtion Process?"
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

;------------------�����ҳ��
; handle Option "agree licence"
Function OnOpAgreeLicence
 !insertmacro GETOPSTATE $Dialog "op_agree_licence"  $vOpAgreeLicence
 ${If} $vOpAgreeLicence == 0
   nsTBCIASkinEngine::SetControlData "btn_quick_install" "false" "visible"
   nsTBCIASkinEngine::SetControlData "lbl_quick_install" "true" "visible"
 ${Else}
   nsTBCIASkinEngine::SetControlData "btn_quick_install" "true" "visible"
   nsTBCIASkinEngine::SetControlData "lbl_quick_install" "false" "visible"
   
 ${EndIf}
FunctionEnd

Function OnBtnShowLicence
  ${If} $boolShowLicence == 1
    IntOp $boolShowLicence $boolShowLicence - 1
    nsTBCIASkinEngine::SetControlData "LicenceRichEdit" "false" "visible"
    nsTBCIASkinEngine::SetControlData "btn_close_licence" "false" "visible"
    nsTBCIASkinEngine::SetControlData "lbl_licence_edit_bk" "false" "visible"
  ${Else}
    IntOp $boolShowLicence $boolShowLicence + 1
    nsTBCIASkinEngine::SetControlData "lbl_licence_edit_bk" "true" "visible"
    nsTBCIASkinEngine::SetControlData "LicenceRichEdit" "true" "visible"
    nsTBCIASkinEngine::SetControlData "btn_close_licence" "true" "visible"
  ${EndIf}
FunctionEnd

; �ر�licence ��ť
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
      nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIACANCEL "1" "please read and select the Licence"
   ${Else}
      ;Messagebox MB_OK "1 $vOpAgreeLicence"
      nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIANEXT
   ${EndIf}
FunctionEnd
;------------------��һ��ҳ��
Function OnNextBtnFunc

      nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIANEXT
   
FunctionEnd

; "������װ" ��ť �󶨺���"
Function OnBtnInstallNow
    ;nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIAMSGBOX "1" "hello <n>World!"
    Call OnNextBtnFunc
    Call OnStartInstallBtnFunc
FunctionEnd

; handle Option "create desktop icon"
Function OnOpCreateDeskIcon
 !insertmacro GETOPSTATE $Dialog "op_create_deskicon"  $vOpCreateDeskIcon
FunctionEnd

; handle Option "add quick launch"
Function OnOpAddQuickLaunch
 !insertmacro GETOPSTATE $Dialog "op_add_quick_launch"  $vOpAddQuickLaunch
FunctionEnd

;------------------�ڶ���ҳ��

Function OnBtnStartNow
 ;MessageBox MB_OK "btn_start_now"
 Call OnLeaveCompletePage
 nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIAFINISHEDINSTALL
FunctionEnd

Function OnLeaveCompletePage
  ; �����Զ�����
 StrCmp $vOpRunAuto "1" "" +2
 WriteRegStr ${PRODUCT_AUTORUN_ROOT_KEY} "${PRODUCT_AUTORUN_KEY}" "${PRODUCT_AUTORUN_VALUE}" "$\"$INSTDIR\Start.exe$\""

 ; ����CC
 StrCmp $vOpRunCC "1" "" +2
    Call OnRunChecked
FunctionEnd

; Handle Option "��������CC"
Function OnOpRunCC
 !insertmacro GETOPSTATE $Dialog "op_run_cc"  $vOpRunCC
 ${If} $vOpRunCC == 1
     nsTBCIASkinEngine::SetControlData "btn_start_now" "true" "visible"   ; ��ʾ
     nsTBCIASkinEngine::SetControlData "btn_install_complete" "false" "visible"   ; ��ʾ
     Exec CC_FINISHPAGE_RUN
 ${Else}
     nsTBCIASkinEngine::SetControlData "btn_start_now" "false" "visible"   ; ��ʾ
     nsTBCIASkinEngine::SetControlData "btn_install_complete" "true" "visible"   ; ��ʾ
  ${EndIf}
FunctionEnd

; Handle Option "�����Զ�����"
Function OnOpRunAuto
 !insertmacro GETOPSTATE $Dialog "op_run_auto"  $vOpRunAuto
 MessageBox MB_OK "$vOpRunAuto"
FunctionEnd

Function OnBtnInstallComplete
 ;MessageBox MB_OK "btn_install_complete"
 nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIAFINISHEDINSTALL
FunctionEnd

; btn ��ʾ������
Function OnBtnShowCharacter
  ${If} $boolShowCharacter == 0
    IntOp $boolShowCharacter $boolShowCharacter + 1
    nsTBCIASkinEngine::SetControlData "lbl_character_edit_bk" "true" "visible"
    nsTBCIASkinEngine::SetControlData "CharacterRichEdit" "true" "visible"   ; �˾���������һ��ĺ��棬����رհ�ť�ᱻ�ڵ�
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
   ; �ı���ô��̴�С
   nsTBCIASkinEngine::GetControlData edit_path "text"
   Pop $0
   ;MessageBox MB_OK $0
   StrCpy $INSTDIR $0

   ;���»�ȡ���̿ռ�
   Call UpdateFreeSpace

   MessageBox MB_OK "FreeSpace: $FreeSpaceSize"

FunctionEnd

Function OnInstallPathBrownBtnFunc
   nsTBCIASkinEngine::SelectFolderDialog "please select install path"
   Pop $installPath

   StrCpy $0 $installPath
   ${If} $0 == "-1"
   ${Else}
      StrCpy $INSTDIR "$installPath\${PRODUCT_NAME_EN}"
      ;���ð�װ·���༭���ı�
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

   ;���»�ȡ���̿ռ�
   Call UpdateFreeSpace

   ;·���Ƿ�Ϸ������Ϸ���Ϊ0Bytes���
   ${If} $FreeSpaceSize == "0Bytes"
    MessageBox MB_OK "invalide path FreeSapce: $FreeSpaceSize"
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

    ; ��ʼ�˵�
    CreateDirectory "$SMPROGRAMS\����CC"
    CreateShortCut "$SMPROGRAMS\����CC\����CC.lnk" "$\"$INSTDIR\Start.exe$\""
    CreateShortCut "$SMPROGRAMS\����CC\ж������CC.lnk" "$\"$INSTDIR\uninstall.exe$\""
    CreateShortCut "$STARTMENU\����CC.lnk" "$\"$INSTDIR\Start.exe$\""

    ;�����ݷ�ʽ
    StrCmp $vOpCreateDeskIcon "1" "" +2
    Call OnDesktopShortcutChecked

    ;��������
    StrCmp $vOpAddQuickLaunch "1" "" +2
    Call OnQuickLaunchChecked
FunctionEnd

;------------------������ҳ��
; ����CC
Function OnRunChecked
	Exec "${CC_FINISHPAGE_RUN}"
FunctionEnd

; �����ݷ�ʽ
Function OnDesktopShortcutChecked
    CreateShortCut "$DESKTOP\${CC_LINK_NAME}" "${CC_FINISHPAGE_RUN}"
FunctionEnd

; ��������
Function OnQuickLaunchChecked
    CreateShortCut "$QUICKLAUNCH\${CC_LINK_NAME}" "${CC_FINISHPAGE_RUN}"
FunctionEnd

Function un.UninstallShow
   ;�������󶨺����
   nsTBCIASkinEngine::FindControl "Wizard_UninstallProgress"
   Pop $0
   ${If} $0 == "-1"
	MessageBox MB_OK "Do not have Wizard_InstallProgress button"
   ${Else}
	nsTBCIASkinEngine::StartUninstall  Wizard_UninstallProgress
   ${EndIf}
FunctionEnd

Function un.OnGlobalCancelFunc
   nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIACANCEL "1" "are you sure to Exit uninstall?"
   Pop $0
   ${If} $0 == ${ID_YES}
     nsTBCIASkinEngine::ExitTBCIASkinEngine
   ${EndIf}
FunctionEnd

Function un.OnBtnUninstall
   nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIACANCEL "1" "are you sure to uninstall CC?"
FunctionEnd

Function un.OnStartUninstallBtnFunc
  messagebox MB_OK "unistall"                ;WM_TBCIACANCEL
  nsTBCIASkinEngine::TBCIASendMessage $Dialog  WM_TBCIACANCEL   "1"   "are you sure to uninstall CC?"
  pop $0
  ${If} $0 == ${ID_YES}
      nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIASTARTUNINSTALL
  ${Else}
      nsTBCIASkinEngine::ExitTBCIASkinEngine
  ${EndIf}
FunctionEnd

Function un.OnbtnMoreChanceFunc
  nsTBCIASkinEngine::ExitTBCIASkinEngine
FunctionEnd

Function un.OnUninstallFinishedBtnFunc
   ;DeleteRegValue HKLM  "Software\Microsoft\Windows\CurrentVersion\Run" "360Safe"
   nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIAFINISHEDINSTALL
   ;nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIAOPENURL "http://110.taobao.com"
FunctionEnd

Function un.AfterUnistall
  IfRebootFlag 0 NO_REBOOT
    nsTBCIASkinEngine::TBCIASendMessage $Dialog WM_TBCIACANCEL "1" "some project will be cleared after reboot, Reboot Now?"
    ;MessageBox MB_YESNO "some project will be cleared after reboot, Reboot Now?" IDYES FORYES IDNO NO_REBOOT

    Pop $0
    ${If} $0 == ${ID_YES}
      ReBoot
;    ${Else}
;      goto NO_REBOOT
    ${EndIf}
NO_REBOOT:
FunctionEnd


