return function(deps)
	local CFG = deps.Config
	local Bank = deps.Bank
	local Harvest = deps.Harvest
	local Core = deps.Core
	local log = deps.log

	local UserInputService = game:GetService("UserInputService")
	local CoreGui = game:GetService("CoreGui")

	local gui = {}

	local function build()
		pcall(function()
			local o = CoreGui:FindFirstChild("BK_Exploit")
			if o then o:Destroy() end
		end)

		local sg = Instance.new("ScreenGui")
		sg.Name = "BK_Exploit"
		sg.ResetOnSpawn = false
		sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		sg.Parent = CoreGui

		local frame = Instance.new("Frame")
		frame.Size = UDim2.fromOffset(360, 460)
		frame.Position = UDim2.new(0, 14, 0.5, -230)
		frame.BackgroundColor3 = Color3.fromRGB(16, 18, 28)
		frame.BorderSizePixel = 0
		frame.Parent = sg
		Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -16, 0, 26)
		title.Position = UDim2.fromOffset(8, 6)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBold
		title.TextSize = 15
		title.TextColor3 = Color3.fromRGB(255, 210, 80)
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Text = "Ball Knowledge"
		title.Parent = frame

		gui.support = Instance.new("TextLabel")
		gui.support.Size = UDim2.new(1, -16, 0, 26)
		gui.support.Position = UDim2.fromOffset(8, 34)
		gui.support.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
		gui.support.Font = Enum.Font.GothamBold
		gui.support.TextSize = 12
		gui.support.TextColor3 = Color3.new(1, 1, 1)
		gui.support.Text = "waiting..."
		gui.support.Parent = frame
		Instance.new("UICorner", gui.support).CornerRadius = UDim.new(0, 6)

		gui.prompt = Instance.new("TextLabel")
		gui.prompt.Size = UDim2.new(1, -16, 0, 44)
		gui.prompt.Position = UDim2.fromOffset(8, 66)
		gui.prompt.BackgroundTransparency = 1
		gui.prompt.Font = Enum.Font.Gotham
		gui.prompt.TextSize = 12
		gui.prompt.TextColor3 = Color3.fromRGB(220, 225, 235)
		gui.prompt.TextWrapped = true
		gui.prompt.TextXAlignment = Enum.TextXAlignment.Left
		gui.prompt.TextYAlignment = Enum.TextYAlignment.Top
		gui.prompt.Text = "(no prompt)"
		gui.prompt.Parent = frame

		gui.meta = Instance.new("TextLabel")
		gui.meta.Size = UDim2.new(1, -16, 0, 16)
		gui.meta.Position = UDim2.fromOffset(8, 110)
		gui.meta.BackgroundTransparency = 1
		gui.meta.Font = Enum.Font.Code
		gui.meta.TextSize = 11
		gui.meta.TextColor3 = Color3.fromRGB(130, 140, 160)
		gui.meta.TextXAlignment = Enum.TextXAlignment.Left
		gui.meta.Text = ""
		gui.meta.Parent = frame

		local function btn(text, y, color, cb)
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(1, -16, 0, 28)
			b.Position = UDim2.fromOffset(8, y)
			b.BackgroundColor3 = color
			b.Font = Enum.Font.GothamBold
			b.TextSize = 12
			b.TextColor3 = Color3.new(1, 1, 1)
			b.Text = text
			b.Parent = frame
			Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
			b.MouseButton1Click:Connect(cb)
			return b
		end

		gui.autoBtn = btn(CFG.auto and "Auto: ON" or "Auto: OFF", 132,
			CFG.auto and Color3.fromRGB(35, 130, 60) or Color3.fromRGB(70, 70, 80), function()
			CFG.auto = not CFG.auto
			gui.autoBtn.Text = CFG.auto and "Auto: ON" or "Auto: OFF"
			gui.autoBtn.BackgroundColor3 = CFG.auto and Color3.fromRGB(35, 130, 60) or Color3.fromRGB(70, 70, 80)
			log("auto " .. (CFG.auto and "on" or "off"))
			if CFG.auto then task.spawn(Core.tryAuto) end
		end)

		btn("Submit best now", 166, Color3.fromRGB(45, 95, 170), function()
			local live = Core.live
			local a = Bank.next(live.promptId, nil)
			if a then Core.doSubmit(a) else log("no bank answer") end
		end)

		local box = Instance.new("TextBox")
		box.Size = UDim2.new(1, -16, 0, 26)
		box.Position = UDim2.fromOffset(8, 200)
		box.BackgroundColor3 = Color3.fromRGB(28, 30, 42)
		box.Font = Enum.Font.Gotham
		box.TextSize = 12
		box.TextColor3 = Color3.new(1, 1, 1)
		box.PlaceholderText = "manual answer..."
		box.Text = ""
		box.ClearTextOnFocus = false
		box.Parent = frame
		Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

		btn("Submit manual", 232, Color3.fromRGB(110, 60, 150), function()
			local t = box.Text
			if t and t:gsub("%s", "") ~= "" then Core.doSubmit(t) end
		end)

		btn("Dump new questions", 266, Color3.fromRGB(160, 110, 30), function()
			local _, n = Harvest.dump(Core.rank)
			log("dumped " .. tostring(n) .. " prompts")
		end)

		gui.log = Instance.new("TextLabel")
		gui.log.Size = UDim2.new(1, -16, 0, 140)
		gui.log.Position = UDim2.fromOffset(8, 304)
		gui.log.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
		gui.log.Font = Enum.Font.Code
		gui.log.TextSize = 11
		gui.log.TextColor3 = Color3.fromRGB(170, 180, 195)
		gui.log.TextXAlignment = Enum.TextXAlignment.Left
		gui.log.TextYAlignment = Enum.TextYAlignment.Top
		gui.log.TextWrapped = true
		gui.log.Text = ""
		gui.log.Parent = frame
		Instance.new("UICorner", gui.log).CornerRadius = UDim.new(0, 6)

		local dragging, origin, start
		title.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				origin = i.Position
				start = frame.Position
			end
		end)
		title.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
		end)
		UserInputService.InputChanged:Connect(function(i)
			if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
				local d = i.Position - origin
				frame.Position = UDim2.new(start.X.Scale, start.X.Offset + d.X, start.Y.Scale, start.Y.Offset + d.Y)
			end
		end)

		return gui
	end

	local function onSupportChanged(live)
		if not gui.support then return end
		if live.supported then
			gui.support.Text = "SUPPORTED  " .. tostring(live.promptId)
			gui.support.BackgroundColor3 = Color3.fromRGB(30, 110, 50)
		elseif live.promptId then
			gui.support.Text = "UNSUPPORTED — answer yourself"
			gui.support.BackgroundColor3 = Color3.fromRGB(140, 50, 40)
		else
			gui.support.Text = "waiting..."
			gui.support.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
		end
		if gui.prompt then
			gui.prompt.Text = string.format("[%s] %s",
				live.category ~= "" and live.category or "?",
				live.promptText ~= "" and live.promptText or "(no prompt)")
		end
		if gui.meta then
			gui.meta.Text = string.format("id=%s  round=%s  phase=%s  done=%s",
				tostring(live.promptId or "?"),
				tostring(live.round),
				tostring(live.phase),
				tostring(live.myDone))
		end
	end

	local logs = {}
	local function uiLog(msg)
		table.insert(logs, 1, os.date("%H:%M:%S") .. " " .. tostring(msg))
		while #logs > 30 do table.remove(logs) end
		if gui.log then gui.log.Text = table.concat(logs, "\n") end
	end

	return {
		build = build,
		onSupportChanged = onSupportChanged,
		uiLog = uiLog,
		getGui = function() return gui end,
	}
end
