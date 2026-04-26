local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)
local talkState = {}
local talkUser = NPCHANDLER_CONVBEHAVIOR == CONVERSATION_DEFAULT and 0 or cid

local price,gold,moneycount,vialcount

local fire = createConditionObject(CONDITION_FIRE)
addDamageCondition(fire, 10, 4000, -9)
function onCreatureAppear(cid)                  npcHandler:onCreatureAppear(cid)                        end
function onCreatureDisappear(cid)               npcHandler:onCreatureDisappear(cid)                     end
function onCreatureSay(cid, type, msg)  npcHandler:onCreatureSay(cid, type, msg)        end
function onThink()                                              npcHandler:onThink()    end
 
function RachelGreetCallback(cid)
  if (isSorcerer(cid)) then
     if (isFemale(cid) == TRUE) then
         npcHandler:setMessage(MESSAGE_GREET, "Welcome back, sister |PLAYERNAME|! Wasn't your name |PLAYERNAME|?")
         talkState[talkUser] = 6
     else
         npcHandler:setMessage(MESSAGE_GREET, "Welcome back, brother |PLAYERNAME|! Wasn't your name |PLAYERNAME|?")
         talkState[talkUser] = 6
     end
  else
     npcHandler:setMessage(MESSAGE_GREET, "Welcome |PLAYERNAME|! Whats your need?")
  end
  return 1
end

function RachelSayCallback (cid, type, msg)
  if(npcHandler.focus ~= cid) then
     return 0
  end

        if (msgcontains(msg:lower(),"yes")) and (talkState[talkUser] == 6) then
                npcHandler:say("I thought so, what do you want?")
                talkState[talkUser] = 0
        elseif (msgcontains(msg:lower(),"no")) and (talkState[talkUser] == 6) then
                npcHandler:say("First lesson: DON'T LIE TO RACHEL!")
                doTargetCombatCondition(0, cid, fire, 4)
                doSendMagicEffect(getThingPos(getNpcCid()), 14)
                talkState[talkUser] = 0
        elseif (msgcontains(msg:lower(),"sorcerer")) and (talkState[talkUser] == 6) then
                npcHandler:say("I thought only intelligent persons are allowed to become sorcerers.")
                npcHandler:doTopic(cid, 0)
        elseif (talkState[talkUser] == 6) then
                npcHandler:say("I am glad that only intelligent persons are allowed to become sorcerers.")
                talkState[talkUser] = 0

-----MANA FLUID-----
        elseif(getCount(msg) > 1) and (isKeywords(msg, {"mana","fluid"}) or msgcontains(msg,"manafluid")) then
               moneycount = getCount(msg)
               price = 55
               gold = moneycount*price
               npcHandler:doTopic(cid, 1)
               npcHandler:say("Do you want to buy "..moneycount.." potions of mana fluid for "..gold.." gold?", cid)
        elseif (isKeywords(msg, {"mana","fluid"}) or msgcontains(msg,"manafluid")) then
               moneycount = 1
               price = 55
               gold = price
               npcHandler:doTopic(cid, 1)
               npcHandler:say("Do you want to buy mana fluid for "..gold.." gold?")
        elseif (msgcontains(msg:lower(),'yes')) and (npcHandler.Topic == 1) then
            if (getPlayerMoney(cid) >= gold) then
                 for i=1,moneycount do
		  doPlayerAddItem(cid,2006,7)
                 end
                npcHandler:say("Here you are. There is a deposit of 5 gold on the vial.", cid)
                npcHandler:doTopic(cid, 0)
                doPlayerRemoveMoney(cid,gold)

            else
                npcHandler:say("Come back, when you have enough money.")
                npcHandler:doTopic(cid, 0)
            end
        elseif (npcHandler.Topic == 1) then
                npcHandler:say("Hmm, but next time.")
                npcHandler:doTopic(cid, 0)

