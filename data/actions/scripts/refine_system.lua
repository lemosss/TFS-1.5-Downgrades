local cfg = {
	attribute = "refine_info", -- (NÃO MEXA!)

	fail_effect = {2, {x = 0, y = 0}}, -- efeito e offset caso falhar
	success_effect = {12, {x = 0, y = 0}}, -- efeito e offset caso bem sucedido

	items = {
		-- [id do item refinador]
		[8065] = {
			refines = {
				-- [nivel do refine]
				-- level = level necessario para poder refinar
				-- price = preço para poder refinar
				-- increment = quantidade de arm/def/atk que vai aumentar
				-- chance = chance de sucesso
				-- regress_chance = chance de regredir em caso de falha
				[1] = {level = 40, price = 10000, increment = 1, chance = 90, regress_chance = 0},
				[2] = {level = 50, price = 15000, increment = 1, chance = 75, regress_chance = 1},
				[3] = {level = 50, price = 20000, increment = 1, chance = 60, regress_chance = 5},
				[4] = {level = 50, price = 30000, increment = 1, chance = 45, regress_chance = 5},
				[5] = {level = 60, price = 40000, increment = 1, chance = 35, regress_chance = 8},
				[6] = {level = 70, price = 60000, increment = 1, chance = 20, regress_chance = 10},
			}
		},

		[8066] = {
			refines = {
				[7] = {level = 80, price = 130000, increment = 2, chance = 18, regress_chance = 15},
				[8] = {level = 90, price = 150000, increment = 2, chance = 15, regress_chance = 17},
				[9] = {level = 100, price = 200000, increment = 2, chance = 10, regress_chance = 20},
				[10] = {level = 120, price = 300000, increment = 2, chance = 5, regress_chance = 25},
				[11] = {level = 140, price = 350000, increment = 2, chance = 4, regress_chance = 30},
				[12] = {level = 150, price = 400000, increment = 2, chance = 3, regress_chance = 35},
			}
		},
	}
}

do
	for _, t in pairs(cfg.items) do
		for l in pairs(t.refines) do
			if (not t.min or l < t.min) then
				t.min = l
			end

			if (not t.max or l > t.max) then
				t.max = l
			end
		end
	end
end

math.randomseed(os.mtime())
local function getItemAttributes(item)
	local itemInfo = getItemInfo(item.itemid)
	itemInfo.refine = {level = 0}
	for i = 1, math.huge do
		local attributeStr = getItemAttribute(item.uid, cfg.attribute .. "_" .. i)
		if (not attributeStr) then
			break
		end

		itemInfo.refine.level = i
		itemInfo.refine[i] = {}
		for attribute, value in attributeStr:gmatch("([^;]-):(%d+)") do
			itemInfo.refine[i][attribute] = tonumber(value)
		end
	end

	itemInfo.name = getItemAttribute(item.uid, "name") or itemInfo.name
	itemInfo.attack = tonumber(getItemAttribute(item.uid, "attack")) or itemInfo.attack
	itemInfo.defense = tonumber(getItemAttribute(item.uid, "defense")) or itemInfo.defense
	itemInfo.armor = tonumber(getItemAttribute(item.uid, "armor")) or itemInfo.armor
	return itemInfo
end

