--[[
	Answer bank keyed by prompt.id
	Each entry: { text, tier } — best tiers first.
]]

local Bank = {
	art_supplies = {
		{ text = "Copper Plate", tier = "Obscure" },
		{ text = "Blending Stump", tier = "Rare" },
	},
	beauty_products = {
		{ text = "Hair Mask", tier = "Uncommon" },
		{ text = "Lip Mask", tier = "Uncommon" },
	},
	breads = {
		{ text = "Oat Bread", tier = "Rare" },
		{ text = "Pumpernickel", tier = "Uncommon" },
	},
	car_models = {
		{ text = "Club Wagon", tier = "Rare" },
		{ text = "Skyline", tier = "Uncommon" },
	},
	crafts = {
		{ text = "Quilling", tier = "Rare" },
		{ text = "Embroidery", tier = "Familiar" },
	},
	dinosaurs = {
		{ text = "Yi", tier = "Obscure" },
		{ text = "Therizinosaurus", tier = "Rare" },
		{ text = "Microraptor", tier = "Uncommon" },
		{ text = "Carnotaurus", tier = "Uncommon" },
		{ text = "Brontosaurus", tier = "Familiar" },
	},
	kitchen_tools = {
		{ text = "Duck Press", tier = "Obscure" },
		{ text = "Mandoline", tier = "Rare" },
	},
	landforms = {
		{ text = "Fjord", tier = "Uncommon" },
		{ text = "Bay", tier = "Familiar" },
	},
	mario_characters = {
		{ text = "Thwomp", tier = "Familiar" },
		{ text = "Professor E. Gadd", tier = "Familiar" },
	},
	math_topics = {
		{ text = "Category Theory", tier = "Obscure" },
		{ text = "p-adic Numbers", tier = "Obscure" },
		{ text = "Spherical Trigonometry", tier = "Rare" },
	},
	multiples_of_7 = {
		{ text = "91", tier = "Obscure" },
		{ text = "70", tier = "Familiar" },
	},
	soups = {
		{ text = "Kapustnica", tier = "Legendary" },
		{ text = "Zuppa Gallurese", tier = "Obscure" },
	},
	transport = {
		{ text = "Shikara", tier = "Rare" },
		{ text = "Chairlift", tier = "Rare" },
	},
	trees = {
		{ text = "Wollemi Pine", tier = "Legendary" },
		{ text = "Dawn Redwood", tier = "Obscure" },
		{ text = "Mockernut Hickory", tier = "Rare" },
		{ text = "Ginkgo", tier = "Uncommon" },
		{ text = "Apple Tree", tier = "Common" },
	},
	web_browsers = {
		{ text = "Fennec", tier = "Rare" },
		{ text = "Zen Browser", tier = "Uncommon" },
		{ text = "Pale Moon", tier = "Uncommon" },
		{ text = "LibreWolf", tier = "Uncommon" },
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
