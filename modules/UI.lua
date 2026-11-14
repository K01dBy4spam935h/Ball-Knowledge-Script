return function(deps)
	local CFG = deps.Config
	local Bank = deps.Bank
	local Harvest = deps.Harvest
	local Core = deps.Core
	local log = deps.log

	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local Stats = game:GetService("Stats")
	local LP = Players.LocalPlayer

	local gui = { window = nil }
	local connections = {}
	local supportParagraph, promptParagraph, metaParagraph
	local playersP, pingP, fpsP, jobP, execP

	local function detectExecutor()
		for _, n in ipairs({ "identifyexecutor", "getexecutorname", "get_executor_name" }) do
			local f = rawget(getfenv and getfenv() or _G, n)
			if not f and getgenv then f = getgenv()[n] end
			if type(f) == "function" then
				local ok, a, b = pcall(f)
				if ok and type(a) == "string" and a ~= "" then
					return b and (a .. " " .. tostring(b)) or a
				end
			end
		end
		return "Unknown"
	end

	local function getPingMs()
		local ok, v = pcall(function()
			return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
		end)
		if ok and type(v) == "number" then
			return math.floor(v + 0.5)
		end
		ok, v = pcall(function()
			return LP:GetNetworkPing() * 1000
		end)
		if ok and type(v) == "number" then
			return math.floor(v + 0.5)
		end
		return 0
	end

	local executorName = detectExecutor()

	local function unload()
		for _, c in ipairs(connections) do
			pcall(function()
				if typeof(c) == "RBXScriptConnection" then
					c:Disconnect()
				end
			end)
		end
		table.clear(connections)
		if gui.window then
			pcall(function() gui.window:Destroy() end)
			gui.window = nil
		end
		print("[BK] unloaded")
	end

	local function build()
		local WindUI = loadstring(game:HttpGet(
			"https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
		))()

		local Window = WindUI:CreateWindow({
			Title = "Ball Knowledge Script",
			Author = "LarpSec · v1",
			Folder = "BallKnowledgeScript",
			Icon = "book-open",
			NewElements = true,
			HideSearchBar = true,
			Size = UDim2.fromOffset(560, 400),
			ToggleKey = Enum.KeyCode.LeftControl,
		})
		pcall(function()
			Window:SetToggleKey(Enum.KeyCode.LeftControl)
		end)
		gui.window = Window

		-- ===== MAIN =====
		local Main = Window:Tab({
			Title = "Main",
			Icon = "monitor",
		})

		Main:Section({ Title = "Server" })

		playersP = Main:Paragraph({ Title = "Players", Desc = "—" })
		pingP = Main:Paragraph({ Title = "Ping", Desc = "—" })
		fpsP = Main:Paragraph({ Title = "FPS", Desc = "—" })
		jobP = Main:Paragraph({ Title = "JobId", Desc = "—" })
		execP = Main:Paragraph({ Title = "Executor", Desc = executorName })

		-- ===== AUTO-FARM =====
		local Farm = Window:Tab({
			Title = "Auto-farm",
			Icon = "zap",
		})

		Farm:Section({ Title = "Status" })
		supportParagraph = Farm:Paragraph({
			Title = "Support",
			Desc = "waiting...",
		})
		promptParagraph = Farm:Paragraph({
			Title = "Prompt",
			Desc = "(no prompt)",
		})
		metaParagraph = Farm:Paragraph({
			Title = "Match",
			Desc = "—",
		})

		Farm:Section({ Title = "Controls" })

		Farm:Toggle({
			Title = "Auto answer",
			Desc = "Submit bank answers when supported",
			Value = CFG.auto == true,
			Callback = function(state)
				CFG.auto = state
				log("auto " .. (state and "on" or "off"))
				if state and Core then
					task.spawn(Core.tryAuto)
				end
			end,
		})

		Farm:Button({
			Title = "Submit best",
			Callback = function()
				local live = Core.live
				local a = Bank.next(live.promptId, nil)
				if a then
					Core.doSubmit(a)
				else
					log("no bank answer")
					WindUI:Notify({ Title = "Bank", Content = "No answer for this prompt", Duration = 3 })
				end
			end,
		})

		Farm:Button({
			Title = "Dump questions",
			Callback = function()
				local _, n = Harvest.dump(Core.rank)
				log("dumped " .. tostring(n) .. " prompts")
				WindUI:Notify({ Title = "Dump", Content = tostring(n) .. " prompts printed", Duration = 3 })
			end,
		})

		Farm:Input({
			Title = "Manual answer",
			Placeholder = "type answer and press enter",
			Callback = function(text)
				if text and text:gsub("%s", "") ~= "" then
					Core.doSubmit(text)
				end
			end,
		})

		-- ===== SETTINGS =====
		local Settings = Window:Tab({
			Title = "Settings",
			Icon = "settings",
		})

		Settings:Section({ Title = "Script" })

		Settings:Button({
			Title = "Unload script",
			Callback = function()
				unload()
			end,
		})

		Settings:Paragraph({
			Title = "Notes",
			Desc = "Unsupported prompts need a manual answer (still harvested).\nDump exports a table to paste into modules/Bank.lua.",
		})

		-- select main
		pcall(function() Main:Select() end)

		-- stats loop
		local frames, fps, last = 0, 0, os.clock()
		table.insert(connections, RunService.RenderStepped:Connect(function()
			frames = frames + 1
			local now = os.clock()
			if now - last >= 0.5 then
				fps = math.floor(frames / (now - last) + 0.5)
				frames = 0
				last = now
			end
		end))

		table.insert(connections, task.spawn(function()
			while gui.window do
				pcall(function()
					if playersP and playersP.SetDesc then
						playersP:SetDesc(tostring(#Players:GetPlayers()) .. " / " .. tostring(Players.MaxPlayers))
					end
					if pingP and pingP.SetDesc then
						pingP:SetDesc(tostring(getPingMs()) .. " ms")
					end
					if fpsP and fpsP.SetDesc then
						fpsP:SetDesc(tostring(fps))
					end
					if jobP and jobP.SetDesc then
						jobP:SetDesc(tostring(game.JobId))
					end
				end)
				task.wait(0.5)
			end
		end))

		return gui
	end

	local function onSupportChanged(live)
		pcall(function()
			if supportParagraph and supportParagraph.SetDesc then
				if live.supported then
					supportParagraph:SetDesc("SUPPORTED · " .. tostring(live.promptId))
				elseif live.promptId then
					supportParagraph:SetDesc("UNSUPPORTED — answer yourself")
				else
					supportParagraph:SetDesc("waiting...")
				end
			end
			if promptParagraph and promptParagraph.SetDesc then
				promptParagraph:SetDesc(string.format("[%s] %s",
					live.category ~= "" and live.category or "?",
					live.promptText ~= "" and live.promptText or "(no prompt)"))
			end
			if metaParagraph and metaParagraph.SetDesc then
				metaParagraph:SetDesc(string.format("%s · round %s · %s",
					tostring(live.promptId or "—"),
					tostring(live.round),
					tostring(live.phase or "")))
			end
		end)
	end

	local function uiLog(msg)
		-- WindUI has no log panel; print only (Notify optional)
		print("[BK] " .. tostring(msg))
	end

	return {
		build = build,
		onSupportChanged = onSupportChanged,
		uiLog = uiLog,
		unload = unload,
		getGui = function() return gui end,
	}
end
