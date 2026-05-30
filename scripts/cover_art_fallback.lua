--[[
文档_ 无

加载纯音频文件时自动挂载备用封面，封面的默认路径为 "~~/cover_fbk.jpg"

（不使用选项 --cover-art-files 的原因是存在严重bug）
 https://github.com/mpv-player/mpv/issues/12219
 https://github.com/mpv-player/mpv/issues/12165

]]

local mp = require "mp"
mp.options = require "mp.options"

local user_opt = {
	load = true,
	cover = "~~/cover_fbk.jpg",
}
mp.options.read_options(user_opt)

if user_opt.load == false then
	mp.msg.info("脚本已被初始化禁用")
	return
end
-- 原因：flag: attached-picture
local min_major = 0
local min_minor = 40
local min_patch = 0
local mpv_ver_curr = mp.get_property_native("mpv-version", "unknown")
local function incompat_check(full_str, tar_major, tar_minor, tar_patch)
	if full_str == "unknown" then
		return true
	end

	local clean_ver_str = full_str:gsub("^[^%d]*", "")
	local major, minor, patch = clean_ver_str:match("^(%d+)%.(%d+)%.(%d+)")
	major = tonumber(major)
	minor = tonumber(minor)
	patch = tonumber(patch or 0)
	if major < tar_major then
		return true
	elseif major == tar_major then
		if minor < tar_minor then
			return true
		elseif minor == tar_minor then
			if patch < tar_patch then
				return true
			end
		end
	end

	return false
end
if incompat_check(mpv_ver_curr, min_major, min_minor, min_patch) then
	mp.msg.warn("当前mpv版本 (" .. (mpv_ver_curr or "未知") .. ") 低于 " .. min_major .. "." .. min_minor .. "." .. min_patch .. "，已终止脚本。")
	return
end


function add_cover()
	local skip = mp.get_property_native("current-tracks/video/external", "")
	if skip ~= "" then return end
	local cover_path = mp.command_native({"expand-path", user_opt.cover})
		--           video-add   <url>      [<flags>            [<title>          [<lang> [<albumart>]]]]
		mp.commandv("video-add", cover_path, "attached-picture", "cover_fallback", "no",   "yes")
end

mp.register_event("file-loaded", add_cover)
