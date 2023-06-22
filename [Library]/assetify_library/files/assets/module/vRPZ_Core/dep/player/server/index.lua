-----------------
--[[ Imports ]]--
-----------------

local imports = {
    type = type,
    pairs = pairs,
    tonumber = tonumber,
    isElement = isElement,
    getElementType = getElementType,
    getElementsByType = getElementsByType,
    getPlayerSerial = getPlayerSerial,
    assetify = assetify,
    dbify = dbify
}


----------------
--[[ Module ]]--
----------------

CPlayer.CBuffer = {}
CPlayer.CChannel = {}

CPlayer.fetch = function(cThread, serial)
    if not cThread then return false end
    local result = imports.dbify.module.serial.fetchAll({
        {dbify.module.serial.__TMP.structure[(dbify.module.serial.__TMP.structure.key)][1], serial}
    })
    return result
end

CPlayer.setData = function(cThread, serial, serialDatas)
    if not cThread then return false end
    local result = imports.dbify.module.serial.setData(serial, serialDatas)
    if result and CPlayer.CBuffer[serial] then
        for i = 1, #serialDatas, 1 do
            local j = serialDatas[i]
            CPlayer.CBuffer[serial][(j[1])] = j[2]
        end
    end
    return result
end

CPlayer.getData = function(cThread, serial, serialDatas)
    if not cThread then return false end
    local result = imports.dbify.module.serial.getData(serial, serialDatas)
    if result and CPlayer.CBuffer[serial] then
        for i = 1, #serialDatas, 1 do
            local j = serialDatas[i]
            CPlayer.CBuffer[serial][j] = result[j]
        end
    end
    return result
end

CPlayer.getSerial = function(player)
    if not player or not imports.isElement(player) or (imports.getElementType(player) ~= "player") then return false end
    return imports.getPlayerSerial(player)
end

CPlayer.getPlayer = function(serial)
    if not serial then return false end
    local serverPlayers = imports.getElementsByType("player")
    for i = 1, #serverPlayers, 1 do
        local j = serverPlayers[i]
        if CPlayer.isInitialized(j) then
            if CPlayer.getSerial(j) == serial then
                return j
            end
        end
    end
    return false
end

CPlayer.getInventoryID = function(player)
    local characterID = CPlayer.getCharacterID(player)
    return (characterID and CCharacter.CBuffer[characterID] and CCharacter.CBuffer[characterID].inventory) or false
end

CPlayer.setLogged = function(player, state)
    if not player or not imports.isElement(player) or (imports.getElementType(player) ~= "player") then return false end
    if state then
        if CPlayer.CLogged[player] then return false end
        CPlayer.CLogged[player] = true
        for i, j in imports.pairs(CPlayer.CLogged) do
            imports.assetify.network:emit("Player:onLogin", true, false, i, player)
            if i ~= player then
                imports.assetify.network:emit("Player:onLogin", true, false, player, i)
            end
        end
        imports.assetify.network:emit("Player:onLogin", false, player)
    else
        if not CPlayer.CLogged[player] then return false end
        for i, j in imports.pairs(CPlayer.CLogged) do
            imports.assetify.network:emit("Player:onLogout", true, false, i, player)
        end
        CPlayer.CLogged[player] = nil
        imports.assetify.network:emit("Player:onLogout", false, player)
    end
    return true
end

CPlayer.setChannel = function(player, channelIndex)
    channelIndex = imports.tonumber(channelIndex)
    if not CPlayer.isInitialized(player) or not channelIndex or not FRAMEWORK_CONFIGS["Game"]["Chatbox"]["Chats"][channelIndex] then return false end
    imports.assetify.network:emit("Client:onUpdateChannel", false, true, player, channelIndex)
    CPlayer.CChannel[player] = channelIndex
    return true 
end

CPlayer.getChannel = function(player)
    if not CPlayer.isInitialized(player) then return false end
    return CPlayer.CChannel[player] or false
end

CPlayer.setParty = function(player, partyData)
    --TODO: this is completely bugged
    --[[
    if imports.type(player) == "table" then
        for i = 1, #player do
            local j = player[i]
            CPlayer.CParty[j] = partyData
            imports.assetify.network:emit("Client:onUpdateParty", false, true, j, partyData)
        end
        return true
    else
        if not CPlayer.isInitialized(player) then return false end
        for i, #partyData.members, 1 do
            local j = partyData.members[i]
            imports.assetify.network:emit("Client:onUpdateParty", false, true, j, partyData)
        end
        CPlayer.CParty[player] = partyData
        return true
    end
    ]]
end