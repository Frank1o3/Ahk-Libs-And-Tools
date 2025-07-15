#Include Libs\HttpClientV2.ahk
#Include Libs\Codes.ahk
Persistent(true)

; Initialize once at script startup
StatusCodes.Init()

; This script demonstrates how to use the HttpClientV2 library to make an asynchronous HTTP request.
; It sets a timeout for the request and handles the response with a callback function.
; It should give a timeout error because the URL is set to delay the response for 5 seconds.


client := Http()
client.SetTimeout(3000)

callback(status, msg) {
    MsgBox "Status: " StatusCodes.Get(status) . "`nResponse: " . msg
}

client.AsyncRequest("GET", "http://httpbin.org/delay/1", callback)
Sleep 5
client.AsyncRequest("GET", "http://httpbin.org/delay/2", callback)
Sleep 5
client.AsyncRequest("GET", "http://httpbin.org/delay/3", callback)
Sleep 5
client.AsyncRequest("GET", "http://httpbin.org/delay/4", callback)

Sleep 1000 + 3000 + 4000 + 2000 - 15

ExitApp