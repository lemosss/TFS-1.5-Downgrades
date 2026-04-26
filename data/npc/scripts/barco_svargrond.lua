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
	if (msgcontains(msg, 'bring') and msgcontains(msg, 'me') and msgcontains(msg, 'to') and msgcontains(msg, 'carlin') and (not npcHandler:isFocused(cid))) then
		if doPlayerRemoveMoney(cid, 110) == TRUE then
		doTeleportThing(cid,{x=32387, y=31820, z=7})
		npcHandler:addFocus(cid)
		else 
         selfSay('Sorry, you don\'t have enough money.') 
        end
	elseif (msgcontains(msg, 'bring') and msgcontains(msg, 'me') and msgcontains(msg, 'to') and msgcontains(msg, 'thais') and (not npcHandler:isFocused(cid))) then
		if doPlayerRemoveMoney(cid, 160) == TRUE then
		doTeleportThing(cid,{x=32313, y=32212, z=7})
		npcHandler:addFocus(cid)
		else 
         selfSay('Sorry, you don\'t have enough money.') 
        end
	elseif (msgcontains(msg, 'bring') and msgcontains(msg, 'me') and msgcontains(msg, 'to') and msgcontains(msg, 'venore') and (not npcHandler:isFocused(cid))) then
		if doPlayerRemoveMoney(cid, 40) == TRUE then
		doTeleportThing(cid,{x=32954, y=32022, z=7})
		npcHandler:addFocus(cid)
		else 
         selfSay('Sorry, you don\'t have enough money.') 
        end	
	end
	return true
end	       
        
        -- Don't forget npcHandler = npcHandler in the parameters. It is required for all StdModule functions!
	local travelNode = keywordHandler:addKeyword({'thais'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, text = 'Do you seek a passage to Thais for 160 gold coins?'})
        	travelNode:addChildKeyword({'yes'}, StdModule.travel, {npcHandler = npcHandler, premium = false, level = 0, cost = 160, destination = {x=32313, y=32212, z=7} })
        	travelNode:addChildKeyword({'no'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, reset = true, text = 'We would like to serve you some time.'})

    local travelNode = keywordHandler:addKeyword({'carlin'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, text = 'Do you want to sail to Carlin for 110 gold coins?'})
        	travelNode:addChildKeyword({'yes'}, StdModule.travel, {npcHandler = npcHandler, premium = false, level = 0, cost = 0, destination = {x=32387, y=31820, z=7} })
        	travelNode:addChildKeyword({'no'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, reset = true, text = 'We would like to serve you some time.'})
        
	local travelNode = keywordHandler:addKeyword({'venore'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, text = 'Do you want to sail to Venore for 40 gold coins?'})
        	travelNode:addChildKeyword({'yes'}, StdModule.travel, {npcHandler = npcHandler, premium = false, level = 0, cost = 40, destination = {x=32954, y=32022, z=7} })
        	travelNode:addChildKeyword({'no'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, reset = true, text = 'We would like to serve you some time.'})
       
        keywordHandler:addKeyword({'sail'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, text = 'Where do you want to go? To Thais, Carlin, Ab\'Dendriel, Venore, Ankrahmun or the isle Cormaya?'})
        keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, text = 'I\'m the captain of this sailing ship.'})
		keywordHandler:addKeyword({'captain'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, text = 'I\'m the captain of this sailing ship.'})
       
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
        npcHandler:addModule(FocusModule:new())
