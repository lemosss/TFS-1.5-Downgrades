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
	if (msgcontains(msg, 'bring') and msgcontains(msg, 'me') and msgcontains(msg, 'to') and msgcontains(msg, 'svaasdasdr') and (not npcHandler:isFocused(cid))) then
		if doPlayerRemoveMoney(cid, 60) == TRUE then
		doTeleportThing(cid,{x = 32871, y = 31024, z = 4})
		npcHandler:addFocus(cid)
		else 
         selfSay('Sorry, you don\'t have enough money.') 
        end
	elseif (msgcontains(msg, 'bring') and msgcontains(msg, 'me') and msgcontains(msg, 'to') and msgcontains(msg, 'svargrasdasdond') and (not npcHandler:isFocused(cid))) then
		if doPlayerRemoveMoney(cid, 60) == TRUE then
		doTeleportThing(cid,{x = 32871, y = 31024, z = 4})
		npcHandler:addFocus(cid)
		else 
         selfSay('Sorry, you don\'t have enough money.') 
        end
	elseif (msgcontains(msg, 'bring') and msgcontains(msg, 'me') and msgcontains(msg, 'to') and msgcontains(msg, 'femor hills') and (not npcHandler:isFocused(cid))) then
		if doPlayerRemoveMoney(cid, 60) == TRUE then
		doTeleportThing(cid,{x = 32535, y = 31837, z = 4})
		npcHandler:addFocus(cid)
		else 
         selfSay('Sorry, you don\'t have enough money.') 
        end
	elseif (msgcontains(msg, 'bring') and msgcontains(msg, 'me') and msgcontains(msg, 'to') and msgcontains(msg, 'hills') and (not npcHandler:isFocused(cid))) then
		if doPlayerRemoveMoney(cid, 60) == TRUE then
		doTeleportThing(cid,{x = 32535, y = 31837, z = 4})
		npcHandler:addFocus(cid)
		else 
         selfSay('Sorry, you don\'t have enough money.') 
        end
	elseif (msgcontains(msg, 'bring') and msgcontains(msg, 'me') and msgcontains(msg, 'to') and msgcontains(msg, 'hill') and (not npcHandler:isFocused(cid))) then
		if doPlayerRemoveMoney(cid, 60) == TRUE then
		doTeleportThing(cid,{x = 32535, y = 31837, z = 4})
		npcHandler:addFocus(cid)
		else 
         selfSay('Sorry, you don\'t have enough money.') 
        end
	elseif (msgcontains(msg, 'bring') and msgcontains(msg, 'me') and msgcontains(msg, 'to') and msgcontains(msg, 'darashia') and (not npcHandler:isFocused(cid))) then
		if doPlayerRemoveMoney(cid, 60) == TRUE then
		doTeleportThing(cid,{x=33270, y=32441, z=6})
		npcHandler:addFocus(cid)
		else 
         selfSay('Sorry, you don\'t have enough money.') 
        end
	end
	return true
end	            
        
        -- Don't forget npcHandler = npcHandler in the parameters. It is required for all StdModule functions!
        local travelNode = keywordHandler:addKeyword({'darashia'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, text = 'Do you want to fly to darashia for 40 gold coins'})
        	travelNode:addChildKeyword({'yes'}, StdModule.travel, {npcHandler = npcHandler, premium = false, level = 0, cost = 40, destination = {x=33270, y=32441, z=6} })
        	travelNode:addChildKeyword({'no'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, reset = true, text = 'Then stay here.'})

        local travelNode = keywordHandler:addKeyword({'femor hills'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, text = 'Do you want to fly to fermo hills for 60 gold coins?'})
        	travelNode:addChildKeyword({'yes'}, StdModule.travel, {npcHandler = npcHandler, premium = false, level = 0, cost = 60, destination = {x = 32535, y = 31837, z = 4} })
        	travelNode:addChildKeyword({'no'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, reset = true, text = 'Then stay here.'})

        local travelNode = keywordHandler:addKeyword({'hills'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, text = 'Do you want to fly to fermo hills for 60 gold coins?'})
        	travelNode:addChildKeyword({'yes'}, StdModule.travel, {npcHandler = npcHandler, premium = false, level = 0, cost = 60, destination = {x = 32535, y = 31837, z = 4} })
        	travelNode:addChildKeyword({'no'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, reset = true, text = 'Then stay here.'})

        local travelNode = keywordHandler:addKeyword({'hill'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, text = 'Do you want to fly to fermo hills for 60 gold coins?'})
        	travelNode:addChildKeyword({'yes'}, StdModule.travel, {npcHandler = npcHandler, premium = false, level = 0, cost = 60, destination = {x = 32535, y = 31837, z = 4} })
        	travelNode:addChildKeyword({'no'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, reset = true, text = 'Then stay here.'})
			
		local travelNode = keywordHandler:addKeyword({'xxsasdvargrond'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, text = 'Do you want to fly to svargrond for 60 gold coins?'})
        	travelNode:addChildKeyword({'yes'}, StdModule.travel, {npcHandler = npcHandler, premium = false, level = 0, cost = 60, destination = {x = 32871, y = 31024, z = 4} })
        	travelNode:addChildKeyword({'no'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, reset = true, text = 'Then stay here.'})
			
        keywordHandler:addKeyword({'fly'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, text = 'I can take you to Femor hills and Darashia.'})
        keywordHandler:addKeyword({'travel'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, text = 'I only can offer you my services to Femor Hills and darashia.'})
        -- Makes sure the npc reacts when you say hi, bye etc.
		npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback) 
        npcHandler:addModule(FocusModule:new())
