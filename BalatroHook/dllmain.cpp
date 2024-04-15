// dllmain.cpp : Defines the entry point for the DLL application.
#include "pch.h"

#include <detours.h>

typedef void * lua_State;

typedef int (*_luaL_loadfilex)(lua_State * L, const char * filename, const char * mode);
_luaL_loadfilex luaL_loadfilex;

typedef int (*_luaopen_jit)(lua_State * L);
_luaopen_jit luaopen_jit_original;

typedef int (*_lua_pcall)(lua_State * L, int nargs, int nresults, int errfunc);
_lua_pcall lua_pcall;

int luaopen_jit_hook(lua_State * L)
{
	int ret_val = luaopen_jit_original(L);
	//luaL_loadfilex(L, "C:\\Users\\chase\\Desktop\\Desktop_4\\BalatroHook\\BalatroHook\\test.lua", NULL) || lua_pcall(L, 0, -1, 0);
	luaL_loadfilex(L, "C:\\Users\\chase\\Desktop\\Desktop_4\\BalatroHook\\BalatroHook\\empty.lua", NULL) || lua_pcall(L, 0, -1, 0);
	return ret_val;
}

BOOL APIENTRY DllMain(HMODULE hModule,
	DWORD  dwReason,
	LPVOID lpReserved)
{
	switch (dwReason)
	{
	case DLL_PROCESS_ATTACH:
	{
		HMODULE hModule = GetModuleHandle(L"Lua51.dll");
		if (!hModule)
		{
			MessageBox(nullptr, L"Error: Didn't find module", L"Result", MB_ICONINFORMATION);
			return FALSE;
		}

		FARPROC farprocLuaopenjit = GetProcAddress(hModule, "luaopen_jit");
		if (!farprocLuaopenjit)
		{
			MessageBox(nullptr, L"Error: Failed to find luaopen_jit!", L"Result", MB_ICONINFORMATION);
			return FALSE;
		}

		FARPROC farprocLualloadfilex = GetProcAddress(hModule, "luaL_loadfilex");
		if (!farprocLualloadfilex)
		{
			MessageBox(nullptr, L"Error: Failed to find luaopen_jit!", L"Result", MB_ICONINFORMATION);
			return FALSE;
		}

		FARPROC farprocLuapcall = GetProcAddress(hModule, "lua_pcall");
		if (!farprocLuapcall)
		{
			MessageBox(nullptr, L"Error: Failed to find luaopen_jit!", L"Result", MB_ICONINFORMATION);
			return FALSE;
		}

		if (DetourIsHelperProcess())
		{
			MessageBox(nullptr, L"Error: Helper process???", L"Result", MB_ICONINFORMATION);
			return TRUE;
		}

		luaopen_jit_original = (_luaopen_jit) farprocLuaopenjit;
		luaL_loadfilex = (_luaL_loadfilex) farprocLualloadfilex;
		lua_pcall = (_lua_pcall) farprocLuapcall;

		DetourRestoreAfterWith();

		DetourTransactionBegin();
		DetourUpdateThread(GetCurrentThread());
		DetourAttach(&luaopen_jit_original, luaopen_jit_hook);
		DetourTransactionCommit();
	}
	break;
	case DLL_PROCESS_DETACH:
		{
			DetourTransactionBegin();
			DetourUpdateThread(GetCurrentThread());
			DetourDetach(&luaopen_jit_original, luaopen_jit_hook);
			DetourTransactionCommit();
		}
		break;
	default:
		break;
	}

	return TRUE;
}
