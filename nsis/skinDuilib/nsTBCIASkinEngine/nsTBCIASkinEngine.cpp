#include "StdAfx.h"
#include "nsTBCIASkinEngine.h"
#include "SkinEngine.h"
#include "resource.h "
#include <map>
#include <shlobj.h>
#include <stdio.h>
#include <atlconv.h>
#include <string>
#include <windows.h>
#include <sstream>
using namespace DuiLib;


///////////////////////////////////////////////////////////////////////////////////
DECLARE_HANDLE(HZIP);	// An HZIP identifies a zip file that has been opened
typedef DWORD ZRESULT;
typedef struct
{ 
	int index;                 // index of this file within the zip
	char name[MAX_PATH];       // filename within the zip
	DWORD attr;                // attributes, as in GetFileAttributes.
	FILETIME atime,ctime,mtime;// access, create, modify filetimes
	long comp_size;            // sizes of item, compressed and uncompressed. These
	long unc_size;             // may be -1 if not yet known (e.g. being streamed in)
} ZIPENTRY;
typedef struct
{ 
	int index;                 // index of this file within the zip
	TCHAR name[MAX_PATH];      // filename within the zip
	DWORD attr;                // attributes, as in GetFileAttributes.
	FILETIME atime,ctime,mtime;// access, create, modify filetimes
	long comp_size;            // sizes of item, compressed and uncompressed. These
	long unc_size;             // may be -1 if not yet known (e.g. being streamed in)
} ZIPENTRYW;
#define OpenZip OpenZipU
#define CloseZip(hz) CloseZipU(hz)
extern HZIP OpenZipU(void *z,unsigned int len,DWORD flags);
extern ZRESULT CloseZipU(HZIP hz);
#ifdef _UNICODE
#define ZIPENTRY ZIPENTRYW
#define GetZipItem GetZipItemW
#define FindZipItem FindZipItemW
#else
#define GetZipItem GetZipItemA
#define FindZipItem FindZipItemA
#endif
extern ZRESULT GetZipItemA(HZIP hz, int index, ZIPENTRY *ze);
extern ZRESULT GetZipItemW(HZIP hz, int index, ZIPENTRYW *ze);
extern ZRESULT FindZipItemA(HZIP hz, const TCHAR *name, bool ic, int *index, ZIPENTRY *ze);
extern ZRESULT FindZipItemW(HZIP hz, const TCHAR *name, bool ic, int *index, ZIPENTRYW *ze);
extern ZRESULT UnzipItem(HZIP hz, int index, void *dst, unsigned int len, DWORD flags);
/////////////////////////////////////////////////////////////////////////////////////////////


extern HINSTANCE g_hInstance;
extra_parameters* g_pluginParms;
DuiLib::CSkinEngine* g_pFrame = NULL;
BOOL g_bMSGLoopFlag = TRUE;
std::map<HWND, WNDPROC> g_windowInfoMap;
CDuiString g_tempParam = _T("");
CDuiString g_installPageTabName = _T("");
std::map<CDuiString, CDuiString> g_controlLinkInfoMap;

DuiLib::CTBCIAMessageBox* g_pMessageBox = NULL;

TCHAR g_messageBoxLayoutFileName[5][MAX_PATH] = {0};
TCHAR g_messageBoxTitleControlName[MAX_PATH] = {0};
TCHAR g_messageBoxTextControlName[MAX_PATH] = {0};

TCHAR g_messageBoxCloseBtnControlName[MAX_PATH] = {0}; 
TCHAR g_messageBoxYESBtnControlName[MAX_PATH] = {0}; 
TCHAR g_messageBoxNOBtnControlName[MAX_PATH] = {0}; 

static UINT_PTR PluginCallback(enum NSPIM msg)
{
	return 0;
}

