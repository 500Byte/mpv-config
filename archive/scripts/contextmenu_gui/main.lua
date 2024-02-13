--[[
*****************************************************************
** Context menu for mpv.                                       **
** Origin_ Avi Halachmi https://github.com/avih                **
** Extension_ Thomas Carmichael https://gitlab.com/carmanaught **
*****************************************************************
mpv的tcl图形菜单的核心脚本
建议在 input.conf 中绑定右键以支持唤起菜单
MOUSE_BTN2   script-message-to contextmenu_gui contextmenu_tk
--]]

local langcodes = require "contextmenu_gui_lang"
local function mpdebug(x) mp.msg.info(x) end
local propNative = mp.get_property_native

-- Set options
local options = require "mp.options"
local opt = {
    filter01B = "", filter01C = "", filter01D = "", filter01G = false,
    filter02B = "", filter02C = "", filter02D = "", filter02G = false,
    filter03B = "", filter03C = "", filter03D = "", filter03G = false,
    filter04B = "", filter04C = "", filter04D = "", filter04G = false,
    filter05B = "", filter05C = "", filter05D = "", filter05G = false,
    filter06B = "", filter06C = "", filter06D = "", filter06G = false,
    filter07B = "", filter07C = "", filter07D = "", filter07G = false,
    filter08B = "", filter08C = "", filter08D = "", filter08G = false,
    filter09B = "", filter09C = "", filter09D = "", filter09G = false,
    filter10B = "", filter10C = "", filter10D = "", filter10G = false,

    shader01B = "", shader01C = "", shader01D = "", shader01G = false,
    shader02B = "", shader02C = "", shader02D = "", shader02G = false,
    shader03B = "", shader03C = "", shader03D = "", shader03G = false,
    shader04B = "", shader04C = "", shader04D = "", shader04G = false,
    shader05B = "", shader05C = "", shader05D = "", shader05G = false,
    shader06B = "", shader06C = "", shader06D = "", shader06G = false,
    shader07B = "", shader07C = "", shader07D = "", shader07G = false,
    shader08B = "", shader08C = "", shader08D = "", shader08G = false,
    shader09B = "", shader09C = "", shader09D = "", shader09G = false,
    shader10B = "", shader10C = "", shader10D = "", shader10G = false,
}
options.read_options(opt)

-- Set some constant values
local SEP = "separator"
local CASCADE = "cascade"
local COMMAND = "command"
local CHECK = "checkbutton"
local RADIO = "radiobutton"
local AB = "ab-button"

local function round(num, numDecimalPlaces)
    return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

-- 版本（Edition）子菜单
local function inspectEdition()
    local editionDisable = false
    if propNative("edition-list/count") == nil or propNative("edition-list/count") < 1 then editionDisable = true end
    return editionDisable
end

local function checkEdition(editionNum)
    local editionState, editionCur = false, propNative("current-edition")
    if (editionNum == editionCur) then editionState = true end
    return editionState
end

local function editionMenu()
    local editionCount = propNative("edition-list/count")
    local editionMenuVal = {}

    if editionCount ~= nil and not (editionCount == 0) then
        for editionNum=0, (editionCount - 1), 1 do
            local editionTitle = propNative("edition-list/" .. editionNum .. "/title")
            if not (editionTitle) then editionTitle = "Edition " .. string.format("%02.f", editionNum + 1) end

            local editionCommand = "set edition " .. editionNum
            table.insert(editionMenuVal, {RADIO, editionTitle, "", editionCommand, function() return checkEdition(editionNum) end, false})
        end
    end

    return editionMenuVal
end

-- 章节子菜单
local function inspectChapter()
    local chapterDisable = false
    if propNative("chapter-list/count") == nil or propNative("chapter-list/count") < 1 then chapterDisable = true end
    return chapterDisable
end

local function checkChapter(chapterNum)
    local chapterState, chapterCur = false, propNative("chapter")
    if (chapterNum == chapterCur) then chapterState = true end
    return chapterState
end

local function chapterMenu()
    local chapterCount = propNative("chapter-list/count")
    local chapterMenuVal = {}

    chapterMenuVal = {
        {COMMAND, "上一章节", "PGDWN", "add chapter -1", "", false},
        {COMMAND, "下一章节", "PGUP", "add chapter 1", "", false},
    }
    if chapterCount ~= nil and not (chapterCount == 0) then
        for chapterNum=0, (chapterCount - 1), 1 do
            local chapterTitle = propNative("chapter-list/" .. chapterNum .. "/title")
            local chapterTime = propNative("chapter-list/" .. chapterNum .. "/time")
            if chapterTitle == "" then chapterTitle = "章节 " .. string.format("%02.f", chapterNum + 1) end
            if chapterTime < 0 then chapterTime = 0
            else chapterTime = math.floor(chapterTime) end
            chapterTime = string.format("[%02d:%02d:%02d]", math.floor(chapterTime/60/60), math.floor(chapterTime/60)%60, chapterTime%60)
            chapterTitle = chapterTime ..'   '.. chapterTitle

            local chapterCommand = "set chapter " .. chapterNum
            if (chapterNum == 0) then table.insert(chapterMenuVal, {SEP}) end
            table.insert(chapterMenuVal, {RADIO, chapterTitle, "", chapterCommand, function() return checkChapter(chapterNum) end, false})
        end
    end

    return chapterMenuVal
end

-- Track type count function to iterate through the track-list and get the number of
-- tracks of the type specified. Types are:  video / audio / sub. This actually
-- returns a table of track numbers of the given type so that the track-list/N/
-- properties can be obtained.

local function trackCount(checkType)
    local tracksCount = propNative("track-list/count")
    local trackCountVal = {}

    if not (tracksCount < 1) then
        for i = 0, (tracksCount - 1), 1 do
            local trackType = propNative("track-list/" .. i .. "/type")
            if (trackType == checkType) then table.insert(trackCountVal, i) end
        end
    end

    return trackCountVal
end

-- Track check function, to check if a track is selected. This isn't specific to a set
-- track type and can be used for the video/audio/sub tracks, since they're all part
-- of the track-list.

local function checkTrack(trackNum)
    local trackState, trackCur = false, propNative("track-list/" .. trackNum .. "/selected")
    if (trackCur == true) then trackState = true end
    return trackState
end

-- Convert ISO 639-1/639-2 codes to be full length language names. The full length names
-- are obtained by using the property accessor with the iso639_1/_2 tables stored in
-- the contextmenu_gui_lang.lua file (require "langcodes" above).
local function getLang(trackLang)
    trackLang = string.upper(trackLang)
    if (string.len(trackLang) == 2) and trackLang == "SC" then trackLang = "sc"  --修复中文字幕常见语言标识的误识别
    elseif (string.len(trackLang) == 2) then trackLang = langcodes.iso639_1(trackLang)
    elseif (string.len(trackLang) == 3) then trackLang = langcodes.iso639_2(trackLang) end
    return trackLang
end

local function noneCheck(checkType)
    local checkVal, trackID = false, propNative(checkType)
    if (type(trackID) == "boolean") then
        if (trackID == false) then checkVal = true end
    end
    return checkVal
end

local function is_empty(input)
    if input == nil or input == "" then
        return true
    end
end

----- string
local function replace(str, what, with)
    if is_empty(str) then return "" end
    if is_empty(what) then return str end
    if with == nil then with = "" end
    what = string.gsub(what, "[%(%)%.%+%-%*%?%[%]%^%$%%]", "%%%1")
    with = string.gsub(with, "[%%]", "%%%%")
    return string.gsub(str, what, with)
end

local function esc_for_title(string)
    string = string:gsub('^[%._%-%s]*', '')
            :gsub('%.%w+$', '')
    return string
end

