class HttpClient {
    __New() {
        this.headers := Map()
    }

    ; Set headers for future requests
    SetHeader(name, value) {
        this.headers[name] := value
    }

    ; Clear all headers
    ClearHeaders() {
        this.headers := Map()
    }

    ; HTTP GET request
    Get(url) {
        return this.Request("GET", url)
    }

    ; HTTP POST request (if needed)
    Post(url, data := "") {
        return this.Request("POST", url, data)
    }

    ; Download file from URL
    Download(url, fileName) {
        req := ComObject("MSXML2.XMLHTTP")
        req.open("GET", url, false)
        req.send()

        if req.status != 200 {
            return "Error: " req.status " - " req.statusText
        }

        FileAppend req.responseBody, fileName
        return "File downloaded: " fileName
    }

    ; Main request handler for any HTTP method
    Request(method, url, data := "") {
        req := ComObject("MSXML2.XMLHTTP")
        req.open(method, url, false)

        ; Set all headers
        for header, value in this.headers {
            req.setRequestHeader(header, value)
        }

        ; Send the request (POST only if data is provided)
        try {
            req.send(data)
        } catch Error as e {
            return "Error: Failed to send request - " e.message
        }

        while (req.readyState != 4) {
            Sleep(10)  ; Wait for the request to complete
        }

        ; Error management for non-200 status codes
        if req.status != 200 {
            return "Error: " req.status " - " req.statusText
        }

        ; Return the response text
        return req.responseText
    }
}