void InitTBCIASkinEngine(HWND hwndParent, int string_size, char *variables, stack_t **stacktop, extra_parameters *extra)
{
	CPaintManagerUI::SetInstance(g_hInstance);
	CPaintManagerUI::SetResourceZip(130);
	//::AllocConsole();
	freopen("CONOUT$","w+t",stdout);
	freopen("CONOUT$","w+t",stderr);
	g_pluginParms = extra;
	//char *s = itoa(string_size);
	TCHAR sizeBuffer[512] = {0};
	_itot(string_size, sizeBuffer, 10);
	//wchar_t k;
	//MessageBoxA()
	
	/*MessageBox(g_pFrame->GetHWND(),_T("test"),variables,MB_OK);
	MessageBox(g_pFrame->GetHWND(),_T("test"),*stacktop,MB_OK);
	MessageBox(g_pFrame->GetHWND(),_T("test"),*extra,MB_OK);*/

	EXDLL_INIT();/*-----》 g_stringsize=string_size; 
							g_stacktop=stacktop;      
							g_variables=variables; }*/
	extra->RegisterPluginCallback(g_hInstance, PluginCallback);
	{
		//TCHAR skinPath[MAX_PATH];
		TCHAR skinLayoutFileName[MAX_PATH];
		TCHAR installPageTabName[MAX_PATH];
		//ZeroMemory(skinPath, MAX_PATH);
		ZeroMemory(skinLayoutFileName, MAX_PATH);
		ZeroMemory(installPageTabName, MAX_PATH);

		//popstring(skinPath);  // 皮肤路径
		popstring(skinLayoutFileName); //皮肤文件
		popstring( installPageTabName ); // 安装页面tab的名字

		//DuiLib::CPaintManagerUI::SetResourcePath( skinPath);
		g_installPageTabName = installPageTabName;

		g_pFrame = new DuiLib::CSkinEngine();
		if( g_pFrame == NULL ) return;
		g_pFrame->SetSkinXMLPath( skinLayoutFileName );               // WS_EX_STATICEDGE | WS_EX_APPWINDOW
		g_pFrame->Create( NULL, _T("CC 开黑安装包"), UI_WNDSTYLE_FRAME,WS_EX_WINDOWEDGE , 10, 10, 200, 100 );
		g_pFrame->SetIcon(IDI_ICON1);
		g_pFrame->CenterWindow();
		ShowWindow( g_pFrame->GetHWND(), false ); //ShowWindow( g_pFrame->GetHWND(), false );

		//pushint( int(25));
	
		pushint( int(g_pFrame->GetHWND()));
	}
}

void FindControl(HWND hwndParent, int string_size, char *variables, stack_t **stacktop, extra_parameters *extra)
{
	TCHAR controlName[MAX_PATH];
	ZeroMemory(controlName, MAX_PATH);
	//MessageBoxA(0,0,"find_control",0);
	popstring( controlName );
	CControlUI* pControl = static_cast<CControlUI*>(g_pFrame->GetPaintManager().FindControl( controlName ));
	if( pControl == NULL )
		//MessageBoxA(0,0,"no_btn",0);
		pushint( - 1 );
	pushint( 0 );
}

void ShowLicense(HWND hwndParent, int string_size, char *variables, stack_t **stacktop, extra_parameters *extra)
{
	TCHAR controlName[MAX_PATH];
	TCHAR fileName[MAX_PATH];
	ZeroMemory(controlName, MAX_PATH);
	ZeroMemory(fileName, MAX_PATH);
	popstring( controlName );
	popstring( fileName );
	CDuiString finalFileName = fileName;	
	CRichEditUI* pRichEditControl = static_cast<CRichEditUI*>(g_pFrame->GetPaintManager().FindControl( controlName ));
	if( pRichEditControl == NULL )
		return;

	// 读许可协议文件，append到richedit中
	USES_CONVERSION;
	FILE* infile;
	char *pLicense = NULL;	
	infile = fopen( T2A(finalFileName.GetData()), "rb" );
	if (!infile)
	{
		return ;
	}
	fseek( infile, 0,  SEEK_END );
	long nSize = ftell(infile);
	fseek(infile, 0, SEEK_SET);
	pLicense = new char[nSize];	
	if (pLicense == NULL)
	{
		fclose(infile);
		return;
	}

	ZeroMemory(pLicense, sizeof(char) * nSize);
	fread_s(pLicense, nSize, sizeof(char), nSize, infile);
	PARAFORMAT2   pf;   
	memset(&pf,   0,   sizeof(pf));   
	pf.cbSize   =   sizeof(PARAFORMAT2);   
	pf.dwMask = PFM_LINESPACING | PFM_SPACEAFTER;
	pf.dyLineSpacing = 800;
	pf.bLineSpacingRule = 1;
	pRichEditControl->SetParaFormat(pf);   
	pRichEditControl->AppendText( A2T(pLicense) );
	if (pLicense != NULL)
	{
		delete []pLicense;
	}
	fclose( infile );
}

