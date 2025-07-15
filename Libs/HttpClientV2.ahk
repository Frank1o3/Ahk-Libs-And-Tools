/*
* Made by: Frank1o3
* Version: 0.0.2
* Implements: Basic HTTP protocols with manual timeout
*/

class Http {

    __New() {
        this.xhr := ComObject("Msxml2.XMLHTTP.6.0")
        this.ActiveRequests := Map()
        this.timeout := 30000  ; Default timeout (ms)
    }

    SetTimeout(timeout) {
        this.timeout := timeout
    }

    Request(method, url, data := "", headers := "") {
        this.xhr := ComObject("Msxml2.XMLHTTP.6.0")
        this.xhr.open(method, url, true)  ; Must be async to allow timeout abort

        if IsObject(headers) {
            for name, value in headers
                this.xhr.setRequestHeader(name, value)
        }

        response := ""
        done := false

        this.xhr.onreadystatechange := (*) => (
            this.xhr.readyState = 4 ? (done := true, response := this.xhr.responseText) : ""
        )

        try {
            this.xhr.send(StrLen(data) ? data : "")
        } catch Error as e {
            return "Error: Send failed - " e.Message
        }

        start := A_TickCount
        while !done {
            if A_TickCount - start >= this.timeout {
                try this.xhr.abort()
                return "Error: Request timed out"
            }
            Sleep(10)
        }

        return response
    }

    AsyncRequest(method, url, callback, data := "", headers := "") {
        xhr := ComObject("Msxml2.XMLHTTP.6.0")
        reqId := A_TickCount . "-" . Random(1000, 9999)
        started := A_TickCount

        xhr.onreadystatechange := (*) => this._HandleResponse(reqId)
        this.ActiveRequests[reqId] := { xhr: xhr, callback: callback, start: started }

        xhr.open(method, url, true)

        if IsObject(headers) {
            for name, value in headers
                xhr.setRequestHeader(name, value)
        }

        try {
            xhr.send(StrLen(data) ? data : "")
        } catch Error as e {
            callback.Call(-1, "Error: Send failed - " e.Message)
            return
        }

        SetTimer(this._MakeTimeoutChecker(reqId), 100)
    }

    _MakeTimeoutChecker(reqId) {
        return ObjBindMethod(this, "_CheckTimeout", reqId)
    }

    _CheckTimeout(reqId) {
        if !this.ActiveRequests.Has(reqId) {
            SetTimer(this._MakeTimeoutChecker(reqId), 0)
            return
        }

        data := this.ActiveRequests[reqId]
        if A_TickCount - data.start >= this.timeout {
            try data.xhr.abort()
            data.callback.Call(-1, "Error: Async request timed out")
            this.ActiveRequests.Delete(reqId)
            SetTimer(this._MakeTimeoutChecker(reqId), 0)
            return
        }

        if data.xhr.readyState = 4 {
            SetTimer(this._MakeTimeoutChecker(reqId), 0)
            return
        }

    }

    _HandleResponse(reqId) {
        if !this.ActiveRequests.Has(reqId)
            return

        data := this.ActiveRequests[reqId]
        xhr := data.xhr
        callback := data.callback

        if xhr.readyState = 4 {
            this.ActiveRequests.Delete(reqId)
            try {
                callback.Call(xhr.status, xhr.responseText)
            } catch Error as e {
                callback.Call(xhr.status, "Error: " e.Message)
            }
        }
    }
}