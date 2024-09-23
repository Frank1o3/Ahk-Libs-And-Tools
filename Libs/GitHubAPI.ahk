#Include JSON.ahk

class GitHubAPI {
    __New(token := "") {
        this.baseURL := "https://api.github.com"
        this.token := token  ; Token is optional, use for higher rate limits if available
    }

    ; Generic method to make GET requests
    Request(endpoint) {
        headers := Map("User-Agent", "AHK-GitHubAPI")
        if this.token {
            headers["Authorization"] := "token " this.token  ; Only include token if provided
        }
        return this.HttpGet(this.baseURL endpoint, headers)
    }

    ; Get list of public repos from a user
    GetRepos(user) {
        return this.Request("/users/" user "/repos")
    }

    ; Search for a repo by name
    SearchRepos(query) {
        return this.Request("/search/repositories?q=" query)
    }

    ; Download the zipball of a repo (no auth required for public repos)
    DownloadRepo(user, repo, fileName) {
        url := "https://github.com/" user "/" repo "/archive/refs/heads/main.zip"
        A_Clipboard := url
        Download(url, fileName ".zip")
    }

    ; List all files in the root of the repository and get their raw URLs
    ListRepoFiles(user, repo, path := "") {
        endpoint := "/repos/" user "/" repo "/contents/" path
        response := this.Request(endpoint)

        if InStr(response, "Error") {
            return response  ; If there's an error, return it
        }

        ; Parse the JSON response
        dirs := []
        result := JSON.Parse(response)
        for thing in result {
            ; if InStr(thing["name"], ".") and StrSplit(thing["name"], ".")[2] == "ahk" {
            ;     if thing["download_url"] != "null" {
            ;         files.Push(["download_url"])
            ;     }
            ; }
            if thing["type"] == "dir" {
                if thing["name"] == "Libs" {
                    dirs.Push(thing["name"])
                }
            }
        }

        return dirs
    }

    ; HTTP GET function using ComObj
    HttpGet(url, headers) {
        req := ComObject("MSXML2.XMLHTTP")
        req.open("GET", url, false)

        ; Add headers
        for header, value in headers {
            req.setRequestHeader(header, value)
        }

        req.send()
        if req.status = 200 {
            return req.responseText
        } else {
            return "Error: " req.status " - " req.statusText
        }
    }
}

; Example Usage (without token)
github := GitHubAPI()  ; No token needed for free API access

; List all files in a repo and get their raw URLs
files := github.ListRepoFiles("Frank1o3", "Python-Proxy")

for names in files {
    MsgBox names
}