#Requires AutoHotkey v2.0

class TCPSocket {
    ; Class properties
    static version := "1.0.0"
    __New() {
        this.WSAData := Buffer(400)
        this.sock := 0
        this.Connected := false
        this.lastError := 0

        ; Initialize Winsock
        if DllCall("Ws2_32\WSAStartup", "UShort", 0x202, "Ptr", this.WSAData.Ptr) != 0 {
            this.lastError := DllCall("Ws2_32\WSAGetLastError")
            throw Error("WSAStartup failed with error: " this.lastError)
        }
    }

    /**
     * Performs DNS lookup for a given hostname
     * @param host Hostname to resolve
     * @returns {String} IP address
     * @throws {Error} If DNS lookup fails
     */
    DNSLookup(host) {
        AF_INET := 2
        AI_PASSIVE := 1
        hints := Buffer(28, 0)
        NumPut("UInt", AI_PASSIVE, hints, 0) ; ai_flags
        NumPut("Int", AF_INET, hints, 4)    ; ai_family
        NumPut("Int", 1, hints, 8)          ; ai_socktype = SOCK_STREAM
        NumPut("Int", 6, hints, 12)         ; ai_protocol = IPPROTO_TCP

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

        sockaddr_ptr := NumGet(pAddrInfo + 16, "Ptr")
        if !sockaddr_ptr {
            DllCall("Ws2_32\freeaddrinfo", "Ptr", pAddrInfo)
            throw Error("No sockaddr found for " host)
        }

        ip_int := NumGet(sockaddr_ptr + 4, 0, "UInt")
        ip := Format("{}.{}.{}.{}", ip_int & 0xFF, (ip_int >> 8) & 0xFF, (ip_int >> 16) & 0xFF, (ip_int >> 24) & 0xFF)

        DllCall("Ws2_32\freeaddrinfo", "Ptr", pAddrInfo)
        return ip
    }

    /**
     * Connects to a remote host
     * @param host Hostname or IP address
     * @param port Port number
     * @param timeout Connection timeout in milliseconds (default: 5000)
     * @returns {Boolean} True if connection successful
     * @throws {Error} If connection fails
     */
    Connect(host, port, timeout := 5000) {
        if this.IsConnected()
            throw Error("Socket already connected")

        ip := (RegExMatch(host, "^\d+\.\d+\.\d+\.\d+$")) ? host : this.DNSLookup(host)

        this.sock := DllCall("Ws2_32\socket", "Int", 2, "Int", 1, "Int", 6, "Ptr")
        if this.sock = -1 {
            this.lastError := DllCall("Ws2_32\WSAGetLastError")
            throw Error("Socket creation failed: " this.GetErrorMessage(this.lastError))
        }

        ; Set to non-blocking
        mode := Buffer(4, 0)
        NumPut("UInt", 1, mode)
        DllCall("Ws2_32\ioctlsocket", "Ptr", this.sock, "UInt", 0x8004667E, "Ptr", mode.Ptr)

        ; sockaddr_in
        addr := Buffer(16, 0)
        NumPut("UShort", 2, addr, 0) ; AF_INET
        NumPut("UShort", DllCall("Ws2_32\htons", "UShort", port), addr, 2)
        NumPut("UInt", DllCall("Ws2_32\inet_addr", "AStr", ip), addr, 4)

        ; Start connection
        result := DllCall("Ws2_32\connect", "Ptr", this.sock, "Ptr", addr, "Int", 16)
        err := DllCall("Ws2_32\WSAGetLastError")
        if result != 0 && err != 10035 {
            this.Close()
            throw Error("Immediate connect failed: " this.GetErrorMessage(err))
        }

        ; Check for error on socket
        err := 0
        len := 4
        DllCall("Ws2_32\getsockopt", "Ptr", this.sock, "Int", 0xFFFF, "Int", 0x1007, "Int*", &err, "Int*", &len)
        if err != 0 {
            this.Close()
            throw Error("Connection failed (getsockopt): " this.GetErrorMessage(err))
        }
        
        ; Restore blocking mode
        NumPut("UInt", 0, mode)
        DllCall("Ws2_32\ioctlsocket", "Ptr", this.sock, "UInt", 0x8004667E, "Ptr", mode.Ptr)

        this.SetConnected(true)
        return true
    }

    /**
     * Sends data over the socket
     * @param data String or Buffer to send
     * @returns {Integer} Number of bytes sent
     * @throws {Error} If socket not connected or send fails
     */
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

    /**
     * Receives string data from the socket
     * @param maxLen Maximum length to receive (default: 1024)
     * @returns {String} Received data
     * @throws {Error} If socket not connected or receive fails
     */
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

    /**
     * Receives raw data from the socket
     * @param maxLen Maximum length to receive (default: 1024)
     * @returns {Buffer} Received data buffer
     * @throws {Error} If socket not connected or receive fails
     */
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

        DllCall("ws2_32\")
    }

    /**
     * Sets socket timeout for send/receive operations
     * @param ms Timeout in milliseconds
     */
    SetTimeout(ms) {
        if !this.IsConnected()
            throw Error("Socket not connected")

        DllCall("Ws2_32\setsockopt", "Ptr", this.sock, "Int", 0xFFFF, "Int", 0x1006, "Int*", ms, "Int", 4)
    }

    /**
     * Checks if socket is connected
     * @returns {Boolean} True if connected
     */
    IsConnected() {
        return this.Connected
    }

    SetConnected(mode) {
        this.Connected := mode
    }

    /**
     * Gets last error code
     * @returns {Integer} Last error code
     */
    GetLastError() {
        return this.lastError
    }

    /**
     * Converts Winsock error code to descriptive message
     * @param errorCode Winsock error code
     * @returns {String} Error description
     */
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

    /**
     * Closes the socket connection
     */
    Close() {
        if this.sock {
            DllCall("Ws2_32\shutdown", "Ptr", this.sock, "Int", 2)
            DllCall("Ws2_32\closesocket", "Ptr", this.sock)
            this.sock := 0
            this.SetConnected(false)
        }
        DllCall("Ws2_32\WSACleanup")
    }

    /**
     * Class destructor
     */
    __Delete() {
        this.Close()
    }
}
