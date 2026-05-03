 local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)			npcHandler:onCreatureAppear(cid)			end
function onCreatureDisappear(cid)		npcHandler:onCreatureDisappear(cid)			end
function onCreatureSay(cid, type, msg)		npcHandler:onCreatureSay(cid, type, msg)		end
function onThink()		npcHandler:onThink()		end

local voices = {
	{ text = 'Alms! Alms for the poor!' },
	{ text = 'Sir, Ma\'am, have a gold coin to spare?' },
	{ text = 'I need help! Please help me!' }
}

npcHandler:addModule(VoiceModule:new(voices))

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end

	local player = Player(cid)

	if msgcontains(msg, 'cookie') then
		if player:getStorageValue(Storage.WhatAFoolishQuest.Questline) == 31
				and player:getStorageValue(Storage.WhatAFoolishQuest.CookieDelivery.SimonTheBeggar) ~= 1 then
			npcHandler:say('Have you brought a cookie for the poor?', cid)
			npcHandler.topic[cid] = 1
		end
	elseif msgcontains(msg, 'help') then
		npcHandler:say('I need gold. Can you spare 100 gold pieces for me?', cid)
		npcHandler.topic[cid] = 2
	elseif msgcontains(msg, 'yes') then
		if npcHandler.topic[cid] == 1 then
			if not player:removeItem(8111, 1) then
				npcHandler:say('You have no cookie that I\'d like.', cid)
				npcHandler.topic[cid] = 0
				return true
			end

			player:setStorageValue(Storage.WhatAFoolishQuest.CookieDelivery.SimonTheBeggar, 1)
			if player:getCookiesDelivered() == 10 then
				player:addAchievement('Allow Cookies?')
			end

			Npc():getPosition():sendMagicEffect(CONST_ME_GIFT_WRAPS)
			npcHandler:say('Well, it\'s the least you can do for those who live in dire poverty. A single cookie is a bit less than I\'d expected, but better than ... WHA ... WHAT?? MY BEARD! MY PRECIOUS BEARD! IT WILL TAKE AGES TO CLEAR IT OF THIS CONFETTI!', cid)
			npcHandler:releaseFocus(cid)
			npcHandler:resetNpc(cid)
		elseif npcHandler.topic[cid] == 2 then
			if not player:removeMoneyNpc(100) then
				npcHandler:say('You haven\'t got enough money for me.', cid)
				npcHandler.topic[cid] = 0
				return true
			end

			npcHandler:say('Thank you very much. Can you spare 500 more gold pieces for me? I will give you a nice hint.', cid)
			npcHandler.topic[cid] = 3
		elseif npcHandler.topic[cid] == 3 then
			if not player:removeMoneyNpc(500) then
				npcHandler:say('Sorry, that\'s not enough.', cid)
				npcHandler.topic[cid] = 0
				return true
			end

			npcHandler:say('That\'s great! I have stolen something from Dermot. You can buy it for 200 gold. Do you want to buy it?', cid)
			npcHandler.topic[cid] = 4
		elseif npcHandler.topic[cid] == 4 then
			if not player:removeMoneyNpc(200) then
				npcHandler:say('Pah! I said 200 gold. You don\'t have that much.', cid)
				npcHandler.topic[cid] = 0
				return true
			end

			local key = player:addItem(2087, 1)
			if key then
				key:setActionId(3940)
			end
			npcHandler:say('Now you own the hot key.', cid)
			npcHandler.topic[cid] = 0
		end
	elseif msgcontains(msg, 'no') and npcHandler.topic[cid] ~= 0 then
		if npcHandler.topic[cid] == 1 then
			npcHandler:say('I see.', cid)
		elseif npcHandler.topic[cid] == 2 then
			npcHandler:say('Hmm, maybe next time.', cid)
		elseif npcHandler.topic[cid] == 3 then
			npcHandler:say('It was your decision.', cid)
		elseif npcHandler.topic[cid] == 4 then
			npcHandler:say('Ok. No problem. I\'ll find another buyer.', cid)
		end
		npcHandler.topic[cid] = 0
	end
	return true
end

npcHandler:setMessage(MESSAGE_GREET, "Hello |PLAYERNAME|. I am a poor man. Please help me.")
npcHandler:setMessage(MESSAGE_FAREWELL, "Have a nice day.")
npcHandler:setMessage(MESSAGE_WALKAWAY, "Have a nice day.")

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