void ShowNewCharacter(HWND hwndParent, int string_size, char *variables, stack_t **stacktop, extra_parameters *extra)
{
	TCHAR controlName[MAX_PATH];
	TCHAR fileName[MAX_PATH];
	ZeroMemory(controlName, MAX_PATH);
	ZeroMemory(fileName, MAX_PATH);
	popstring( controlName );
	popstring( fileName );
	CDuiString finalFileName = fileName;	
	CRichEditUI* pRichEditControl = static_cast<CRichEditUI*>(g_pFrame->GetPaintManager().FindControl( controlName ));
	if( pRichEditControl == NULL )
		return;

	// 读许可协议文件，append到richedit中
	USES_CONVERSION;
	FILE* infile;
	char *pLicense = NULL;	
	infile = fopen( T2A(finalFileName.GetData()), "r" );
	if (!infile)
	{
		return;
	}
	fseek( infile, 0,  SEEK_END );
	long nSize = ftell(infile);
	fseek(infile, 0, SEEK_SET);
	pLicense = new char[nSize];	
	if (pLicense == NULL)
	{
		fclose(infile);
		return;
	}

	ZeroMemory(pLicense, sizeof(char) * nSize);
	fread_s(pLicense, nSize, sizeof(char), nSize, infile);
	PARAFORMAT2   pf;   
	memset(&pf,   0,   sizeof(pf));   
	pf.cbSize   =   sizeof(PARAFORMAT2);   
	pf.dwMask = PFM_LINESPACING | PFM_SPACEAFTER;
	pf.dyLineSpacing = 800;
	pf.bLineSpacingRule = 1;
	pRichEditControl->SetParaFormat(pf);   
	pRichEditControl->AppendText( A2T(pLicense) );
	if (pLicense != NULL)
	{
		delete []pLicense;
	}
	fclose( infile );
}

void  OnControlBindNSISScript(HWND hwndParent, int string_size, char *variables, stack_t **stacktop, extra_parameters *extra)
{
	TCHAR controlName[MAX_PATH];
	ZeroMemory(controlName, MAX_PATH);

	popstring(controlName); 
	int callbackID = popint();
	g_pFrame->SaveToControlCallbackMap( controlName, callbackID );
}

void  SetControlData(HWND hwndParent, int string_size, char *variables, stack_t **stacktop, extra_parameters *extra)
{
	TCHAR controlName[MAX_PATH];
	TCHAR controlData[MAX_PATH];
	TCHAR dataType[MAX_PATH];
	ZeroMemory(controlName, MAX_PATH);
	ZeroMemory(controlData, MAX_PATH);
	ZeroMemory(dataType, MAX_PATH);

	popstring( controlName );
	popstring( controlData );
	popstring( dataType );

	CControlUI* pControl = static_cast<CControlUI*>(g_pFrame->GetPaintManager().FindControl( controlName ));
	if( pControl == NULL )
		return;
	
	if( _tcsicmp( dataType, _T("text") ) == 0 )
	{
		if( _tcsicmp( controlData, _T("error")) == 0 || _tcsicmp( controlData, _T("")) == 0 )
			pControl->SetText( pControl->GetText() );
		else
			pControl->SetText( controlData );
	}
	else if (_tcsicmp(dataType, _T("spacetext")) == 0)
	{
		if( _tcsicmp( controlData, _T("error")) == 0 || _tcsicmp( controlData, _T("")) == 0 )
		{
			pControl->SetText( pControl->GetText() );
		}
		else
		{
			int free_space = _ttoi(controlData);
			float free_gb_space = float(free_space)/1024;
			free_gb_space=( (float)( (int)( (free_gb_space+0.005)*100 ) ) )/100;
			std::wstringstream ss;
			ss<<L"可用空间："<<free_gb_space<<L"GB";
			std::wstring free_gb_text = ss.str();
			pControl->SetText( free_gb_text.c_str());
		}
	}
	else if( _tcsicmp( dataType, _T("bkimage") ) == 0 )
	{
		if( _tcsicmp( controlData, _T("error")) == 0 || _tcsicmp( controlData, _T("")) == 0 )
			pControl->SetBkImage( pControl->GetBkImage());
		else
			pControl->SetBkImage( controlData );
	}
	else if( _tcsicmp( dataType, _T("link") ) == 0 )
	{
		g_controlLinkInfoMap[controlName] = controlData;
	}
	else if( _tcsicmp( dataType, _T("enable") ) == 0 )
	{
		if( _tcsicmp( controlData, _T("true")) == 0 )
			pControl->SetEnabled( true );
		else if( _tcsicmp( controlData, _T("false")) == 0 )
			pControl->SetEnabled( false );
	}
	else if( _tcsicmp( dataType, _T("visible") ) == 0 )
	{
		if( _tcsicmp( controlData, _T("true")) == 0 )
			pControl->SetVisible( true );
		else if( _tcsicmp( controlData, _T("false")) == 0 )
			pControl->SetVisible( false );
	}
	else if(_tcsicmp(dataType,_T("optioncheck")) == 0)
	{
		COptionUI* pOption = static_cast<COptionUI*>(pControl);
	    pOption->Selected(!pOption->IsSelected());
	}
}

