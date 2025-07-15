#Requires AutoHotkey v2.0

class TCPSocket {
    static version := "1.2.0"

    __New() {
        this.WSAData := Buffer(400)
        this.sock := 0
        this.Connected := false
        this.lastError := 0
        this.recvBuffer := ""
        this.recvCallback := ""
        this.dnsCache := Map()

        if DllCall("Ws2_32\WSAStartup", "UShort", 0x202, "Ptr", this.WSAData.Ptr) != 0 {
            this.lastError := DllCall("Ws2_32\WSAGetLastError")
            throw Error("WSAStartup failed with error: " this.lastError)
        }
    }

    ; -- Step 4: DNS Lookup with caching, IPv4 & IPv6 support --

    DNSLookup(host) {
        if this.dnsCache.Has(host) {
            return this.dnsCache[host]
        }

        AF_UNSPEC := 0        ; Allow IPv4 or IPv6
        hints := Buffer(28, 0)
        NumPut("UInt", 0, hints, 0)   ; ai_flags = 0 no passive
        NumPut("Int", AF_UNSPEC, hints, 4)   ; ai_family: IPv4/IPv6
        NumPut("Int", 1, hints, 8)    ; SOCK_STREAM
        NumPut("Int", 6, hints, 12)   ; IPPROTO_TCP

        ppResult := Buffer(8, 0)
        ret := DllCall("Ws2_32\getaddrinfo", "AStr", host, "Ptr", 0, "Ptr", hints.Ptr, "Ptr*", ppResult.Ptr)
        if ret != 0 {
            this.lastError := ret
            throw Error("DNS lookup failed for " host ": " this.GetErrorMessage(ret))
        }

        pAddrInfo := NumGet(ppResult, 0, "Ptr")
        if !pAddrInfo {
            throw Error("No address info found for " host)
        }

        ip := ""
        while pAddrInfo {
            family := NumGet(pAddrInfo + 0, 0, "Int")
            if family = 2 { ; AF_INET IPv4
                sockaddr_ptr := NumGet(pAddrInfo + 16, 0, "Ptr")
                ip_int := NumGet(sockaddr_ptr + 4, 0, "UInt")
                ip := Format("{}.{}.{}.{}", ip_int & 0xFF, (ip_int >> 8) & 0xFF, (ip_int >> 16) & 0xFF, (ip_int >> 24) & 0xFF)
                break
            } else if family = 23 { ; AF_INET6 IPv6
                sockaddr_ptr := NumGet(pAddrInfo + 16, 0, "Ptr")
                ipBytes := Buffer(16)
                DllCall("RtlMoveMemory", "Ptr", ipBytes.Ptr, "Ptr", sockaddr_ptr + 8, "UPtr", 16)
                ip := this._FormatIPv6(ipBytes)
                break
            }
            pAddrInfo := NumGet(pAddrInfo + 8, 0, "Ptr") ; next addrinfo
        }

        DllCall("Ws2_32\freeaddrinfo", "Ptr", NumGet(ppResult, 0, "Ptr"))
        if ip = "" {
            throw Error("No suitable IP found for " host)
        }

        this.dnsCache[host] := ip
        return ip
    }

    _FormatIPv6(buf) {
        parts := []
        Loop 8 {
            part := NumGet(buf.Ptr, (A_Index - 1) * 2, "UShort")
            parts.Push(Format("{:x}", part))
        }
        return this.StrJoin(":", parts*)
    }

    StrJoin(separator, elements*) {
        count := elements.Length()
        if count = 0
            return ""
        result := elements[1]
        for i, val in elements {
            if i = 1
                continue
            result .= separator . val
        }
        return result
    }


    ; -- Step 2 & 3: Connect with non-blocking socket and timeout using select() --

    Connect(host, port, timeout := 5000) {
        if this.IsConnected()
            throw Error("Socket already connected")

        ip := (RegExMatch(host, "^\d+\.\d+\.\d+\.\d+$")) ? host : this.DNSLookup(host)

        af := 2  ; AF_INET by default
        if InStr(ip, ":")
            af := 23 ; AF_INET6

        this.sock := DllCall("Ws2_32\socket", "Int", af, "Int", 1, "Int", 6, "Ptr")
        if this.sock = -1 {
            this.lastError := DllCall("Ws2_32\WSAGetLastError")
            throw Error("Socket creation failed: " this.GetErrorMessage(this.lastError))
        }

        ; Set non-blocking mode
        modeBuf := Buffer(4, 0)
        NumPut("UInt", 1, modeBuf)
        DllCall("Ws2_32\ioctlsocket", "Ptr", this.sock, "UInt", 0x8004667E, "Ptr", modeBuf.Ptr)

        addr := this._CreateSockaddr(ip, port, af)

        result := DllCall("Ws2_32\connect", "Ptr", this.sock, "Ptr", addr.Ptr, "Int", addr.Size)
        err := DllCall("Ws2_32\WSAGetLastError")
        if result != 0 && err != 10035 { ; WSAEWOULDBLOCK expected
            this.Close()
            throw Error("Immediate connect failed: " this.GetErrorMessage(err))
        }

        ; Wait for socket writability within timeout
        ; if !this._WaitForConnect(timeout) {
        ;     this.Close()
        ;     throw Error("Connection timed out after " timeout " ms")
        ; }

        errVal := 0
        len := 4
        if DllCall("Ws2_32\getsockopt", "Ptr", this.sock, "Int", 0xFFFF, "Int", 0x1007, "Int*", &errVal, "Int*", &len) != 0 || errVal != 0 {
            this.Close()
            throw Error("Connection failed after select (getsockopt): " this.GetErrorMessage(errVal))
        }

        ; Restore blocking mode
        NumPut("UInt", 0, modeBuf)
        DllCall("Ws2_32\ioctlsocket", "Ptr", this.sock, "UInt", 0x8004667E, "Ptr", modeBuf.Ptr)

        this.SetConnected(true)
        return true
    }

