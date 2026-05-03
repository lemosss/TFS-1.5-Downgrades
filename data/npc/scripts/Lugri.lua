 local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)			npcHandler:onCreatureAppear(cid)			end
function onCreatureDisappear(cid)		npcHandler:onCreatureDisappear(cid)			end
function onCreatureSay(cid, type, msg)		npcHandler:onCreatureSay(cid, type, msg)		end
function onThink()				npcHandler:onThink()					end

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end
	local player = Player(cid)
	if msgcontains(msg, "task") then
		if player:getStorageValue(Storage.KillingInTheNameOf.LugriNecromancers) <= 0 then
			npcHandler:say({
				"What? Who are you to imply I need help from a worm like you? ...",
				"I don't need help. But if you desperately wish to do something to earn the favour of Zathroth, feel free. Don't expect any reward though. ...",
				"Do you want to help and serve Zathroth out of your own free will, without demanding payment or recognition?"
			}, cid)
			npcHandler.topic[cid] = 7
		elseif player:getStorageValue(Storage.KillingInTheNameOf.LugriNecromancers) == 1 then
			if player:getStorageValue(Storage.KillingInTheNameOf.LugriNecromancerCount) >= 4000 then
				npcHandler:say({
					"You've slain a mere {4000 necromancers and priestesses}. Still, you've shown some dedication. Maybe that means you can kill one of those so-called 'leaders' too. ...",
					"Deep under Drefia, a necromancer called Necropharus is hiding in the Halls of Sacrifice. I'll place a spell on you with which you will be able to pass his weak protective gate. ...",
					"Know that this will be your only chance to enter his room. If you leave it or die, you won't be able to return. We'll see if you really dare enter those halls."
				}, cid)
				player:setStorageValue(17521, 1)
				player:setStorageValue(Storage.KillingInTheNameOf.LugriNecromancers, 2)
			else
				npcHandler:say("Come back when you have slain {4000 necromancers and priestesses!}", cid)
			end
		elseif player:getStorageValue(Storage.KillingInTheNameOf.LugriNecromancers) == 2 then
			npcHandler:say({
				"So you had the guts to enter that room. Well, it's all fake magic anyway and no real threat. ...",
				"What are you looking at me for? Waiting for something? I told you that there was no reward. Despite being allowed to stand before me without being squashed like a bug. Get out of my sight!"
			}, cid)
			player:setStorageValue(Storage.KillingInTheNameOf.LugriNecromancers, 3)
		elseif player:getStorageValue(Storage.KillingInTheNameOf.LugriNecromancers) == 3 then
			npcHandler:say("You can't live without serving, can you? Although you are quite annoying, you're still somewhat useful. Continue killing Necromancers and Priestesses for me. 1000 are enough this time. What do you say?", cid)
			npcHandler.topic[cid] = 8
		end
	elseif msgcontains(msg, "yes") then
		if npcHandler.topic[cid] == 7 then
			npcHandler:say({
				"You do? I mean - wise decision. Let me explain. By now, Tibia has been overrun by numerous followers of different cults and beliefs. The true Necromancers died or left Tibia long ago, shortly after their battle was lost. ...",
				"What is left are mainly pseudo-dark pretenders, the old wisdom and power being far beyond their grasp. They think they have the right to tap that dark power, but they don't. ...",
				"I want you to eliminate them. As many as you can. All of the upstart necromancer orders, and those priestesses. And as I said, don't expect a reward - this is what has to be done to cleanse Tibia of its false dark prophets."
			}, cid)

			-- aqui
			player:setStorageValue(JOIN_STOR, 1)
			-- aqui
			player:setStorageValue(Storage.KillingInTheNameOf.LugriNecromancers, 1)
			player:setStorageValue(Storage.KillingInTheNameOf.LugriNecromancerCount, 0)
		elseif npcHandler.topic[cid] == 8 then
			npcHandler:say("Good. Then go.", cid)
			player:setStorageValue(Storage.KillingInTheNameOf.LugriNecromancers, 4)
		end
	elseif msgcontains(msg, "no") then
		if npcHandler.topic[cid] > 1 then
			npcHandler:say("Then no.", cid)
			npcHandler.topic[cid] = 0
		end
	end
	return true
end

npcHandler:setMessage(MESSAGE_GREET, "What is it that you want, |PLAYERNAME|?")
npcHandler:setMessage(MESSAGE_FAREWELL, "Bye.")
npcHandler:setMessage(MESSAGE_WALKAWAY, "Bye.")

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
