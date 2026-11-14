--[[
	Answer bank keyed by prompt.id
	Each entry: list of { text, tier } sorted best-first at runtime.
	Fill this from harvest dumps or by hand.
]]

local Bank = {
	-- example seeds (replace/expand with harvest)
	trees = {
		{ text = "Mockernut Hickory", tier = "Rare" },
		{ text = "Dawn Redwood", tier = "Obscure" },
		{ text = "Wollemi Pine", tier = "Legendary" },
		{ text = "Ginkgo", tier = "Uncommon" },
	},
	dinosaurs = {
		{ text = "Therizinosaurus", tier = "Rare" },
		{ text = "Microraptor", tier = "Uncommon" },
		{ text = "Carnotaurus", tier = "Uncommon" },
	},
	math_topics = {
		{ text = "Spherical Trigonometry", tier = "Rare" },
		{ text = "Category Theory", tier = "Obscure" },
		{ text = "p-adic Numbers", tier = "Obscure" },
	},
}

function Bank.get(id)
	return Bank[id]
end

function Bank.has(id)
	local list = Bank[id]
	return type(list) == "table" and #list > 0
end

function Bank.add(id, text, tier, preferTier)
	if not id or not text or text == "" then return false end
	Bank[id] = Bank[id] or {}
	local rank = preferTier or {}
	local function r(t) return rank[t] or 0 end
	for _, row in ipairs(Bank[id]) do
		if row.text == text then
			if r(tier) > r(row.tier) then
				row.tier = tier
				return true
			end
			return false
		end
	end
	table.insert(Bank[id], { text = text, tier = tier or "?" })
	table.sort(Bank[id], function(a, b) return r(a.tier) > r(b.tier) end)
	return true
end

function Bank.next(id, triedSet)
	local list = Bank[id]
	if not list then return nil end
	triedSet = triedSet or {}
	for _, row in ipairs(list) do
		if not triedSet[row.text] then
			return row.text, row.tier
		end
	end
	return nil
end

function Bank.allIds()
	local ids = {}
	for k, v in pairs(Bank) do
		if type(v) == "table" and type(k) == "string" then
			table.insert(ids, k)
		end
	end
	table.sort(ids)
	return ids
end

return Bank
