#include <string>
#include "UpdateTrace.h"
#include "windows.h"

#ifdef _DEBUG
static int tracelvl_ = TRACE_DETAIL;
#else
static int tracelvl_ = TRACE_INFO;
#endif

static const size_t kLogBufferSize =  500 * 1024;
static wchar_t *kLogBuffer = NULL;	
static CRITICAL_SECTION kLock;
static HANDLE kLogFile = INVALID_HANDLE_VALUE;


static BOOL StringToWString(const std::string &str,std::wstring &wstr)
{    
    int nLen = (int)str.length();    
    wstr.resize(nLen,L' ');
    int nResult = MultiByteToWideChar(CP_ACP,0,(LPCSTR)str.c_str(),nLen,(LPWSTR)wstr.c_str(),nLen);
    if (nResult == 0)
    {
        return FALSE;
    }
    return TRUE;
}

static std::string TraceToMBCS(UINT codepage, const std::wstring &src)
{
	std::string dest;

	int buflen = WideCharToMultiByte(codepage, 0, src.c_str(), src.length(), 0, 0, 0, 0);

	char *buf = (char*)malloc(buflen + 1);
	int count = WideCharToMultiByte(codepage, 0, src.c_str(), src.length(), buf, buflen + 1, 0, 0);
	buf[count] = 0;
	dest.append(buf);
	free(buf);

	return dest;
}

void TraceInit(const wchar_t *log_path)
{
	if(kLogFile == INVALID_HANDLE_VALUE)
	{
		InitializeCriticalSection(&kLock);
		kLogBuffer = (wchar_t*)malloc(kLogBufferSize * sizeof(wchar_t));
		kLogFile = CreateFile(log_path, GENERIC_WRITE, FILE_SHARE_READ, NULL, CREATE_ALWAYS, NULL, NULL);
		LARGE_INTEGER size;
		size.QuadPart = 0;
		if(GetFileSizeEx(kLogFile, &size) == FALSE || size.QuadPart > 4 * 1024 * 1024)
		{
			SetFilePointer(kLogFile, 0, 0, FILE_BEGIN);
			SetEndOfFile(kLogFile);
		}
		else
		{
			SetFilePointer(kLogFile, 0, 0, FILE_END);
		}
	}
}

void TraceClose()
{
	if(kLogFile != INVALID_HANDLE_VALUE)
	{
		EnterCriticalSection(&kLock);
		CloseHandle(kLogFile);
		kLogFile = NULL;
		LeaveCriticalSection(&kLock);
	}
}

void Trace(int level, bool flush, const wchar_t * format, ...)
{
	if(level < tracelvl_) return;
	if(kLogFile == INVALID_HANDLE_VALUE) return;

	va_list args;
	va_start(args, format);
	SYSTEMTIME current;
	GetLocalTime(&current);

	std::wstring logw;

	EnterCriticalSection(&kLock);

	swprintf_s(kLogBuffer, kLogBufferSize, L"[%4d-%02d-%02d %02d:%02d:%02d.%03d] ", current.wYear, current.wMonth, current.wDay, current.wHour, current.wMinute, current.wSecond, current.wMilliseconds);
	logw.append(kLogBuffer);
	_vsnwprintf_s(kLogBuffer, kLogBufferSize, kLogBufferSize, format, args);
	logw.append(kLogBuffer);
	logw.append(L"\r\n");

	std::string log = TraceToMBCS(CP_UTF8, logw);

#ifdef _DEBUG
	OutputDebugStringA(log.c_str());
#endif
	DWORD written_bytes = 0;
	WriteFile(kLogFile, log.c_str(), log.length(), &written_bytes, 0);
	if(flush)
	{
		FlushFileBuffers(kLogFile);
	}

	LeaveCriticalSection(&kLock);
}

void Trace( const char* format, ... )
{
    const int BUFF_SIZE = 1024;
    char buf[BUFF_SIZE];
    memset(buf, 0, sizeof(buf));

    va_list args;
    va_start(args, format);
    vsnprintf_s(buf, BUFF_SIZE - 1, format, args);
    va_end(args);

    std::wstring wstr;
    StringToWString(buf, wstr);
    Trace(TRACE_INFO, true, wstr.c_str());
}
