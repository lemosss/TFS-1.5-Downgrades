local keywordHandler = KeywordHandler:new()
        local npcHandler = NpcHandler:new(keywordHandler)
        NpcSystem.parseParameters(npcHandler)
        
        
        
        -- OTServ event handling functions start
        function onCreatureAppear(cid)				npcHandler:onCreatureAppear(cid) end
        function onCreatureDisappear(cid) 			npcHandler:onCreatureDisappear(cid) end
        function onCreatureSay(cid, type, msg) 	npcHandler:onCreatureSay(cid, type, msg) end
        function onThink() 						npcHandler:onThink() end
        -- OTServ event handling functions end
 local function creatureSayCallback(cid, type, msg)
	
	local talkUser = NPCHANDLER_CONVBEHAVIOR == CONVERSATION_DEFAULT and 0 or cid
	
	if (msgcontains(msg, 'bring') and msgcontains(msg, 'me') and msgcontains(msg, 'to')) then
        local storageExhaust = 5555
        if exhaustion.get(cid, storageExhaust) then
            return true
        end
        exhaustion.set(cid, storageExhaust, 2) -- 2 seconds
    end
	if (msgcontains(msg, 'bring') and msgcontains(msg, 'me') and msgcontains(msg, 'to') and msgcontains(msg, 'tyrsung') and (not npcHandler:isFocused(cid))) then
		if doPlayerRemoveMoney(cid, 60) == TRUE then
		doTeleportThing(cid,{x=32951, y=31154, z=7})
		npcHandler:addFocus(cid)
		else 
         selfSay('Sorry, you don\'t have enough money.') 
        end
	elseif (msgcontains(msg, 'bring') and msgcontains(msg, 'me') and msgcontains(msg, 'to') and msgcontains(msg, 'okolnir') and (not npcHandler:isFocused(cid))) then
		if doPlayerRemoveMoney(cid, 160) == TRUE then
		doTeleportThing(cid,{x = 32843, y = 31308, z = 7})
		npcHandler:addFocus(cid)
		else 
         selfSay('Sorry, you don\'t have enough money.') 
        end
	elseif (msgcontains(msg, 'bring') and msgcontains(msg, 'me') and msgcontains(msg, 'to') and msgcontains(msg, 'helheim') and (not npcHandler:isFocused(cid))) then
		if doPlayerRemoveMoney(cid, 160) == TRUE then
		doTeleportThing(cid,{x=33080, y=31100, z=7})
		npcHandler:addFocus(cid)
		else 
         selfSay('Sorry, you don\'t have enough money.') 
        end
	end
	return true
end	            
        
        -- Don't forget npcHandler = npcHandler in the parameters. It is required for all StdModule functions!
        local travelNode = keywordHandler:addKeyword({'tyrsung'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, text = 'Do you want to travel to Tyrsung for 60 gold coins'})
        	travelNode:addChildKeyword({'yes'}, StdModule.travel, {npcHandler = npcHandler, premium = false, level = 0, cost = 60, destination = {x=32951, y=31154, z=7} })
        	travelNode:addChildKeyword({'no'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, reset = true, text = 'Then stay here.'})

        local travelNode = keywordHandler:addKeyword({'okolnir'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, text = 'Do you want to travel to Okolnir for 160 gold coins?'})
        	travelNode:addChildKeyword({'yes'}, StdModule.travel, {npcHandler = npcHandler, premium = false, level = 0, cost = 160, destination = {x = 32843, y = 31308, z = 7} })
        	travelNode:addChildKeyword({'no'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, reset = true, text = 'Then stay here.'})
        
        local travelNode = keywordHandler:addKeyword({'helheim'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, text = 'Do you want to travel to Helheim for 160 gold coins?'})
        	travelNode:addChildKeyword({'yes'}, StdModule.travel, {npcHandler = npcHandler, premium = false, level = 0, cost = 160, destination = {x = 33080, y=31100, z=7} })
        	travelNode:addChildKeyword({'no'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, reset = true, text = 'Then stay here.'})

        keywordHandler:addKeyword({'pass'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, text = 'I can take you to Helheim, Okolnir, Tyrsung.'})
        keywordHandler:addKeyword({'travel'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, text = 'I only can offer you my services to Helheim, Okolnir, Tyrsung.'})
        -- Makes sure the npc reacts when you say hi, bye etc.
		npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback) 
        npcHandler:addModule(FocusModule:new())