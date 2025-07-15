class StatusCodes {
    static _codes := Map()

    static Init() {
        ; HTTP 1xx: Informational
        StatusCodes._codes[100] := "Continue"
        StatusCodes._codes[101] := "Switching Protocols"
        StatusCodes._codes[102] := "Processing"
        StatusCodes._codes[103] := "Early Hints"
        StatusCodes._codes[104] := "Upload Resumption Supported"
        StatusCodes._addRange(105, 199, "Unassigned")

        ; HTTP 2xx: Success
        StatusCodes._codes[200] := "OK"
        StatusCodes._codes[201] := "Created"
        StatusCodes._codes[202] := "Accepted"
        StatusCodes._codes[203] := "Non-Authoritative Information"
        StatusCodes._codes[204] := "No Content"
        StatusCodes._codes[205] := "Reset Content"
        StatusCodes._codes[206] := "Partial Content"
        StatusCodes._codes[207] := "Multi-Status"
        StatusCodes._codes[208] := "Already Reported"
        StatusCodes._addRange(209, 225, "Unassigned")
        StatusCodes._codes[226] := "IM Used"
        StatusCodes._addRange(227, 299, "Unassigned")

        ; HTTP 3xx: Redirection
        StatusCodes._codes[300] := "Multiple Choices"
        StatusCodes._codes[301] := "Moved Permanently"
        StatusCodes._codes[302] := "Found"
        StatusCodes._codes[303] := "See Other"
        StatusCodes._codes[304] := "Not Modified"
        StatusCodes._codes[305] := "Use Proxy"
        StatusCodes._codes[306] := "(Unused)"
        StatusCodes._codes[307] := "Temporary Redirect"
        StatusCodes._codes[308] := "Permanent Redirect"
        StatusCodes._addRange(309, 339, "Unassigned")

        ; HTTP 4xx: Client Errors
        StatusCodes._codes[400] := "Bad Request"
        StatusCodes._codes[401] := "Unauthorized"
        StatusCodes._codes[402] := "Payment Required"
        StatusCodes._codes[403] := "Forbidden"
        StatusCodes._codes[404] := "Not Found"
        StatusCodes._codes[405] := "Method Not Allowed"
        StatusCodes._codes[406] := "Not Acceptable"
        StatusCodes._codes[407] := "Proxy Authentication Required"
        StatusCodes._codes[408] := "Request Timeout"
        StatusCodes._codes[409] := "Conflict"
        StatusCodes._codes[410] := "Gone"
        StatusCodes._codes[411] := "Length Required"
        StatusCodes._codes[412] := "Precondition Failed"
        StatusCodes._codes[413] := "Content Too Large"
        StatusCodes._codes[414] := "URI Too Long"
        StatusCodes._codes[415] := "Unsupported Media Type"
        StatusCodes._codes[416] := "Range Not Satisfiable"
        StatusCodes._codes[417] := "Expectation Failed"
        StatusCodes._codes[418] := "(Unused)"
        StatusCodes._addRange(419, 420, "Unassigned")
        StatusCodes._codes[421] := "Misdirected Request"
        StatusCodes._codes[422] := "Unprocessable Content"
        StatusCodes._codes[423] := "Locked"
        StatusCodes._codes[424] := "Failed Dependency"
        StatusCodes._codes[425] := "Too Early"
        StatusCodes._codes[426] := "Upgrade Required"
        StatusCodes._codes[427] := "Unassigned"
        StatusCodes._codes[428] := "Precondition Required"
        StatusCodes._codes[429] := "Too Many Requests"
        StatusCodes._codes[430] := "Unassigned"
        StatusCodes._codes[431] := "Request Header Fields Too Large"
        StatusCodes._addRange(432, 450, "Unassigned")
        StatusCodes._codes[451] := "Unavailable For Legal Reasons"
        StatusCodes._addRange(452, 499, "Unassigned")

        ; HTTP 5xx: Server Errors
        StatusCodes._codes[500] := "Internal Server Error"
        StatusCodes._codes[501] := "Not Implemented"
        StatusCodes._codes[502] := "Bad Gateway"
        StatusCodes._codes[503] := "Service Unavailable"
        StatusCodes._codes[504] := "Gateway Timeout"
        StatusCodes._codes[505] := "HTTP Version Not Supported"
        StatusCodes._codes[506] := "Variant Also Negotiates"
        StatusCodes._codes[507] := "Insufficient Storage"
        StatusCodes._codes[508] := "Loop Detected"
        StatusCodes._codes[509] := "Unassigned"
        StatusCodes._codes[510] := "Not Extended"
        StatusCodes._codes[511] := "Network Authentication Required"
        StatusCodes._addRange(512, 599, "Unassigned")

        ; HTTP 6xx: Non-standard
        StatusCodes._addRange(600, 699, "Nonstandard")

        ; Internal / Custom Codes
        StatusCodes._codes[-1] := "Timeout or Unknown Network Error"
        StatusCodes._codes[-2] := "Failed to Send Request"
        StatusCodes._codes[-3] := "Manually Aborted"
        StatusCodes._codes[-4] := "Malformed URL"
        StatusCodes._codes[-5] := "Offline or Unreachable Host"
    }

    static _addRange(start, end, msg := "Unassigned") {
        Loop end - start + 1 {
            code := A_Index + start - 1
            StatusCodes._codes[code] := msg
        }
    }

    static Get(code) {
        code := code = 1223 ? 204 : code  ; Handle IE's 1223 as 204
        return StatusCodes._codes.Has(code) ? StatusCodes._codes[code] : "Unknown Status: " . code
    }

    static Exists(code) {
        return StatusCodes._codes.Has(code)
    }

    static All() {
        return StatusCodes._codes
    }
}
