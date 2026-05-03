 local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)


function onCreatureAppear(cid)			npcHandler:onCreatureAppear(cid)			end
function onCreatureDisappear(cid)		npcHandler:onCreatureDisappear(cid)			end
function onCreatureSay(cid, type, msg)		npcHandler:onCreatureSay(cid, type, msg)		end
function onThink()				npcHandler:onThink()					end

function creatureSayCallback(cid, type, msg)
	if(not npcHandler:isFocused(cid)) then
		return false
	end

	local player = Player(cid)

	if(msgcontains(msg, "yes")) then
		if npcHandler.topic[cid] == 5 then
			 if getPlayerItemCount(cid,2655) >= 1 then
      			doPlayerRemoveItem(cid,2655,1)
				npcHandler:say("A {Red Robe}! Great. Here, take this red piece of cloth, I don\'t need it anyway.", cid)
				doPlayerAddItem(cid,5911,1)
				npcHandler.topic[cid] = 0
			else
				npcHandler:say('Are you trying to mess with me?!', cid)
			end
		elseif npcHandler.topic[cid] == 6 then
   			 if getPlayerItemCount(cid,2663) >= 1 then
				doPlayerRemoveItem(cid,2663,1)
				npcHandler:say("A {Mystic Turban}! Great. Here, take this blue piece of cloth, I don\'t need it anyway.", cid)
				doPlayerAddItem(cid,5912,1)
				npcHandler.topic[cid] = 0
			else
				npcHandler:say('Are you trying to mess with me?!', cid)
			end
		elseif npcHandler.topic[cid] == 7 then
   			 if getPlayerItemCount(cid,2652) >= 150 then
				doPlayerRemoveItem(cid,2652,150)
				npcHandler:say("A 150 {Green Tunic}! Great. Here, take this green piece of cloth, I don\'t need it anyway.", cid)
				doPlayerAddItem(cid,5910,1)
				npcHandler.topic[cid] = 0
			else
				npcHandler:say('Are you trying to mess with me?!', cid)
			end
		end
	elseif(msgcontains(msg, "red robe")) then
		npcHandler:say("Have you found a {Red Robe} for me?", cid)
		npcHandler.topic[cid] = 5
	elseif(msgcontains(msg, "mystic turban")) then
		npcHandler:say("Have you found a {Mystic Turban} for me?", cid)
		npcHandler.topic[cid] = 6
	elseif(msgcontains(msg, "green tunic")) then
		npcHandler:say("Have you found {150 Green Tunic} for me?", cid)
		npcHandler.topic[cid] = 7	
	
	end
	
	--Scatterbrained 
	
	if player:getStorageValue(45215) == 1 then
		if(msgcontains(msg, "hat"))  then
			npcHandler:say("Yes, I can help you with fabricating a {dark hat}", cid)			
		end 
		
		if(msgcontains(msg, "dark hat")) then
			npcHandler:say("To create a dark hat, I need one piece of {minotaur leather} and two {bat wings}. Do you have those materials with you by coincidence?", cid)	
			npcHandler.topic[cid] = 8
			
		elseif(msgcontains(msg, "yes")) and npcHandler.topic[cid] == 8 then
			if player:getItemCount(5878) >= 1 and player:getItemCount(5894) >= 2 then
				player:removeItem(5878, 1)
				player:removeItem(5894, 2)
				doPlayerAddItem(player,10046,1)
				player:setStorageValue(45215, 2) 
				npcHandler:say("A little stitch here and a little stitch there... perfect! Here you are. With the best wishes to your master.", cid)
			else
				npcHandler:say("To create a dark hat, I need {one} piece of minotaur leather and {two} bat wings. Do you have those materials with you by coincidence?", cid)	
			end
			npcHandler.topic[cid] = 9
		end
	end
	
	
	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
