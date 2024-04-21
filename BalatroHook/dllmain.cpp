// dllmain.cpp : Defines the entry point for the DLL application.
#include "pch.h"

#include <detours.h>
#include <stdio.h>

LPCTSTR lpctstrSlot = TEXT("\\\\.\\mailslot\\BalatroInjector");

HANDLE m_hMailslot;
HMODULE m_hModule;

#define LUA_REGISTRYINDEX       (-10000)
#define LUA_ENVIRONINDEX        (-10001)
#define LUA_GLOBALSINDEX        (-10002)

#define DIM(arg) (sizeof(arg) / sizeof(*arg))

BOOL Write(const char * pChz)
{
	BOOL fResult;
	DWORD cbWritten;

	LPCSTR lpcstr = pChz;

	fResult = WriteFile(m_hMailslot,
		lpcstr,
		(DWORD) (strlen(lpcstr) + 1) * sizeof(CHAR),
		&cbWritten,
		(LPOVERLAPPED) NULL);

	if (!fResult)
	{
		return FALSE;
	}

	return TRUE;
}

BOOL WriteFmt(const char * pChzFmt, ...) 
{
	char pChzBuffer[1000];

    va_list argList;
    va_start(argList, pChzFmt);
	vsprintf_s(pChzBuffer, DIM(pChzBuffer), pChzFmt, argList);
    va_end(argList);

	return Write(pChzBuffer);
}

typedef void * lua_State;

typedef void * (*lua_Alloc) (void *ud,
                             void *ptr,
                             size_t osize,
                             size_t nsize);

typedef int (*_luaL_loadfilex)(lua_State * L, const char * filename, const char * mode);
_luaL_loadfilex luaL_loadfilex;

typedef int (*_luaopen_jit)(lua_State * L);
_luaopen_jit luaopen_jit_original;

typedef int (*_luaL_error)(lua_State * L, const char * fmt, ...);
_luaL_error luaL_error_original;

typedef int (*_luaL_loadstring)(lua_State * L, const char * str);
_luaL_loadstring luaL_loadstring_original;

typedef int (*_lua_pcall)(lua_State * L, int nargs, int nresults, int errfunc);
_lua_pcall lua_pcall;

typedef int (*_lua_CFunction) (lua_State *L);

typedef void (*_lua_pushcclosure)(lua_State * L,_lua_CFunction f, int n);
_lua_pushcclosure lua_pushcclosure;

typedef void (*_lua_setfield)(lua_State * L, int index, const char * k);
_lua_setfield lua_setfield;

typedef const char * (*_lua_tolstring)(lua_State * L, int index, size_t * pLen);
_lua_tolstring lua_tolstring;

typedef lua_State * (*_lua_newstate)(lua_Alloc f, void *ud);
_lua_newstate lua_newstate;

int luaL_loadstring(lua_State * L, const char * str)
{
	Write("LoadString!\n");
	int ret_val = luaL_loadstring_original(L, str);
	return ret_val;
}

int luaL_error(lua_State * L, const char * fmt, ...) 
{
	WriteFmt(fmt, va_list());
	WriteFmt("Error!\n");

	int ret_val = luaL_error_original(L, fmt, va_list());
	return ret_val;
}

int lua_my_print(lua_State * L) 
{
	const char * pChz = lua_tolstring(L, 1, nullptr);
	Write(pChz);
	return 0;
}

int luaopen_jit_hook(lua_State * L)
{
	Write("lauopen_jit_hook!\n");
	int ret_val = luaopen_jit_original(L);

	lua_pushcclosure(L, lua_my_print, 0);
	lua_setfield(L, LUA_GLOBALSINDEX, "my_print");

	luaL_loadfilex(L, "C:\\Users\\chase\\Desktop\\Desktop_4\\BalatroHook\\BalatroHook\\mod.lua", NULL) || lua_pcall(L, 0, -1, 0);

	return ret_val;
}

BOOL FTryFindFARPROCFromPchz(const char * pChz, FARPROC * pFarproc)
{
	FARPROC farproc = GetProcAddress(m_hModule, pChz);
	if (!farproc)
	{
		WriteFmt("Couldn't find procedure '%s'!\n", pChz);
		return FALSE;
	}
	*pFarproc = farproc;
	return TRUE;
}

//MessageBox(nullptr, L"Error: Didn't find module", L"Result", MB_ICONINFORMATION);

BOOL APIENTRY DllMain(HMODULE hModule,
	DWORD  dwReason,
	LPVOID lpReserved)
{
	switch (dwReason)
	{
	case DLL_PROCESS_ATTACH:
	{
		m_hMailslot = CreateFile(lpctstrSlot,
			GENERIC_WRITE,
			FILE_SHARE_READ,
			(LPSECURITY_ATTRIBUTES) NULL,
			OPEN_EXISTING,
			FILE_ATTRIBUTE_NORMAL,
			(HANDLE) NULL);

		if (m_hMailslot == INVALID_HANDLE_VALUE)
		{
			return FALSE;
		}

		Write("Created mailslot!\n");

		m_hModule = GetModuleHandle(L"Lua51.dll");
		if (!m_hModule)
		{
			Write("Couldn't load module!");
			return FALSE;
		}

		if (!FTryFindFARPROCFromPchz("luaopen_jit", (FARPROC *) &luaopen_jit_original))
			return FALSE;

		if (!FTryFindFARPROCFromPchz("luaL_loadfilex", (FARPROC *) &luaL_loadfilex))
			return FALSE;

		if (!FTryFindFARPROCFromPchz("lua_pcall", (FARPROC *) &lua_pcall))
			return FALSE;

		if (!FTryFindFARPROCFromPchz("luaL_error", (FARPROC *) &luaL_error_original))
			return FALSE;

		if (!FTryFindFARPROCFromPchz("luaL_loadstring", (FARPROC *) &luaL_loadstring_original))
			return FALSE;

		if (!FTryFindFARPROCFromPchz("lua_pushcclosure", (FARPROC *) &lua_pushcclosure))
			return FALSE;

		if (!FTryFindFARPROCFromPchz("lua_setfield", (FARPROC *) &lua_setfield))
			return FALSE;

		if (!FTryFindFARPROCFromPchz("lua_tolstring", (FARPROC *) &lua_tolstring))
			return FALSE;

		if (!FTryFindFARPROCFromPchz("lua_newstate", (FARPROC *) &lua_newstate))
			return FALSE;

		DetourRestoreAfterWith();

		DetourTransactionBegin();
		DetourUpdateThread(GetCurrentThread());
		DetourAttach(&luaopen_jit_original, luaopen_jit_hook);
		DetourAttach(&luaL_error_original, luaL_error);
		DetourAttach(&luaL_loadstring_original, luaL_loadstring);
		DetourTransactionCommit();

		Write("Finished init!\n");
	}
	break;
	case DLL_PROCESS_DETACH:
	{
		CloseHandle(m_hMailslot);
		DetourTransactionBegin();
		DetourUpdateThread(GetCurrentThread());
		DetourDetach(&luaopen_jit_original, luaopen_jit_hook);
		DetourDetach(&luaL_error_original, luaL_error);
		DetourDetach(&luaL_loadstring_original, luaL_loadstring);
		DetourTransactionCommit();
	}
	break;
	default:
		break;
	}

	return TRUE;
}