-----BLANK RUNE-----

        elseif(getCount(msg) > 1) and (isKeywords(msg, {"blank","rune"}) or msgcontains(msg,"blankrune")) then
               moneycount = getCount(msg)
               price = 10
               gold = moneycount*price
               npcHandler:doTopic(cid, 4)
               npcHandler:say("Do you want to buy "..moneycount.." blank runes for "..gold.." gold?", cid)
        elseif (isKeywords(msg, {"blank","rune"}) or msgcontains(msg,"blankrune")) then
               moneycount = 1
               price = 10
               gold = price
               npcHandler:doTopic(cid, 4)
               npcHandler:say("Do you want to buy one for "..gold.." gold?")
        elseif (msgcontains(msg:lower(),'yes')) and (npcHandler.Topic == 4) then
            if (getPlayerMoney(cid) >= gold) then
                 for i=1,moneycount do
		  doPlayerAddItem(cid,2260,1)
                 end
                doPlayerRemoveMoney(cid,gold)
                npcHandler:say("Here you are.", cid)
                npcHandler:doTopic(cid, 0)
            else
                npcHandler:say("Come back, when you have enough money.")
                npcHandler:doTopic(cid, 0)
            end
        elseif (npcHandler.Topic == 4) then
                npcHandler:say("Hmm, but next time.")
                npcHandler:doTopic(cid, 0)

-----LIFE FLUID-----

        elseif(getCount(msg) > 1) and (isKeywords(msg, {"life","fluid"}) or msgcontains(msg,"lifefluid")) then
               moneycount = getCount(msg)
               price = 60
               gold = moneycount*price
               npcHandler:doTopic(cid, 3)
               npcHandler:say("Do you want to buy "..moneycount.." potions of life fluid for "..gold.." gold?", cid)
        elseif (isKeywords(msg, {"life","fluid"}) or msgcontains(msg,"lifefluid")) then
               moneycount = 1
               price = 60
               gold = price
               npcHandler:doTopic(cid, 3)
               npcHandler:say("Do you want to buy life fluid for "..gold.." gold?")
        elseif (msgcontains(msg:lower(),'yes')) and (npcHandler.Topic == 3) then
            if (getPlayerMoney(cid) >= gold) then
                 for i=1,moneycount do
		  doPlayerAddItem(cid,2006,10)
                 end
                doPlayerRemoveMoney(cid,gold)
                npcHandler:say("Here you are. There is a deposit of 5 gold on the vial.", cid)
                npcHandler:doTopic(cid, 0)
            else
                npcHandler:say("Come back, when you have enough money.")
                npcHandler:doTopic(cid, 0)
            end
        elseif (npcHandler.Topic == 3) then
                npcHandler:say("Hmm, but next time.")
                npcHandler:doTopic(cid, 0)

-----SPELLBOOK-----

        elseif(getCount(msg) > 1) and (msgcontains(msg:lower(),"spellbook")) then
               moneycount = getCount(msg)
               price = 150
               gold = moneycount*price
               npcHandler:doTopic(cid, 5)
               npcHandler:say("Do you want to buy "..moneycount.." spellbooks for "..gold.." gold?", cid)
        elseif (msgcontains(msg:lower(),"spellbook")) then
               moneycount = 1
               price = 150
               gold = price
               npcHandler:doTopic(cid, 5)
               npcHandler:say("A spellbook is a nice tool for beginners. Do you want to buy one for "..gold.." gold?")
        elseif (msgcontains(msg:lower(),'yes')) and (npcHandler.Topic == 5) then
            if (getPlayerMoney(cid) >= gold) then
                 for i=1,moneycount do
		  doPlayerAddItem(cid,2175,1)
                 end
                doPlayerRemoveMoney(cid,gold)
                npcHandler:say("Here you are.", cid)
                npcHandler:doTopic(cid, 0)
            else
                npcHandler:say("Come back, when you have enough money.")
                npcHandler:doTopic(cid, 0)
            end
        elseif (npcHandler.Topic == 5) then
                npcHandler:say("Hmm, but next time.")
                npcHandler:doTopic(cid, 0)

        elseif (msgcontains(msg:lower(),'spell')) then
                npcHandler:say("I am too busy to teach you, ask in your guild about that.")

