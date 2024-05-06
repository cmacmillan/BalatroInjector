// dllmain.cpp : Defines the entry point for the DLL application.
#include "pch.h"

#include <detours.h>
#include <stdio.h>

#include "common.h"

HANDLE m_hMailslotWrite;
HMODULE m_hModule;
char * m_pChzLuaPath = nullptr;

// BB Really should just include lua.h so I don't have to manually write all this junk
//  e.g. https://github.com/lua/lua/blob/master/lua.h but for 5.1

#define LUA_REGISTRYINDEX       (-10000)
#define LUA_ENVIRONINDEX        (-10001)
#define LUA_GLOBALSINDEX        (-10002)

#define LUA_OK		0
#define LUA_YIELD	1
#define LUA_ERRRUN	2
#define LUA_ERRSYNTAX	3
#define LUA_ERRMEM	4
#define LUA_ERRERR	5

#define LUA_ERRFILE     (LUA_ERRERR+1)

BOOL Write(const char * pChz)
{
	BOOL fResult;
	DWORD cbWritten;

	LPCSTR lpcstr = pChz;

	fResult = WriteFile(m_hMailslotWrite,
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

    va_list arglist;
    va_start(arglist, pChzFmt);
	vsprintf_s(pChzBuffer, DIM(pChzBuffer), pChzFmt, arglist);
    va_end(arglist);

	return Write(pChzBuffer);
}

typedef void * lua_State;

typedef void * (*lua_Alloc) (void *ud,
                             void *ptr,
                             size_t osize,
                             size_t nsize);

typedef int (*_luaL_loadfilex)(lua_State * L, const char * filename, const char * mode);
_luaL_loadfilex m_lualloadfilexOriginal;

typedef int (*_luaopen_jit)(lua_State * L);
_luaopen_jit m_luaopenjitOriginal;

typedef int (*_luaL_error)(lua_State * L, const char * fmt, ...);
_luaL_error m_lualerrorOriginal;

typedef int (*_luaL_loadstring)(lua_State * L, const char * str);
_luaL_loadstring m_lualloadstringOriginal;

typedef int (*_lua_pcall)(lua_State * L, int nargs, int nresults, int errfunc);
_lua_pcall m_luapcallOriginal;

typedef int (*_lua_CFunction) (lua_State *L);
typedef void (*_lua_pushcclosure)(lua_State * L,_lua_CFunction f, int n);
_lua_pushcclosure m_luapushcclosureOriginal;

typedef void (*_lua_setfield)(lua_State * L, int index, const char * k);
_lua_setfield m_luasetfieldOriginal;

typedef const char * (*_lua_tolstring)(lua_State * L, int index, size_t * pLen);
_lua_tolstring m_luatolstringOriginal;

typedef lua_State * (*_lua_newstate)(lua_Alloc f, void *ud);
_lua_newstate m_luanewstateOriginal;

int m_cJithooks = 0;

int LualloadstringReplacement(lua_State * pLuastate, const char * pChz)
{
	Write("LoadString!\n");

	return m_lualloadstringOriginal(pLuastate, pChz);
}

int LualerrorReplacement(lua_State * pLuastate, const char * pChz, ...) 
{
	Write("Error!\n");

	return m_lualerrorOriginal(pLuastate, pChz, va_list());
}

int PrintToInjectorConsole(lua_State * pLuastate) 
{
	const char * pChz = m_luatolstringOriginal(pLuastate, 1, nullptr);
	Write(pChz);
	return 0;
}

int LuaopenjithookReplacement(lua_State * pLuastate)
{
	int nReturn = m_luaopenjitOriginal(pLuastate);

	m_cJithooks++;
	if (m_cJithooks > 1)
		return nReturn;

	Write("Loading mod...\n");
	WriteFmt("    Mod path: %s\n", m_pChzLuaPath);

	m_luapushcclosureOriginal(pLuastate, PrintToInjectorConsole, 0);
	m_luasetfieldOriginal(pLuastate, LUA_GLOBALSINDEX, "InjectorPrint");

	int loadfileret = m_lualloadfilexOriginal(pLuastate, m_pChzLuaPath, NULL);

	if (loadfileret != LUA_OK)
	{
		WriteFmt("Error loading lua file! %s\n", m_luatolstringOriginal(pLuastate, 0, nullptr));
	}
	else 
	{
		Write("Loaded lua file!\n");
		m_luapcallOriginal(pLuastate, 0, -1, 0);
	}

	return nReturn;
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

void ReceiveMailslotMessage(LPSTR lpstr) 
{
	const int cCharBuffer = 1024;
	m_pChzLuaPath = new char[cCharBuffer];
	memcpy_s(m_pChzLuaPath, cCharBuffer, lpstr, strlen(lpstr) + 1);
}

BOOL APIENTRY DllMain(HMODULE hModule,
	DWORD  dwReason,
	LPVOID lpReserved)
{
	switch (dwReason)
	{
	case DLL_PROCESS_ATTACH:
	{
		m_hMailslotWrite = CreateFile(lpctstrSlotFromDll,
							GENERIC_WRITE,
							FILE_SHARE_READ,
							(LPSECURITY_ATTRIBUTES) NULL,
							OPEN_EXISTING,
							FILE_ATTRIBUTE_NORMAL,
							(HANDLE) NULL);

		if (m_hMailslotWrite == INVALID_HANDLE_VALUE)
		{
			return FALSE;
		}

		Write("Created write mailslot!\n");

		HANDLE hMailslotRead = CreateMailslot(lpctstrSlotToDll, 0, MAILSLOT_WAIT_FOREVER, nullptr);

		if (hMailslotRead == INVALID_HANDLE_VALUE) 
		{ 
			Write("CreateMailslot failed! (Do you have multiple copies of balatro open?)\n");
			return FALSE;
		} 

		Write("Created read mailslot!\n");

		Write("Waiting to read lua file path from mailslot...\n");

		ReadMailslot(hMailslotRead, true, ReceiveMailslotMessage);

		m_hModule = GetModuleHandle(L"Lua51.dll");
		if (!m_hModule)
		{
			Write("Couldn't load module!");
			return FALSE;
		}

		if (!FTryFindFARPROCFromPchz("luaopen_jit", (FARPROC *) &m_luaopenjitOriginal))
			return FALSE;

		if (!FTryFindFARPROCFromPchz("luaL_loadfilex", (FARPROC *) &m_lualloadfilexOriginal))
			return FALSE;

		if (!FTryFindFARPROCFromPchz("lua_pcall", (FARPROC *) &m_luapcallOriginal))
			return FALSE;

		if (!FTryFindFARPROCFromPchz("luaL_error", (FARPROC *) &m_lualerrorOriginal))
			return FALSE;

		if (!FTryFindFARPROCFromPchz("luaL_loadstring", (FARPROC *) &m_lualloadstringOriginal))
			return FALSE;

		if (!FTryFindFARPROCFromPchz("lua_pushcclosure", (FARPROC *) &m_luapushcclosureOriginal))
			return FALSE;

		if (!FTryFindFARPROCFromPchz("lua_setfield", (FARPROC *) &m_luasetfieldOriginal))
			return FALSE;

		if (!FTryFindFARPROCFromPchz("lua_tolstring", (FARPROC *) &m_luatolstringOriginal))
			return FALSE;

		if (!FTryFindFARPROCFromPchz("lua_newstate", (FARPROC *) &m_luanewstateOriginal))
			return FALSE;

		DetourRestoreAfterWith();

		DetourTransactionBegin();
		DetourUpdateThread(GetCurrentThread());
		DetourAttach(&m_luaopenjitOriginal, LuaopenjithookReplacement);
		DetourAttach(&m_lualerrorOriginal, LualerrorReplacement);
		DetourAttach(&m_lualloadstringOriginal, LualloadstringReplacement);
		DetourTransactionCommit();

		Write("Finished init!\n");
	}
	break;
	case DLL_PROCESS_DETACH:
	{
		CloseHandle(m_hMailslotWrite);
		DetourTransactionBegin();
		DetourUpdateThread(GetCurrentThread());
		DetourDetach(&m_luaopenjitOriginal, LuaopenjithookReplacement);
		DetourDetach(&m_lualerrorOriginal, LualerrorReplacement);
		DetourDetach(&m_lualloadstringOriginal, LualloadstringReplacement);
		DetourTransactionCommit();
	}
	break;
	default:
		break;
	}

	return TRUE;
}
