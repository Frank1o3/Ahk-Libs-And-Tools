#Include JSON.ahk  ; Include your custom JSON parser
#Include HttpClient.ahk  ; Include the HttpClient class

class GitHubAPI {
    static token := ''

    __New(token := "") {
        this.baseURL := "https://api.github.com"
        this.client := HttpClient()  ; Use HttpClient for HTTP requests
        this.client.SetHeader("User-Agent", "AHK-GitHubAPI")
        this.token := token
        if (token) {
            this.client.SetHeader("Authorization", "token " token)  ; Add Authorization header if token is provided
            this.client.SetHeader("Accept", "application/vnd.github.v3+json")
        }
    }

    ; Generic method to make GET requests to GitHub API
    Request(endpoint) {
        url := this.baseURL endpoint
        response := this.client.Get(url)
        ; Parse JSON response
        return JSON.Parse(response)
    }

    Request2(endpoint) {
        url := this.baseURL endpoint
        response := this.client.Get(url)
        ; Parse JSON response
        return response
    }

    PostRequest(endpoint, data) {
        return this.client.Post(this.baseURL endpoint, data)
    }

    ; Get list of public repos from a user
    GetRepos(user) {
        return this.Request("/users/" user "/repos")
    }

    ; Search for a repo by name
    SearchRepos(query) {
        return this.Request2("/search/repositories?q=" query)
    }

    ; Download the zipball of a repo (no auth required for public repos)
    DownloadRepo(user, repo, fileName) {
        url := "https://github.com/" user "/" repo "/archive/refs/heads/main.zip"
        return this.client.Download(url, fileName ".zip")
    }
    
    ; List all files in the repository directory
    ListRepoFiles(user, repo, path := "") {
        response := this.Request("/repos/" user "/" repo "/contents/" path)
        ; Extract files from response
        files := []
        for item in response {
            if item["type"] == "file" {
                files.Push(item["name"])
            }
        }

        return files
    }

    ; List all directories in the repository directory
    ListRepoDirs(user, repo, path := "") {
        response := this.Request("/repos/" user "/" repo "/contents/" path)
        ; Extract directories from response
        dirs := []
        for item in response {
            if item["type"] == "dir" {
                dirs.Push(item["name"])
            }
        }

        return dirs
    }

    ; Loop through files in a specific directory
    ListFilesInDir(user, repo, dir) {
        endpoint := "/repos/" user "/" repo "/contents/" dir
        response := this.Request(endpoint)
        files := []
        result := JSON.Parse(response)
        for thing in result {
            if thing["type"] == "file" {
                files.Push(thing["name"])
            }
        }
        return files
    }

    ListAllFilesInDir(user, repo, dir := "") {
        allFiles := []

        ; List files in the current directory
        files := this.ListRepoFiles(user, repo, dir)
        for file in files {
            allFiles.Push(dir "/" files[file])
        }

        ; List directories in the current directory
        dirs := this.ListRepoDirs(user, repo, dir)
        for dirName in dirs {
            ; Recursively list all files in each subdirectory
            subDirFiles := this.ListAllFilesInDir(user, repo, dir "/" dirs[dirName])
            for file in subDirFiles {
                allFiles.Push(file)
            }
        }

        return allFiles
    }

    GetFile(user, repo, path, filename) {
        response := this.Request("/repos/" user "/" repo "/contents/" path)
        ; Extract files from response]
        data := []
        for item in response {
            if !InStr(item["name"], ".") {
                continue
            }
            if item["type"] == "file" and StrSplit(item["name"],".")[1] == filename {
                data := [item["name"], item["download_url"]]
            }
        }
        return data
    }

    GetFilesOfExtension(user, repo, path, extension) {
        response := this.Request("/repos/" user "/" repo "/contents/" path)
        ; Extract files from response]
        data := []
        for item in response {
            if !InStr(item["name"], ".") {
                continue
            }
            if item["type"] == "file" and StrSplit(item["name"],".")[2] == extension {
                data.Push([item["name"], item["download_url"]])
            }
        }
        return data
    }
    ; Get detailed information about a repository
    GetRepoDetails(user, repo) {
        return this.Request2("/repos/" user "/" repo)
    }

    ; Get all branches in a repository
    GetBranches(user, repo) {
        return this.Request("/repos/" user "/" repo "/branches")
    }

    ; Get recent commits from a repository
    GetCommits(user, repo) {
        return this.Request2("/repos/" user "/" repo "/commits")
    }

    ; Get the contents of a specific file in a repository
    GetFileContents(user, repo, filePath) {
        return this.Request2("/repos/" user "/" repo "/contents/" filePath)
    }

    ; Create a new issue in the repository
    CreateIssue(user, repo, title, body := "") {
        endpoint := "/repos/" user "/" repo "/issues"
        issueData := JSON.Stringify('{ "title": "' title '", "body": "' body '"}')
        return this.PostRequest(endpoint, issueData)
    }

    ; Star a repository
    StarRepo(user, repo) {
        return this.PostRequest("/user/starred/" user "/" repo, "")
    }

    ; Fork a repository
    ForkRepo(user, repo) {
        return this.PostRequest("/repos/" user "/" repo "/forks", "")
    }
}