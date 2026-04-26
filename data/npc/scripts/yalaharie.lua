local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)			npcHandler:onCreatureAppear(cid)			end
function onCreatureDisappear(cid)		npcHandler:onCreatureDisappear(cid)			end
function onCreatureSay(cid, type, msg)	npcHandler:onCreatureSay(cid, type, msg)	end
function onThink()						npcHandler:onThink()						end

function creatureSayCallback(cid, type, msg)
	-- Place all your code in here. Remember that hi, bye and all that stuff is already handled by the npcsystem, so you do not have to take care of that yourself.
	if not npcHandler:isFocused(cid) then
		return false
	end

		if msgcontains(msg, 'mission') or msgcontains(msg, 'quest') then
        npcHandler:say('What do you need '.. getPlayerName(cid) ..' Are you interested in doing the last yalahar quest?')
        talk_state = 1
		elseif msgcontains(msg, 'yes') and talk_state == 1 then
			if (getPlayerStorageValue(cid, 9898194) <= 0) then
					npcHandler:say('Hey '.. getPlayerName(cid) ..', First you need to do a service for Timothy, talk mission to him, then come back and talk to me.')
					talk_state = 2
			elseif (getPlayerStorageValue(cid,9898194) >= 1) then
					npcHandler:say('Very well, you are ready to do the most dangerous mission in yalahar, I will release your access to the door, good luck!.')
					setPlayerStorageValue(cid,52200, 3)
					talk_State = 0
                end
            else
                npcHandler:say('I need the ferumbras hat for give your addon.', cid)
                talk_state = 0
            end		
	-- Place all your code in here. Remember that hi, bye and all that stuff is already handled by the npcsystem, so you do not have to take care of that yourself.
	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
npcHandler:addModule(FocusModule:new())