    _CreateSockaddr(ip, port, af) {
        if af = 2 { ; IPv4
            addr := Buffer(16, 0)
            NumPut("UShort", af, addr, 0) ; AF_INET
            NumPut("UShort", DllCall("Ws2_32\htons", "UShort", port), addr, 2)
            NumPut("UInt", DllCall("Ws2_32\inet_addr", "AStr", ip), addr, 4)
            addr.Size := 16
            return addr
        } else if af = 23 { ; IPv6
            addr := Buffer(28, 0)
            NumPut("UShort", af, addr, 0) ; AF_INET6
            NumPut("UShort", DllCall("Ws2_32\htons", "UShort", port), addr, 2)
            ; ScopeId = 0 for now (offset 24)
            NumPut("UInt", 0, addr, 24)
            ipBytes := Buffer(16, 0)
            ; Parse IPv6 string into 8 UShorts (simple heuristic)
            parts := StrSplit(ip, ":")
            Loop 8 {
                val := 0
                if (A_Index <= parts.Length()) && parts[A_Index] {
                    val := "0x" . parts[A_Index]
                }
                NumPut("UShort", val, ipBytes, (A_Index - 1) * 2)
            }
            DllCall("RtlMoveMemory", "Ptr", addr.Ptr + 8, "Ptr", ipBytes.Ptr, "UPtr", 16)
            addr.Size := 28
            return addr
        }
        throw Error("Unsupported address family: " af)
    }

    _WaitForConnect(timeoutMs) {
        fdSet := Buffer(16, 0)
        NumPut("UInt", 1, fdSet, 0)          ; fd_count = 1
        NumPut("Ptr", this.sock, fdSet, 4)  ; fd_array[0] = socket handle

        tv := Buffer(8, 0)
        NumPut("Int", Floor(timeoutMs / 1000), tv, 0)
        NumPut("Int", Mod(timeoutMs, 1000) * 1000, tv, 4) ; microseconds

        ret := DllCall("Ws2_32\select", "Int", 0, "Ptr", 0, "Ptr", fdSet.Ptr, "Ptr", 0, "Ptr", tv.Ptr)
        return ret > 0
    }

    ; -- Send and Receive --

    Send(data) {
        if !this.IsConnected()
            throw Error("Socket not connected")

        bytesSent := 0
        if Type(data) = "String"
            bytesSent := DllCall("Ws2_32\send", "Ptr", this.sock, "AStr", data, "Int", StrLen(data), "Int", 0)
        else if data is Buffer
            bytesSent := DllCall("Ws2_32\send", "Ptr", this.sock, "Ptr", data.Ptr, "Int", data.Size, "Int", 0)
        else
            throw Error("Invalid data type for send")

        if bytesSent = -1 {
            this.lastError := DllCall("Ws2_32\WSAGetLastError")
            throw Error("Send failed: " this.GetErrorMessage(this.lastError))
        }
        return bytesSent
    }

    Recv(maxLen := 1024) {
        if !this.IsConnected()
            throw Error("Socket not connected")

        buf := Buffer(maxLen, 0)
        len := DllCall("Ws2_32\recv", "Ptr", this.sock, "Ptr", buf.Ptr, "Int", maxLen, "Int", 0)
        if len = -1 {
            this.lastError := DllCall("Ws2_32\WSAGetLastError")
            throw Error("Receive failed: " this.GetErrorMessage(this.lastError))
        }
        return (len > 0) ? StrGet(buf, len, "UTF-8") : ""
    }

    RecvRaw(maxLen := 1024) {
        if !this.IsConnected()
            throw Error("Socket not connected")

        buf := Buffer(maxLen, 0)
        len := DllCall("Ws2_32\recv", "Ptr", this.sock, "Ptr", buf.Ptr, "Int", maxLen, "Int", 0)
        if len = -1 {
            this.lastError := DllCall("Ws2_32\WSAGetLastError")
            throw Error("Receive failed: " this.GetErrorMessage(this.lastError))
        }
        return (len > 0) ? buf : Buffer(0)
    }

