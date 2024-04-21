// BalatroInjector.cpp : This file contains the 'main' function. Program execution begins and ends there.
//

#include <Windows.h>
#include <stdio.h>
#include <tchar.h>
#include <strsafe.h>

LPCTSTR lpctstrSlot = TEXT("\\\\.\\mailslot\\BalatroInjector");

int main(int argc, const char * argv[])
{
	if (argc < 3) 
	{
		printf("Usage: Injector <exepath> <dllpath>\n");
		return 0;
	}

	HANDLE hMailslot = CreateMailslot(lpctstrSlot, 0, MAILSLOT_WAIT_FOREVER, nullptr);

    if (hMailslot == INVALID_HANDLE_VALUE) 
    { 
        printf("CreateMailslot failed with %d\n", GetLastError());
		return 1;
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

	while (true) 
	{
		// Sleep
 
		Sleep(100);

		DWORD cbMessage, cMessage, cbRead; 
		BOOL fResult; 
		LPTSTR lpszBuffer; 
		TCHAR achID[80]; 
		DWORD cAllMessages; 
		HANDLE hEvent;
		OVERLAPPED ov;
	 
		cbMessage = cMessage = cbRead = 0; 

		hEvent = CreateEvent(NULL, FALSE, FALSE, TEXT("ExampleSlot"));
		if (NULL == hEvent)
			continue;
		ov.Offset = 0;
		ov.OffsetHigh = 0;
		ov.hEvent = hEvent;
	 
		fResult = GetMailslotInfo( hMailslot, // mailslot handle 
			(LPDWORD) NULL,               // no maximum message size 
			&cbMessage,                   // size of next message 
			&cMessage,                    // number of messages 
			(LPDWORD) NULL);              // no read time-out 
	 
		if (!fResult) 
		{ 
			printf("GetMailslotInfo failed with %d.\n", GetLastError()); 
			return 1; 
		} 
	 
		if (cbMessage == MAILSLOT_NO_MESSAGE) 
		{ 
			continue;
		} 
	 
		cAllMessages = cMessage; 
	 
		while (cMessage != 0)  // retrieve all messages
		{ 
			// Allocate memory for the message. 
	 
			lpszBuffer = (LPTSTR) GlobalAlloc(GPTR, 
				lstrlen((LPTSTR) achID)*sizeof(TCHAR) + cbMessage); 
			if( NULL == lpszBuffer )
				return FALSE;
			lpszBuffer[0] = '\0'; 
	 
			fResult = ReadFile(hMailslot, 
				lpszBuffer, 
				cbMessage, 
				&cbRead, 
				&ov); 
	 
			if (!fResult) 
			{ 
				printf("ReadFile failed with %d.\n", GetLastError()); 
				GlobalFree((HGLOBAL) lpszBuffer); 
				return FALSE; 
			} 
		 
			// Display the message. 
	 
			_tprintf(lpszBuffer); 
	 
			GlobalFree((HGLOBAL) lpszBuffer); 
	 
			fResult = GetMailslotInfo(hMailslot,  // mailslot handle 
				(LPDWORD) NULL,               // no maximum message size 
				&cbMessage,                   // size of next message 
				&cMessage,                    // number of messages 
				(LPDWORD) NULL);              // no read time-out 
	 
			if (!fResult) 
			{ 
				printf("GetMailslotInfo failed (%d)\n", GetLastError());
				return FALSE; 
			} 
		} 
		CloseHandle(hEvent);
		return TRUE; 
	}

	CloseHandle(hThread);
	CloseHandle(hProcess);

	printf("Done.\n");

	return 0;
}
