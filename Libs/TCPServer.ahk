#Requires AutoHotkey v2.0

class TCPServer {
    __New(port := 8080) {
        this.port := port
        this.sock := 0
        this.clientSock := 0
        this.running := false

        this.WSAData := Buffer(400)
        if DllCall("Ws2_32\WSAStartup", "UShort", 0x202, "Ptr", this.WSAData.Ptr) != 0
            throw Error("WSAStartup failed")
    }

    __Delete() {
        this.Close()
    }

    Start() {
        AF_INET := 2
        SOCK_STREAM := 1
        IPPROTO_TCP := 6

        this.sock := DllCall("Ws2_32\socket", "Int", AF_INET, "Int", SOCK_STREAM, "Int", IPPROTO_TCP, "Ptr")
        if this.sock = -1
            throw Error("Socket creation failed")

        addr := Buffer(16, 0)
        NumPut("UShort", AF_INET, addr, 0)
        NumPut("UShort", DllCall("Ws2_32\htons", "UShort", this.port), addr, 2)
        NumPut("UInt", 0, addr, 4)  ; INADDR_ANY (0.0.0.0)

        if DllCall("Ws2_32\bind", "Ptr", this.sock, "Ptr", addr, "Int", 16) != 0
            throw Error("Bind failed")

        if DllCall("Ws2_32\listen", "Ptr", this.sock, "Int", 5) != 0
            throw Error("Listen failed")

        this.running := true
        MsgBox "Server started on port " this.port
    }

    WaitForClient() {
        this.clientSock := DllCall("Ws2_32\accept", "Ptr", this.sock, "Ptr", 0, "Ptr", 0, "Ptr")
        if this.clientSock = -1
            throw Error("Accept failed")
        MsgBox "Client connected!"
    }

    Send(data) {
        if this.clientSock
            return DllCall("Ws2_32\send", "Ptr", this.clientSock, "AStr", data, "Int", StrLen(data), "Int", 0)
    }

    Recv(maxLen := 1024) {
        if !this.clientSock
            return ""

        buf := Buffer(maxLen, 0)
        len := DllCall("Ws2_32\recv", "Ptr", this.clientSock, "Ptr", buf.Ptr, "Int", maxLen, "Int", 0)
        return (len > 0) ? StrGet(buf, len, "UTF-8") : ""
    }

    Close() {
        if this.clientSock {
            DllCall("Ws2_32\shutdown", "Ptr", this.clientSock, "Int", 2)
            DllCall("Ws2_32\closesocket", "Ptr", this.clientSock)
        }
        if this.sock {
            DllCall("Ws2_32\closesocket", "Ptr", this.sock)
        }
        DllCall("Ws2_32\WSACleanup")
        this.running := false
        MsgBox "Server stopped"
    }
}
