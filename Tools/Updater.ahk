#Include ..\Libs\HttpClientV2.ahk

IP := "https://httpbin.org/delay/3"

client := Http()

client.SetTimeout(5000)  ; Set a custom timeout

response := client.Request("GET", IP)
MsgBox response