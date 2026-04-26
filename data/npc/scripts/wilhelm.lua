local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

local COUNT
local GOLD = 2148
local PLATINUM = 2152
local CRYSTAL = 2160

function onCreatureAppear(cid)          npcHandler:onCreatureAppear(cid)         end
function onCreatureDisappear(cid)       npcHandler:onCreatureDisappear(cid)      end
function onCreatureSay(cid, type, msg)  npcHandler:onCreatureSay(cid, type, msg) end
function onThink()                      npcHandler:onThink()                     end

function WilhelmBehaviour (cid, type, msg)
  if(not npcHandler:isFocused(cid)) then
     return 0
  end

-----BANK SYSTEM-----
---GOLD TO PLATINUM--
        if(msgcontains(msg, "change") and msgcontains(msg, "gold"))  then
                npcHandler:say("How many platinum coins do you want to get?",cid)
                npcHandler:doTopic(cid, 1)
        elseif (getCount(msg) > 0) and (npcHandler.Topic == 1) then
            if (getCount(msg) > 100) then
                COUNT = 100
            else
                COUNT = getCount(msg)
            end
                npcHandler:say('So I should change '.. (COUNT*100) ..' of your gold coins to '..COUNT..' platinum coins for you?')
                npcHandler:doTopic(cid, 2)
        elseif (msgcontains(msg, "yes")) and (npcHandler.Topic == 2) then
                npcHandler:doTopic(cid, 0)
            if (doPlayerRemoveItem(cid,GOLD,COUNT*100) == TRUE) then
                npcHandler:say("Here you are.",cid)
                doPlayerAddItem(cid,PLATINUM,COUNT)
            else
                npcHandler:say("Sorry, you don't have enough gold coins.",cid)
            end

---CRYSTAL TO PLATINUM--
        elseif(msgcontains(msg, "change") and msgcontains(msg, "crystal"))  then
                npcHandler:say("How many crystal coins do you want to change to platinum?",cid)
                npcHandler:doTopic(cid, 8)
        elseif (getCount(msg) > 0) and (npcHandler.Topic == 8) then
                COUNT = getCount(msg)
                npcHandler:say('So I should change '..COUNT..' of your crystal coins to '..(COUNT*100)..' platinum coins for you?')
                npcHandler:doTopic(cid, 9)
        elseif (msgcontains(msg, "yes")) and (npcHandler.Topic == 9) then
                npcHandler:doTopic(cid, 0)
            if (doPlayerRemoveItem(cid,CRYSTAL,COUNT) == TRUE) then
                npcHandler:say("Here you are.",cid)
	        for i=1,COUNT do
		   doPlayerAddItem(cid,PLATINUM,100)
                end
            else
                npcHandler:say("Sorry, you don't have so many crystal coins.",cid)
            end

---PLATINUM TO CRYSTAL--
        elseif(msgcontains(msg, "change") and msgcontains(msg, "platinum")) then
                npcHandler:say("Do you want to change your platinum coins to gold or crystal?",cid)
                npcHandler:doTopic(cid, 3)
        elseif (msgcontains(msg, "crystal")) and (npcHandler.Topic == 3) then
                npcHandler:say("How many crystal coins do you want to get?",cid)
                npcHandler:doTopic(cid, 4)
        elseif (getCount(msg) > 0) and (npcHandler.Topic == 4) then
            if (getCount(msg) > 100) then
                COUNT = 100
            else
                COUNT = getCount(msg)
            end
                npcHandler:say('So I should change '..(COUNT*100)..' of your platinum coins to '..COUNT..' crystal coins for you?')
                npcHandler:doTopic(cid, 5)
        elseif (msgcontains(msg, "yes")) and (npcHandler.Topic == 5) then
                npcHandler:doTopic(cid, 0)
            if (doPlayerRemoveItem(cid,PLATINUM,COUNT*100) == TRUE) then
                npcHandler:say("Here you are.",cid)
                doPlayerAddItem(cid,CRYSTAL,COUNT)
            else
                npcHandler:say("Sorry, you don't have so many platinum coins.",cid)
            end

---PLATINUM TO GOLD--
        elseif (msgcontains(msg, "gold")) and (npcHandler.Topic == 3) then
                npcHandler:say("How many platinum coins do you want to change to gold?",cid)
                npcHandler:doTopic(cid, 6)
        elseif (getCount(msg) > 0) and (npcHandler.Topic == 6) then
                COUNT = getCount(msg)
                npcHandler:say('So I should change '..COUNT..' of your platinum coins to '..(COUNT*100)..' gold coins for you?')
                npcHandler:doTopic(cid, 7)
        elseif (msgcontains(msg, "yes")) and (npcHandler.Topic == 7) then
                npcHandler:doTopic(cid, 0)
            if (doPlayerRemoveItem(cid,PLATINUM,COUNT) == TRUE) then
                npcHandler:say("Here you are.",cid)
	        for i=1,COUNT do
		   doPlayerAddItem(cid,GOLD,100)
                end
            else
                npcHandler:say("Sorry, you don't have so many platinum coins.",cid)
            end

        elseif (msgcontains(msg, "change")) then
                npcHandler:say("We maintain the account balances of our citizens and we exchange gold, platinum and crystal coins.",cid)
                npcHandler:doTopic(cid, 0)
        elseif (msgcontains(msg, "job")) then
                npcHandler:say("I can change money for you.",cid)
                npcHandler:doTopic(cid, 0)
        elseif (msgcontains(msg, "offer")) then
                npcHandler:say("I can change money for you.",cid)
                npcHandler:doTopic(cid, 0)
        elseif (msgcontains(msg, "name")) then
                npcHandler:say("I am Wilhelm Pursesniffer, son of Fire, proud member of the Molten Rock fellowship.",cid)
                npcHandler:doTopic(cid, 0)
        elseif (msgcontains(msg, "time")) then
                npcHandler:say("It is exactly "..getTime().." right now.",cid)
                npcHandler:doTopic(cid, 0)

