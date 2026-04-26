local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)			npcHandler:onCreatureAppear(cid)			end
function onCreatureDisappear(cid)		npcHandler:onCreatureDisappear(cid)			end
function onCreatureSay(cid, type, msg)		npcHandler:onCreatureSay(cid, type, msg)		end
function onThink()		npcHandler:onThink()		end

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end

	local player = Player(cid)
	if(msgcontains(msg, "report")) then
		if(player:getStorageValue(Storage.InServiceofYalahar.Questline) == 7 or player:getStorageValue(Storage.InServiceofYalahar.Questline) == 13) then
			npcHandler:say("A report? What do they think is happening here? <gives an angry and bitter report>. ", cid)
			player:setStorageValue(Storage.InServiceofYalahar.Questline, player:getStorageValue(Storage.InServiceofYalahar.Questline) + 1)
			player:setStorageValue(Storage.InServiceofYalahar.Mission02, player:getStorageValue(Storage.InServiceofYalahar.Mission02) + 1) -- StorageValue for Questlog "Mission 02: Watching the Watchmen"
			npcHandler.topic[cid] = 0
		end
	elseif(msgcontains(msg, "pass")) then
		npcHandler:say("You can {pass} either to the {Factory Quarter} or {Sunken Quarter}. Which one will it be?", cid)
		npcHandlerfocus = 1
	elseif(msgcontains(msg, "factory")) then
		if(npcHandlerfocus == 1) then
			doTeleportThing(cid, {x=31437, y=31131, z=7})
			npcHandlerfocus = 0
		end
	elseif(msgcontains(msg, "sunken")) then
		if(npcHandlerfocus == 1) then
			doTeleportThing(cid, {x=31437, y=31123, z=7})
			npcHandlerfocus = 0
		end
	end
	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
