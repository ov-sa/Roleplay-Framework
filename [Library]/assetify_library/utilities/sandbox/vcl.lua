----------------------------------------------------------------
--[[ Resource: Assetify Library
     Script: utilities: sandbox: vcl.lua
     Author: vStudio
     Developer(s): Aviril, Tron, Mario, Аниса
     DOC: 19/10/2021
     Desc: VCL Utilities ]]--
----------------------------------------------------------------


-----------------
--[[ Imports ]]--
-----------------

local imports = {
    type = type,
    tonumber = tonumber,
    outputDebugString = outputDebugString
}


--------------------
--[[ Class: vcl ]]--
--------------------

local vcl = class:create("vcl")

function vcl.private.isVoid(rw)
    return (not rw or (imports.type(rw) ~= "string") or not string.match(rw, "%w") and true) or false
end

function vcl.private.fetch(rw, index)
    return string.sub(rw, index, index)
end

function vcl.private.fetchLine(rw, index)
    return #string.split(string.sub(rw, 0, index), "\n")
end

function vcl.private.parse(buffer, index, isChild)
    index = index or 1
    local parsedDatas = {
        isType = (not isChild and "object") or false,
        isParsed = (not isChild and true) or false, isErrored = "Failed to parse vcl. [Line: %s] [Reason: %s]",
        ref = (isChild and index) or false, index = "", pointer = {}, value = ""
    }
    while(index <= #buffer) do
        local char = vcl.private.fetch(buffer, index)
        if (parsedDatas.isType ~= "object") or not vcl.private.isVoid(char) then
            if parsedDatas.isType == "object" then
                parsedDatas.index = parsedDatas.index..char
                local __char = vcl.private.fetch(buffer, index + 1)
                if __char and (__char == ":") then
                    local value, __index = vcl.private.parse(buffer, index + 2, true)
                    if value then
                        parsedDatas.pointer[(parsedDatas.index)], index = value, __index
                        parsedDatas.index = ""
                    else
                        parsedDatas.isChildErrored = true
                        break
                    end
                end
            else
                local isSkipAppend = false
                if not parsedDatas.isType or (parsedDatas.isType == "object") then
                    --TODO: CHECK IF ITS OVJECT???
                    --[[
                    if (char == "\"") or (char == "\'") then
                        if not parsedDatas.isType then
                            isSkipAppend, parsedDatas.isType = true, "object"
                        else
                            parsedDatas.isParsed = true
                        end
                    end
                    ]]
                end
                if not parsedDatas.isType or (parsedDatas.isType == "string") then
                    if (not parsedDatas.isTypeChar and ((char == "\"") or (char == "\'"))) or (parsedDatas.isTypeChar and (parsedDatas.isTypeChar == char)) then
                        if not parsedDatas.isType then isSkipAppend, parsedDatas.isType, parsedDatas.isTypeChar = true, "string", char
                        else parsedDatas.isParsed = true end
                    end
                end
                if not parsedDatas.isType or (parsedDatas.isType == "number") then
                    if imports.tonumber(char) then
                        parsedDatas.isType = "number"
                    elseif not vcl.private.isVoid(parsedDatas.value) then
                        --Match if its decimal or space
                        --if char == "."
                        parsedDatas.isParsed = true
                    end
                end
                if parsedDatas.isType and not isSkipAppend and not parsedDatas.isParsed then parsedDatas.value = parsedDatas.value..char end
            end
        elseif (parsedDatas.isType == "object") and not vcl.private.isVoid(parsedDatas.index) then
            parsedDatas.isParsed = false
            break
        end
        index = index + 1
        if isChild and parsedDatas.isParsed then break end
    end

    parsedDatas.isParsed = (not parsedDatas.isChildErrored and parsedDatas.isParsed) or parsedDatas.isParsed
    if not parsedDatas.isParsed then
        if not parsedDatas.isChildErrored then
            parsedDatas.isErrored = string.format(
                parsedDatas.isErrored,
                vcl.private.fetchLine(buffer, parsedDatas.ref or index),
                ((parsedDatas.isType == "string") and "Unterminated string") or
                "Invalid declaration"
            )
            imports.outputDebugString(parsedDatas.isErrored)
        end
        return parsedDatas.isParsed, false, parsedDatas.isErrored
    elseif (parsedDatas.isType == "object") then return parsedDatas.pointer, index
    else return ((parsedDatas.isType == "number" and imports.tonumber(parsedDatas.value)) or parsedDatas.value), index end
end

vcl.public.parse = function(buffer)
    return vcl.private.parse(buffer)
end

--TESTS

setTimer(function()

    local test2 = [[
        index1: 12.34
        index2: "value2"
        index3: "value3"
        index4: "value4"
        index5: "value5"
        index6: "value6"
        index7: "value7"
    ]]
    local result = vcl.public.parse(test2)
    iprint(result)

end, 1000, 1)