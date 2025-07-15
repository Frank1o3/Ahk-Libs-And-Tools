#Include Libs\HttpClientV2.ahk
#Include Libs\Codes.ahk
Persistent(true)

; Initialize once at script startup
StatusCodes.Init()

; This script demonstrates how to use the HttpClientV2 library to make an asynchronous HTTP request.
; It sets a timeout for the request and handles the response with a callback function.
; It should give a timeout error because the URL is set to delay the response for 5 seconds.


client := Http()

URL := "https://discord.com/api/webhooks/1394719446278340721/2S_RAuxA5AAMsQa9qg7wzvsUxD7b567o9kcFgVYiEvXE2pnWmRKFnBaQbmTCdXQRBSS4"

data := Map()

data["content"] := "" . A_TickCount
data["embeds"] := [Map(
    "title", "This is a test for the new HttpClientV2 library",
    "description", "This ahk lib implements basic http request handling and usage",
    "color", 0xd82d2d,
    "fields", [
        Map("name", "Implements", "value", "Basic HTTP protocols with manual timeout, asynchronous requests, and JSON handling")
    ],
    "author", Map("name", "Frank1o3")
)]

data["attachments"] := []  ; Discord API requires this to be null if not used
data["username"] := A_ScriptName ; Set a custom username for the webhook
data["tts"] := false  ; Text-to-speech option


client.AsyncRequest("POST", URL,
    (status, msg?, body?) => (MsgBox("Status: " . StatusCodes.Get(status) . "`nResponse: " . msg . "`nBody: " . body), ExitApp()),
    data
)