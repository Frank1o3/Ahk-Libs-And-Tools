#Include Libs\HttpClientV2.ahk
#Include Libs\StatusCodes.ahk
Persistent(true)

; This script demonstrates how to use the HttpClientV2 library to make an asynchronous HTTP request.
; It sets a timeout for the request and handles the response with a callback function.
; It should give a timeout error because the URL is set to delay the response for 5 seconds.


client := Http()
client.SetTimeout(3000)

callback(status, msg) {
    MsgBox "Status: " CodeToMSG(status) . "`nResponse: " . msg
    Persistent(false)
}

client.AsyncRequest("GET", "http://httpbin.org/delay/4", callback)