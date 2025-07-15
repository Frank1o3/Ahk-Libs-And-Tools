#Include Libs\TCPSocket.ahk

sock := TCPSocket()

sock.Connect("10.0.0.8", 12345, 3000)  ; 3 sec timeout

sock.SetReceiveCallback(OnDataReceived)

sock.Send("Hi")

while sock.IsConnected()
{
    sock.Poll()
    Sleep(10)
}

sock.Close()

OnDataReceived(data) {
    MsgBox("Received chunk: " . data)
}

F1:: {
    ExitApp()
}