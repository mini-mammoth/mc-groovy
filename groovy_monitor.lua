os.loadAPI("nbs") -- load the API
 
local function endsWith(input, endPattern)
    if input == nil or (not type(string) == string) then
        return false
    else
        local length = string.len(input)
        if endPattern == nil or (not type(endPattern) == string) then
            return false
        else
            local patternLength = string.len(endPattern)
            local inputEnd = string.sub(input, 0 - string.len(endPattern))
         
            if inputEnd == endPattern then
                return true
            else
                return false
            end
        end
    end
end
 
local function getSongNames(dirPath)
    if fs.isDir(dirPath) then
        files = fs.list(dirPath)
        songFiles = {}
       
        local i = 1
        for key, value in pairs(files) do
            if endsWith(value, ".nbs") then
                songFiles[i] = value
                i = i + 1
            end  
        end
       
        return songFiles
    else
        return nil
    end
end
 
local function printSongLabel(monitor, text, maxLength, x, y)
    text = string.sub(text, 1, maxLength)
   
    for j = 0, 2, 1 do
        monitor.setCursorPos(x, y + j)
        for i = 1, maxLength + 2, 1 do
            monitor.write(" ")
        end
    end
   
    local shiftX = math.floor((maxLength - string.len(text)) / 2)
   
    monitor.setCursorPos(x + 1 + shiftX, y + 1)
    monitor.write(text)
end
 
local function getSelectedIdx()
    if touchedX == nil or touchedY == nil then
        return nil
    end
 
    local sizeX, sizeY = monitor.getSize()
    local songsPerPage = songsPerRow * songsPerColumn
    
    local shiftX = math.floor((sizeX - songsPerRow * (maxFileNameLength + 4)) / 2)
    local shiftY = math.floor(((sizeY - 5) - songsPerColumn * 5) / 2) + 5
 
    local col = nil
    local row = nil
 
    local xStart = nil
    for k = 1, songsPerRow, 1 do
        xStart = 2 + shiftX + (k-1) * (maxFileNameLength + 4)
        if touchedX >= xStart and touchedX <= xStart + maxFileNameLength + 2 then
            col = k
        end
    end
 
    local yStart = nil
    for k = 1, songsPerColumn, 1 do
        yStart = 2 + shiftY + (k - 1) * 5
        if touchedY >= yStart and touchedY <= yStart + 2 then
            row = k
        end
    end
 
    if col and row then
        local selectedIdx = (pageNumber - 1) * songsPerPage + (col - 1) * songsPerColumn + row
        return selectedIdx
    end
    return nil
end

local function getSelectedPager()
    local sizeX, sizeY = monitor.getSize()

    if touchedY >= 2 and touchedY <= 4 then
        if touchedX >= sizeX - 7 and touchedX <= sizeX - 5 then
            return "prev_page"
        elseif touchedX >= sizeX - 4 and touchedX <= sizeX - 2 then 
            return "next_page"
        end
    end
end

local function getSelectedShuffle()
    local xPageInfoStart = sizeX - 9 - string.len(pageCount) - string.len(pageNumber)
    local xShuffleButtonStart = xPageInfoStart - 4 - string.len(shuffleText)

    if touchedY >= 2 and touchedY <= 4 then
        if touchedX >= xShuffleButtonStart and touchedX <= xShuffleButtonStart + string.len(shuffleText) + 2 then
            return true
        end
    end
end
 
local function updateSongs(monitor, songFiles, maxFileNameLength, pageNumber, selectedIdx, songsPerRow, songsPerColumn)
    local sizeX, sizeY = monitor.getSize()
    local songsPerPage = songsPerRow * songsPerColumn
    local firstSongIdx = 1 + (pageNumber - 1) * songsPerPage
   
    local x = 1
    local y = 1
    local shiftX = math.floor((sizeX - songsPerRow * (maxFileNameLength + 4)) / 2)
    local shiftY = math.floor(((sizeY - 5) - songsPerColumn * 5) / 2) + 5
   
    local defaultBgColor = colors.lightGray
    local selectedBgColor = colors.lime
   
    local k = 1
    for i = firstSongIdx, firstSongIdx + songsPerPage - 1, 1 do
        if i == selectedIdx then
            monitor.setBackgroundColor(selectedBgColor)
        else
            monitor.setBackgroundColor(defaultBgColor)
        end
       
        x = 2 + shiftX + math.floor((k - 1) / songsPerColumn) * (maxFileNameLength + 4)
        y = 2 + shiftY + ((k - 1) % songsPerColumn) * 5
                     
        if songFiles[i] then
            printSongLabel(monitor, songFiles[i], maxFileNameLength, x, y)
        end
       
        k = k + 1
    end
   
    monitor.setBackgroundColor(colors.black)
