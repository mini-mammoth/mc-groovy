local function split (inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end
 
local modemSide, speakerSide = ...
 
local listenId = nil
 
rednet.open(modemSide)
local speaker = peripheral.wrap(speakerSide)
 
while true do
    senderId, message, distance, protocol = rednet.receive()
   
    params = split(message, ",")
    cmd = params[1]
   
    if listenId == senderId and cmd == "groovy_play" then
        i = 2
        while params[i] do
            speaker.playNote(params[i], tonumber(params[i+1]), tonumber(params[i+2]))
            i = i + 3
        end
    end
 
    if cmd == "groovy_start" then
        listenId = senderId
    elseif cmd == "groovy_stop" then
        listenId = nil
    end
end