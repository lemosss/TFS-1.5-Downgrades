-- Staff-only utility. Regular players read their balance via the Store
-- window in the OTCv8 client (the "Points: N" label) — they shouldn't see
-- this command at all, including the read-only form.
--
-- /coins                         -> shows your own balance
-- /coins add <amount>            -> credits yourself
-- /coins set <amount>            -> overwrites your balance
-- /coins give <player> <amount>  -> credits another player
function onSay(player, words, param)
	if player:getAccountType() < ACCOUNT_TYPE_GAMEMASTER then
		return true -- silently swallow for non-staff so the command isn't discoverable
	end

	local args = param:split(" ")
	local sub = args[1]

	if not sub or sub == "" then
		player:sendTextMessage(MESSAGE_INFO_DESCR,
			"You have " .. player:getCoins() .. " coin(s).")
		return false
	end

	if sub == "add" then
		local amount = tonumber(args[2])
		if not amount or amount <= 0 then
			player:sendTextMessage(MESSAGE_INFO_DESCR, "Usage: /coins add <amount>")
			return false
		end
		player:addCoins(amount)
		player:sendTextMessage(MESSAGE_INFO_DESCR,
			"Added " .. amount .. " coin(s). New balance: " .. player:getCoins())
	elseif sub == "set" then
		local amount = tonumber(args[2])
		if not amount or amount < 0 then
			player:sendTextMessage(MESSAGE_INFO_DESCR, "Usage: /coins set <amount>")
			return false
		end
		player:setCoins(amount)
		player:sendTextMessage(MESSAGE_INFO_DESCR,
			"Set balance to " .. amount .. " coin(s).")
	elseif sub == "give" then
		local target = Player(args[2] or "")
		local amount = tonumber(args[3])
		if not target or not amount or amount <= 0 then
			player:sendTextMessage(MESSAGE_INFO_DESCR, "Usage: /coins give <player> <amount>")
			return false
		end
		target:addCoins(amount)
		player:sendTextMessage(MESSAGE_INFO_DESCR,
			"Gave " .. amount .. " coin(s) to " .. target:getName() ..
			". Their balance: " .. target:getCoins())
	else
		player:sendTextMessage(MESSAGE_INFO_DESCR,
			"Usage: /coins | /coins add <n> | /coins set <n> | /coins give <player> <n>")
	end
	return false
end