end

local function updateHeader(monitor, pageNumber, pageCount)
    local xPageInfoStart = sizeX - 9 - string.len(pageCount) - string.len(pageNumber)
    local xShuffleButtonStart = xPageInfoStart - 4 - string.len(shuffleText)

    -- draw shuffle button
    if hasSelectedShuffle then
        monitor.setBackgroundColor(colors.lime)
    else
        monitor.setBackgroundColor(colors.lightGray)
    end

    for i = 2, 4, 1 do
        monitor.setCursorPos(xShuffleButtonStart, i)
        monitor.write(string.rep(" ", string.len(shuffleText) + 2))
    end

    monitor.setCursorPos(xShuffleButtonStart + 1, 3)
    monitor.write(shuffleText)

    -- draw pagers
    monitor.setBackgroundColor(colors.lightGray)

    for i = 2, 4, 1 do
        monitor.setCursorPos(sizeX - 7, i)
        monitor.write("   ")
        monitor.setCursorPos(sizeX - 3, i)
        monitor.write("   ")
    end
    
    monitor.setCursorPos(sizeX - 6, 3)
    monitor.write("<")
    monitor.setCursorPos(sizeX - 2, 3)
    monitor.write(">")

    -- draw pageInfo
    monitor.setBackgroundColor(colors.black)
    monitor.setCursorPos(xPageInfoStart, 3)
    monitor.write(""..pageNumber.."/"..pageCount)
end

local function updateMonitor()
    monitor.clear()
    updateHeader(monitor, pageNumber, pageCount)
    updateSongs(monitor, songFiles, maxFileNameLength, pageNumber, selectedIdx, songsPerRow, songsPerColumn)
end

local function receiveTouchTask()
    local shouldRun = true
    while shouldRun do
        event, par1, touchedX, touchedY = os.pullEvent("monitor_touch")

        selectedPager = getSelectedPager()

        if selectedPager then
            if selectedPager == "prev_page" and pageNumber > 1 then
                pageNumber = pageNumber - 1
                updateMonitor()
            elseif selectedPager == "next_page" and pageNumber < pageCount then
                pageNumber = pageNumber + 1
                updateMonitor()
            end
        else
            shouldRun = false
        end
    end
end

local function playSongTask()
    local selectedSong = songFiles[selectedIdx]
    nbs.play("music/"..selectedSong, modemSide, volume, false)
end

local function playShuffle()
    while true do
        selectedIdx = math.random(1, numberOfSongs)
        
        updateMonitor()
        playSongTask()
        updateMonitor()
    end
end
 
modemSide, monitorSide = ...
 
rednet.open(modemSide)
volume = 3

monitor = peripheral.wrap(monitorSide)
monitor.setTextScale(1)
monitor.clear()

shuffleText = "Shuffle"

maxFileNameLength = 16
sizeX, sizeY = monitor.getSize()
songsPerRow = math.floor(sizeX / (maxFileNameLength + 4))
songsPerColumn = math.floor((sizeY - 5) / 5)
songsPerPage = songsPerRow * songsPerColumn

selectedIdx = nil
selectedPager = nil
hasSelectedShuffle = nil

songFiles = getSongNames("music")

pageNumber = 1
pageCount = nil
numberOfSongs = table.getn(songFiles)

if numberOfSongs % songsPerPage == 0 then
    pageCount = numberOfSongs / songsPerPage
else
    pageCount = math.ceil(numberOfSongs / songsPerPage)
end

updateMonitor()
 
while true do
    event, par1, touchedX, touchedY = os.pullEvent("monitor_touch")

    selectedIdx = getSelectedIdx()
    selectedPager = getSelectedPager()
    hasSelectedShuffle = getSelectedShuffle()

    if selectedIdx then
        if songFiles[selectedIdx] then
            updateMonitor()
            parallel.waitForAny(receiveTouchTask, playSongTask)
            selectedIdx = nil
            updateMonitor()
        end
    elseif selectedPager then
        if selectedPager == "prev_page" and pageNumber > 1 then
            pageNumber = pageNumber - 1
            updateMonitor()
        elseif selectedPager == "next_page" and pageNumber < pageCount then
            pageNumber = pageNumber + 1
            updateMonitor()
        end
    elseif hasSelectedShuffle then
        parallel.waitForAny(receiveTouchTask, playShuffle)
        selectedIdx = nil
        hasSelectedShuffle = nil
        updateMonitor()
    end
end