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

		if msgcontains(msg, 'ferumbras') or msgcontains(msg, 'hat') then
        npcHandler:say('I cannot believe my eyes. You retrieved this hat from Ferumbras remains? That is incredible. If you give it to me, I will grant you the right to wear this hat as addon. What do you say?')
        talk_state = 1
		elseif msgcontains(msg, 'yes') and talk_state == 1 then
			if (getPlayerItemCount(cid, 5806) <= 0) then
					npcHandler:say('Hey'.. getPlayerName(cid) ..', Are you making a joke? First you give me the hat, and then I reward you. Next time, come back with him.')
					talk_state = 2
			elseif (getPlayerStorageValue(cid,8470003) >= 1) then
					npcHandler:say('You already have this addon, I cant buy another hat.')
					talk_State = 3
            elseif getPlayerItemCount(cid, 5806) >= 1 then
                    npcHandler:say('I bow to you '.. getPlayerName(cid) ..', and hereby grant you the right to wear Ferumbras hat as accessory. Congratulations!', cid)
                    doPlayerRemoveItem(cid, 5806, 1)
					setPlayerStorageValue(cid,8470003, 3)
					doPlayerAddOutfit(cid,260, 2)
					doPlayerAddOutfit(cid,269, 1)
                    talk_state = 0
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