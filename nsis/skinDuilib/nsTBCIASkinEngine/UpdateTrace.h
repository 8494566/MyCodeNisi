#pragma once

#define TRACE_DETAIL	1	//!< 细节输出，用于模块内部调试
#define TRACE_DEBUG		2	//!< 调试输出，用于系统调试
#define TRACE_INFO		3	//!< 关键信息输出， 默认输出级别
#define TRACE_ERROR		4	//!< 错误输出
#define TRACE_FATAL		5	//!< 致命错误输出

void TraceInit(const wchar_t *log_path);
void TraceClose();
void Trace(int level, bool flush, const wchar_t* format, ...);
void Trace(const char* format, ...);
