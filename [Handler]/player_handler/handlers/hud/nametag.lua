----------------------------------------------------------------
--[[ Resource: Player Handler
     Script: handlers: hud: nametag.lua
     Author: vStudio
     Developer(s): Mario, Tron, Aviril, Аниса
     DOC: 31/01/2022
     Desc: Nametag HUD Handler ]]--
----------------------------------------------------------------


-----------------
--[[ Imports ]]--
-----------------

local imports = {
    pairs = pairs,
    camera = getCamera(),
    collectgarbage = collectgarbage,
    tocolor = tocolor,
    unpackColor = unpackColor,
    isElement = isElement,
    destroyElement = destroyElement,
    getElementPosition = getElementPosition,
    getPedBonePosition = getPedBonePosition,
    getScreenFromWorldPosition = getScreenFromWorldPosition,
    getDistanceBetweenPoints3D = getDistanceBetweenPoints3D,
    interpolateBetween = interpolateBetween,
    beautify = beautify,
    assetify = assetify
}


CGame.execOnModuleLoad(function()
    -------------------
    --[[ Variables ]]--
    -------------------

    local nametagUI = {
        buffer = {},
        padding = 5, iconSize = 20,
        clipRange = {4, 6},
        font = CGame.createFont(1, 15, true),
        fontColor = imports.tocolor(imports.unpackColor({150, 150, 150, 250}))
    }

    local roleIcon = imports.assetify.getAssetDep("module", "vRPZ_HUD", "texture", "role:developer")
    
    nametagUI.createBuffer = function(player, isReload)
        if not CPlayer.isInitialized(player) then return false end
        if not isReload then
            if nametagUI.buffer[player] then return false end
        else
            nametagUI.destroyBuffer(player)
        end
        local width, height = nametagUI.updateBuffer(player, true)
        nametagUI.buffer[player] = {
            width = width, height = height,
            rt = imports.beautify.native.createRenderTarget(width, height, true),
            shader = imports.beautify.native.createShader("fx/nametag.fx")
        }
        imports.beautify.native.setShaderValue(nametagUI.buffer[player].shader, "baseTexture", nametagUI.buffer[player].rt)
        nametagUI.updateBuffer(player)
        return true
    end
    
    nametagUI.destroyBuffer = function(player)
        if not nametagUI.buffer[player] then return false end
        if imports.isElement(nametagUI.buffer[player].rt) then
            imports.destroyElement(nametagUI.buffer[player].rt)
        end
        if imports.isElement(nametagUI.buffer[player].shader) then
            imports.destroyElement(nametagUI.buffer[player].shader)
        end
        nametagUI.buffer[player] = nil
        imports.collectgarbage()
        return true
    end

    nametagUI.updateBuffer = function(player, isFetchSize)
        if not CPlayer.isInitialized(player) or (not isFetchSize and not nametagUI.buffer[player]) then return false end
        local playerID, playerName, playerGroup = CPlayer.getCharacterID(player), CPlayer.getName(player), CCharacter.getGroup(player)
        local playerLevel, playerRank = CCharacter.getLevel(player), CCharacter.getRank(player)
        local nameTag, rankTag = "["..playerID.."]  ━  "..((playerGroup and ""..playerGroup.." |  ") or "")..playerName, playerRank.." - "..playerLevel
        local nameTag_width, rankTag_height = imports.beautify.native.getTextWidth(nameTag, 1, nametagUI.font.instance), imports.beautify.native.getTextWidth(rankTag, 1, nametagUI.font.instance)
        local rtWidth, rtHeight = imports.math.max(nameTag_width, rankTag_height) + nametagUI.iconSize + (nametagUI.padding*4), (nametagUI.iconSize*2) + (nametagUI.padding*8)
        if isFetchSize then
            return rtWidth, rtHeight
        elseif (nametagUI.buffer[player].width ~= rtWidth) or (nametagUI.buffer[player].height ~= rtHeight) then
            return nametagUI.createBuffer(player, true)
        end
        imports.beautify.native.setRenderTarget(nametagUI.buffer[player].rt, true)
        local nameTag_startX, nameTag_startY = nametagUI.buffer[player].width*0.5 + (nametagUI.iconSize*0.5), 0
        local rankTag_startY = nameTag_startY + nametagUI.iconSize + (nametagUI.padding*0.5)
        imports.beautify.native.drawText(nameTag, nameTag_startX, nameTag_startY, nameTag_startX, nameTag_startY, nametagUI.fontColor, 1, nametagUI.font.instance, "center", "top")
        imports.beautify.native.drawText(rankTag, nameTag_startX, rankTag_startY, nameTag_startX, rankTag_startY, nametagUI.fontColor, 1, nametagUI.font.instance, "center", "top")
        imports.beautify.native.drawImage(nameTag_startX - (nameTag_width*0.5) - nametagUI.iconSize - nametagUI.padding, nameTag_startY, nametagUI.iconSize, nametagUI.iconSize, roleIcon, 0, 0, 0, -1)
        imports.beautify.native.drawImage(nameTag_startX - (rankTag_height*0.5) - nametagUI.iconSize - nametagUI.padding, rankTag_startY, nametagUI.iconSize, nametagUI.iconSize, roleIcon, 0, 0, 0, -1)
        imports.beautify.native.setRenderTarget()
        return true
    end


    -------------------------------
    --[[ Function: Renders HUD ]]--
    -------------------------------

    imports.beautify.render.create(function()
        if not CPlayer.isInitialized(localPlayer) then return false end

        local cameraX, cameraY, cameraZ = imports.getElementPosition(imports.camera)
        for i, j in imports.pairs(CPlayer.CLogged) do
            if nametagUI.buffer[i] then
                local boneX, boneY, boneZ = imports.getPedBonePosition(i, 7)
                boneZ = boneZ + 0.25
                local cameraDistance = imports.getDistanceBetweenPoints3D(cameraX, cameraY, cameraZ, boneX, boneY, boneZ)
                local nearClipDistance, farClipDistance = ((cameraDistance <= nametagUI.clipRange[2]) and (cameraDistance/nametagUI.clipRange[2])) or 1, ((cameraDistance >= nametagUI.clipRange[1]) and ((cameraDistance/nametagUI.clipRange[1]) - 1)) or 1
                local tagAlpha = nearClipDistance*farClipDistance
                local isAlphaChanged = nametagUI.buffer[i].alpha ~= tagAlpha
                nametagUI.buffer[i].alpha = (isAlphaChanged and imports.interpolateBetween(nametagUI.buffer[i].alpha or 0, 0, 0, tagAlpha, 0, 0, 0.25, "InQuad")) or nametagUI.buffer[i].alpha
                if nametagUI.buffer[i].alpha > 0 then
                    local screenX, screenY = imports.getScreenFromWorldPosition(boneX, boneY, boneZ)
                    if screenX and screenY then
                        if isAlphaChanged then imports.beautify.native.setShaderValue(nametagUI.buffer[i].shader, "baseColor", 1.25, 1.25, 1.25, nametagUI.buffer[i].alpha) end
                        imports.beautify.native.drawImage(screenX - (nametagUI.buffer[i].width*0.5), screenY, nametagUI.buffer[i].width, nametagUI.buffer[i].height, nametagUI.buffer[i].shader, 0, 0, 0, -1)
                    end
                end
            end
        end
    end)

    imports.assetify.network:fetch("Player:onLogin", true):on(function(source) nametagUI.createBuffer(source) end)
    imports.assetify.network:fetch("Player:onLogout", true):on(function(source) nametagUI.destroyBuffer(source) end)
end)