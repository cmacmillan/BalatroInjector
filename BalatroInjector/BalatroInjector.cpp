// BalatroInjector.cpp : This file contains the 'main' function. Program execution begins and ends there.
//

#include <Windows.h>
#include <stdio.h>
#include <tchar.h>
#include <strsafe.h>

#include "common.h"

HANDLE m_hProcess;

int main(int argc, const char * argv[])
{
	if (argc < 4) 
	{
		printf("Usage: Injector <exepath> <dllpath> <luapath>\n");
		return 0;
	}

	printf("Starting injector...\n");

	HANDLE hMailslot = CreateMailslot(lpctstrSlotFromDll, 0, MAILSLOT_WAIT_FOREVER, nullptr);

    if (hMailslot == INVALID_HANDLE_VALUE) 
    { 
        printf("CreateMailslotRead failed with %d\n", GetLastError());
		return 1;
    } 

	const char * pChzBalatroPath = argv[1];
	const char * pChzDllPath = argv[2];
	const char * pChzLuaPath = argv[3];

	STARTUPINFOA si;
	ZeroMemory(&si, sizeof(si));
	si.cb = sizeof(si);
	LPSTARTUPINFOA lpsi = &si;

	PROCESS_INFORMATION pi;
	ZeroMemory(&pi, sizeof(pi));

	printf("Launching balatro...\n");

	if (!CreateProcessA(
			pChzBalatroPath,
			nullptr,
			nullptr,
			nullptr,
			FALSE,
			CREATE_SUSPENDED,
			nullptr,	
			nullptr,
			lpsi,
			&pi)
		) 
	{
		printf("Error launching balatro!");
		return 1;
	}

	HANDLE m_hProcess = pi.hProcess;

	if (!m_hProcess)
	{
		printf("Error opening balatro (%u)\n", GetLastError());
		return 1;
	}

	printf("Allocating dll memory...\n");

	LPVOID pChzDllPathRemote = VirtualAllocEx(
									m_hProcess, 
									nullptr, 
									1 << 12, 
									MEM_COMMIT | MEM_RESERVE, 
									PAGE_READWRITE);

	if (!pChzDllPathRemote) {
		printf("Error allocating memory!\n");
		return 1;
	}

	printf("Writing dll memory...\n");

	WriteProcessMemory(
		m_hProcess, 
		pChzDllPathRemote, 
		pChzDllPath, 
		strlen(pChzDllPath) + 1, 
		nullptr);

	printf("Creating remote thread...\n");

	HANDLE hThread = CreateRemoteThread(
						m_hProcess, 
						nullptr, 
						0, 
						(LPTHREAD_START_ROUTINE) GetProcAddress(GetModuleHandle(L"kernel32.dll"), "LoadLibraryA"),
						pChzDllPathRemote,
						0,
						nullptr);

	if (!hThread) 
	{
		printf("Error creating thread!\n");
		return 1;
	}

	printf("Writing lua path to mailslot...\n");

	while (true) 
	{
		Sleep(100);

		HANDLE hMailslotWrite = CreateFile(lpctstrSlotToDll,
									GENERIC_WRITE,
									FILE_SHARE_READ,
									(LPSECURITY_ATTRIBUTES) NULL,
									OPEN_EXISTING,
									FILE_ATTRIBUTE_NORMAL,
									(HANDLE) NULL);

		if (hMailslotWrite == INVALID_HANDLE_VALUE)
			continue;

		DWORD cbWritten;

		bool fResult = WriteFile(hMailslotWrite,
			pChzLuaPath,
			(DWORD) (strlen(pChzLuaPath) + 1) * sizeof(CHAR),
			&cbWritten,
			(LPOVERLAPPED) NULL);

		if (!fResult)
		{
			printf("Error writing lua path!\n");
			return 1;
		}

		break;
	}

	printf("Waiting for thread...\n");

	DWORD waitResult = WaitForSingleObject(hThread, 5000);

	if (waitResult != WAIT_OBJECT_0) 
	{
		printf("Error waiting for single object!\n");
	}

	printf("Resuming balatro...\n");
	
	ResumeThread(pi.hThread);

	ReadMailslot(hMailslot, false, [](LPSTR lpstr) { printf(lpstr); });

	CloseHandle(hThread);
	CloseHandle(m_hProcess);

	printf("Done.\n");

	return 0;
}