-- 视频轨子菜单
local function inspectVidTrack()
    local vidTrackDisable, vidTracks = false, trackCount("video")
    if (#vidTracks < 1) then vidTrackDisable = true end
    return vidTrackDisable
end

local function vidTrackMenu()
    local vidTrackMenuVal, vidTrackCount = {}, trackCount("video")

    if not (#vidTrackCount == 0) then
        for i = 1, #vidTrackCount, 1 do
            local vidTrackNum = vidTrackCount[i]
            local vidTrackID = propNative("track-list/" .. vidTrackNum .. "/id")
            local vidTrackTitle = propNative("track-list/" .. vidTrackNum .. "/title")
            local vidTrackCodec = propNative("track-list/" .. vidTrackNum .. "/codec"):upper()
            local vidTrackImage = propNative("track-list/" .. vidTrackNum .. "/image")
            local vidTrackwh = propNative("track-list/" .. vidTrackNum .. "/demux-w") .. "x" .. propNative("track-list/" .. vidTrackNum .. "/demux-h") 
            local vidTrackFps = string.format("%.3f", propNative("track-list/" .. vidTrackNum .. "/demux-fps"))
            local vidTrackDefault = propNative("track-list/" .. vidTrackNum .. "/default")
            local vidTrackForced = propNative("track-list/" .. vidTrackNum .. "/forced")
            local vidTrackExternal = propNative("track-list/" .. vidTrackNum .. "/external")
            local filename = propNative("filename/no-ext")

            if vidTrackTitle then vidTrackTitle = replace(vidTrackTitle, filename, "") end
            if vidTrackExternal then vidTrackTitle = esc_for_title(vidTrackTitle) end
            if vidTrackCodec:match("MPEG2") then vidTrackCodec = "MPEG2"
            elseif vidTrackCodec:match("DVVIDEO") then vidTrackCodec = "DV"
            end

            if vidTrackTitle and not vidTrackImage then vidTrackTitle = vidTrackTitle .. "[" .. vidTrackCodec .. "]" .. "," .. vidTrackwh .. "," .. vidTrackFps .. " FPS"
            elseif vidTrackTitle then vidTrackTitle = vidTrackTitle .. "[" .. vidTrackCodec .. "]" .. "," .. vidTrackwh
            elseif vidTrackImage then vidTrackTitle = "[" .. vidTrackCodec .. "]" .. "," .. vidTrackwh
            elseif vidTrackFps then vidTrackTitle = "[" .. vidTrackCodec .. "]" .. "," .. vidTrackwh .. "," .. vidTrackFps .. " FPS"
            else vidTrackTitle = "视频轨 " .. i end
            if vidTrackForced then  vidTrackTitle = vidTrackTitle .. "," .. "Forced" end
            if vidTrackDefault then  vidTrackTitle = vidTrackTitle .. "," .. "Default" end
            if vidTrackExternal then  vidTrackTitle = vidTrackTitle .. "," .. "External" end

            local vidTrackCommand = "set vid " .. vidTrackID
            table.insert(vidTrackMenuVal, {RADIO, vidTrackTitle, "", vidTrackCommand, function() return checkTrack(vidTrackNum) end, false})
        end
    else
        table.insert(vidTrackMenuVal, {RADIO, "无视频轨", "", "", "", true})
    end

    return vidTrackMenuVal
end

-- 音频轨子菜单
local function inspectAudTrack()
    local audTrackDisable, audTracks = false, trackCount("audio")
    if (#audTracks < 1) then audTrackDisable = true end
    return audTrackDisable
end

local function audTrackMenu()
    local audTrackMenuVal, audTrackCount = {}, trackCount("audio")

    audTrackMenuVal = {
         {COMMAND, "重载当前音频轨（限外挂）", "", "audio-reload", "", false},
         {COMMAND, "移除当前音频轨（限外挂）", "", "audio-remove", "", false},
    }
    if not (#audTrackCount == 0) then
        for i = 1, (#audTrackCount), 1 do
            local audTrackNum = audTrackCount[i]
            local audTrackID = propNative("track-list/" .. audTrackNum .. "/id")
            local audTrackTitle = propNative("track-list/" .. audTrackNum .. "/title")
            local audTrackLang = propNative("track-list/" .. audTrackNum .. "/lang")
            local audTrackCodec = propNative("track-list/" .. audTrackNum .. "/codec"):upper()
            -- local audTrackBitrate = propNative("track-list/" .. audTrackNum .. "/demux-bitrate")/1000  -- 此属性似乎不可用
            local audTrackSamplerate = string.format("%.1f", propNative("track-list/" .. audTrackNum .. "/demux-samplerate")/1000)
            local audTrackChannels = propNative("track-list/" .. audTrackNum .. "/demux-channel-count")
            local audTrackDefault = propNative("track-list/" .. audTrackNum .. "/default")
            local audTrackForced = propNative("track-list/" .. audTrackNum .. "/forced")
            local audTrackExternal = propNative("track-list/" .. audTrackNum .. "/external")
            local filename = propNative("filename/no-ext")
            -- Convert ISO 639-1/2 codes
            if not (audTrackLang == nil) then audTrackLang = getLang(audTrackLang) and getLang(audTrackLang) or audTrackLang end
            if audTrackTitle then audTrackTitle = replace(audTrackTitle, filename, "") end
            if audTrackExternal then audTrackTitle = esc_for_title(audTrackTitle) end
            if audTrackCodec:match("PCM") then audTrackCodec = "PCM" end

            if audTrackTitle and audTrackLang then audTrackTitle = audTrackTitle .. "," .. audTrackLang .. "[" .. audTrackCodec .. "]" .. "," .. audTrackChannels .. " ch" .. "," .. audTrackSamplerate .. " kHz"
            elseif audTrackTitle then audTrackTitle = audTrackTitle .. "[" .. audTrackCodec .. "]" .. "," .. audTrackChannels .. " ch" .. "," .. audTrackSamplerate .. " kHz"
            elseif audTrackLang then audTrackTitle = audTrackLang .. "[" .. audTrackCodec .. "]" .. "," .. audTrackChannels .. " ch" .. "," .. audTrackSamplerate .. " kHz"
            elseif audTrackChannels then audTrackTitle = "[" .. audTrackCodec .. "]" .. "," .. audTrackChannels .. " ch" .. "," .. audTrackSamplerate .. " kHz"
            else audTrackTitle = "音频轨 " .. i end
            if audTrackForced then  audTrackTitle = audTrackTitle .. "," .. "Forced" end
            if audTrackDefault then  audTrackTitle = audTrackTitle .. "," .. "Default" end
            if audTrackExternal then  audTrackTitle = audTrackTitle .. "," .. "External" end

            local audTrackCommand = "set aid " .. audTrackID
            if (i == 1) then
                table.insert(audTrackMenuVal, {RADIO, "不渲染音频", "", "set aid 0", function() return noneCheck("aid") end, false})
                table.insert(audTrackMenuVal, {SEP})
            end
            table.insert(audTrackMenuVal, {RADIO, audTrackTitle, "", audTrackCommand, function() return checkTrack(audTrackNum) end, false})
        end
    end

    return audTrackMenuVal
end

-- 字幕轨子菜单
local function inspectSubTrack()
    local subTrackDisable, subTracks = false, trackCount("sub")
    if (#subTracks < 1) then subTrackDisable = true end
    return subTrackDisable
end

-- Subtitle label
local function subVisLabel() return propNative("sub-visibility") and "隐藏" or "取消隐藏" end

local function subTrackMenu()
    local subTrackMenuVal, subTrackCount = {}, trackCount("sub")

    subTrackMenuVal = {
        {COMMAND, "重载当前字幕轨（限外挂）", "", "sub-reload", "", false},
        {COMMAND, "移除当前字幕轨（限外挂）", "", "sub-remove", "", false},
        {CHECK, function() return subVisLabel() end, "v", "cycle sub-visibility;show-text 字幕可见性:${sub-visibility} ", function() return not propNative("sub-visibility") end, false},
    }
    if not (#subTrackCount == 0) then
        for i = 1, (#subTrackCount), 1 do
            local subTrackNum = subTrackCount[i]
            local subTrackID = propNative("track-list/" .. subTrackNum .. "/id")
            local subTrackTitle = propNative("track-list/" .. subTrackNum .. "/title")
            local subTrackLang = propNative("track-list/" .. subTrackNum .. "/lang")
            local subTrackCodec = propNative("track-list/" .. subTrackNum .. "/codec"):upper()
            local subTrackDefault = propNative("track-list/" .. subTrackNum .. "/default")
            local subTrackForced = propNative("track-list/" .. subTrackNum .. "/forced")
            local subTrackExternal = propNative("track-list/" .. subTrackNum .. "/external")
            local filename = propNative("filename/no-ext")
            -- Convert ISO 639-1/2 codes
            if not (subTrackLang == nil) then subTrackLang = getLang(subTrackLang) and getLang(subTrackLang) or subTrackLang end
            if subTrackTitle then subTrackTitle = replace(subTrackTitle, filename, "") end end
            if subTrackExternal then subTrackTitle = esc_for_title(subTrackTitle) end
            if subTrackCodec:match("PGS") then subTrackCodec = "PGS"
            elseif subTrackCodec:match("SUBRIP") then subTrackCodec = "SRT"
            elseif subTrackCodec:match("VTT") then subTrackCodec = "VTT"
            elseif subTrackCodec:match("DVB_SUB") then subTrackCodec = "DVB"
            elseif subTrackCodec:match("DVD_SUB") then subTrackCodec = "VOB"
            end

            if subTrackTitle and subTrackLang then subTrackTitle = subTrackTitle .. "," .. subTrackLang .. "[" .. subTrackCodec .. "]" 
            elseif subTrackTitle then subTrackTitle = subTrackTitle .. "[" .. subTrackCodec .. "]"
            elseif subTrackLang then subTrackTitle = subTrackLang .. "[" .. subTrackCodec .. "]"
            elseif subTrackCodec then subTrackTitle = "[" .. subTrackCodec .. "]"
            else subTrackTitle = "字幕轨 " .. i end
            if subTrackForced then  subTrackTitle = subTrackTitle .. "," .. "Forced" end
            if subTrackDefault then  subTrackTitle = subTrackTitle .. "," .. "Default" end
            if subTrackExternal then  subTrackTitle = subTrackTitle .. "," .. "External" end

            local subTrackCommand = "set sid " .. subTrackID
            if (i == 1) then
                table.insert(subTrackMenuVal, {RADIO, "不渲染字幕", "", "set sid 0", function() return noneCheck("sid") end, false})
                table.insert(subTrackMenuVal, {SEP})
            end
            table.insert(subTrackMenuVal, {RADIO, subTrackTitle, "", subTrackCommand, function() return checkTrack(subTrackNum) end, false})
        end
    end

    return subTrackMenuVal
end

local function stateABLoop()
    local abLoopState = ""
    local abLoopA, abLoopB = propNative("ab-loop-a"), propNative("ab-loop-b")

    if (abLoopA == "no") and (abLoopB == "no") then abLoopState =  "off"
    elseif not (abLoopA == "no") and (abLoopB == "no") then abLoopState = "a"
    elseif not (abLoopA == "no") and not (abLoopB == "no") then abLoopState = "b" end

    return abLoopState
end

local function stateFileLoop()
    local loopState, loopval = false, propNative("loop-file")
    if (loopval == "inf") then loopState = true end
    return loopState
end

-- 长宽比子菜单
local function stateRatio(ratioVal)
    -- Ratios and Decimal equivalents
    -- Ratios:    "4:3" "16:10"  "16:9" "1.85:1" "2.35:1"
    -- Decimal: "1.333" "1.600" "1.778"  "1.850"  "2.350"
    local ratioState = false
    local ratioCur = round(propNative("video-aspect-override"), 3)

    if (ratioVal == "4:3") and (ratioCur == round(4/3, 3)) then ratioState = true
    elseif (ratioVal == "16:10") and (ratioCur == round(16/10, 3)) then ratioState = true
    elseif (ratioVal == "16:9") and (ratioCur == round(16/9, 3)) then ratioState = true
    elseif (ratioVal == "1.85:1") and (ratioCur == round(1.85/1, 3)) then ratioState = true
    elseif (ratioVal == "2.35:1") and (ratioCur == round(2.35/1, 3)) then ratioState = true
    end

    return ratioState
end

-- 解码模式子菜单
local function stateHwdec(hwdecVal)

    local hwdecState = false
    local hwdecCur = propNative("hwdec-current")

    if (hwdecVal == "no") and (hwdecCur == "no" or hwdecCur == "") then hwdecState = true
    elseif (hwdecVal == "dxva2") and (hwdecCur == "dxva2") then hwdecState = true
    elseif (hwdecVal == "dxva2-copy") and (hwdecCur == "dxva2-copy") then hwdecState = true
    elseif (hwdecVal == "d3d11va") and (hwdecCur == "d3d11va") then hwdecState = true
    elseif (hwdecVal == "d3d11va-copy") and (hwdecCur == "d3d11va-copy") then hwdecState = true
    elseif (hwdecVal == "qsv") and (hwdecCur == "qsv") then hwdecState = true
    elseif (hwdecVal == "qsv-copy") and (hwdecCur == "qsv-copy") then hwdecState = true
    elseif (hwdecVal == "cuda") and (hwdecCur == "cuda") then hwdecState = true
    elseif (hwdecVal == "cuda-copy") and (hwdecCur == "cuda-copy") then hwdecState = true
    elseif (hwdecVal == "nvdec") and (hwdecCur == "nvdec") then hwdecState = true
    elseif (hwdecVal == "nvdec-copy") and (hwdecCur == "nvdec-copy") then hwdecState = true

    end

    return hwdecState
end

-- Video Rotate radio item check
local function stateRotate(rotateVal)
    local rotateState, rotateCur = false, propNative("video-rotate")
    if (rotateVal == rotateCur) then rotateState = true end
    return rotateState
end

-- Video Alignment radio item checks
local function stateAlign(alignAxis, alignPos)
    local alignState = false
    local alignValY, alignValX = propNative("video-align-y"), propNative("video-align-x")

    -- This seems a bit unwieldy. Should look at simplifying if possible.
    if (alignAxis == "y") then
        if (alignPos == alignValY) then alignState = true end
    elseif (alignAxis == "x") then
        if (alignPos == alignValX) then alignState = true end
    end

    return alignState
end

-- Deinterlacing radio item check
local function stateDeInt(deIntVal)
    local deIntState, deIntCur = false, propNative("deinterlace")
    if (deIntVal == deIntCur) then deIntState = true end
    return deIntState
end

local function stateFlip(flipVal)
    local vfState, vfVals = false, propNative("vf")
    for i, vf in pairs(vfVals) do
        if (vf["name"] == flipVal) then vfState = true end
    end
    return vfState
end

-- Mute label
local function muteLabel() return propNative("mute") and "取消静音" or "静音" end

-- 输出声道子菜单
local audio_channels = { {"自动（安全）", "auto-safe"}, {"自动", "auto"}, {"无", "empty"}, {"单声道", "mono"}, {"立体声", "stereo"}, {"2.1", "2.1"}, {"5.1（标准）", "5.1"}, {"7.1（标准）", "7.1"} }

-- Create audio key/value pairs to check against the native property
-- e.g. audio_pair["2.1"] = "2.1", etc.
local audio_pair = {}
for i = 1, #audio_channels do
    audio_pair[audio_channels[i][2]] = audio_channels[i][2]
end

-- Audio channel layout radio item check
local function stateAudChannel(audVal)
    local audState, audLayout = false, propNative("audio-channels")

    audState = (audio_pair[audVal] == audLayout) and true or false
    return audState
end

-- Audio channel layout menu creation
local function audLayoutMenu()
    local audLayoutMenuVal = {}

    for i = 1, #audio_channels do
        if (i == 3) then table.insert(audLayoutMenuVal, {SEP}) end
        table.insert(audLayoutMenuVal, {RADIO, audio_channels[i][1], "", "set audio-channels \"" .. audio_channels[i][2] .. "\"", function() return stateAudChannel(audio_channels[i][2]) end, false})
    end

    return audLayoutMenuVal
end

-- OSD时间轴检查
local function stateOsdLevel(osdLevelVal)
    local osdLevelState, osdLevelCur = false, propNative("osd-level")
    osdLevelState = (osdLevelVal == osdLevelCur) and true or false
    return osdLevelState
end

-- Subtitle Alignment radio item check
local function stateSubAlign(subAlignVal)
    local subAlignState, subAlignCur = false, propNative("sub-align-y")
    subAlignState = (subAlignVal == subAlignCur) and true or false
    return subAlignState
end

-- Subtitle Position radio item check
local function stateSubPos(subPosVal)
    local subPosState, subPosCur = false, propNative("image-subs-video-resolution")
    subPosState = (subPosVal == subPosCur) and true or false
    return subPosState
end

local function movePlaylist(direction)
    local playlistPos, newPos = propNative("playlist-pos"), 0
    -- We'll remove 1 here to "0 index" the value since we're using it with playlist-pos
    local playlistCount = propNative("playlist-count") - 1

    if (direction == "up") then
        newPos = playlistPos - 1
        if not (playlistPos == 0) then
            mp.commandv("plalist-move", playlistPos, newPos)
        else mp.osd_message("已排最前") end
    elseif (direction == "down") then
        if not (playlistPos == playlistCount) then
            newPos = playlistPos + 2
            mp.commandv("plalist-move", playlistPos, newPos)
        else mp.osd_message("已排最后") end
    end
end

local function statePlayLoop()
    local loopState, loopVal = false, propNative("loop-playlist")
    if not (tostring(loopVal) == "false") then loopState = true end
    return loopState
end

local function stateOnTop(onTopVal)
    local onTopState, onTopCur = false, propNative("ontop")
    onTopState = (onTopVal == onTopCur) and true or false
    return onTopState
end

--[[ ************ 菜单内容 ************ ]]--

local menuList = {}

-- Format for object tables
-- {Item Type, Label, Accelerator, Command, Item State, Item Disable, Repost Menu (Optional)}

-- Item Type - The type of item, e.g. CASCADE, COMMAND, CHECK, RADIO, etc
-- Label - The label for the item
-- Accelerator - The text shortcut/accelerator for the item
-- Command - This is the command to run when the item is clicked
-- Item State - The state of the item (selected/unselected). A/B Repeat is a special case.
-- Item Disable - Whether to disable
-- Repost Menu (Optional) - This is only for use with the Tk menu and is optional (only needed
-- if the intent is for the menu item to cause the menu to repost)

-- Item Type, Label and Accelerator should all evaluate to strings as a result of the return
-- from a function or be strings themselves.
-- Command can be a function or string, this will be handled after a click.
-- Item State and Item Disable should normally be boolean but can be a string for A/B Repeat.
-- Repost Menu (Optional) should only be boolean and is only needed if the value is true.

-- The 'file_loaded_menu' value is used when the table is passed to the menu-engine to handle the
-- behavior of the 'playback_only' (cancellable) argument.

-- This is to be shown when nothing is open yet and is a small subset of the greater menu that
-- will be overwritten when the full menu is created.

menuList = {
    file_loaded_menu = false,

-- Primary menu (when no file is loaded)
    context_menu = {
        {CASCADE, "Load", "open_menu", "", "", false},
        {SEP},
        {CASCADE, "Output", "output_menu", "", "", false},
        {SEP},
        {CASCADE, "Other", "etc_menu", "", "", false},
        {SEP},
        {CASCADE, "About", "about_menu", "", "", false},
        {COMMAND, "Quit mpv", "q", "quit", "", false},
    },

-- Secondary menu — Load
    open_menu = {
        {COMMAND, "[External Script] File", "CTRL+o", "script-message-to open_dialog import_files", "", false},
        {COMMAND, "[External Script] URL", "CTRL+O", "script-message-to open_dialog import_url", "", false},
        {COMMAND, "[External Script] Internal File Browser", "Tab", "script-message-to file_browser browse-files;script-message-to file_browser dynamic/reload;show-text ''", "", false},
        {COMMAND, "[External Script] Load Last Played File", "CTRL+l", "script-binding simplehistory/history-load-last", "", false},
        {COMMAND, "[External Script] Load Last Played File and Position", "CTRL+L", "script-binding simplehistory/history-resume", "", false},
        {COMMAND, "[External Script] Toggle Incognito History", "ALT+l", "script-binding simplehistory/history-incognito-mode", "", false},
        {COMMAND, "[External Script] Open History Menu", "`", "script-binding simplehistory/open-list;show-text ''", "", false},
        {COMMAND, "[External Script] Open Bookmark Menu", "N", "script-binding simplebookmark/open-list;show-text ''", "", false},
        {COMMAND, "[External Script] Open Clipboard Menu", "ALT+w", "script-binding smartcopypaste_II/open-list;show-text ''", "", false},
    },

-- Secondary menu — Output
    output_menu = {
        {CHECK, "Window Topmost", "ALT+t", "cycle ontop", function() return propNative("ontop") end, false},
        {CHECK, "Window Border", "CTRL+B", "cycle border", function() return propNative("border") end, false},
        {CHECK, "Fullscreen", "ENTER", "cycle fullscreen", function() return propNative("fullscreen") end, false},
    },

-- Secondary menu — Other
    etc_menu = {
        {COMMAND, "[Internal Script] Console", "~", "script-binding console/enable", "", false},
        {COMMAND, "[External Script] OSD Advanced Audio Device Menu", "F6", "script-message-to adevice_list toggle-adevice-browser;show-text ''", "", false},
        {COMMAND, "[External Script] Update Script Shaders", "M", "script-message manager-update-all;show-text Update Script Shaders", "", false},
    },

-- Secondary menu — About
    about_menu = {
        {COMMAND, mp.get_property("mpv-version"), "", "", "", false},
        {COMMAND, "ffmpeg " .. mp.get_property("ffmpeg-version"), "", "", "", false},
        {COMMAND, "libass " .. mp.get_property("libass-version"), "", "", "", false},
    },
}


-- If mpv enters a stopped state, change the change the menu back to the "no file loaded" menu
-- so that it will still popup.
menuListBase = menuList

-- DO NOT create the "playing" menu tables until AFTER the file has loaded as we're unable to
-- dynamically create some menus if it tries to build the table before the file is loaded.
-- A prime example is the chapter-list or track-list values, which are unavailable until
-- the file has been loaded.

local function playmenuList()
    menuList = {
        file_loaded_menu = true,

-- Primary menu (after file is loaded)
    context_menu = {
        {CASCADE, "Load", "open_menu", "", "", false},
        {SEP},
        {CASCADE, "File", "file_menu", "", "", false},
        {CASCADE, "Navigation", "navi_menu", "", "", false},
        {CASCADE, "Output", "output_menu", "", "", false},
        {CASCADE, "Video", "video_menu", "", "", false},
        {CASCADE, "Audio", "audio_menu", "", "", false},
        {CASCADE, "Subtitle", "subtitle_menu", "", "", false},
        {SEP},
        {CASCADE, "Filter", "filter_menu", "", "", false},
        {CASCADE, "Shader", "shader_menu", "", "", false},
        {CASCADE, "Profile", "profile_menu", "", "", false},
        {CASCADE, "Other", "etc_menu", "", "", false},
        {CASCADE, "Tools", "tool_menu", "", "", false},
        {SEP},
        {CASCADE, "About", "about_menu", "", "", false},
        {COMMAND, "Minimize", "b", "cycle window-minimized", "", false},
        {COMMAND, "Quit mpv", "q", "quit", "", false},
        {COMMAND, "Quit and Save Current File State", "Q", "quit-watch-later", "", false},
    },

-- Secondary menu — Load
    open_menu = {
        {COMMAND, "[External Script] File", "CTRL+o", "script-message-to open_dialog import_files", "", false},
        {COMMAND, "[External Script] URL", "CTRL+O", "script-message-to open_dialog import_url", "", false},
        {CASCADE, "[External Script] Bookmarks", "bookmarker_menu", "", "", false},
        {CASCADE, "[External Script] Clipboard", "copy_menu", "", "", false},
        {CASCADE, "[External Script] Chapter Creation", "chaptercreat_menu", "", "", false},
        {COMMAND, "[External Script] Internal File Browser", "Tab", "script-message-to file_browser browse-files;script-message-to file_browser dynamic/reload;show-text ''", "", false},
        {COMMAND, "[External Script] Toggle Incognito History", "ALT+l", "script-binding simplehistory/history-incognito-mode", "", false},
        {COMMAND, "[External Script] Open History Menu", "`", "script-binding simplehistory/open-list;show-text ''", "", false},
        {SEP},
        {COMMAND, "[External Script] Load Other Subtitles (Switch)", "ALT+e", "script-message-to open_dialog append_sid", "", false},
        {COMMAND, "[External Script] Load Other Audio Tracks (No Switch)", "ALT+E", "script-message-to open_dialog append_aid", "", false},
        {COMMAND, "[External Script] Load Secondary Subtitles (Filter Type)", "CTRL+e", "script-message-to open_dialog append_vfSub", "", false},
        {COMMAND, "[External Script] Toggle Secondary Subtitles Visibility", "CTRL+E", "script-message-to open_dialog toggle_vfSub", "", false},
        {COMMAND, "[External Script] Remove Secondary Subtitles", "CTRL+ALT+e", "script-message-to open_dialog remove_vfSub", "", false},
    },

-- Tertiary menu — Bookmarks
    bookmarker_menu = {
        {COMMAND, "Open Bookmark Menu", "N", "script-binding simplebookmark/open-list;show-text ''", "", false},
        {COMMAND, "Add Progress Bookmark", "CTRL+n", "script-binding simplebookmark/bookmark-save", "", false},
        {COMMAND, "Add File Bookmark", "ALT+n", "script-binding simplebookmark/bookmark-fileonly", "", false},
    },
-- Tertiary menu — Clipboard
    copy_menu = {
        {COMMAND, "Open Clipboard Menu", "ALT+w", "script-binding smartcopypaste_II/open-list;show-text ''", "", false},
        {COMMAND, "Copy File Path", "CTRL+ALT+c", "script-binding smartcopypaste_II/copy-specific", "", false},
        {COMMAND, "Copy File Path and Position", "CTRL+c", "script-binding smartcopypaste_II/copy", "", false},
        {COMMAND, "Jump to Copied Content", "CTRL+v", "script-binding smartcopypaste_II/paste", "", false},
        {COMMAND, "Add Copied Content to Playlist", "CTRL+ALT+v", "script-binding smartcopypaste_II/paste-specific", "", false},
    },
-- Tertiary menu — Chapter Creation
    chaptercreat_menu = {
        {COMMAND, "Mark Chapter Time", "ALT+C", "script-message create_chapter", "", false},
        {COMMAND, "Create chp External Chapter File", "ALT+B", "script-message write_chapter", "", false},
        {COMMAND, "Create xml External Chapter File", "CTRL+ALT+b", "script-message write_chapter_xml", "", false},
    },
-- Secondary menu — File
    file_menu = {
        {CHECK, "Play/Pause", "SPACE", "cycle pause;show-text 暂停:${pause}", function() return propNative("pause") end, false},
        {COMMAND, "Stop", "SHIFT+F11", "stop", "", false},
        {COMMAND, "Reset Modified Options in Playback", "R", "cycle-values reset-on-next-file all no vf,af,border,contrast,brightness,gamma,saturation,hue,video-zoom,video-rotate,video-pan-x,video-pan-y,panscan,speed,audio,sub,audio-delay,sub-pos,sub-scale,sub-delay,sub-speed,sub-visibility;show-text 播放下一个文件时重置以下选项:${reset-on-next-file}", "", false},
        {SEP},
        {AB, "A-B Loop", "l", "ab-loop", function() return stateABLoop() end, false},
        {CHECK, "Loop Playback", "L", "cycle-values loop-file inf no;show-text 循环播放:${loop-file}", function() return stateFileLoop() end, false},
        {SEP},
        {COMMAND, "Speed -0.1", "[", "add speed -0.1;show-text 减速播放:${speed}", "", false},
        {COMMAND, "Speed +0.1", "]", "add speed  0.1;show-text 加速播放:${speed}", "", false},
        {COMMAND, "Half Speed", "{", "set speed 0.5;show-text 半速播放:${speed}", "", false},
        {COMMAND, "Double Speed", "}", "set speed 2;show-text 倍速播放:${speed}", "", false},
        {COMMAND, "Reset Speed", "BS", "set speed 1;show-text 重置播放速度:${speed}", "", false},
        {SEP},
        {COMMAND, "[External Script] Locate Current File", "ALT+o", "script_message-to locatefile locate-current-file", "", false},
        {COMMAND, "[External Script] Delete Current File", "CTRL+DEL", "script-message-to delete_current_file delete-file 1 '请按1确认删除'", "", false},
        {CASCADE, "[External Script] Youtube-dl Menu", "ytdl_menu", "", "", false},
    },

-- Tertiary menu — Youtube-dl Menu
    ytdl_menu = {
        {COMMAND, "Toggle ytdl Video Format Menu", "CTRL+F", "script-message-to quality_menu video_formats_toggle;show-text ''", "", false},
        {COMMAND, "Toggle ytdl Audio Format Menu", "ALT+F", "script-message-to quality_menu audio_formats_toggle;show-text ''", "", false},
        {COMMAND, "Reload", "CTRL+ALT+f", "script-message-to quality_menu reload", "", false},
        {COMMAND, "Download ytdl Video", "ALT+V", "script-message-to youtube_download download-video", "", false},
        {COMMAND, "Download ytdl Audio", "ALT+Y", "script-message-to youtube_download download-audio", "", false},
        {COMMAND, "Download ytdl Subtitle", "ALT+Z", "script-message-to youtube_download download-subtitle", "", false},
        {COMMAND, "Download ytdl Subtitle + Video", "CTRL+ALT+V", "script-message-to youtube_download download-embed-subtitle", "", false},
        {COMMAND, "Select ytdl Download Segment", "ALT+R", "script-message-to youtube_download select-range-start", "", false},
    },

-- Secondary menu — Navigation
    navi_menu = {
        {CHECK, "Show OSD Timeline", "O", "no-osd cycle-values osd-level 3 1", function() return stateOsdLevel(3) end, false},
        {COMMAND, "OSD Track Information", "", "show-text ${track-list} 5000", "", false},
        {CASCADE, "OSD Interactive Menu", "advosd_menu", "", "", false},
        {SEP},
        {CASCADE, "Editions", "edition_menu", "", "", function() return inspectEdition() end},
        {CASCADE, "Chapters", "chapter_menu", "", "", function() return inspectChapter() end},
        {SEP},
        {CHECK, "Playlist Loop", "", "cycle-values loop-playlist inf no", function() return statePlayLoop() end, false},
        {CHECK, "Shuffle Playlist", "", "cycle shuffle", function() return propNative("shuffle") end, false},
        {COMMAND, "Clear Playlist", "", "playlist-clear", "", false},
        {COMMAND, "Shuffle Playlist Randomly", "", "playlist-shuffle", "", false},
        {COMMAND, "Restore Playlist Order", "", "playlist-unshuffle", "", false},
        {SEP},
        {COMMAND, "Replay", "", "seek 0 absolute", "", false},
        {COMMAND, "Previous File", "<", "playlist-prev;show-text Playlist:${playlist-pos-1}/${playlist-count}", "", false},
        {COMMAND, "Next File", ">", "playlist-next;show-text Playlist:${playlist-pos-1}/${playlist-count}", "", false},
        {COMMAND, "Previous Frame", ",", "frame-back-step;show-text Current Frame:${estimated-frame-number}", "", false},
        {COMMAND, "Next Frame", ".", "frame-step;show-text Current Frame:${estimated-frame-number}", "", false},
        {CASCADE, "Seek Forward/Backward", "seek_menu", "", "", false},
        {SEP},
        {CASCADE, "[External Script] Jump", "undoredo_menu", "", "", false},
        {COMMAND, "[External Script] Automatically Skip Specified Chapters", "ALT+q", "script-message-to chapterskip chapter-skip;show-text Automatically Skip Specified Chapters", "", false},
        {COMMAND, "[External Script] Jump to Next Silent Position", "F4", "script-message-to skiptosilence skip-to-silence;show-text Jump to Next Silent Position", "", false},
    },

-- Tertiary menu — OSD Interactive Menu
    advosd_menu = {
        {COMMAND, "[External Script] Playlist", "F7", "script-message-to playlistmanager showplaylist;show-text ''", "", false},
        {COMMAND, "[External Script] Chapter List", "F8", "script-message-to chapter_list toggle-chapter-browser;show-text ''", "", false},
        {COMMAND, "[External Script] Video Track List", "F9", "script-message-to track_menu toggle-vidtrack-browser;show-text ''", "", false},
        {COMMAND, "[External Script] Audio Track List", "F10", "script-message-to track_menu toggle-audtrack-browser;show-text ''", "", false},
        {COMMAND, "[External Script] Subtitle Track List", "F11", "script-message-to track_menu toggle-subtrack-browser;show-text ''", "", false},
        {COMMAND, "[External Script] Edition List", "F12", "script-message-to editions_notification_menu toggle-edition-browser;show-text ''", "", false},
    },

-- Tertiary menu — Seek Forward/Backward
    seek_menu = {
        {COMMAND, "Seek Forward 05 Seconds", "LEFT", "seek 5", "", false},
        {COMMAND, "Seek Backward 05 Seconds", "RIGHT", "seek -5", "", false},
        {COMMAND, "Seek Forward 60 Seconds", "UP", "seek 60", "", false},
        {COMMAND, "Seek Backward 60 Seconds", "DOWN", "seek -60", "", false},
        {COMMAND, "Precise Seek Forward 01 Second", "SHIFT+LEFT", "seek  1 exact", "", false},
        {COMMAND, "Precise Seek Backward 01 Second", "SHIFT+RIGHT", "seek -1 exact", "", false},
        {COMMAND, "Precise Seek Forward 80 Seconds", "SHIFT+UP", "seek  80 exact", "", false},
        {COMMAND, "Precise Seek Backward 80 Seconds", "SHIFT+DOWN", "seek -80 exact", "", false},
    },

-- Tertiary menu — Jump
    undoredo_menu = {
        {COMMAND, "Undo Jump", "CTRL+z", "script-binding undoredo/undo", "", false},
        {COMMAND, "Redo Jump", "CTRL+r", "script-binding undoredo/redo", "", false},
        {COMMAND, "Loop Jump", "CTRL+ALT+z", "script-binding undoredo/undoLoop", "", false},
    },

-- Secondary menu — Output
    output_menu = {
        {CHECK, "Window Topmost", "ALT+t", "cycle ontop;show-text Topmost:${ontop}", function() return propNative("ontop") end, false},
        {CHECK, "Window Border", "CTRL+B", "cycle border", function() return propNative("border") end, false},
        {CHECK, "Maximize Window", "ALT+b", "cycle window-maximized", function() return propNative("window-maximized") end, false},
        {CHECK, "Fullscreen", "ENTER", "cycle fullscreen", function() return propNative("fullscreen") end, false},
        {CASCADE, "Aspect Ratio", "aspect_menu", "", "", false},
        {SEP},
        {COMMAND, "Crop Fill (None/Max)", "ALT+p", "cycle-values panscan 0.0 1.0;show-text Video Zoom:${panscan}", "", false},
        {COMMAND, "Rotate Left", "CTRL+LEFT", "cycle-values video-rotate 0 270 180 90;show-text Video Rotate:${video-rotate}", "", false},
        {COMMAND, "Rotate Right", "CTRL+RIGHT", "cycle-values video-rotate 0 90 180 270;show-text Video Rotate:${video-rotate}", "", false},
        {COMMAND, "Zoom Out", "ALT+-", "add video-zoom -0.1;show-text Zoom Out:${video-zoom}", "", false},
        {COMMAND, "Zoom In", "ALT+=", "add video-zoom  0.1;show-text Zoom In:${video-zoom}", "", false},
        {CASCADE, "Video Pan", "videopan_menu", "", "", false},
        {COMMAND, "Window Shrink", "CTRL+-", "add current-window-scale -0.1;show-text Current Window Shrink:${current-window-scale}", "", false},
        {COMMAND, "Window Enlarge", "CTRL+=", "add current-window-scale  0.1;show-text Current Window Enlarge:${current-window-scale}", "", false},
        {COMMAND, "Reset", "ALT+BS", "set video-zoom 0;set panscan 0;set video-rotate 0;set video-pan-x 0;set video-pan-y 0;show-text Reset Video Operations", "", false},
        {SEP},
        {CHECK, "Auto ICC Color Calibration", "CTRL+I", "cycle icc-profile-auto;show-text ICC Auto Calibration:${icc-profile-auto}", function() return propNative("icc-profile-auto") end, false},
        {CHECK, "Non-Linear Color Upscaling", "ALT+s", "cycle sigmoid-upscaling;show-text Non-Linear Color Upscaling:${sigmoid-upscaling}", function() return propNative("sigmoid-upscaling") end, false},
        {COMMAND, "Toggle Gamma Correction Factor", "G", "cycle-values gamma-factor 1.1 1.2 1.0;show-text Gamma Correction Factor:${gamma-factor}", "", false},
        {COMMAND, "Toggle HDR Mapping Curve", "h", "cycle-values tone-mapping auto mobius reinhard hable bt.2390 gamma spline bt.2446a;show-text HDR Mapping Curve:${tone-mapping}", "", false},
        {COMMAND, "Toggle HDR Dynamic Mapping", "ALT+h", "cycle-values hdr-compute-peak yes no;show-text HDR Dynamic Mapping:${hdr-compute-peak}", "", false},
        {COMMAND, "Toggle Color Mapping Mode", "CTRL+t", "cycle tone-mapping-mode;show-text Color Mapping Mode:${tone-mapping-mode}", "", false},
        {COMMAND, "Toggle Color Gamut Clipping Mode", "CTRL+g", "cycle gamut-mapping-mode;show-text Color Gamut Clipping Mode:${gamut-mapping-mode}", "", false},
    },

-- Tertiary menu — Aspect Ratio
    aspect_menu = {
        {COMMAND, "Reset", "", "set video-aspect-override -1", "", false},
        {RADIO, "Force 4:3", "", "set video-aspect-override 4:3", function() return stateRatio("4:3") end, false},
        {RADIO, "Force 16:9", "", "set video-aspect-override 16:9", function() return stateRatio("16:9") end, false},
        {RADIO, "Force 16:10", "", "set video-aspect-override 16:10", function() return stateRatio("16:10") end, false},
        {RADIO, "Force 1.85:1", "", "set video-aspect-override 1.85:1", function() return stateRatio("1.85:1") end, false},
        {RADIO, "Force 2.35:1", "", "set video-aspect-override 2.35:1", function() return stateRatio("2.35:1") end, false},
    },

-- Tertiary menu — Video Pan
    videopan_menu = {
        {COMMAND, "Reset", "", "set video-pan-x 0;set video-pan-y 0;show-text Reset Video Pan", "", false},
        {COMMAND, "Pan Left", "ALT+LEFT", "add video-pan-x -0.1;show-text Pan Left:${video-pan-x}", "", false},
        {COMMAND, "Pan Right", "ALT+RIGHT", "add video-pan-x  0.1;show-text Pan Right:${video-pan-x}", "", false},
        {COMMAND, "Pan Up", "ALT+UP", "add video-pan-y -0.1;show-text Pan Up:${video-pan-y}", "", false},
        {COMMAND, "Pan Down", "ALT+DOWN", "add video-pan-y  0.1;show-text Pan Down:${video-pan-y}", "", false},
    },

-- Secondary menu — Video
    video_menu = {
        {CASCADE, "Tracks", "vidtrack_menu", "", "", function() return inspectVidTrack() end},
        {SEP},
        {CASCADE, "Decoding Mode", "hwdec_menu", "", "", false},
        {COMMAND, "Toggle flip Mode", "CTRL+f", "cycle d3d11-flip;show-text flip Mode:${d3d11-flip}", "", false},
        {COMMAND, "Toggle Compatibility with x264 Old Encoding Mode", "", "cycle vd-lavc-assume-old-x264;show-text Compatibility with x264 Old Encoding Mode:${vd-lavc-assume-old-x264}", "", false},
        {COMMAND, "Switch Frame Sync Mode", "CTRL+p", "cycle-values video-sync display-resample audio display-vdrop display-resample-vdrop;show-text Frame Sync Mode:${video-sync}", "", false},
        {CHECK, "Jitter Compensation", "ALT+i", "cycle interpolation;show-text Jitter Compensation:${interpolation}", function() return propNative("interpolation") end, false},
        {COMMAND, "Toggle Black Borders Removal", "C", "script-message-to dynamic_crop toggle_crop", "", false},
        {CHECK, "Deinterlace", "d", "cycle deinterlace;show-text Deinterlace:${deinterlace}", function() return propNative("deinterlace") end, false},
        {CHECK, "Debanding", "D", "cycle deband;show-text Debanding:${deband}", function() return propNative("deband") end, false},
        {COMMAND, "Debanding Strength +1", "ALT+z", "add deband-iterations +1;show-text Increase Debanding Strength:${deband-iterations}", "", false},
        {COMMAND, "Debanding Strength -1", "ALT+x", "add deband-iterations -1;show-text Decrease Debanding Strength:${deband-iterations}", "", false},
        {SEP},
        {CASCADE, "Color Adjustment", "color_menu", "", "", false},
        {CASCADE, "Screenshot", "screenshot_menu", "", "", false},
        {SEP},
        {CASCADE, "[External Script] Clip Segments", "slicing_menu", "", "", false},
        {CASCADE, "[External Script] Clip Animated Images", "webp_menu", "", "", false},
    },

-- Tertiary menu — Decoding Mode
    hwdec_menu = {
        {COMMAND, "Prefer Software Decoding", "", "set hwdec no", "", false},
        {COMMAND, "Prefer Hardware Decoding", "", "set hwdec auto-safe", "", false},
        {COMMAND, "Prefer Hardware Decoding (Copy)", "", "set hwdec auto-copy-safe", "", false},
        {SEP},
        {RADIO, "SW", "", "set hwdec no", function() return stateHwdec("no") end, false},
        {RADIO, "nvdec", "", "set hwdec nvdec", function() return stateHwdec("nvdec") end, false},
        {RADIO, "nvdec-copy", "", "set hwdec nvdec-copy", function() return stateHwdec("nvdec-copy") end, false},
        {RADIO, "d3d11va", "", "set hwdec d3d11va", function() return stateHwdec("d3d11va") end, false},
        {RADIO, "d3d11va-copy", "", "set hwdec d3d11va-copy", function() return stateHwdec("d3d11va-copy") end, false},
        {RADIO, "dxva2", "", "set hwdec dxva2", function() return stateHwdec("dxva2") end, false},
        {RADIO, "dxva2-copy", "", "set hwdec dxva2-copy", function() return stateHwdec("dxva2-copy") end, false},
        {RADIO, "cuda", "", "set hwdec cuda", function() return stateHwdec("cuda") end, false},
        {RADIO, "cuda-copy", "", "set hwdec cuda-copy", function() return stateHwdec("cuda-copy") end, false},
    },

-- Tertiary menu — Color Adjustment
    color_menu = {
        {COMMAND, "Reset", "CTRL+BS", "no-osd set contrast 0; no-osd set brightness 0; no-osd set gamma 0; no-osd set saturation 0; no-osd set hue 0;show-text Reset Color Adjustment", "", false},
        {COMMAND, "Contrast -1", "1", "add contrast -1;show-text Contrast:${contrast}", "", false},
        {COMMAND, "Contrast +1", "2", "add contrast  1;show-text Contrast:${contrast}", "", false},
        {COMMAND, "Brightness -1", "3", "add brightness -1;show-text Brightness:${brightness}", "", false},
        {COMMAND, "Brightness +1", "4", "add brightness  1;show-text Brightness:${brightness}", "", false},
        {COMMAND, "Gamma -1", "5", "add gamma -1;show-text Gamma:${gamma}", "", false},
        {COMMAND, "Gamma +1", "6", "add gamma  1;show-text Gamma:${gamma}", "", false},
        {COMMAND, "Saturation -1", "7", "add saturation -1;show-text Saturation:${saturation}", "", false},
        {COMMAND, "Saturation +1", "8", "add saturation  1;show-text Saturation:${saturation}", "", false},
        {COMMAND, "Hue -1", "-", "add hue -1;show-text Hue:${hue}", "", false},
        {COMMAND, "Hue +1", "=", "add hue  1;show-text Hue:${hue}", "", false},
    },

-- Tertiary menu — Screenshot
    screenshot_menu = {
        {COMMAND, "Original Size - With Subtitles - With OSD - Single Frame", "s", "screenshot subtitles", "", false},
        {COMMAND, "Original Size - Without Subtitles - Without OSD - Single Frame", "S", "screenshot video", "", false},
        {COMMAND, "Actual Size - With Subtitles - With OSD - Single Frame", "CTRL+s", "screenshot window", "", false},
        {SEP},
        {COMMAND, "Original Size - With Subtitles - With OSD - Each Frame", "", "screenshot subtitles+each-frame", "", false},
        {COMMAND, "Original Size - Without Subtitles - Without OSD - Each Frame", "", "screenshot video+each-frame", "", false},
        {COMMAND, "Actual Size - With Subtitles - With OSD - Each Frame", "CTRL+S", "screenshot window+each-frame", "", false},
    },

-- Tertiary menu — Clip Segments
    slicing_menu = {
        {COMMAND, "Specify Start/End Positions", "c", "script-message slicing_mark", "", false},
        {COMMAND, "Toggle Cutting Audio Info", "a", "script-message slicing_audio", "", false},
        {COMMAND, "Clear Markers", "CTRL+C", "script-message clear_slicing_mark", "", false},
    },

-- Tertiary menu — Clip Animated Images
    webp_menu = {
        {COMMAND, "Start Time", "w", "script-message set_webp_start", "", false},
        {COMMAND, "End Time", "W", "script-message set_webp_end", "", false},
        {COMMAND, "Export WebP Animation", "CTRL+w", "script-message make_webp", "", false},
        {COMMAND, "Export WebP Animation with Subtitles", "CTRL+W", "script-message make_webp_with_subtitles", "", false},
    },

-- Secondary menu — Audio
    audio_menu = {
        {CASCADE, "Tracks", "audtrack_menu", "", "", function() return inspectAudTrack() end},
        {SEP},
        {COMMAND, "Toggle Audio Track", "y", "cycle audio;show-text Audio Track:${audio}", "", false},
        {CHECK, "Audio Normalization", "", "cycle audio-normalize-downmix;show-text Audio Normalization:${audio-normalize-downmix}", function() return propNative("audio-normalize-downmix") end, false},
        {CHECK, "Audio Exclusive Mode", "CTRL+y", "cycle audio-exclusive;show-text Audio Exclusive Mode:${audio-exclusive}", function() return propNative("audio-exclusive") end, false},
        {CHECK, "Audio Sync Mode", "CTRL+Y", "cycle hr-seek-framedrop;show-text Audio Sync Mode:${hr-seek-framedrop}", function() return propNative("hr-seek-framedrop") end, false},
        {COMMAND, "Adjust Multi-channel Audio for Each Channel", "F2", "cycle-values  af @loudnorm:lavfi=[loudnorm=I=-16:TP=-3:LRA=4] @dynaudnorm:lavfi=[dynaudnorm=g=5:f=250:r=0.9:p=0.5] \"\"", "", false},
        {SEP},
        {COMMAND, "Volume -1", "9", "add volume -1;show-text Volume:${volume}", "", false},
        {COMMAND, "Volume +1", "0", "add volume  1;show-text Volume:${volume}", "", false},
        {CHECK, function() return muteLabel() end, "m", "cycle mute;show-text Mute:${mute}", function() return propNative("mute") end, false},
        {SEP},
        {COMMAND, "Delay -0.1", "CTRL+,", "add audio-delay -0.1;show-text Audio Delay:${audio-delay}", "", false},
        {COMMAND, "Delay +0.1", "CTRL+.", "add audio-delay +0.1;show-text Audio Preload:${audio-delay}", "", false},
        {COMMAND, "Reset Offset", ";", "set audio-delay 0;show-text Reset Audio Delay:${audio-delay}", "", false},
        {SEP},
        {CASCADE, "Channel Layout", "channel_layout", "", "", false},
        {SEP},
        {COMMAND, "[External Script] Toggle Interactive Audio Device Menu", "F6", "script-message-to adevice_list toggle-adevice-browser;show-text ''", "", false},
        {COMMAND, "[External Script] Toggle dynaudnorm Mixing Menu", "ALT+n", "script-message-to drcbox key_toggle_bindings", "", false},
    },

    -- Use function to return list of Audio Tracks
    audtrack_menu = audTrackMenu(),
    channel_layout = audLayoutMenu(),

-- Secondary menu — Subtitle
    subtitle_menu = {
        {CASCADE, "Tracks", "subtrack_menu", "", "", function() return inspectSubTrack() end},
        {SEP},
        {COMMAND, "Toggle Subtitle Track", "j", "cycle sub;show-text Subtitle Track:${sub}", "", false},
        {COMMAND, "Toggle Rendering Style", "u", "cycle sub-ass-override;show-text Subtitle Rendering Style:${sub-ass-override}", "", false},
        {COMMAND, "Toggle Default Font", "T", "cycle-values sub-font 'NotoSansCJKsc-Bold' 'NotoSerifCJKsc-Bold';show-text Using Font:${sub-font}", "", false},
        {COMMAND, "Load Secondary Subtitle", "k", "cycle secondary-sid;show-text Load Secondary Subtitle:${secondary-sid}", "", false},
        {SEP},
        {CASCADE, "Subtitle Compatibility", "sub_menu", "", "", false},
        {SEP},
        {COMMAND, "Reset", "SHIFT+BS", "no-osd set sub-delay 0; no-osd set sub-pos 100; no-osd set sub-scale 1.0;show-text Reset Subtitle Status", "", false},
        {COMMAND, "Font Size -0.1", "ALT+j", "add sub-scale -0.1;show-text Shrink Subtitle:${sub-scale}", "", false},
        {COMMAND, "Font Size +0.1", "ALT+k", "add sub-scale  0.1;show-text Enlarge Subtitle:${sub-scale}", "", false},
        {COMMAND, "Delay -0.1", "z", "add sub-delay -0.1;show-text Subtitle Delay:${sub-delay}", "", false},
        {COMMAND, "Delay +0.1", "x", "add sub-delay  0.1;show-text Subtitle Preload:${sub-delay}", "", false},
        {COMMAND, "Move Up", "r", "add sub-pos -1;show-text Subtitle Move Up:${sub-pos}", "", false},
        {COMMAND, "Move Down", "t", "add sub-pos  11;show-text Subtitle Move Down:${sub-pos}", "", false},
--        {SEP},
--        {COMMAND, "Subtitle Vertical Position", "", "cycle-values sub-align-y top bottom", "", false},
--        {RADIO, " Top", "", "set sub-align-y top", function() return stateSubAlign("top") end, false},
--        {RADIO, " Bottom", "", "set sub-align-y bottom", function() return stateSubAlign("bottom") end, false},
        {SEP},
        {COMMAND, "[External Script] Open Subtitle Sync Menu", "CTRL+m", "script-message-to autosubsync autosubsync-menu", "", false},
        {COMMAND, "[External Script] Toggle Subtitle Selection Script", "Y", "script-message sub-select toggle", "", false},
        {COMMAND, "[External Script] Export Current Embedded Subtitles", "ALT+m", "script-message-to sub_export export-selected-subtitles", "", false},
    },

    -- Use function to return list of Subtitle Tracks
    subtrack_menu = subTrackMenu(),

-- Tertiary menu — Subtitle Compatibility
    sub_menu = {
         {COMMAND, "Toggle Font Rendering Method", "F", "cycle sub-font-provider;show-text Font Rendering Method:${sub-font-provider}", "", false},
         {COMMAND, "Toggle Subtitle Color Conversion Method", "J", "cycle sub-ass-vsfilter-color-compat;show-text Subtitle Color Conversion Method:${sub-ass-vsfilter-color-compat}", "", false},
         {COMMAND, "Toggle Ass Subtitle Shadow Border Scaling", "X", "cycle-values sub-ass-force-style ScaledBorderAndShadow=no ScaledBorderAndShadow=yes;show-text Force Replace Ass Style:${sub-ass-force-style}", "", false},
         {CHECK, "Vsfilter Compatibility", "V", "cycle sub-ass-vsfilter-aspect-compat;show-text Vsfilter Compatibility:${sub-ass-vsfilter-aspect-compat}", function() return propNative("sub-ass-vsfilter-aspect-compat") end, false},
         {CHECK, "Blur Tag Scaling Compatibility", "B", "cycle sub-ass-vsfilter-blur-compat;show-text Blur Tag Scaling Compatibility:${sub-ass-vsfilter-blur-compat}", function() return propNative("sub-ass-vsfilter-blur-compat") end, false},
         {SEP},
         {CHECK, "Toggle Unicode Bidirectional Algorithm", "", "cycle sub-ass-feature-bidi-brackets;show-text Enable Unicode Bidirectional Algorithm:${sub-ass-feature-bidi-brackets}", function() return propNative("sub-ass-feature-bidi-brackets") end, false},
         {CHECK, "Toggle Whole Text Layout Approach", "", "cycle sub-ass-feature-whole-text-layout;show-text Enable Whole Text Layout:${sub-ass-feature-whole-text-layout}", function() return propNative("sub-ass-feature-whole-text-layout") end, false},
         {CHECK, "Toggle Unicode Wrapping Approach", "", "cycle sub-ass-feature-wrap-unicode;show-text Enable Unicode Wrapping:${sub-ass-feature-wrap-unicode}", function() return propNative("sub-ass-feature-wrap-unicode") end, false},
         {SEP},
         {CHECK, "Ass Subtitle Output to Black Borders", "H", "cycle sub-ass-force-margins;show-text Ass Subtitle Output Black Borders:${sub-ass-force-margins}", function() return propNative("sub-ass-force-margins") end, false},
         {CHECK, "Srt Subtitle Output to Black Borders", "Z", "cycle sub-use-margins;show-text Srt Subtitle Output Black Borders:${sub-use-margins}", function() return propNative("sub-use-margins") end, false},
         {CHECK, "Pgs Subtitle Output to Black Borders", "P", "cycle stretch-image-subs-to-screen;show-text Pgs Subtitle Output Black Borders:${stretch-image-subs-to-screen}", function() return propNative("stretch-image-subs-to-screen") end, false},
         {CHECK, "Pgs Subtitle Grayscale Conversion", "p", "cycle sub-gray;show-text Pgs Subtitle Grayscale Conversion:${sub-gray}", function() return propNative("sub-gray") end, false},
        },

-- Secondary menu — Filter
    filter_menu = {
        {COMMAND, "Clear All Video Filters", "CTRL+`", "vf clr \"\"", "", false},
        {COMMAND, "Clear All Audio Filters", "ALT+`", "af clr \"\"", "", false},
        {SEP},
        {COMMAND, opt.filter01B, opt.filter01C, opt.filter01D, "", false, opt.filter01G},
        {COMMAND, opt.filter02B, opt.filter02C, opt.filter02D, "", false, opt.filter02G},
        {COMMAND, opt.filter03B, opt.filter03C, opt.filter03D, "", false, opt.filter03G},
        {COMMAND, opt.filter04B, opt.filter04C, opt.filter04D, "", false, opt.filter04G},
        {COMMAND, opt.filter05B, opt.filter05C, opt.filter05D, "", false, opt.filter05G},
        {COMMAND, opt.filter06B, opt.filter06C, opt.filter06D, "", false, opt.filter06G},
        {COMMAND, opt.filter07B, opt.filter07C, opt.filter07D, "", false, opt.filter07G},
        {COMMAND, opt.filter08B, opt.filter08C, opt.filter08D, "", false, opt.filter08G},
        {COMMAND, opt.filter09B, opt.filter09C, opt.filter09D, "", false, opt.filter09G},
        {COMMAND, opt.filter10B, opt.filter10C, opt.filter10D, "", false, opt.filter10G},
    },

-- Secondary menu — Shader
    shader_menu = {
        {COMMAND, "Clear All Shaders", "CTRL+0", "change-list glsl-shaders clr \"\"", "", false},
        {SEP},
        {COMMAND, opt.shader01B, opt.shader01C, opt.shader01D, "", false, opt.shader01G},
        {COMMAND, opt.shader02B, opt.shader02C, opt.shader02D, "", false, opt.shader02G},
        {COMMAND, opt.shader03B, opt.shader03C, opt.shader03D, "", false, opt.shader03G},
        {COMMAND, opt.shader04B, opt.shader04C, opt.shader04D, "", false, opt.shader04G},
        {COMMAND, opt.shader05B, opt.shader05C, opt.shader05D, "", false, opt.shader05G},
        {COMMAND, opt.shader06B, opt.shader06C, opt.shader06D, "", false, opt.shader06G},
        {COMMAND, opt.shader07B, opt.shader07C, opt.shader07D, "", false, opt.shader07G},
        {COMMAND, opt.shader08B, opt.shader08C, opt.shader08D, "", false, opt.shader08G},
        {COMMAND, opt.shader09B, opt.shader09C, opt.shader09D, "", false, opt.shader09G},
        {COMMAND, opt.shader10B, opt.shader10C, opt.shader10D, "", false, opt.shader10G},
    },

-- Secondary menu — Other
    etc_menu = {
        {COMMAND, "[Internal Script] Display Info (Toggle)", "I", "script-binding stats/display-stats-toggle", "", false},
        {COMMAND, "[Internal Script] Info Overview", "", "script-binding stats/display-page-1", "", false},
        {COMMAND, "[Internal Script] Frame Timing Info (Paginated)", "", "script-binding stats/display-page-2", "", false},
        {COMMAND, "[Internal Script] Input Buffer Info", "", "script-binding stats/display-page-3", "", false},
        {COMMAND, "[Internal Script] Shortcut Info (Paginated)", "", "script-binding stats/display-page-4", "", false},
        {COMMAND, "[Internal Script] Internal Streams Info (Paginated)", "", "script-binding stats/display-page-0", "", false},
        {COMMAND, "[Internal Script] Console", "~", "script-binding console/enable", "", false},
    },

-- Secondary menu — Tools
    tool_menu = {
        {COMMAND, "[External Script] Match Video Refresh Rate", "CTRL+F10", "script-binding change_refresh/match-refresh", "", false},
        {COMMAND, "[External Script] Copy Current Time", "CTRL+ALT+t", "script-message-to copy_subortime copy-time", "", false},
        {COMMAND, "[External Script] Copy Current Subtitle Content", "CTRL+ALT+s", "script-message-to copy_subortime copy-subtitle", "", false},
        {COMMAND, "[External Script] Update Script Shaders", "M", "script-message manager-update-all;show-text Update Script Shaders", "", false},
    },

-- Secondary menu — Configuration Profiles
    profile_menu = {
        {COMMAND, "[External Script] Switch to Specified Profile", "CTRL+P", "script-message cycle-commands \"apply-profile Anime4K;show-text Profile: Anime4K\" \"apply-profile ravu-3x;show-text Profile: ravu-3x\" \"apply-profile Normal;show-text Profile: Normal\" \"apply-profile AMD-FSR_EASU;show-text Profile: AMD-FSR_EASU\" \"apply-profile NNEDI3;show-text Profile: NNEDI3\"", "", false},
        {SEP},
        {COMMAND, "Switch to Normal Profile", "ALT+1", "apply-profile Normal;show-text Profile: Normal", "", false},
        {COMMAND, "Switch to Normal+ Profile", "ALT+2", "apply-profile Normal+;show-text Profile: Normal+", "", false},
        {COMMAND, "Switch to Anime Profile", "ALT+3", "apply-profile Anime;show-text Profile: Anime", "", false},
        {COMMAND, "Switch to Anime+ Profile", "ALT+4", "apply-profile Anime+;show-text Profile: Anime+", "", false},
        {COMMAND, "Switch to Ravu-lite Profile", "", "apply-profile ravu-lite;show-text Profile: ravu-lite", "", false},
        {COMMAND, "Switch to Ravu-3x Profile", "ALT+5", "apply-profile ravu-3x;show-text Profile: ravu-3x", "", false},
        {COMMAND, "Switch to ACNet Profile", "ALT+6", "apply-profile ACNet;show-text Profile: ACNet", "", false},
        {COMMAND, "Switch to ACNet+ Profile", "", "apply-profile ACNet+;show-text Profile: ACNet+", "", false},
        {COMMAND, "Switch to Anime4K Profile", "ALT+7", "apply-profile Anime4K;show-text Profile: Anime4K", "", false},
        {COMMAND, "Switch to Anime4K+ Profile", "", "apply-profile Anime4K+;show-text Profile: Anime4K+", "", false},
        {COMMAND, "Switch to NNEDI3 Profile", "ALT+8", "apply-profile NNEDI3;show-text Profile: NNEDI3", "", false},
        {COMMAND, "Switch to NNEDI3+ Profile", "", "apply-profile NNEDI3+;show-text Profile: NNEDI3+", "", false},
        {COMMAND, "Switch to AMD-FSR_EASU Profile", "ALT+9", "apply-profile AMD-FSR_EASU;show-text Profile: AMD-FSR_EASU", "", false},
        {COMMAND, "Switch to Blur2Sharpen Profile", "ALT+0", "apply-profile Blur2Sharpen;show-text Profile: Blur2Sharpen", "", false},
        {COMMAND, "Switch to SSIM Profile", "", "apply-profile SSIM;show-text Profile: SSIM", "", false},
        {SEP},
        {COMMAND, "Switch to ICC Profile", "", "apply-profile ICC;show-text Profile: ICC", "", false},
        {COMMAND, "Switch to ICC+ Profile", "", "apply-profile ICC+;show-text Profile: ICC+", "", false},
        {COMMAND, "Switch to Target Profile", "", "apply-profile Target;show-text Profile: Target", "", false},
        {COMMAND, "Switch to Tscale Profile", "", "apply-profile Tscale;show-text Profile: Tscale", "", false},
        {COMMAND, "Switch to Tscale-box Profile", "", "apply-profile Tscale-box;show-text Profile: Tscale-box", "", false},
        {COMMAND, "Switch to DeBand-low Profile", "ALT+1", "apply-profile DeBand-low;show-text Profile: DeBand-low", "", false},
        {COMMAND, "Switch to DeBand-mediu Profile", "ALT+d", "apply-profile DeBand-medium;show-text Profile: DeBand-medium", "", false},
        {COMMAND, "Switch to DeBand-high Profile", "ALT+D", "apply-profile DeBand-high;show-text Profile: DeBand-high", "", false},
    },

-- Secondary menu — About
about_menu = {
    {COMMAND, mp.get_property("mpv-version"), "", "", "", false},
    {COMMAND, "ffmpeg " .. mp.get_property("ffmpeg-version"), "", "", "", false},
    {COMMAND, "libass " .. mp.get_property("libass-version"), "", "", "", false},
},

--[[
Reserved for future use
            -- Y Values: -1 = Top, 0 = Vertical Center, 1 = Bottom
            -- X Values: -1 = Left, 0 = Horizontal Center, 1 = Right
            {RADIO, "Top", "", "set video-align-y -1", function() return stateAlign("y",-1) end, false},
            {RADIO, "Vertical Center", "", "set video-align-y 0", function() return stateAlign("y",0) end, false},
            {RADIO, "Bottom", "", "set video-align-y 1", function() return stateAlign("y",1) end, false},
            {RADIO, "Left", "", "set video-align-x -1", function() return stateAlign("x",-1) end, false},
            {RADIO, "Horizontal Center", "", "set video-align-x 0", function() return stateAlign("x",0) end, false},
            {RADIO, "Right", "", "set video-align-x 1", function() return stateAlign("x",1) end, false},
            {CHECK, "Flip Vertically", "", "vf toggle vflip", function() return stateFlip("vflip") end, false},
            {CHECK, "Flip Horizontally", "", "vf toggle hflip", function() return stateFlip("hflip") end, false}

            {RADIO, "Display on Letterbox", "", "set image-subs-video-resolution \"no\"", function() return stateSubPos(false) end, false},
            {RADIO, "Display in Video", "", "set image-subs-video-resolution \"yes\"", function() return stateSubPos(true) end, false},
            {COMMAND, "Move Up", "", function() movePlaylist("up") end, "", function() return (propNative("playlist-count") < 2) and true or false end},
            {COMMAND, "Move Down", "", function() movePlaylist("down") end, "", function() return (propNative("playlist-count") < 2) and true or false end},
]]--

}

-- This check ensures that all tables of data without SEP in them are 6 or 7 items long.
for key, value in pairs(menuList) do
    -- Skip the 'file_loaded_menu' key as the following for loop will fail due to an
    -- attempt to get the length of a boolean value.
    if (key == "file_loaded_menu") then goto keyjump end

    for i = 1, #value do
        if (value[i][1] ~= SEP) then
            if (#value[i] < 6 or #value[i] > 7) then mpdebug("Menu item at index of " .. i .. " is " .. #value[i] .. " items long for: " .. key) end
        end
    end
    
    ::keyjump::
end

mp.add_hook("on_preloaded", 100, playmenuList)

local function observe_change()
    mp.observe_property("track-list/count", "number", playmenuList)
    mp.observe_property("chapter-list/count", "number", playmenuList)
end

mp.register_event("file-loaded", observe_change)

mp.register_event("end-file", function()
    mp.unobserve_property(playmenuList)
    menuList = menuListBase
end)

--[[ ************ Menu Content ************ ]]--

local menuEngine = require "contextmenu_gui_engine"

mp.register_script_message("contextmenu_tk", function()
    menuEngine.createMenu(menuList, "context_menu", -1, -1, "tk")
end)