-----TALONS-----

        elseif(getCount(msg) > 1) and (msgcontains(msg:lower(),"talon")) then
               moneycount = getCount(msg)
               price = 320
               gold = moneycount*price
               npcHandler:doTopic(cid, 7)
               npcHandler:say("Do you want to sell "..moneycount.." magic gems called talon for "..gold.." gold?")
        elseif (msgcontains(msg:lower(),"talon") or msgcontains(msg:lower(),"talons")) then
               moneycount = 1
               price = 320
               gold = price
               npcHandler:doTopic(cid, 7)
               npcHandler:say("Do you want to sell one of the magic gems called talon for "..gold.." gold?")
        elseif (msgcontains(msg:lower(),'yes')) and (npcHandler.Topic == 7) then
            if (doPlayerRemoveItem(cid,2151,moneycount) == TRUE) then
                doPlayerAddMoney(cid,gold)
                npcHandler:say("Ok. Here is your money.", cid)
                npcHandler:doTopic(cid, 0)
            else
              if moneycount > 1 then
                npcHandler:say("Sorry, you do not have so many.")
              else
                npcHandler:say("Sorry, you do not have one.")
              end
                npcHandler:doTopic(cid, 0)
            end
        elseif (npcHandler.Topic == 7) then
                npcHandler:say("Maybe next time.")
                npcHandler:doTopic(cid, 0)
-----VIALS-----

        elseif (msgcontains(msg:lower(),"deposit")) or (msgcontains(msg:lower(),"vial")) or (msgcontains(msg:lower(),"flask")) then
                npcHandler:say("I will pay you 5 gold for every empty vial. Ok?")
                npcHandler:doTopic(cid, 2)
        elseif (msgcontains(msg:lower(),'yes')) and (npcHandler.Topic == 2) then
		vialcount = getPlayerItemCount(cid, 2006)
		for i=1,vialcount do
		   if 1 > doPlayerRemoveItem(cid, 2006, 1, 0) then vialcount = vialcount-1 end
		end
		   if vialcount > 0 then
		       doPlayerAddMoney(cid,vialcount*5)
                       npcHandler:say("Here you are ... "..(vialcount*5).." gold.")
                       npcHandler:doTopic(cid, 0)
		   else
		       npcHandler:say("You don't have any empty vials.")
                       npcHandler:doTopic(cid, 0)
		   end
        elseif (npcHandler.Topic == 2) then
                npcHandler:say("Hmm, but please keep Tibia litter free.")
                npcHandler:doTopic(cid, 0)

        elseif (msgcontains(msg:lower(),'rune')) then
                npcHandler:say("I sell blank runes.")
        -----BP OF MF-----		

		elseif msgcontains(msg, 'bp of mf') or msgcontains(msg, 'bp of manafluid') or msgcontains(msg, 'bp mf') then
               npcHandler:say('Do you want to buy a backpack of mana fluid for 1200 gold coins?')
               talk_state = 6
    
        elseif msgcontains(msg, 'yes') and talk_state == 6 then
            if getPlayerMoney(cid) >= 1200 then
                brown_bp = doPlayerAddItem(cid, 2001, 1)
             for i = 1, 20 do -- Aqui a mesma coisa...
			 doAddContainerItem(brown_bp, 2006, 7)
				end
                doPlayerRemoveMoney(cid, 1200)
                npcHandler:say('Thank you for buying.')
                talk_state = 0
            else
                npcHandler:say('You don\'t have enough money.')
                talk_state = 0
            end
    end
    

local keywords = {
["job"] = {response = "I am the head alchemist of Carlin. I keep the secret recipies of our ancestors. Besides, I am selling mana and life fluids, spellbooks, wands, rods and runes."},
["name"] = {response = "I am the illusterous Rachel, of course."},
["time"] = {response = "Time is of no meaning to us sorcerers."},
["wisdom"] = {response = "Wisdom arises from patience."},
["patience"] = {response = "You have to free yourself from unpatience to learn the deeper secrets of magic."},
["ancestor"] = {response = "We are a guild of old traditions and even older secrets."},
["sorcerer"] = {response = "Spells are the minor parts that make a sorcerer. To be one is a state of mind, not of a full spellbook."},
["power"] = {response = "Power is important, but it is just the way, not the ultimate goal."},
["goal"] = {response = "This secrect will be taught you by life, not by me."},
["vocation"] = {response = "Your vocation is your profession. There are four vocations in Tibia: Sorcerers, paladins, knights, and druids."},
}
  for v in pairs(keywords) do
    if (msgcontains(msg, v)) then
        npcHandler:say(keywords[v].response, cid)
        npcHandler:doTopic(cid, 0)
    end
  end
  return 1
end



npcHandler:setCallback(CALLBACK_GREET, RachelGreetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, RachelSayCallback)
npcHandler:addModule(FocusModule:new())