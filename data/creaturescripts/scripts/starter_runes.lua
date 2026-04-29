-- One-shot starter pack: give 50 blank runes to mage characters on first login.
-- Tracked via storage 88888 so it doesn't repeat.

local STORAGE_KEY = 88888
local MAGE_VOCATIONS = {[1] = true, [2] = true, [5] = true, [6] = true}  -- Sorc/Druid/MS/ED

function onLogin(player)
	if player:getStorageValue(STORAGE_KEY) == 1 then
		return true
	end

	if not MAGE_VOCATIONS[player:getVocation():getId()] then
		return true
	end

	player:addItem(2260, 50)  -- 50 blank runes
	player:setStorageValue(STORAGE_KEY, 1)
	player:sendTextMessage(MESSAGE_INFO_DESCR, "Welcome! You received 50 blank runes to start conjuring.")
	return true
end
