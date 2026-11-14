return function(deps)
	local CFG = deps.Config
	local Bank = deps.Bank
	local Harvest = deps.Harvest
	local log = deps.log
	local onSupportChanged = deps.onSupportChanged

	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local VirtualUser = game:GetService("VirtualUser")
	local LP = Players.LocalPlayer

	local remotes = {}
	local live = {
		matchId = nil,
		round = 0,
		phase = nil,
		promptId = nil,
		promptText = "",
		category = "",
		clarify = "",
		myDone = false,
		supported = false,
	}
	local tried = {}
	local submitting = false

	local function rank(t)
		return CFG.preferTier[t] or 0
	end

	local function bind()
		local root = ReplicatedStorage:WaitForChild("BallKnowledge", 10)
		local folder = root and root:WaitForChild("Remotes", 5)
		if not folder then
			log("no Remotes")
			return false
		end
		remotes.submit = folder:FindFirstChild("SubmitAnswer")
		remotes.matchEvent = folder:FindFirstChild("MatchEvent")
		remotes.tableAction = folder:FindFirstChild("TableAction")
		return remotes.submit ~= nil
	end

	local Net
	pcall(function()
		Net = require(ReplicatedStorage.BallKnowledge.Net)
	end)

	local function getSubmit()
		if Net and Net.Get then
			local ok, rf = pcall(Net.Get, "SubmitAnswer")
			if ok and rf then return rf end
		end
		return remotes.submit
	end

	local StateMod
	pcall(function()
		local c = LP.PlayerScripts:FindFirstChild("BallKnowledgeClient")
		if c then StateMod = require(c.State) end
	end)

	local function setPrompt(prompt)
		local id, isNew = Harvest.notePrompt(prompt)
		if not id then return end
		live.promptId = id
		live.promptText = tostring(prompt.text or "")
		live.category = tostring(prompt.category or "")
		live.clarify = tostring(prompt.clarify or "")
		live.supported = Bank.has(id)
		if isNew then
			log(string.format("Q [%s] %s id=%s bank=%s",
				live.category, live.promptText, id, live.supported and "YES" or "NO"))
		end
		if onSupportChanged then onSupportChanged(live) end
	end

	local function absorbAnswer(id, answer, tier)
		if Harvest.addAnswer(id, answer, tier, rank) then
			Bank.add(id, answer, tier, CFG.preferTier)
			log(string.format("harvest %s -> %s (%s)", id, answer, tostring(tier)))
			if id == live.promptId then
				live.supported = Bank.has(id)
				if onSupportChanged then onSupportChanged(live) end
			end
		end
	end

	local function doSubmit(text)
		if submitting or live.myDone then return end
		local rf = getSubmit()
		if not rf then log("no SubmitAnswer") return end
		if not live.matchId or live.round < 1 then log("no matchId/round") return end

		submitting = true
		tried[live.round] = tried[live.round] or {}
		tried[live.round][text] = true
		log("submit: " .. text)

		local ok, res = pcall(function()
			return rf:InvokeServer({
				text = string.sub(text, 1, 60),
				matchId = live.matchId,
				round = live.round,
			})
		end)
		submitting = false

		if not ok then log("err " .. tostring(res)) return end
		if type(res) ~= "table" then log("bad res") return end

		if res.status == "locked" then
			live.myDone = true
			local display = tostring(res.display or text)
			local tier = tostring(res.tier or "?")
			log("LOCKED " .. display .. " (" .. tier .. ")")
			if live.promptId then absorbAnswer(live.promptId, display, tier) end
		elseif res.status == "suggest" then
			log("suggest " .. tostring(res.display))
			if CFG.confirmSuggest and res.display then
				task.wait(0.35)
				doSubmit(res.display)
			end
		elseif res.status == "rejected" then
			log("rejected")
			if CFG.retryOnRejected then
				task.wait(0.3)
				local n = Bank.next(live.promptId, tried[live.round])
				if n then doSubmit(n) end
			end
		elseif res.status == "skipped" then
			live.myDone = true
			log("skipped")
		else
			log("status " .. tostring(res.status))
		end
		if onSupportChanged then onSupportChanged(live) end
	end

	local function tryAuto()
		if not CFG.auto then return end
		if live.phase ~= "Answering" or live.myDone then return end
		if not live.matchId or live.round < 1 then return end
		if not live.supported then
			log("unsupported — manual")
			return
		end
		local ans = Bank.next(live.promptId, tried[live.round])
		if not ans then log("bank empty") return end
		local d = CFG.delayMin + math.random() * (CFG.delayMax - CFG.delayMin)
		log(string.format("auto %.1fs -> %s", d, ans))
		task.wait(d)
		if live.phase == "Answering" and not live.myDone then
			doSubmit(ans)
		end
	end

	local function onMatchEvent(a, b)
		local data = type(a) == "table" and a or b
		if type(data) ~= "table" then return end

		if data.matchId then live.matchId = data.matchId end
		if data.round then
			if data.round ~= live.round then
				tried[data.round] = {}
				live.myDone = false
			end
			live.round = data.round
		end
		if type(data.prompt) == "table" then setPrompt(data.prompt) end

		if type(data.entries) == "table" then
			live.phase = "Reveal"
			for _, row in ipairs(data.entries) do
				if type(row) == "table" then
					local ans = row.display or row.answer or row.text
					local tier = row.tier or row.rarity
					if ans and live.promptId then
						absorbAnswer(live.promptId, tostring(ans), tostring(tier or "?"))
					end
				end
			end
		end

		if data.prompt and data.statuses then
			live.phase = "Answering"
		elseif data.prompt and data.players and not data.statuses and not data.entries then
			live.phase = "PromptIntro"
		elseif data.entries then
			live.phase = "Reveal"
		end

		if live.phase == "Answering" and not live.myDone then
			task.spawn(tryAuto)
		end
		if onSupportChanged then onSupportChanged(live) end
	end

	local function pollState()
		if not StateMod then return end
		local m = StateMod.match
		if type(m) ~= "table" then return end
		if m.id then live.matchId = m.id end
		if m.round then live.round = m.round end
		if m.phase then live.phase = m.phase end
		if m.myDone ~= nil then live.myDone = m.myDone end
		if type(m.prompt) == "table" then setPrompt(m.prompt) end
	end

	local function start()
		if not bind() then
			log("bind failed")
			return
		end
		if remotes.matchEvent then
			remotes.matchEvent.OnClientEvent:Connect(onMatchEvent)
			log("MatchEvent hooked")
		end
		task.spawn(function()
			while true do
				task.wait(0.5)
				pcall(pollState)
				if onSupportChanged then onSupportChanged(live) end
				if CFG.auto and live.phase == "Answering" and not live.myDone
					and live.supported and live.matchId then
					local t = tried[live.round]
					if not (t and next(t)) and not submitting then
						task.spawn(tryAuto)
					end
				end
			end
		end)
		if CFG.antiAfk then
			task.spawn(function()
				while true do
					task.wait(70 + math.random(0, 25))
					pcall(function()
						VirtualUser:CaptureController()
						VirtualUser:ClickButton2(Vector2.new())
					end)
				end
			end)
		end
		log("core ready")
	end

	return {
		start = start,
		live = live,
		doSubmit = doSubmit,
		tryAuto = tryAuto,
		rank = rank,
	}
end
