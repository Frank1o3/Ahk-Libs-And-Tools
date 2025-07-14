/*
* Made by: Frank1o3
* Version: 0.0.1
* Implements: Basic Http protocals
*/

Class Http {

    __New() {
        this.xhr := ComObject("Msxml2.XMLHTTP")
        this.ActiveRequests := Map()
    }

    Request(method, url, data := "", headers := "") {
        this.xhr.open(method, url, false)

        if IsObject(headers) {
            for name, value in headers {
                this.xhr.setRequestHeader(name, value)
            }
        }

        if StrLen(data) > 0 {
            try {
                this.xhr.send(data)
            } catch Error as e {
                return "Error: Failed to send request - " e.message
            }
        }
        if this.xhr.status != 200 {
            return "Error: " this.xhr.status
        }
        return this.xhr.responseText
    }

    AsyncRequest(method, url, callback, data := "", headers := "") {
        xhr := ComObject("Msxml2.XMLHTTP")
        reqId := A_TickCount . "-" . Random(1000, 9999)

        this.ActiveRequests[reqId] := { xhr: xhr, callback: callback }

        xhr.onreadystatechange := (*) => this._HandleResponse(reqId)
        xhr.open(method, url, true)

        if IsObject(headers) {
            for name, value in headers {
                xhr.setRequestHeader(name, value)
            }
        }

        if StrLen(data) > 0 {
            xhr.send(data)
        }
    }

    _HandleResponse(reqId) {
        if !this.ActiveRequests.Has(reqId) {
            return
        }

        data := this.ActiveRequests[reqId]
        xhr := data.xhr
        callback := data.callback

        if xhr.readyState = 4 {
            this.ActiveRequests.Delete(reqId)
            try {
                callback.Call(xhr.status, xhr.responseText)
            }
        }
    }
}