void  GetControlData(HWND hwndParent, int string_size, char *variables, stack_t **stacktop, extra_parameters *extra)
{
	TCHAR ctlName[MAX_PATH];
	TCHAR dataType[MAX_PATH];
	ZeroMemory(ctlName, MAX_PATH);
	ZeroMemory(dataType, MAX_PATH);
	popstring( ctlName );
	popstring( dataType );
	
	CControlUI* pControl = static_cast<CControlUI*>(g_pFrame->GetPaintManager().FindControl( ctlName ));
	if( pControl == NULL )
		return;

	TCHAR temp[MAX_PATH] = {0};
	_tcscpy( temp, pControl->GetText().GetData());
	if( _tcsicmp( dataType, _T("text") ) == 0 )
		pushstring( temp );
}

void CALLBACK TimerProc(HWND hwnd, UINT uMsg, UINT_PTR idEvent, DWORD dwTime)
{
	g_pluginParms->ExecuteCodeSegment(idEvent - 1, 0);
}

void  TBCIACreatTimer(HWND hwndParent, int string_size, char *variables, stack_t **stacktop, extra_parameters *extra)
{
	UINT callback;
	UINT interval;

	callback = popint();
	interval = popint();

	if (!callback || !interval)
		return;

	SetTimer( g_pFrame->GetHWND(), callback, interval, TimerProc );
}

void  TBCIAKillTimer(HWND hwndParent, int string_size, char *variables, stack_t **stacktop, extra_parameters *extra)
{
	UINT id;
	id = popint();
	KillTimer(g_pFrame->GetHWND(), id);
}

UINT  TBCIAMessageBox( HWND hwndParent, LPCTSTR lpTitle, LPCTSTR lpText )
{
	if( g_pMessageBox == NULL )
	{
		g_pMessageBox = new DuiLib::CTBCIAMessageBox();
		if( g_pMessageBox == NULL ) return IDNO;
		g_pMessageBox->SetSkinXMLPath( g_messageBoxLayoutFileName[_ttoi(lpTitle)] );
		g_pMessageBox->Create( hwndParent, _T(""), UI_WNDSTYLE_FRAME, WS_EX_STATICEDGE | WS_EX_APPWINDOW , 0, 0, 0, 0 );
		g_pMessageBox->CenterWindow();
	}

	CControlUI* pTitleControl = static_cast<CControlUI*>(g_pMessageBox->GetPaintManager().FindControl( g_messageBoxTitleControlName ));
	CControlUI* pTipTextControl = static_cast<CControlUI*>(g_pMessageBox->GetPaintManager().FindControl( g_messageBoxTextControlName ));
	/*if( pTitleControl != NULL )
	{
		pTitleControl->SetText( lpTitle );
		printf("lpTitle :%s", lpTitle);
	}*/
	printf("create msgbox lptext:%s",lpText);
	if( pTipTextControl != NULL )
		pTipTextControl->SetText( lpText );
	
	int ret_msgbox = g_pMessageBox->ShowModal() ;
	if( ret_msgbox == 1)
	{
		g_pMessageBox = NULL;
		printf ("show modal 6\n");
		return IDYES;
	}
	else if ( ret_msgbox == 0 || ret_msgbox == 2) // CLOSE or NO
	{
		g_pMessageBox = NULL;
		printf ("show modal 7\n");
		return IDNO;
	}
	else
	{
		g_pMessageBox = NULL;
		printf ("show modal %d\n", ret_msgbox);
		return ret_msgbox;
	}
	/*g_pMessageBox = NULL;
	printf ("show modal 7\n");
	return IDNO;*/
}

