/*
 *  AdViewNetManager.cpp
 *  AdViewSDK
 *
 *  Created by AdView on 12-10-16.
 *  Copyright 2012 AdView. All rights reserved.
 *
 */

#include "AdViewNetManager.h"

#include <stdio.h>  
#include <stdlib.h>  
#include <string.h>  
#include <unistd.h>  
#include <sys/ioctl.h>  
#include <sys/types.h>  
#include <sys/socket.h>  
#include <netinet/in.h>  
#include <netdb.h>  
#include <arpa/inet.h>  
#include <sys/sockio.h>  
#include <net/if.h>  
#include <errno.h>  
#include <net/if_dl.h>

#define min(a,b)    ((a) < (b) ? (a) : (b))  
#define max(a,b)    ((a) > (b) ? (a) : (b))

#define BUFFERSIZE  4096

AdViewNetManager::AdViewNetManager():nextAddr(0)
{
	InitAddresses();
}

void AdViewNetManager::InitAddresses()
{  
    int i;  
    for (i=0; i<MAX_ADDRS; ++i)  
    {  
        m_ifNames[i] = m_ipNames[i] = m_hwAddrs[i] = NULL;  
        m_ipAddrs[i] = 0;
    }
    nextAddr = 0;
}

void AdViewNetManager::FreeAddresses()
{  
    int i;  
    for (i=0; i<MAX_ADDRS; ++i)  
    {  
        if (m_ifNames[i] != 0) free(m_ifNames[i]);  
		if (m_ipNames[i] != 0) free(m_ipNames[i]);  
		if (m_hwAddrs[i] != 0) free(m_hwAddrs[i]);  
		m_ipAddrs[i] = 0;
	}
	InitAddresses();
}

void AdViewNetManager::GetIPAddresses()
{  
    int                 i, len, flags;  
    char                buffer[BUFFERSIZE], *ptr, lastname[IFNAMSIZ], *cptr;  
    struct ifconf       ifc;  
    struct ifreq        *ifr, ifrcopy;  
    struct sockaddr_in  *sin;  
    char temp[80];  
    int sockfd;
	
	FreeAddresses();
	
    for (i=0; i<MAX_ADDRS; ++i)  
    {  
        m_ifNames[i] = m_ipNames[i] = NULL;  
        m_ipAddrs[i] = 0;  
    }  
    sockfd = socket(AF_INET, SOCK_DGRAM, 0);  
    if (sockfd < 0)  
    {  
        perror("socket failed");  
        return;  
    }  
	
    ifc.ifc_len = BUFFERSIZE;  
    ifc.ifc_buf = buffer;  
	
    if (ioctl(sockfd, SIOCGIFCONF, &ifc) < 0)  
    {  
        perror("ioctl error");  
        return;  
    }  
	
    lastname[0] = 0;
	
	int nextAddr = 0;
	
    for (ptr = buffer; ptr < buffer + ifc.ifc_len; )  
    {  
        ifr = (struct ifreq *)ptr;  
        len = max(sizeof(struct sockaddr), ifr->ifr_addr.sa_len);  
        ptr += sizeof(ifr->ifr_name) + len;  // for next one in buffer  
		
        if (ifr->ifr_addr.sa_family != AF_INET)  
        {  
            continue;   // ignore if not desired address family  
        }  
		
        if ((cptr = (char *)strchr(ifr->ifr_name, ':')) != NULL)  
        {  
            *cptr = 0;      // replace colon will null  
        }  
		
        if (strncmp(lastname, ifr->ifr_name, IFNAMSIZ) == 0)  
        {  
            continue;   /* already processed this interface */  
        }  
		
        memcpy(lastname, ifr->ifr_name, IFNAMSIZ);  
		
        ifrcopy = *ifr;  
        ioctl(sockfd, SIOCGIFFLAGS, &ifrcopy);  
        flags = ifrcopy.ifr_flags;  
        if ((flags & IFF_UP) == 0)  
        {  
            continue;   // ignore if interface not up  
        }  
		
        m_ifNames[nextAddr] = (char *)malloc(strlen(ifr->ifr_name)+1);  
        if (m_ifNames[nextAddr] == NULL)  
        {  
            return;  
        }  
        strcpy(m_ifNames[nextAddr], ifr->ifr_name);  
		
        sin = (struct sockaddr_in *)&ifr->ifr_addr;  
        strcpy(temp, inet_ntoa(sin->sin_addr));  
		
        m_ipNames[nextAddr] = (char *)malloc(strlen(temp)+1);  
        if (m_ipNames[nextAddr] == NULL)  
        {  
            return;  
        }  
        strcpy(m_ipNames[nextAddr], temp);  
        m_ipAddrs[nextAddr] = sin->sin_addr.s_addr;  
        ++nextAddr;  
    }  
	
    close(sockfd);  
}

void AdViewNetManager::GetHWAddresses()
{  
	struct ifconf ifc;  
	struct ifreq *ifr;  
	int i, sockfd;  
	char buffer[BUFFERSIZE], *cp, *cplim;  
	char temp[80];  
	for (i=0; i<MAX_ADDRS; ++i)  
	{  
		m_hwAddrs[i] = NULL;  
	}  
	sockfd = socket(AF_INET, SOCK_DGRAM, 0);  
	if (sockfd < 0)  
	{  
		perror("socket failed");  
		return;  
	}  
	ifc.ifc_len = BUFFERSIZE;  
	ifc.ifc_buf = buffer;  
	if (ioctl(sockfd, SIOCGIFCONF, (char *)&ifc) < 0)  
	{  
		perror("ioctl error");  
		close(sockfd);  
		return;  
	}  
	//ifr = ifc.ifc_req;
	cplim = buffer + ifc.ifc_len;  
	for (cp=buffer; cp < cplim; )  
	{  
		ifr = (struct ifreq *)cp;  
		if (ifr->ifr_addr.sa_family == AF_LINK)  
		{  
			struct sockaddr_dl *sdl = (struct sockaddr_dl *)&ifr->ifr_addr;  
			int a,b,c,d,e,f;
			unsigned char        *ptr;
			int i;
			
			ptr = (unsigned char *)LLADDR(sdl);
			a = ptr[0];
			b = ptr[1];
			c = ptr[2];
			d = ptr[3];
			e = ptr[4];
			f = ptr[5];
			
			sprintf(temp, "%02X:%02X:%02X:%02X:%02X:%02X",a,b,c,d,e,f);  
			for (i=0; i<MAX_ADDRS; ++i)  
			{  
				if ((m_ifNames[i] != NULL) && (strcmp(ifr->ifr_name, m_ifNames[i]) == 0))  
				{  
					if (m_hwAddrs[i] == NULL)  
					{  
						m_hwAddrs[i] = (char *)malloc(strlen(temp)+1);  
						strcpy(m_hwAddrs[i], temp);  
						break;  
					}  
				}  
			}  
		}  
		cp += sizeof(ifr->ifr_name) + max(sizeof(ifr->ifr_addr), ifr->ifr_addr.sa_len);  
	}  
	close(sockfd);  
}

#pragma c functions.



void *AdViewNetManager_new()
{
	return new AdViewNetManager();
}

void AdViewNetManager_delete(void *manager)
{
	delete ((AdViewNetManager*)manager);
}

void AdViewNetManager_GetIPAddresses(void *manager)
{
	if (NULL != manager)
	{
		((AdViewNetManager*)manager)->GetIPAddresses();
	}
}

const char *AdViewNetManager_GetIPName(void *manager, int idx)
{
	if (NULL != manager)
	{
		return ((AdViewNetManager*)manager)->GetIpName(idx);
	}
	return NULL;
}