---BALANCE SYSTEM--
---deposit---

        elseif (msgcontains(msg, "balance") and (getConfigValue("UseNpcBalance") == true)) then
                npcHandler:say("Your account balance is "..getPlayerBalance(cid).." gold.",cid)

        elseif (msgcontains(msg, "deposit") and (getBalanceCount(msg) > 0) and (getConfigValue("UseNpcBalance") == true)) then
            if (getBalanceCount(msg) > 1000000) then
                npcHandler:say("You are joking, aren't you?",cid)
                npcHandler:doTopic(cid, 0)
            else
                COUNT = getBalanceCount(msg)
                npcHandler:say("Would you really like to deposit " ..COUNT.. " gold?",cid)
                npcHandler:doTopic(cid, 10)
            end

        elseif (msgcontains(msg, "deposit") and msgcontains(msg, "all") and (getConfigValue("UseNpcBalance") == true)) then
                COUNT = getPlayerMoney(cid)
            if (COUNT == 0) then
                npcHandler:say("You don't have enough gold.",cid)
            else
                npcHandler:say("Would you really like to deposit " ..COUNT.. " gold?",cid)
                npcHandler:doTopic(cid, 10)
            end

        elseif (msgcontains(msg, "deposit") and (getConfigValue("UseNpcBalance") == true)) then
                npcHandler:say("Please tell me how much gold it is you would like to deposit?",cid)
                npcHandler:doTopic(cid, 11)

        elseif (getBalanceCount(msg) > 0) and (npcHandler.Topic == 11) then
            if (getBalanceCount(msg) > 1000000) then
                npcHandler:say("You are joking, aren't you?",cid)
                npcHandler:doTopic(cid, 0)
            else
                COUNT = getBalanceCount(msg)
                npcHandler:say("Would you really like to deposit " ..COUNT.. " gold?",cid)
                npcHandler:doTopic(cid, 10)
            end

        elseif (msgcontains(msg, "yes")) and (npcHandler.Topic == 10) then
            if (doPlayerRemoveMoney(cid,COUNT) == TRUE) then
                npcHandler:doTopic(cid, 0)
                doPlayerDepositMoney(cid, COUNT)
                npcHandler:say("Alright, we have added the amount of "..COUNT.." gold to your balance. You can withdraw your gold anytime.",cid)
            else
                npcHandler:doTopic(cid, 0)
                npcHandler:say("You don't have enough gold.",cid)
            end

---withdraw---

        elseif (msgcontains(msg, "withdraw") and (getBalanceCount(msg) > 0) and (getConfigValue("UseNpcBalance") == true)) then
            if (getBalanceCount(msg) > getPlayerBalance(cid)) then
                npcHandler:say("There is not enough gold on your account. Your account balance is " .. getPlayerBalance(cid) .. ". Please tell me the amount of gold coins you would like to withdraw.",cid)
                npcHandler:doTopic(cid, 0)
            else
                COUNT = getBalanceCount(msg)
                npcHandler:say("Are you sure you wish to withdraw " ..COUNT.. " gold from your bank account?",cid)
                npcHandler:doTopic(cid, 12)
            end

        elseif (msgcontains(msg, "withdraw") and (getConfigValue("UseNpcBalance") == true)) then
                npcHandler:say("Please tell me how much gold you would like to withdraw?",cid)
                npcHandler:doTopic(cid, 13)

        elseif (getBalanceCount(msg) > 0) and (npcHandler.Topic == 13) then
            if (getBalanceCount(msg) > getPlayerBalance(cid)) then
                npcHandler:say("There is not enough gold on your account. Your account balance is " .. getPlayerBalance(cid) .. ". Please tell me the amount of gold coins you would like to withdraw.",cid)
                npcHandler:doTopic(cid, 0)
            else
                COUNT = getBalanceCount(msg)
                npcHandler:say("Are you sure you wish to withdraw " ..COUNT.. " gold from your bank account?",cid)
                npcHandler:doTopic(cid, 12)
            end

        elseif (msgcontains(msg, "yes")) and (npcHandler.Topic == 12) then
                npcHandler:doTopic(cid, 0)
                doPlayerWithdrawMoney(cid, COUNT)
                npcHandler:say("Here you are, " ..COUNT.. " gold. Please let me know if there is something else I can do for you.",cid)

        elseif (npcHandler.Topic >= 1) then
                npcHandler:say("Hmm, can I help you with something else?", cid)
                npcHandler:doTopic(cid, 0)

        end
        return 1
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, WilhelmBehaviour)
npcHandler:addModule(FocusModule:new())