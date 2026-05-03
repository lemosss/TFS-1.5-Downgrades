function onSay(player, words, param)
	if not player:getGroup():getAccess() then
		return true
	end

	if player:getAccountType() < ACCOUNT_TYPE_GOD then
		return false
	end

	local split = param:split(",")

	local itemType = ItemType(split[1])
	if itemType:getId() == 0 then
		itemType = ItemType(tonumber(split[1]))
		if tonumber(split[1]) == nil or itemType:getId() == 0 then
			player:sendCancelMessage("There is no item with that id or name.")
			return false
		end
	end

	-- Runes take a separate code path. Each /i creates ONE fresh rune at the
	-- items.xml `charges` count and drops it in a free slot with
	-- FLAG_IGNOREAUTOSTACK. Without that flag the engine's queryDestination
	-- (player.cpp:2727) tries to merge with any matching rune already in the
	-- player's slots — but the merge check uses `count<100` instead of
	-- `getStackMax()`, so a maxed-out fireball (4/4) still "matches" as a
	-- merge target. The merge then runs in internalAddItem with n=0 (nothing
	-- to add) and falls through to addThing(handSlot, newItem), REPLACING
	-- the full rune in hand with a 1-charge rune. Same root cause causes
	-- the SD-overflow-into-hidden-slots when the main backpack fills up.
	-- IGNOREAUTOSTACK skips the merge attempt entirely → the new rune lands
	-- in an actually-free slot.
	if itemType:isRune() then
		local runesToCreate = tonumber(split[2]) or 1
		runesToCreate = math.min(100, math.max(1, runesToCreate))
		local fullCharges = math.max(1, itemType:getCharges())

		local createdAny = false
		for i = 1, runesToCreate do
			local item = Game.createItem(itemType:getId(), fullCharges)
			if not item then break end
			local ret = player:addItemEx(item, false, INDEX_WHEREEVER, FLAG_IGNOREAUTOSTACK)
			if ret ~= RETURNVALUE_NOERROR then
				break -- no room left, stop creating
			end
			createdAny = true
		end
		if createdAny then
			player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
		else
			player:sendCancelMessage("Not enough room.")
		end
		return false
	end

	local count = tonumber(split[2])
	if count ~= nil then
		if itemType:isStackable() then
			count = math.min(10000, math.max(1, count))
		elseif not itemType:isFluidContainer() then
			count = math.min(100, math.max(1, count))
		else
			count = math.max(0, count)
		end
	else
		if not itemType:isFluidContainer() then
			count = 1
		else
			count = 0
		end
	end

	local result = player:addItem(itemType:getId(), count)
	if result ~= nil then
		if not itemType:isStackable() then
			if type(result) == "table" then
				for _, item in ipairs(result) do
					item:decay()
				end
			else
				result:decay()
			end
		end
		player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
	end
	return false
end
