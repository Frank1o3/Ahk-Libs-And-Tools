#Include Libs\HttpClientV2.ahk

client := Http()


callback(status, data) {
    MsgBox status . "`n" . data
}
client.Request("GET", "http://httpbin.org/get")