    ; -- Timeout setters --

    SetTimeoutSend(ms) {
        if !this.IsConnected()
            throw Error("Socket not connected")

        DllCall("Ws2_32\setsockopt", "Ptr", this.sock, "Int", 0xFFFF, "Int", 0x1005  ; SO_SNDTIMEO
            , "Int*", &ms, "Int", 4)
    }

    SetTimeoutRecv(ms) {
        if !this.IsConnected()
            throw Error("Socket not connected")

        DllCall("Ws2_32\setsockopt", "Ptr", this.sock, "Int", 0xFFFF, "Int", 0x1006  ; SO_RCVTIMEO
            , "Int*", &ms, "Int", 4)
    }

    ; -- Connected flag --

    IsConnected() {
        return this.Connected
    }

    SetConnected(state) {
        this.Connected := state
    }

    ; -- Error handling --

    GetLastError() {
        return this.lastError
    }

    GetErrorMessage(errorCode) {
        static errors := Map(
            10035, "Resource temporarily unavailable (WSAEWOULDBLOCK)",
            10036, "Operation now in progress (WSAEINPROGRESS)",
            10037, "Operation already in progress (WSAEALREADY)",
            10038, "Socket operation on non-socket (WSAENOTSOCK)",
            10039, "Destination address required (WSAEDESTADDRREQ)",
            10040, "Message too long (WSAEMSGSIZE)",
            10041, "Protocol wrong type for socket (WSAEPROTOTYPE)",
            10042, "Bad protocol option (WSAENOPROTOOPT)",
            10043, "Protocol not supported (WSAEPROTONOSUPPORT)",
            10044, "Socket type not supported (WSAESOCKTNOSUPPORT)",
            10045, "Operation not supported (WSAEOPNOTSUPP)",
            10046, "Protocol family not supported (WSAEPFNOSUPPORT)",
            10047, "Address family not supported by protocol (WSAEAFNOSUPPORT)",
            10048, "Address already in use (WSAEADDRINUSE)",
            10049, "Cannot assign requested address (WSAEADDRNOTAVAIL)",
            10050, "Network is down (WSAENETDOWN)",
            10051, "Network is unreachable (WSAENETUNREACH)",
            10052, "Network dropped connection on reset (WSAENETRESET)",
            10053, "Software caused connection abort (WSAECONNABORTED)",
            10054, "Connection reset by peer (WSAECONNRESET)",
            10055, "No buffer space available (WSAENOBUFS)",
            10056, "Socket is already connected (WSAEISCONN)",
            10057, "Socket is not connected (WSAENOTCONN)",
            10058, "Cannot send after socket shutdown (WSAESHUTDOWN)",
            10060, "Connection timed out (WSAETIMEDOUT)",
            10061, "Connection refused (WSAECONNREFUSED)",
            10065, "No route to host (WSAEHOSTUNREACH)",
            10067, "Too many processes (WSAEPROCLIM)",
            11001, "Host not found (WSAHOST_NOT_FOUND)",
            11002, "Non-authoritative host not found (WSATRY_AGAIN)",
            11003, "Non-recoverable error (WSAE_NO_RECOVERY)",
            11004, "Valid name, no data record of requested type (WSAE_NO_DATA)"
        )
        return errors.Has(errorCode) ? errors[errorCode] : "Unknown error: " errorCode
    }

    ; -- Polling and receive callback --

    Poll() {
        if !this.IsConnected()
            return false

        buf := Buffer(4096, 0)
        len := DllCall("Ws2_32\recv", "Ptr", this.sock, "Ptr", buf.Ptr, "Int", buf.Size, "Int", 0)
        if len = 0 {
            ; Connection closed by peer
            this.Close()
            return false
        } else if len = -1 {
            err := DllCall("Ws2_32\WSAGetLastError")
            if err = 10035 {
                ; WSAEWOULDBLOCK - no data available
                return true
            }
            this.lastError := err
            throw Error("Poll receive error: " this.GetErrorMessage(err))
        }

        data := StrGet(buf, len, "UTF-8")
        this.recvBuffer .= data

        if this.recvCallback && Type(this.recvCallback) == "Func" {
            this.recvCallback.Call(data)
        } 

        return true
    }

    SetReceiveCallback(func) {
        if Type(func) != "Func"
            throw Error("Receive callback must be a function")
        this.recvCallback := func
    }

    ; -- Close and cleanup --

    Close() {
        if this.sock {
            DllCall("Ws2_32\shutdown", "Ptr", this.sock, "Int", 2)
            DllCall("Ws2_32\closesocket", "Ptr", this.sock)
            this.sock := 0
            this.SetConnected(false)
        }
        DllCall("Ws2_32\WSACleanup")
    }

    __Delete() {
        this.Close()
    }
}
