-- Handles the OTCv8 client extended-shop "buy" packet for the locally
-- injected Premium Time category (see otclientv8 modules/game_shop/shop.lua).
-- The client sends opcode 201 with a JSON payload that looks like:
--   {"action":"buy","data":{"id":"premium_15","cost":200,...}}
-- We pull the offer id, charge the configured cost in tibia coins,
-- credit premium days, and reply with a "message" packet so OTCv8 shows
-- a popup and refreshes the points label.

local SHOP_OPCODE = 201

local PREMIUM_OFFERS = {
	premium_15  = {days = 15,  cost = 200},
	premium_30  = {days = 30,  cost = 300},
	premium_60  = {days = 60,  cost = 500},
	premium_120 = {days = 120, cost = 950},
}

local function jsonEscape(s)
	return s:gsub('\\', '\\\\'):gsub('"', '\\"')
end

local function sendShopMessage(player, title, msg)
	-- "message" packet shows a popup AND, via the trailing status field,
	-- refreshes the "Points: N" label so the deduction is reflected
	-- without the player having to reopen the shop window.
	local response = string.format(
		'{"action":"message","data":{"title":"%s","msg":"%s"},"status":{"points":%d}}',
		jsonEscape(title), jsonEscape(msg), player:getCoins())
	player:sendExtendedOpcode(SHOP_OPCODE, response)
end

function onExtendedOpcode(player, opcode, buffer)
	if opcode ~= SHOP_OPCODE then
		return
	end
	if not buffer:find('"action"%s*:%s*"buy"', 1) then
		return
	end

	local offerId = buffer:match('"id"%s*:%s*"([^"]+)"')
	if not offerId then
		sendShopMessage(player, "Shop Error", "Invalid offer payload.")
		return
	end

	local offer = PREMIUM_OFFERS[offerId]
	if not offer then
		-- Not one of our local offers; ignore so we don't fight any future
		-- server-side shop module.
		return
	end

	local balance = player:getCoins()
	if balance < offer.cost then
		sendShopMessage(player, "Shop Error",
			string.format("You need %d points but only have %d.",
				offer.cost, balance))
		return
	end

	if not player:removeCoins(offer.cost) then
		sendShopMessage(player, "Shop Error", "Could not deduct points.")
		return
	end

	local now = os.time()
	local current = player:getPremiumEndsAt()
	local base = (current and current > now) and current or now
	player:setPremiumEndsAt(base + offer.days * 86400)

	sendShopMessage(player,
		"Successful shop purchase",
		string.format("Premium time of %d days credited to your account.", offer.days))
end
