local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

local vocation = {}
local town = {}
local destination = {}

-- Canonical Tibia 8.0 mainland cities
-- town_id values must match the towns embedded in the loaded .otbm
-- temple position is the spawn point inside each town's temple
local TOWNS = {
	thais       = {id = 1, pos = Position(32369, 32241, 7)},
	carlin      = {id = 2, pos = Position(32360, 31782, 7)},
	venore      = {id = 3, pos = Position(32957, 32076, 7)},
	abdendriel  = {id = 4, pos = Position(32732, 31634, 7)},
}

-- Aliases the player might say (Oracle keywords)
local TOWN_KEYWORDS = {
	thais      = "thais",
	carlin     = "carlin",
	venore     = "venore",
	["ab'dendriel"] = "abdendriel",
	abdendriel = "abdendriel",
	["ab dendriel"] = "abdendriel",
}

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

local function greetCallback(cid)
	local player = Player(cid)
	local level = player:getLevel()
	if level < 8 then
		npcHandler:say("CHILD! COME BACK WHEN YOU HAVE GROWN UP!", cid)
		return false
	elseif player:getVocation():getId() > 0 then
		npcHandler:say("YOU ALREADY HAVE A VOCATION!", cid)
		return false
	end
	return true
end

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end

	local lowmsg = msg:lower()

	if msgcontains(lowmsg, "yes") and npcHandler.topic[cid] == 0 then
		npcHandler:say("IN WHICH TOWN DO YOU WANT TO LIVE: {THAIS}, {CARLIN}, {VENORE}, OR {AB'DENDRIEL}?", cid)
		npcHandler.topic[cid] = 1
	elseif npcHandler.topic[cid] == 1 then
		local matched_town = nil
		for keyword, town_key in pairs(TOWN_KEYWORDS) do
			if msgcontains(lowmsg, keyword) then
				matched_town = TOWNS[town_key]
				break
			end
		end

		if matched_town then
			town[cid] = matched_town.id
			destination[cid] = matched_town.pos
			npcHandler:say("AND WHAT PROFESSION HAVE YOU CHOSEN: {KNIGHT}, {PALADIN}, {SORCERER}, OR {DRUID}?", cid)
			npcHandler.topic[cid] = 2
		else
			npcHandler:say("IN WHICH TOWN DO YOU WANT TO LIVE: {THAIS}, {CARLIN}, {VENORE}, OR {AB'DENDRIEL}?", cid)
		end
	elseif npcHandler.topic[cid] == 2 then
		if msgcontains(lowmsg, "sorcerer") then
			npcHandler:say("A SORCERER! ARE YOU SURE? THIS DECISION IS IRREVERSIBLE!", cid)
			npcHandler.topic[cid] = 3
			vocation[cid] = 1
		elseif msgcontains(lowmsg, "druid") then
			npcHandler:say("A DRUID! ARE YOU SURE? THIS DECISION IS IRREVERSIBLE!", cid)
			npcHandler.topic[cid] = 3
			vocation[cid] = 2
		elseif msgcontains(lowmsg, "paladin") then
			npcHandler:say("A PALADIN! ARE YOU SURE? THIS DECISION IS IRREVERSIBLE!", cid)
			npcHandler.topic[cid] = 3
			vocation[cid] = 3
		elseif msgcontains(lowmsg, "knight") then
			npcHandler:say("A KNIGHT! ARE YOU SURE? THIS DECISION IS IRREVERSIBLE!", cid)
			npcHandler.topic[cid] = 3
			vocation[cid] = 4
		else
			npcHandler:say("{KNIGHT}, {PALADIN}, {SORCERER}, OR {DRUID}?", cid)
		end
	elseif npcHandler.topic[cid] == 3 then
		if msgcontains(lowmsg, "yes") then
			local player = Player(cid)
			npcHandler:say("SO BE IT!", cid)
			player:setVocation(Vocation(vocation[cid]))
			player:setTown(Town(town[cid]))

			local dest = destination[cid]
			npcHandler:releaseFocus(cid)
			player:teleportTo(dest)
			player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
			dest:sendMagicEffect(CONST_ME_TELEPORT)
		else
			npcHandler:say("THEN WHAT? {KNIGHT}, {PALADIN}, {SORCERER}, OR {DRUID}?", cid)
			npcHandler.topic[cid] = 2
		end
	end
	return true
end

npcHandler:setMessage(MESSAGE_GREET, "ARE YOU PREPARED TO FACE YOUR DESTINY, |PLAYERNAME|?")
npcHandler:setMessage(MESSAGE_FAREWELL, "COME BACK WHEN YOU ARE PREPARED TO FACE YOUR DESTINY!")
npcHandler:setMessage(MESSAGE_WALKAWAY, "COME BACK WHEN YOU ARE PREPARED TO FACE YOUR DESTINY!")
npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
