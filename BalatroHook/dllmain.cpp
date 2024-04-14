// dllmain.cpp : Defines the entry point for the DLL application.
#include "pch.h"

//#include <detours.h>
//#include <cstdio>

typedef void * lua_State;

const void * LOADFILEEX_ADDR = 0x0;
const void * PCALL_ADDR = 0x0; //7FFA8F501B30 - lua51.lua_pcall
const void * OPENJIT_ADDR = (void *) 0x7FFAAAAC2390;


typedef int (*_luaL_loadfilex)(lua_State * L, const char * filename, const char * mode);
_luaL_loadfilex luaL_loadfilex;

typedef int (*_luaopen_jit)(lua_State * L);
_luaopen_jit luaopen_jit_original;

typedef int (*_lua_pcall)(lua_State * L, int nargs, int nresults, int errfunc);
_lua_pcall lua_pcall;

/*
int lua_pcall_hook(lua_State * L, int nargs, int nresults, int errfunc) 
{

}
*/

int luaopen_jit_hook(lua_State * L)
{
	//*(int *)nullptr = 0;
	//printf("asdfasdf");
	//int ret_val = luaopen_jit_original(L);
	//luaL_loadfilex(L, "C:\\Users\\chase\\Desktop\\Desktop_4\\BalatroHook\\BalatroHook\\test.lua", NULL) || lua_pcall(L, 0, -1, 0);
	//return ret_val;
	int ret_val = luaopen_jit_original(L);
	return ret_val;
}

BOOL APIENTRY DllMain(HMODULE hModule,
	DWORD  dwReason,
	LPVOID lpReserved)
{
	switch (dwReason) {
	case DLL_PROCESS_ATTACH:
		WCHAR aWcharText[256];
		wsprintfW(aWcharText, L"Hello from process %u!", GetCurrentProcessId());
		MessageBox(nullptr, aWcharText, L"Blah blah blah", MB_ICONINFORMATION);
		break;
	default:
		break;
	}

	/*
	if (DetourIsHelperProcess())
	{
		return TRUE;
	}

	luaL_loadfilex = (_luaL_loadfilex) LOADFILEEX_ADDR;hThread
	lua_pcall = (_lua_pcall) PCALL_ADDR;
	luaopen_jit_original = (_luaopen_jit) OPENJIT_ADDR;

	if (dwReason == DLL_PROCESS_ATTACH)
	{
		DetourRestoreAfterWith();

		DetourTransactionBegin();
		DetourUpdateThread(GetCurrentThread());
		DetourAttach(&luaopen_jit_original, luaopen_jit_hook);
		DetourTransactionCommit();
	}
	else if (dwReason == DLL_PROCESS_DETACH)
	{
		DetourTransactionBegin();
		DetourUpdateThread(GetCurrentThread());
		DetourDetach(&luaopen_jit_original, luaopen_jit_hook);
		DetourTransactionCommit();
	}
	*/

	return TRUE;
}
