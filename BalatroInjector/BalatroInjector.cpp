// BalatroInjector.cpp : This file contains the 'main' function. Program execution begins and ends there.
//

#include <Windows.h>
#include <stdio.h>
#include <tchar.h>
#include <strsafe.h>

#define DIM(arg) (sizeof(arg) / sizeof(*arg))

LPCTSTR lpctstrSlot = TEXT("\\\\.\\mailslot\\BalatroInjector");
HANDLE m_hProcess;

#define EVADE_WINDOWS_DEFENDER 0

#if EVADE_WINDOWS_DEFENDER
//kernel32.dll
//						  0     1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16    17
wchar_t mpCharWChar[] = { 'q', '2', '3', 'k', 'l', 'e', 'r', 'd', 'o', 'a', 'b', 'y', 'i', 'L', 'n', '.', '\0', 'A'};

//					   k  e  r  n   e  l  3  2  .   d  l  l  \0  junk junk junk
//int aiModuleName[] = { 3, 5, 6, 14, 5, 4, 2, 1, 15, 7, 4, 4, 16, 0, 6, 7, 8, 10};
int aiModuleName[] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

//					     L   o, a, d  L   i   b   r  a  r  y   A   \0  junk junk junk
//int aiFunctionName[] = { 13, 8, 9, 7, 13, 12, 10, 6, 9, 6, 11, 17, 16, 2, 1, 13,15};
int aiFunctionName[] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

wchar_t moduleName[DIM(aiModuleName)];
char functionName[DIM(aiFunctionName)];

void BuildStrings() 
{
	for (int i = 0; i < DIM(aiModuleName); i++) 
	{
		moduleName[i] = mpCharWChar[aiModuleName[i]];
	}
	for (int i = 0; i < DIM(aiFunctionName); i++) 
	{
		functionName[i] = char(mpCharWChar[aiFunctionName[i]]);
	}
}

LPCWSTR lpModuleName() 
{
	return (LPCWSTR) &moduleName;
}

LPCSTR lpProcName() 
{
	return (LPCSTR) &functionName;
}
#endif

int main(int argc, const char * argv[])
{
	if (argc < 3) 
	{
		printf("Usage: Injector <exepath> <dllpath>\n");
		return 0;
	}

	printf("Starting injector...\n");

	//TerminateProcess(m_hProcess, 1);

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

	LPVOID p = VirtualAllocEx(
				m_hProcess, 
				nullptr, 
				1 << 12, 
				MEM_COMMIT | MEM_RESERVE, 
				PAGE_READWRITE);

	if (!p) {
		printf("Error allocating memory!\n");
		return 1;
	}

	printf("Writing dll memory...\n");

	WriteProcessMemory(
		m_hProcess, 
		p, 
		pChzDllPath, 
		strlen(pChzDllPath) + 1, 
		nullptr);

	printf("Creating remote thread...\n");

#if EVADE_WINDOWS_DEFENDER
	BuildStrings();
	HANDLE hThread = CreateRemoteThread(
						m_hProcess, 
						nullptr, 
						0, 
						(LPTHREAD_START_ROUTINE) GetProcAddress(GetModuleHandle(lpModuleName()), lpProcName()),
						p,
						0,
						nullptr);
#else
	HANDLE hThread = CreateRemoteThread(
						m_hProcess, 
						nullptr, 
						0, 
						(LPTHREAD_START_ROUTINE) GetProcAddress(GetModuleHandle(L"kernel32.dll"), "LoadLibraryA"),
						p,
						0,
						nullptr);
#endif

	if (!hThread) 
	{
		printf("Error creating thread!\n");
		return 1;
	}

	printf("Waiting for thread...\n");

	DWORD waitResult = WaitForSingleObject(hThread, 5000);

	if (waitResult != WAIT_OBJECT_0) 
	{
		printf("Error waiting for single object!\n");
	}

	printf("Resuming balatro...\n");
	
	ResumeThread(pi.hThread);

	while (true) 
	{
		// Sleep
 
		Sleep(100);

		DWORD cbMessage, cMessage, cbRead; 
		BOOL fResult; 
		LPSTR lpszBuffer; 
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
	 
			lpszBuffer = (LPSTR) GlobalAlloc(GPTR, 
				strlen((LPSTR) achID)*sizeof(CHAR) + cbMessage); 
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
	 
			printf(lpszBuffer); 
	 
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
	}

	CloseHandle(hThread);
	CloseHandle(m_hProcess);

	printf("Done.\n");

	return 0;
}
