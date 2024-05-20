#ifndef MSGDEF_H
#define MSGDEF_H
#pragma once

#include <WinUser.h>


#ifdef __cplusplus
#define DLLEXPORT extern "C"  __declspec(dllexport)
#else
#define DLLEXPORT __declspec(dllexport)
#endif 

#define WM_TBCIAMIN         WM_USER + 888
#define WM_TBCIACLOSE      WM_USER + 1
#define WM_TBCIABACK        WM_USER + 890
#define WM_TBCIANEXT        WM_USER + 891
#define WM_TBCIACANCEL    WM_USER + 892
#define WM_TBCIASTARTINSTALL          WM_USER + 893
#define WM_TBCIASTATE                       WM_USER + 894
#define WM_TBCIAFINISHEDINSTALL    WM_USER + 895
#define WM_TBCIAOPENURL                         WM_USER + 896
#define WM_TBCIASTARTUNINSTALL          WM_USER + 897
#define WM_MSGBOX          WM_USER + 101



#endif