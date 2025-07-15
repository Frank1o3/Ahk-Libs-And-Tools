class JSON {
    static Load(jsonText) {
        try {
            pos := 1
            result := JSON._parseValue(jsonText, &pos)
            JSON._skipWhitespace(jsonText, &pos)
            return (pos > StrLen(jsonText)) ? result : false
        } catch {
            return false
        }
    }

    ; ────────────────────────────────────────────────

    static _parseValue(text, &pos) {
        JSON._skipWhitespace(text, &pos)
        ch := SubStr(text, pos, 1)
        if ch = "{"      ; object
            return JSON._parseObject(text, &pos)
        else if ch = "[" ; array
            return JSON._parseArray(text, &pos)
        else if ch = "" ""
            return JSON._parseString(text, &pos)
        else if RegExMatch(SubStr(text, pos), "^(true|false|null)", &m)
            return JSON._parseLiteral(m[0], &pos)
        else
            return JSON._parseNumber(text, &pos)
    }

    static _parseObject(text, &pos) {
        obj := Map()
        pos += 1
        JSON._skipWhitespace(text, &pos)
        if SubStr(text, pos, 1) = "}"
            return (pos += 1, obj)

        loop {
            JSON._skipWhitespace(text, &pos)
            if SubStr(text, pos, 1) != "" ""
                throw Error("Invalid object key")
            key := JSON._parseString(text, &pos)
            JSON._skipWhitespace(text, &pos)
            if SubStr(text, pos, 1) != ":"
                throw Error("Expected ':' after key")
            pos += 1
            value := JSON._parseValue(text, &pos)
            obj[key] := value
            JSON._skipWhitespace(text, &pos)
            ch := SubStr(text, pos, 1)
            if ch = "}"
                return (pos += 1, obj)
            else if ch != ","
                throw Error("Expected ',' or '}'")
            pos += 1
        }
    }

    static _parseArray(text, &pos) {
        arr := []
        pos += 1
        JSON._skipWhitespace(text, &pos)
        if SubStr(text, pos, 1) = "]"
            return (pos += 1, arr)

        loop {
            value := JSON._parseValue(text, &pos)
            arr.Push(value)
            JSON._skipWhitespace(text, &pos)
            ch := SubStr(text, pos, 1)
            if ch = "]"
                return (pos += 1, arr)
            else if ch != ","
                throw Error("Expected ',' or ']'")
            pos += 1
        }
    }

    static _parseString(text, &pos) {
        pos += 1
        out := ""
        loop {
            if pos > StrLen(text)
                throw Error("Unterminated string")
            ch := SubStr(text, pos, 1)
            if ch = "" ""
                break
            else if ch = "\"
            {
                pos += 1
                esc := SubStr(text, pos, 1)
                if esc = "n"
                    out .= "`n"
                else if esc = "r"
                    out .= "`r"
                else if esc = "t"
                    out .= "`t"
                else if esc = "b"
                    out .= Chr(8)
                else if esc = "f"
                    out .= Chr(12)
                else if esc = "\"
                    out .= "\"
                else if esc = "" ""
                    out .= "" ""
                else if esc = "u" {
                    hex := SubStr(text, pos + 1, 4)
                    if !RegExMatch(hex, "^[0-9a-fA-F]{4}$")
                        throw Error("Invalid Unicode escape: \u" . hex)
                    out .= Chr("0x" . hex)
                    pos += 4
                } else
                    throw Error("Unknown escape: \" . esc)
            }
            else
                out .= ch
            pos += 1
        }
        pos += 1
        return out
    }

    static _parseNumber(text, &pos) {
        match := ""
        RegExMatch(SubStr(text, pos), "^-?\d+(\.\d+)?([eE][+-]?\d+)?", &match)
        if !match[0]
            throw Error("Invalid number at " . pos)
        pos += StrLen(match[0])
        return InStr(match[0], ".") || InStr(match[0], "e") || InStr(match[0], "E")
            ? match[0] + 0.0
            : match[0] + 0
    }

    static _parseLiteral(text, &pos) {
        remaining := SubStr(text, pos)
        if InStr(remaining, "true") = 1 {
            pos += 4
            return true
        }
        else if InStr(remaining, "false") = 1 {
            pos += 5
            return false
        }
        else if InStr(remaining, "null") = 1 {
            pos += 4
            return ""
        }
        else {
            throw Error("Invalid literal at position " . pos)
        }
    }


    static _skipWhitespace(text, &pos) {
        while pos <= StrLen(text) {
            ch := SubStr(text, pos, 1)
            if ch != " " && ch != "`n" && ch != "`r" && ch != "`t"
                break
            pos += 1
        }
    }
}
