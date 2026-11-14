--[[
	Ball Knowledge multi-file loader

	GitHub:
	  1. set BASE to your raw repo root (trailing /)
	  2. loadstring(game:HttpGet(BASE .. "load.lua"))()

	Local:
	  USE_HTTP = false
	  loadstring(readfile("load.lua"))()
]]

local BASE = "https://raw.githubusercontent.com/K01dBy4spam935h/Ball-Knowledge-Script/main/"
local USE_HTTP = true
local LOCAL_DIR = "modules/"

local function fetch(name)
	local src
	if USE_HTTP then
		src = game:HttpGet(BASE .. "modules/" .. name)
	else
		src = readfile(LOCAL_DIR .. name)
	end
	local fn, err = loadstring(src)
	assert(fn, "load " .. name .. ": " .. tostring(err))
	return fn()
end

local Config = fetch("Config.lua")
local Bank = fetch("Bank.lua")
local Harvest = fetch("Harvest.lua")
local makeCore = fetch("Core.lua")
local makeUI = fetch("UI.lua")

-- mutable sink so Core/UI always hit the same log
local sink = { gui = nil }
local function log(msg)
	msg = tostring(msg)
	print("[BK] " .. msg)
	if sink.gui and sink.gui.uiLog then
		sink.gui.uiLog(msg)
	end
end

local bag = {
	Config = Config,
	Bank = Bank,
	Harvest = Harvest,
	log = log,
	Core = nil,
	onSupportChanged = nil,
}

local UI = makeUI(bag)
bag.onSupportChanged = function(live)
	UI.onSupportChanged(live)
end

local Core = makeCore(bag)
bag.Core = Core

-- rebuild UI with Core present
UI = makeUI(bag)
UI.build()
sink.gui = UI

Core.start()
log("multi-file loaded")
log("UNSUPPORTED = answer yourself | Dump = print harvest")
