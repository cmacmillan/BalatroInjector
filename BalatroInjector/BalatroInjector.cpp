// BalatroInjector.cpp : This file contains the 'main' function. Program execution begins and ends there.
//

#include <Windows.h>
#include <stdio.h>

int main(int argc, const char * argv[])
{
	if (argc < 3) 
	{
		printf("Usage: Injector <pid> <dllpath>\n");
		return 0;
	}

	const char * pChzDllPath = argv[2];

	int pid = atoi(argv[1]);

	HANDLE hProcess = OpenProcess(
						PROCESS_VM_WRITE | PROCESS_VM_OPERATION | PROCESS_CREATE_THREAD,
						FALSE,
						pid);

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

	CloseHandle(hThread);
	CloseHandle(hProcess);

	return 0;
}
