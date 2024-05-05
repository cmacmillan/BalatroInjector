#pragma once

#include <Windows.h>

LPCTSTR lpctstrSlotFromDll = TEXT("\\\\.\\mailslot\\BalatroInjectorFromDll");
LPCTSTR lpctstrSlotToDll = TEXT("\\\\.\\mailslot\\BalatroInjectorToDll");

#define DIM(arg) (sizeof(arg) / sizeof(*arg))

void ReadMailslot(HANDLE hMailslot, bool fQuitAfterFirstRead, void (*funcCallback)(LPSTR))
{
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

		hEvent = CreateEvent(NULL, FALSE, FALSE, TEXT("MailSlotEvent"));
		if (NULL == hEvent)
			continue;
		ov.Offset = 0;
		ov.OffsetHigh = 0;
		ov.hEvent = hEvent;
	 
		fResult = GetMailslotInfo(hMailslot, // mailslot handle 
			(LPDWORD) NULL,               // no maximum message size 
			&cbMessage,                   // size of next message 
			&cMessage,                    // number of messages 
			(LPDWORD) NULL);              // no read time-out 
	 
		if (!fResult) 
		{ 
			printf("GetMailslotInfo failed with %d.\n", GetLastError()); 
			return; 
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
			if (NULL == lpszBuffer) 
			{
				printf("Error allocating buffer! %d \n", GetLastError()); 
				return;
			}
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
				return;
			} 
		 
			// Display the message. 
	 
			funcCallback(lpszBuffer);
	 
			GlobalFree((HGLOBAL) lpszBuffer); 

			if (fQuitAfterFirstRead)
				return;
	 
			fResult = GetMailslotInfo(hMailslot,  // mailslot handle 
				(LPDWORD) NULL,               // no maximum message size 
				&cbMessage,                   // size of next message 
				&cMessage,                    // number of messages 
				(LPDWORD) NULL);              // no read time-out 
	 
			if (!fResult) 
			{ 
				printf("GetMailslotInfo failed (%d)\n", GetLastError());
				return; 
			} 
		} 
		CloseHandle(hEvent);
	}
}
