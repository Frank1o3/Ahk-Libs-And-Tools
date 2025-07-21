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

    static Stringify(value) {
        if IsObject(value) {
            if value is Array
                return JSON._stringifyArray(value)
            else
                return JSON._stringifyObject(value)
        } else if Type(value) = "String" {
            return JSON._escapeString(value)
        } else if Type(value) = "Integer" || Type(value) = "Float" {
            return value
        } else if value = true {
            return "true"
        } else if value = false {
            return "false"
        } else if value = "" {
            return "null"
        } else {
            throw Error("Unsupported type in JSON stringify: " Type(value))
        }
    }

    static _stringifyObject(obj) {
        items := []
        for key, val in obj
            items.Push(JSON._escapeString(key) ":" JSON.Stringify(val))
        return "{" . JSON.StrJoin(",", items*) . "}"
    }

    static _stringifyArray(arr) {
        items := []
        for index, val in arr
            items.Push(JSON.Stringify(val))
        return "[" . JSON.StrJoin(",", items*) . "]"
    }

    static _escapeString(str) {
        esc := Map('"', '\"', "\", "\\", "`n", "\n", "`r", "\r", "`t", "\t", "/", "\/")
        out := '"'
        Loop Parse, str
        {
            c := A_LoopField
            if esc.Has(c)
                out .= "\" . esc[c]
            else if Ord(c) < 32
                out .= Format("\u{:04X}", Ord(c))
            else
                out .= c
        }
        return out . '"'
    }

    static _parseValue(text, &pos) {
        JSON._skipWhitespace(text, &pos)
        ch := SubStr(text, pos, 1)
        if ch = '{'
            return JSON._parseObject(text, &pos)
        else if ch = '['
            return JSON._parseArray(text, &pos)
        else if ch = '"'
            return JSON._parseString(text, &pos)
        else if RegExMatch(SubStr(text, pos), "^-?\d")  ; check for number
            return JSON._parseNumber(text, &pos)
        else if SubStr(text, pos, 4) = "true"
            return JSON._parseLiteral(text, &pos)
        else if SubStr(text, pos, 5) = "false"
            return JSON._parseLiteral(text, &pos)
        else if SubStr(text, pos, 4) = "null"
            return JSON._parseLiteral(text, &pos)
        else
            throw Error("Invalid value at position " . pos)
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
            if SubStr(text, pos, 1) != '"'
                throw Error("Invalid object key at position " . pos)

            key := JSON._parseString(text, &pos)
            JSON._skipWhitespace(text, &pos)

            if SubStr(text, pos, 1) != ":"
                throw Error("Expected ':' after key at position " . pos)
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
        pos += 1  ; skip '['
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
                break
            } else if ch = "," {
                pos += 1
                continue
            } else {
                throw Error("Expected ',' or ']' in array at position " . pos)
            }
        }
        return arr
    }


    static _parseString(text, &pos) {
        pos += 1
        out := ""
        loop {
            if pos > StrLen(text)
                throw Error("Unterminated string at position " . pos)

            ch := SubStr(text, pos, 1)
            if ch = '"' {
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
                else if esc = '"' {
                    out .= '"'
                } else if esc = "\" {
                    out .= "\"
                } else if esc = "u" {
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
        pos += 1
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

    static StrJoin(separator, elements*) {
        count := elements.Length
        if count = 0
            return ""
        result := elements[1]
        for i, val in elements {
            if i = 1
                continue
            result .= separator . val
        }
        return result
    }
}
