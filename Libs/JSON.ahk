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

    static _parseValue(text, &pos) {
        JSON._skipWhitespace(text, &pos)
        ch := SubStr(text, pos, 1)

        if ch = "{" {
            return JSON._parseObject(text, &pos)
        } else if ch = "[" {
            return JSON._parseArray(text, &pos)
        } else if ch = "\`" " {
            return JSON._parseString(text, &pos)
        } else if (SubStr(text, pos, 4) == "true"
            || SubStr(text, pos, 5) = "false"
            || SubStr(text, pos, 4) = "null") {
            return JSON._parseLiteral(text, &pos)
        } else {
            return JSON._parseNumber(text, &pos)
        }
    }


    static _parseObject(text, &pos) {
        obj := Map()
        pos += 1
        JSON._skipWhitespace(text, &pos)
        if SubStr(text, pos, 1) = "}" {
            pos += 1
            return obj
        }

        loop {
            JSON._skipWhitespace(text, &pos)
            if SubStr(text, pos, 1) != "\`" " {
                throw Error("Invalid object key at position " . pos)
            }

            key := JSON._parseString(text, &pos)
            JSON._skipWhitespace(text, &pos)

            if SubStr(text, pos, 1) != ":" {
                throw Error("Expected ':' after key at position " . pos)
            }
            pos += 1

            value := JSON._parseValue(text, &pos)
            obj[key] := value
            JSON._skipWhitespace(text, &pos)

            ch := SubStr(text, pos, 1)
            if ch = "}" {
                pos += 1
                return obj
            } else if ch != "," {
                throw Error("Expected ',' or '}' at position " . pos)
            }
            pos += 1
        }
    }

    static _parseArray(text, &pos) {
        arr := []
        pos += 1
        JSON._skipWhitespace(text, &pos)
        if SubStr(text, pos, 1) = "]" {
            pos += 1
            return arr
        }

        loop {
            value := JSON._parseValue(text, &pos)
            arr.Push(value)
            JSON._skipWhitespace(text, &pos)

            ch := SubStr(text, pos, 1)
            if ch = "]" {
                pos += 1
                return arr
            } else if ch != "," {
                throw Error("Expected ',' or ']' at position " . pos)
            }
            pos += 1
        }
    }

    static _parseString(text, &pos) {
        pos += 1  ; Skip initial quote
        out := ""

        loop {
            if pos > StrLen(text)
                throw Error("Unterminated string at position " . pos)

            ch := SubStr(text, pos, 1)
            if ch = "\`" " {
                break
            } else if ch = "\" {
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
                else if esc = "\`" "
                    out .= "\`" "
                else if esc = "\`" "
                    out .= "\"
                else if esc = "u" {
                    hex := SubStr(text, pos + 1, 4)
                    if !RegExMatch(hex, "^[0-9a-fA-F]{4}$")
                        throw Error("Invalid Unicode escape: \u" . hex)
                    out .= Chr("0x" . hex)
                    pos += 4
                } else {
                    throw Error("Unknown escape: \" . esc)
                }
            } else {
                out .= ch
            }
            pos += 1
        }

        pos += 1  ; Skip closing quote
        return out
    }

    static _parseNumber(text, &pos) {
        RegExMatch(SubStr(text, pos), "^-?\d+(\.\d+)?([eE][+-]?\d+)?", &match)
        if !match[0]
            throw Error("Invalid number at position " . pos)

        pos += StrLen(match[0])
        return InStr(match[0], ".") || InStr(match[0], "e") || InStr(match[0], "E")
            ? match[0] + 0.0
            : match[0] + 0
    }

    static _parseLiteral(text, &pos) {
        if SubStr(text, pos, 4) = "true" {
            pos += 4
            return true
        } else if SubStr(text, pos, 5) = "false" {
            pos += 5
            return false
        } else if SubStr(text, pos, 4) = "null" {
            pos += 4
            return ""
        } else {
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