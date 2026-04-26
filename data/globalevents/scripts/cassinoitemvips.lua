local EventsListalist = {
	    
		{time = "24H", name = "Items VIP"},		
	    
	}
	
	local position = {x = 145, y = 57, z = 7}
	
	
	function onThink(interval, lastExecution)
		
	 local people = getPlayersOnline()
    if #people == 0 then
        return true
    end
	
	local Count = 0
	  for _, t in ipairs(EventsListalist) do
	        local eventTime = hourToNumber(t.time)
	        local realTime = hourToNumber(os.date("%H:%M:%S"))
	        if eventTime >= realTime then
	       doPlayerSay(people[1], "Cassino {"..t.time.."h} "..t.name..", de "..timeString(eventTime - realTime)..".", TALKTYPE_MONSTER_SAY, false, 0, position)
	            return true
	        end
	        Count = Count + 1
	    end
		return true
	end