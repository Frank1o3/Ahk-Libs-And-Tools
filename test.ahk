#Include Libs\HttpClientV2.ahk
#Include Libs\Codes.ahk
Persistent(true)

; Initialize once at script startup
StatusCodes.Init()

; This script demonstrates how to use the HttpClientV2 library to make an asynchronous HTTP request.

client := Http()

URL := "https://discord.com/api/webhooks/1394736582023450844/q9THFQrol2KBSSsVVeqWQOy3zZ8UBNHXwnIr2naisWjl14DRHgAyJqEa7qFJY_LFPTWT"

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
    (status, msg?, body?) => (
        MsgBox("Status: " . StatusCodes.Get(status) . "`nResponse: " . msg . "`nBody: " . body),
        ExitApp()
    ),
    data
)