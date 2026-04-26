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

		if msgcontains(msg, 'mission') or msgcontains(msg, 'palimuth') then
        npcHandler:say('Palimuth warned me that you were coming, go to the alchemist quarter in the bog raiders, and retrieve a note from the chest. talk notes or research. ')
        talk_state = 1
		elseif msgcontains(msg, 'notes') or msgcontains(msg, 'research') and talk_state == 1 then
			if (getPlayerItemCount(cid, 8331) <= 0) then
					npcHandler:say('Didnt find the note? you see the location in this image https://www.tibiawiki.com.br/images/a/a5/In_Service_of_Yalahar_3-4.png.')
					talk_state = 2
			elseif (getPlayerStorageValue(cid,9898194) >= 1) then
					npcHandler:say('You already have Palimuths trust, ask him for a mission..')
					talk_State = 3
            elseif getPlayerItemCount(cid, 8331) >= 1 then
                    npcHandler:say('Thanks '.. getPlayerName(cid) ..', you really are a brave and loyal guy, now you can talk to Palimuth and ask for access to the quest. Good luck.', cid)
                    doPlayerRemoveItem(cid, 8331, 1)
					setPlayerStorageValue(cid,9898194, 3)
                    talk_state = 0
                end
            else
                npcHandler:say('U need the research notes.', cid)
                talk_state = 0
            end		
	-- Place all your code in here. Remember that hi, bye and all that stuff is already handled by the npcsystem, so you do not have to take care of that yourself.
	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
npcHandler:addModule(FocusModule:new())