void  TBCIASendMessage(HWND hwndParent, int string_size, char *variables, stack_t **stacktop, extra_parameters *extra)
{
	HWND hwnd = (HWND)popint();
	TCHAR msgID[MAX_PATH];
	TCHAR wParam[MAX_PATH];
	TCHAR lParam[MAX_PATH];

 	ZeroMemory(msgID, MAX_PATH);
	ZeroMemory(wParam, MAX_PATH);
	ZeroMemory(lParam, MAX_PATH);

	popstring( msgID );
	popstring( wParam );
	popstring( lParam );

	if( _tcsicmp( msgID, _T("WM_TBCIAMIN")) == 0 )
		::SendMessage( hwnd, WM_TBCIAMIN, (WPARAM)wParam, (LPARAM)lParam );
	else if( _tcsicmp( msgID, _T("WM_TBCIACLOSE")) == 0 )
		::SendMessage( hwnd, WM_TBCIACLOSE, (WPARAM)wParam, (LPARAM)lParam );
	else if( _tcsicmp( msgID, _T("WM_TBCIABACK")) == 0 )
		::SendMessage( hwnd, WM_TBCIABACK, (WPARAM)g_installPageTabName.GetData(), (LPARAM)lParam );
	else if( _tcsicmp( msgID, _T("WM_TBCIANEXT")) == 0 )
		::SendMessage( hwnd, WM_TBCIANEXT, (WPARAM)g_installPageTabName.GetData(), (LPARAM)lParam );
	else if( _tcsicmp( msgID, _T("WM_TBCIACANCEL")) == 0 )
	{
		LPCTSTR lpTitle = (LPCTSTR)wParam;
		LPCTSTR lpText = (LPCTSTR)lParam;
		//if( IDYES == MessageBox( hwnd, lpText, lpTitle, MB_YESNO)/*TBCIAMessageBox( hwnd, lpTitle, lpText )*/)
		//::SendMessage(hwnd, WM_MSGBOX,(WPARAM)g_installPageTabName.GetData(), (LPARAM)lParam);
		int ret = TBCIAMessageBox( g_pFrame->GetHWND(), lpTitle, lpText );
		pushint( ret );
		//g_pMessageBox->ShowWindow(true);
		//if( IDYES == TBCIAMessageBox( hwnd, lpTitle, lpText )/*TBCIAMessageBox( hwnd, lpTitle, lpText )*/)
		//{
		//	pushint( 0 );
		//	::SendMessage( hwnd, WM_TBCIACLOSE, (WPARAM)wParam, (LPARAM)lParam );
		//}
		//else
		//	pushint( -1 );
		//MessageBoxA(hwnd,"a","b",0);
		//::SendMessage( hwnd, WM_TBCIACLOSE, (WPARAM)wParam, (LPARAM)lParam );
	}
	else if( _tcsicmp( msgID, _T("WM_TBCIASTARTINSTALL")) == 0 )
		::SendMessage( hwnd, WM_TBCIASTARTINSTALL, (WPARAM)g_installPageTabName.GetData(), (LPARAM)lParam );
	else if( _tcsicmp( msgID, _T("WM_TBCIASTARTUNINSTALL")) == 0 )
		::SendMessage( hwnd, WM_TBCIASTARTUNINSTALL, (WPARAM)g_installPageTabName.GetData(), (LPARAM)lParam );
	else if( _tcsicmp( msgID, _T("WM_TBCIAFINISHEDINSTALL")) == 0 )
		::SendMessage( hwnd, WM_TBCIAFINISHEDINSTALL, (WPARAM)wParam, (LPARAM)lParam );
	else if( _tcsicmp( msgID, _T("WM_TBCIAOPTIONSTATE")) == 0 ) // 返回option的状态
	{
		
		COptionUI* pOption = static_cast<COptionUI*>(g_pFrame->GetPaintManager().FindControl( wParam ));
		if( pOption == NULL )
			return;
		printf("test here %d\n",!pOption->IsSelected());
		pushint( !pOption->IsSelected() );
	}
	else if( _tcsicmp( msgID, _T("WM_TBCIAOPENURL")) == 0 )
	{
		CDuiString url = (CDuiString)wParam;
		if( url.Find( _T("http://") ) == -1 )
		{
			pushstring( _T("url error") );
			return;
		}
		CDuiString lpCmdLine = _T("explorer \"");
		lpCmdLine += url;
		lpCmdLine += _T("\"");
		USES_CONVERSION;
		std::string strCmdLine = T2A(lpCmdLine.GetData());		
		WinExec( strCmdLine.c_str(), SW_SHOWNORMAL);
	}
}

