class JSON {
    static Parse(jsonText) {
        ; Remove any unnecessary whitespace, new lines, or carriage returns
        jsonText := StrReplace(jsonText, "`r`n", "")
        jsonText := StrReplace(jsonText, "`t", "")

        ; Detect if it's an object or array
        if (SubStr(jsonText, 1, 1) = "{") {
            return this.ParseObject(jsonText)
        } else if (SubStr(jsonText, 1, 1) = "[") {
            return this.ParseArray(jsonText)
        }
        return "Invalid JSON format"
    }

    ; Parse JSON object (assumes object starts with '{' and ends with '}')
    static ParseObject(jsonText) {
        obj := Map()
        ; Remove leading and trailing braces
        jsonText := Trim(SubStr(jsonText, 2, -1))

        ; Loop to split key-value pairs
        while (jsonText != "") {
            ; Find the next key
            keyPos := InStr(jsonText, ":")
            key := Trim(SubStr(jsonText, 1, keyPos - 1), ' "')
            jsonText := Trim(SubStr(jsonText, keyPos + 1), " ")

            ; Determine the value type
            if (SubStr(jsonText, 1, 1) = "{") {
                valEnd := InStr(jsonText, "}") + 1
                val := this.ParseObject(SubStr(jsonText, 1, valEnd))
                jsonText := Trim(SubStr(jsonText, valEnd + 1), " ,")
            } else if (SubStr(jsonText, 1, 1) = "[") {
                valEnd := InStr(jsonText, "]") + 1
                val := this.ParseArray(SubStr(jsonText, 1, valEnd))
                jsonText := Trim(SubStr(jsonText, valEnd + 1), " ,")
            } else {
                ; Find the next comma or end of the object
                valPos := InStr(jsonText, ",")
                if !valPos
                    valPos := StrLen(jsonText) + 1
                val := Trim(SubStr(jsonText, 1, valPos - 1), ' "')
                jsonText := Trim(SubStr(jsonText, valPos + 1), " ")
            }

            ; Add the key-value pair to the object
            obj[key] := val

            ; Stop if no more pairs
            if (SubStr(jsonText, 1, 1) = "}") {
                break
            }
        }

        return obj
    }

    ; Parse JSON array (assumes array starts with '[' and ends with ']')
    static ParseArray(jsonText) {
        arr := []
        jsonText := Trim(SubStr(jsonText, 2, -1))  ; Remove leading and trailing square brackets

        ; Parse each element in the array
        while (jsonText != "") {
            if (SubStr(jsonText, 1, 1) = "{") {
                valEnd := InStr(jsonText, "}") + 1
                arr.Push(this.ParseObject(SubStr(jsonText, 1, valEnd)))
                jsonText := Trim(SubStr(jsonText, valEnd + 1), " ,")
            } else {
                ; Find the next comma or end of the array
                valPos := InStr(jsonText, ",")
                if !valPos
                    valPos := StrLen(jsonText) + 1
                val := Trim(SubStr(jsonText, 1, valPos - 1), ' "')
                arr.Push(val)
                jsonText := Trim(SubStr(jsonText, valPos + 1), " ,")
            }

            ; Stop if no more elements
            if (SubStr(jsonText, 1, 1) = "]") {
                break
            }
        }

        return arr
    }
    ; Converts a Map or Array back into a JSON string
    static Stringify(data) {
        if IsObject(data) {
            if Type(data) == "Map" {
                json := "{"
                for key, value in data {
                    json .= Format('"{}":{},', key, this.Stringify(value))
                }
                json := SubStr(json, 1, -1)  ; Remove last comma
                return json . "}"
            } else if Type(data) == "Array" {
                json := "["
                for _, value in data {
                    json .= Format('{},', this.Stringify(value))
                }
                json := SubStr(json, 1, -1)  ; Remove last comma
                return json . "]"
            }
        } else {
            return Format('{}', data)  ; Handle strings and numbers
        }
    }

}