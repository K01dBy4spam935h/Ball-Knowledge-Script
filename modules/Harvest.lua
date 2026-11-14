local Harvest = {
	-- [promptId] = { text, category, clarify, answers = { [answerText] = tier } }
	data = {},
	seen = {},
}

function Harvest.notePrompt(prompt)
	if type(prompt) ~= "table" or not prompt.text then return nil end
	local id = tostring(prompt.id or prompt.text)
	local h = Harvest.data[id]
	if not h then
		h = { text = "", category = "", clarify = "", answers = {} }
		Harvest.data[id] = h
	end
	h.text = prompt.text or h.text
	h.category = prompt.category or h.category
	h.clarify = prompt.clarify or h.clarify
	local isNew = not Harvest.seen[id]
	Harvest.seen[id] = true
	return id, isNew, h
end

function Harvest.addAnswer(id, answer, tier, rankFn)
	if not id or not answer or answer == "" then return false end
	local h = Harvest.data[id]
	if not h then
		h = { text = "", category = "", clarify = "", answers = {} }
		Harvest.data[id] = h
	end
	local prev = h.answers[answer]
	local function r(t)
		return rankFn and rankFn(t) or 0
	end
	if not prev or r(tier) > r(prev) then
		h.answers[answer] = tier or prev or "?"
		return true
	end
	return false
end

function Harvest.dump(rankFn)
	local lines = {
		"-- BK harvest " .. os.date("%Y-%m-%d %H:%M:%S"),
		"-- paste answers into modules/Bank.lua under matching id",
		"return {",
	}
	local ids = {}
	for id in pairs(Harvest.data) do table.insert(ids, id) end
	table.sort(ids)

	for _, id in ipairs(ids) do
		local h = Harvest.data[id]
		table.insert(lines, string.format("  [%q] = {", id))
		table.insert(lines, string.format("    text = %q,", h.text or ""))
		table.insert(lines, string.format("    category = %q,", h.category or ""))
		table.insert(lines, string.format("    clarify = %q,", h.clarify or ""))
		table.insert(lines, "    answers = {")
		local rows = {}
		for a, t in pairs(h.answers) do
			table.insert(rows, { a = a, t = t })
		end
		table.sort(rows, function(x, y)
			local rx = rankFn and rankFn(x.t) or 0
			local ry = rankFn and rankFn(y.t) or 0
			return rx > ry
		end)
		for _, row in ipairs(rows) do
			table.insert(lines, string.format("      { text = %q, tier = %q },", row.a, row.t))
		end
		table.insert(lines, "    },")
		table.insert(lines, "  },")
	end
	table.insert(lines, "}")
	local body = table.concat(lines, "\n")

	print("\n========== BK DUMP ==========")
	print(body)
	print("========== END DUMP ==========\n")
	print("-- questions:")
	for _, id in ipairs(ids) do
		local h = Harvest.data[id]
		local n = 0
		for _ in pairs(h.answers) do n = n + 1 end
		print(string.format("[Q] id=%s | cat=%s | answers=%d | %s", id, h.category, n, h.text))
	end

	if writefile then
		pcall(writefile, "BK_Harvest.lua", body)
	end
	return body, #ids
end

function Harvest.count()
	local q, a = 0, 0
	for _, h in pairs(Harvest.data) do
		q = q + 1
		for _ in pairs(h.answers) do a = a + 1 end
	end
	return q, a
end

return Harvest
