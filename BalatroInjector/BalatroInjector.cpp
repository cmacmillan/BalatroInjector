// BalatroInjector.cpp : This file contains the 'main' function. Program execution begins and ends there.
//

#include <Windows.h>
#include <stdio.h>

int main(int argc, const char * argv[])
{
	if (argc < 3) 
	{
		printf("Usage: Injector <exepath> <dllpath>\n");
		return 0;
	}

	const char * pChzBalatroPath = argv[1];
	const char * pChzDllPath = argv[2];

	STARTUPINFOA si;
	ZeroMemory(&si, sizeof(si));
	si.cb = sizeof(si);
	LPSTARTUPINFOA lpsi = &si;

	PROCESS_INFORMATION pi;
	ZeroMemory(&pi, sizeof(pi));

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
		printf("Error starting process!");
		return 1;
	}

	HANDLE hProcess = pi.hProcess;

	if (!hProcess)
	{
		printf("Error opening process (%u)\n", GetLastError());
		return 1;
	}

	LPVOID p = VirtualAllocEx(
				hProcess, 
				nullptr, 
				1 << 12, 
				MEM_COMMIT | MEM_RESERVE, 
				PAGE_READWRITE);

	if (!p) {
		printf("Error allocating memory!\n");
		return 1;
	}

	WriteProcessMemory(
		hProcess, 
		p, 
		pChzDllPath, 
		strlen(pChzDllPath) + 1, 
		nullptr);

	HANDLE hThread = CreateRemoteThread(
						hProcess, 
						nullptr, 
						0, 
						(LPTHREAD_START_ROUTINE) GetProcAddress(GetModuleHandle(L"kernel32.dll"), "LoadLibraryA"),
						p,
						0,
						nullptr);
	if (!hThread) 
	{
		printf("Error creating thread!\n");
		return 1;
	}

	DWORD waitResult = WaitForSingleObject(hThread, 5000);

	if (waitResult != WAIT_OBJECT_0) 
	{
		printf("Error waiting for single object!\n");
	}
	
	ResumeThread(pi.hThread);

	CloseHandle(hThread);
	CloseHandle(hProcess);

	printf("Done.\n");

	return 0;
}
