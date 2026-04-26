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
	if (msgcontains(msg, 'bring') and msgcontains(msg, 'me') and msgcontains(msg, 'to') and msgcontains(msg, 'svargrond') and (not npcHandler:isFocused(cid))) then
		if doPlayerRemoveMoney(cid, 0) == TRUE then
		doTeleportThing(cid,{x=32969, y=31051, z=6})
		npcHandler:addFocus(cid)
		else 
         selfSay('Sorry, you don\'t have enough money.') 
        end
	end
	return true
end	            
        
        -- Don't forget npcHandler = npcHandler in the parameters. It is required for all StdModule functions!
        local travelNode = keywordHandler:addKeyword({'svar'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, text = 'Do you want to travel to svargrond?'})
        	travelNode:addChildKeyword({'yes'}, StdModule.travel, {npcHandler = npcHandler, premium = false, level = 0, cost = 0, destination = {x=32969, y=31051, z=6} })
        	travelNode:addChildKeyword({'no'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, reset = true, text = 'Then stay here.'})
     
		local travelNode = keywordHandler:addKeyword({'xxsvargrond'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, text = 'Do you want to travel to svargrond?'})
        	travelNode:addChildKeyword({'yes'}, StdModule.travel, {npcHandler = npcHandler, premium = false, level = 0, cost = 0, destination = {x=32969, y=31051, z=6} })
        	travelNode:addChildKeyword({'no'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, reset = true, text = 'Then stay here.'})

        keywordHandler:addKeyword({'pass'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, text = 'I can take you to svargrond.'})
        keywordHandler:addKeyword({'travel'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, text = 'I only can offer you my services to svargrond.'})
		keywordHandler:addKeyword({'passage'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, text = 'I only can offer you my services to svargrond.'})
        -- Makes sure the npc reacts when you say hi, bye etc.
		npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback) 
        npcHandler:addModule(FocusModule:new())