function onUse(cid, item, fromPosition, itemEx, toPosition)
	local t = cfg.items[item.itemid]
	if (not t) then
		return false
	end

	-- 1 = players, 2 = monsters, 3 = npcs, +4 = items
	if (itemEx.itemid <= 3) then
		doPlayerSendCancel(cid, "You can only use this on items.")
		doSendMagicEffect(getThingPosition(cid), CONST_ME_POFF)
		return true
	end

	local attributes = getItemAttributes(itemEx)
	if (attributes.armor == 0 and attributes.defense == 0 and attributes.attack == 0) then
		doPlayerSendCancel(cid, "You can only use this on equipment and weapons.")
		doSendMagicEffect(getThingPosition(cid), CONST_ME_POFF)
		return true
	end

	local nextRefineLevel = attributes.refine.level + 1
	if (nextRefineLevel < t.min) then
		doPlayerSendCancel(cid, "This item can only be used on refined items starting at +6.")
		doSendMagicEffect(getThingPosition(cid), CONST_ME_POFF)
		return true
	elseif (nextRefineLevel > t.max) then
		doPlayerSendCancel(cid, "This item cannot be further refined with this. Use another refiner.")
		doSendMagicEffect(getThingPosition(cid), CONST_ME_POFF)
		return true
	end

	local nextRefine = t.refines[nextRefineLevel]
	if (not nextRefine) then
		doPlayerSendCancel(cid, "You cannot refine this item.")
		doSendMagicEffect(getThingPosition(cid), CONST_ME_POFF)
		return true
	end

	if (getPlayerLevel(cid) < nextRefine.level) then
		doPlayerSendCancel(cid, "You need to be level " .. nextRefine.level .. " to refine this item.")
		doSendMagicEffect(getThingPosition(cid), CONST_ME_POFF)
		return true
	end

	if (not doPlayerRemoveMoney(cid, nextRefine.price)) then
		doPlayerSendCancel(cid, "You need " .. nextRefine.price .. "gps to refine this item.")
		doSendMagicEffect(getThingPosition(cid), CONST_ME_POFF)
		return true
	end

	doRemoveItem(item.uid, 1)

	local position = getThingPosition(itemEx.uid)
	if (math.random(1, 100) <= nextRefine.chance) then
		local attributeStr = ""
		if (attributes.armor > 0) then
			doItemSetAttribute(itemEx.uid, "armor", attributes.armor + nextRefine.increment)
			attributeStr = attributeStr .. "armor:" .. nextRefine.increment .. ";"
		end

		if (attributes.defense > 0) then
			doItemSetAttribute(itemEx.uid, "defense", attributes.defense + nextRefine.increment)
			attributeStr = attributeStr .. "defense:" .. nextRefine.increment .. ";"
		end

		if (attributes.attack > 0) then
			doItemSetAttribute(itemEx.uid, "attack", attributes.attack + nextRefine.increment)
			attributeStr = attributeStr .. "attack:" .. nextRefine.increment .. ";"
		end

		doItemSetAttribute(itemEx.uid, (cfg.attribute .. "_" .. nextRefineLevel), attributeStr)
		local newName, count = attributes.name:gsub("%+%d+", ("+" .. nextRefineLevel), 1)
		if (count == 0) then
			newName = attributes.name .. " +" .. nextRefineLevel
		end

		doItemSetAttribute(itemEx.uid, "name", newName)

		doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "[Congratulations] Refining was successful..")
		position.x = position.x + cfg.success_effect[2].x
		position.y = position.y + cfg.success_effect[2].y
		doSendMagicEffect(position, cfg.success_effect[1])
	else
		local message = "[FAIL] Refining failed..."
		if (attributes.refine.level > 0 and math.random(1, 100) <= nextRefine.regress_chance) then
			message = message .. " Item regressed refining."

			local newName
			if (attributes.refine.level == 1) then
				newName = attributes.name:gsub("%+%d+", "", 1)
			else
				newName = attributes.name:gsub("%+%d+", ("+" .. attributes.refine.level - 1), 1)
			end

			doItemSetAttribute(itemEx.uid, "name", newName)
			doItemEraseAttribute(itemEx.uid, (cfg.attribute .. "_" .. attributes.refine.level))

			local currentRefine = attributes.refine[attributes.refine.level]
			if (currentRefine) then
				for attribute, value in pairs(currentRefine) do
					doItemSetAttribute(itemEx.uid, attribute, attributes[attribute] - value)
				end
			end
		end

		doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, message)
		position.x = position.x + cfg.fail_effect[2].x
		position.y = position.y + cfg.fail_effect[2].y
		doSendMagicEffect(position, cfg.fail_effect[1])
	end
	return true
end
