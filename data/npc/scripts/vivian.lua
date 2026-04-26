local keywordHandler = KeywordHandler:new()
local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
local Count, ItemId, Money
NpcSystem.parseParameters(npcHandler)
function onCreatureAppear(cid)                  npcHandler:onCreatureAppear(cid)                        end
function onCreatureDisappear(cid)               npcHandler:onCreatureDisappear(cid)                     end
function onCreatureSay(cid, type, msg)  npcHandler:onCreatureSay(cid, type, msg)        end
function onThink()                                              npcHandler:onThink()    end
 
function VivianBehaviour (cid, type, msg)

npcHandler:AddFocus({"hi", "hello"}, "Oh, please come in, |PLAYERNAME|. What do you need?", 0, cid, msg)
npcHandler:AddQueue({"hi", "hello"}, "Sorry |PLAYERNAME|, I am already talking to a customer. Please wait.", 0, cid, msg)
npcHandler:RemoveFocus({"bye", "farewell"}, "Good bye.", 0, cid, msg)

if(not npcHandler:isFocused(cid)) then
   return 0
end

   if(msgcontains(msg, 'sell') and msgcontains(msg, 'bow')) then
           npcHandler:say("I don't buy used bows.",cid)
           npcHandler:doTopic(cid, 0)
   elseif(msgcontains(msg, 'sell') and msgcontains(msg, 'crossbow')) then
           npcHandler:say("I don't buy used crossbows.",cid)
           npcHandler:doTopic(cid, 0)

   elseif (getCount(msg) > 1) and (msgcontains(msg, 'bow')) then
           Count = getCount(msg)
           ItemId = 2456
           Money = 400
           npcHandler:say('Do you want to buy '..Count..' bows for '..(Count*Money)..' gold?')
           npcHandler:doTopic(cid, 1)
   elseif (msgcontains(msg, 'bow')) then
           Count = 1
           ItemId = 2456
           Money = 400
           npcHandler:say('Do you want to buy a bow for '..Money..' gold?')
           npcHandler:doTopic(cid, 1)

   elseif (getCount(msg) > 1) and (msgcontains(msg, 'crossbow')) then
           Count = getCount(msg)
           ItemId = 2455
           Money = 500
           npcHandler:say('Do you want to buy '..Count..' crossbows for '..(Count*Money)..' gold?')
           npcHandler:doTopic(cid, 1)
   elseif (msgcontains(msg, 'crossbow')) then
           Count = 1
           ItemId = 2455
           Money = 500
           npcHandler:say('Do you want to buy a crossbow for '..Money..' gold?')
           npcHandler:doTopic(cid, 1)

   elseif (msgcontains(msg:lower(),'yes')) and (npcHandler.Topic == 1) then
           npcHandler:doTopic(cid, 0)
       if (doPlayerRemoveMoney(cid,Money*Count) == 1) then
	  for i=1,Count do
	   doPlayerAddItem(cid,ItemId,1)
          end
           npcHandler:say('Here you are.')
       else
           npcHandler:say("Come back, when you have enough money.")
       end
   elseif (npcHandler.Topic == 1) then
           npcHandler:say("Hmm, but next time.")
           npcHandler:doTopic(cid, 0)

   elseif (msgcontains(msg:lower(),'buy')) then
           npcHandler:say("I am selling bows, crossbows, and ammunition. Do you need anything?",cid)
           npcHandler:doTopic(cid, 0)
   end
local keywords = {
["job"] = {response = "I am the local fletcher. I am selling bows, crossbows, and ammunition. Do you need anything?"},
["fletcher"] = {response = "I am the local fletcher. I am selling bows, crossbows, and ammunition. Do you need anything?"},
["name"] = {response = "I am Vivian, paladin and fletcher."},
["paladin"] = {response = "We are feared warriors and good marksmen. Ask Elane if want to know more about the guild."},
["elane"] = {response = "She is the leader of all paladins."},
["gorn"] = {response = "I supplied him with my goods in the past, now I sell them myself."},
["time"] = {response = "Don't bother me. Go and buy a watch."},
["tibia"] = {response = "Tibia, a green island. Here it is wunderful to walk into the forests and to hunt with a bow."},
["forest"] = {response = "Tibia, a green island. Here it is wunderful to walk into the forests and to hunt with a bow."},
["thais"] = {response = "We have visitors of all kind in Thais, only elves show up seldom."},
["elf"] = {response = "It is rumored that they live in the northeast of Tibia. They are the best in archery."},
["elves"] = {response = "It is rumored that they live in the northeast of Tibia. They are the best in archery."},
["do you sell"] = {response = "I am selling bows, crossbows, and ammunition. Do you need anything?"},
["do you have"] = {response = "I am selling bows, crossbows, and ammunition. Do you need anything?"},
["offer"] = {response = "I am selling bows, crossbows, and ammunition. Do you need anything?"},
["goods"] = {response = "I am selling bows, crossbows, and ammunition. Do you need anything?"},
["ammo"] = {response = "Do you need arrows for a bow, or bolts for a crossbow?"},
["ammunition"] = {response = "Do you need arrows for a bow, or bolts for a crossbow?"},
}
  for v in pairs(keywords) do
    if (msgcontains(msg, v)) then
        npcHandler:say(keywords[v].response, cid)
        npcHandler:doTopic(cid, 0)
    end
  end
  return 1
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, VivianBehaviour)