int CALLBACK BrowseCallbackProc(HWND hwnd, UINT uMsg, LPARAM lp, LPARAM pData)
{
	if (uMsg == BFFM_INITIALIZED)
		SendMessage(hwnd, BFFM_SETSELECTION, TRUE, pData);

	return 0;
}

void SelectFolderDialog(HWND hwndParent, int string_size, char *variables, stack_t **stacktop, extra_parameters *extra)
{
	BROWSEINFO bi;
	TCHAR result[MAX_PATH];
	TCHAR title[MAX_PATH];
	LPITEMIDLIST resultPIDL;
	ZeroMemory(result, MAX_PATH);
	ZeroMemory(title, MAX_PATH);

	popstring( title );
	bi.hwndOwner = g_pFrame->GetHWND();
	bi.pidlRoot = NULL;
	bi.pszDisplayName = result;
	bi.lpszTitle = title;
#ifndef BIF_NEWDIALOGSTYLE
#define BIF_NEWDIALOGSTYLE 0x0040
#endif
	bi.ulFlags = BIF_STATUSTEXT | BIF_RETURNONLYFSDIRS | BIF_NEWDIALOGSTYLE | BIF_NONEWFOLDERBUTTON;
	bi.lpfn = BrowseCallbackProc;
	bi.lParam = NULL;
	bi.iImage = 0;

	resultPIDL = SHBrowseForFolder(&bi);
	if (!resultPIDL)
	{
		pushint(-1);
		return;
	}

	if (SHGetPathFromIDList(resultPIDL, result))
	{
		if( result[_tcslen(result)-1] == _T('\\') )
			result[_tcslen(result)-1] = _T('');
		pushstring(result);
	}
	else
		pushint(-1);

	CoTaskMemFree(resultPIDL);
}

BOOL CALLBACK TBCIAWindowProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
	BOOL res = 0;
	std::map<HWND, WNDPROC>::iterator iter = g_windowInfoMap.find( hwnd );
	if( iter != g_windowInfoMap.end() )
	{
		
 		if( message == WM_PAINT)
 		{
			SetWindowPos(hwnd, NULL, 0, 0, 1, 1, SWP_HIDEWINDOW);
 			ShowWindow( hwnd, SW_HIDE );
 		}
 		else if( message == PBM_SETPOS ) 
 		{
			CProgressUI* pProgress = static_cast<CProgressUI*>(g_pFrame->GetPaintManager().FindControl( g_tempParam ));
			pProgress->SetMaxValue( 30000 );
			if( pProgress == NULL )
				return 0;
			pProgress->SetValue( (int)wParam);
			
		
			CLabelUI* pLabel = static_cast<CLabelUI*>(g_pFrame->GetPaintManager().FindControl(_T("process_value")));
			std::wstringstream ss;
			ss<<(wParam*100)/30000<<L"%";
			std::wstring process_value = ss.str();
			if (pLabel)
				pLabel->SetText(process_value.c_str());
			if( pProgress->GetValue() == 30000 )
			{
				CTabLayoutUI* pTab = NULL;
				int currentIndex;
				pTab = static_cast<CTabLayoutUI*>(g_pFrame->GetPaintManager().FindControl( g_installPageTabName ));
				if( pTab == NULL )
					return -1;
				currentIndex = pTab->GetCurSel();
				pTab->SelectItem( currentIndex + 1 );
			}
 		}
 		else
 		{
			res = CallWindowProc( iter->second, hwnd, message, wParam, lParam);
		}
	}	
	return res;
}

