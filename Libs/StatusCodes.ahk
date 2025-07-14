; Status codes
statusCodes := Map()

add(start, end, mmap, msg := "Unassigned") {
    Loop end - start + 1 {
        code := A_Index + start - 1
        mmap[code] := msg
    }
}

statusCodes[100] := "Continue"
statusCodes[101] := "Switching Protocols"
statusCodes[102] := "Processing"
statusCodes[103] := "Early Hints"
statusCodes[104] := "Upload Resumption Supported"
add(105, 199, statusCodes)
statusCodes[200] := "Ok"
statusCodes[201] := "Created"
statusCodes[202] := "Accepted"
statusCodes[203] := "Non-Authoritative Information"
statusCodes[204] := "No Content"
statusCodes[205] := "Reset Content"
statusCodes[206] := "Partial Content"
statusCodes[207] := "Multi-Status"
statusCodes[208] := "Already Reported"
add(209, 225, statusCodes)
statusCodes[226] := "IM Used"
add(227, 299, statusCodes)
statusCodes[300] := "Multiple Choices"
statusCodes[301] := "Moved Permanently"
statusCodes[302] := "Found"
statusCodes[303] := "See Other"
statusCodes[304] := "Not Modified"
statusCodes[305] := "Use Proxy"
statusCodes[306] := "(Unused)"
statusCodes[307] := "Temporary Redirect"
statusCodes[308] := "Permanent Redirect"
add(309, 339, statusCodes)
statusCodes[400] := "Bad Request"
statusCodes[401] := "Unauthorized"
statusCodes[402] := "Payment Required"
statusCodes[403] := "Forbidden"
statusCodes[404] := "Not Found"
statusCodes[405] := "Method Not Allowed"
statusCodes[406] := "Not Acceptable"
statusCodes[407] := "Proxy Authentication Required"
statusCodes[408] := "Request Timeout"
statusCodes[409] := "Conflict"
statusCodes[410] := "Gone"
statusCodes[411] := "Length Required"
statusCodes[412] := "Precondition Failed"
statusCodes[413] := "Content Too Large"
statusCodes[414] := "URI Too Long"
statusCodes[415] := "Unsupported Media Type"
statusCodes[416] := "Range Not Satisfiable"
statusCodes[417] := "Expectation Failed"
statusCodes[418] := "(Unused)"
add(419, 420, statusCodes)
statusCodes[421] := "Misdirected Request"
statusCodes[422] := "Unprocessable Content"
statusCodes[423] := "Locked"
statusCodes[424] := "Failed Dependency"
statusCodes[425] := "Too Early"
statusCodes[426] := "Upgrade Required"
statusCodes[427] := "Unassigned"
statusCodes[428] := "Precondition Required"
statusCodes[429] := "Too Many Requests"
statusCodes[430] := "Unassigned"
statusCodes[431] := "Request Header Fields Too Large"
add(432, 450, statusCodes)
statusCodes[451] := "Unavailable For Legal Reasons"
add(452, 499, statusCodes)
statusCodes[500] := "Internal Server Error"
statusCodes[501] := "Not Implemented"
statusCodes[502] := "Bad Gateway"
statusCodes[503] := "Service Unavailable"
statusCodes[504] := "Gateway Timeout"
statusCodes[505] := "HTTP Version Not Supported"
statusCodes[506] := "Variant Also Negotiates"
statusCodes[507] := "Insufficient Storage"
statusCodes[508] := "Loop Detected"
statusCodes[509] := "Unassigned"
statusCodes[510] := "Not Extended"
statusCodes[511] := "Network Authentication Required"
add(512, 599, statusCodes)
add(600, 699, statusCodes, "Nonstandard")