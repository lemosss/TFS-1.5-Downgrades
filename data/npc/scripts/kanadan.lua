local keywordHandler = KeywordHandler:new()
        local npcHandler = NpcHandler:new(keywordHandler)
        NpcSystem.parseParameters(npcHandler)
        
        
        
        -- OTServ event handling functions start
        function onCreatureAppear(cid)				npcHandler:onCreatureAppear(cid) end
        function onCreatureDisappear(cid) 			npcHandler:onCreatureDisappear(cid) end
        function onCreatureSay(cid, type, msg) 	npcHandler:onCreatureSay(cid, type, msg) end
        function onThink() 						npcHandler:onThink() end
        -- OTServ event handling functions end
        
        
        -- Don't forget npcHandler = npcHandler in the parameters. It is required for all StdModule functions!
	local travelNode = keywordHandler:addKeyword({'meadowfieldasdasdomnbbasdgh'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, text = 'Do you seek a passage to Meadowfield for 500 gold coins?'})
        	travelNode:addChildKeyword({'yes'}, StdModule.travel, {npcHandler = npcHandler, premium = false, level = 8, cost = 500, destination = {x=1145, y=1059, z=7} })
        	travelNode:addChildKeyword({'no'}, StdModule.say, {npcHandler = npcHandler, onlyFocus = true, reset = true, text = 'We would like to serve you some time.'})
       

        npcHandler:addModule(FocusModule:new())