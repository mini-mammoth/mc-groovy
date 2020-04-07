function downloadFile(url, filePath)
    local content = http.get(url).readAll()
    if not content then
        error("Could not connect to website: "..url)
    end
   
    if fs.exists(filePath) then
        error("File already exists.")
    else
        local file = fs.open(filePath, "w")
        file.write(content)
        file.close()
    end
end
 
local url, filePath = ...
downloadFile(url, filePath)