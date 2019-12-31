/*
 *  AdViewNetManager.h
 *  AdViewSDK
 *
 *  Created by AdView on 12-10-16.
 *  Copyright 2012 AdView. All rights reserved.
 *
 */

#ifndef _AdViewNetManager_H_
#define _AdViewNetManager_H_

#define MAX_ADDRS    32

#ifdef __cplusplus

class AdViewNetManager{
public:
	AdViewNetManager();
	~AdViewNetManager() {FreeAddresses();}
	
public:
	const char *GetIpName(int idx) { return m_ipNames[idx];}
	
public:
	void InitAddresses();
	void GetIPAddresses();
	void GetHWAddresses();
	void FreeAddresses();
private:
	char *m_ifNames[MAX_ADDRS];  
	char *m_ipNames[MAX_ADDRS];
	char *m_hwAddrs[MAX_ADDRS];
	unsigned long m_ipAddrs[MAX_ADDRS];
	int   nextAddr;
};

extern "C" {

#endif
    void *AdViewNetManager_new(void);
	void AdViewNetManager_delete(void *manager);
	
	void AdViewNetManager_GetIPAddresses(void *manager);
	
	//idx == 0, the value is 127.0.0.1
	const char *AdViewNetManager_GetIPName(void *manager, int idx);
	
#ifdef __cplusplus
}
#endif

#endif
