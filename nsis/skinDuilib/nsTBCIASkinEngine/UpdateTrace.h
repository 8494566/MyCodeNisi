#pragma once

#define TRACE_DETAIL	1	//!< ϸ�����������ģ���ڲ�����
#define TRACE_DEBUG		2	//!< �������������ϵͳ����
#define TRACE_INFO		3	//!< �ؼ���Ϣ����� Ĭ���������
#define TRACE_ERROR		4	//!< �������
#define TRACE_FATAL		5	//!< �����������

void TraceInit(const wchar_t *log_path);
void TraceClose();
void Trace(int level, bool flush, const wchar_t* format, ...);
void Trace(const char* format, ...);