void InstallCore( HWND hwndParent )
{
	TCHAR progressName[MAX_PATH];
	ZeroMemory(progressName, MAX_PATH);
	popstring( progressName );
	g_tempParam = progressName;
	// 接管page instfiles的消息
	g_windowInfoMap[hwndParent] = (WNDPROC) SetWindowLong(hwndParent, GWL_WNDPROC, (long) TBCIAWindowProc);
	HWND hProgressHWND = FindWindowEx( FindWindowEx( hwndParent, NULL, _T("#32770"), NULL ), NULL, _T("msctls_progress32"), NULL );
	g_windowInfoMap[hProgressHWND] = (WNDPROC) SetWindowLong(hProgressHWND, GWL_WNDPROC, (long) TBCIAWindowProc);
	HWND hInstallDetailHWND = FindWindowEx( FindWindowEx( hwndParent, NULL, _T("#32770"), NULL ), NULL, _T("SysListView32"), NULL ); 
	g_windowInfoMap[hInstallDetailHWND] = (WNDPROC) SetWindowLong(hInstallDetailHWND, GWL_WNDPROC, (long) TBCIAWindowProc);
}

void StartInstall(HWND hwndParent, int string_size, char *variables, stack_t **stacktop, extra_parameters *extra)
{
	InstallCore( hwndParent );
}

void StartUninstall(HWND hwndParent, int string_size, char *variables, stack_t **stacktop, extra_parameters *extra)
{
	InstallCore( hwndParent );
}

void ShowPage(HWND hwndParent, int string_size, char *variables, stack_t **stacktop, extra_parameters *extra)
{
	g_pFrame->ShowWindow(true);
	//ShowWindow( g_pFrame->GetHWND(), true );
	//MessageBoxA(g_pFrame->GetHWND(),"show_page2","show_page2",0);
	MSG msg = { 0 };
	while( ::GetMessage(&msg, NULL, 0, 0) && g_bMSGLoopFlag ) 
	{
		::TranslateMessage(&msg);
		::DispatchMessage(&msg);
	}
}

void  ExitTBCIASkinEngine(HWND hwndParent, int string_size, char *variables, stack_t **stacktop, extra_parameters *extra)
{
	ExitProcess( 0 );
}

DLLEXPORT void  InitTBCIAMessageBox(HWND hwndParent, int string_size, char *variables, stack_t **stacktop, extra_parameters *extra)
{
	
	popstring( g_messageBoxLayoutFileName[0] );
	popstring( g_messageBoxLayoutFileName[1] );
	popstring( g_messageBoxLayoutFileName[2] );
	popstring( g_messageBoxLayoutFileName[3] );
	popstring( g_messageBoxLayoutFileName[4] );


	popstring( g_messageBoxTitleControlName );
	popstring( g_messageBoxTextControlName );

	popstring( g_messageBoxCloseBtnControlName );
	popstring( g_messageBoxYESBtnControlName );
	popstring( g_messageBoxNOBtnControlName );
	//MessageBoxA(0,"msgbox","msgbox",0);
	
}

void _getFileFromZip(const std::wstring &path, char **data, DWORD &len)
{
	CDuiString sFile = CPaintManagerUI::GetResourcePath();
	HZIP hz = NULL;
	if( CPaintManagerUI::IsCachedResourceZip() ) 
	{
		hz = (HZIP)CPaintManagerUI::GetResourceZipHandle();
	}
	else 
	{
		hz = OpenZip((void*)sFile.GetData(), 0, 2);
	}
	if( hz == NULL )
	{
		return ;
	}
	ZIPENTRY ze; 
	int i; 
	if( FindZipItem(hz, path.c_str(), true, &i, &ze) != 0 ) 
	{
		return ;
	}
	len = ze.unc_size;
	if( len == 0 ) 
	{
		return ;
	}
	if ( len > 4096*1024 ) 
	{
		return ;
	}

	*data = new char[ len ];
	int res = UnzipItem(hz, i, *data, len, 3);
	if( res != 0x00000000 && res != 0x00000600) {
		if( !CPaintManagerUI::IsCachedResourceZip() ) CloseZip(hz);
		return ;
	}
	if( !CPaintManagerUI::IsCachedResourceZip() ) CloseZip(hz);
}