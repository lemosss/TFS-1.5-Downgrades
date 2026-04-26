local keywordHandler = KeywordHandler:new()
local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)
function onCreatureAppear(cid)                  npcHandler:onCreatureAppear(cid)                        end
function onCreatureDisappear(cid)               npcHandler:onCreatureDisappear(cid)                     end
function onCreatureSay(cid, type, msg)  npcHandler:onCreatureSay(cid, type, msg)        end
function onThink()                                              npcHandler:onThink()    end
 
function QueroBehaviour (cid, type, msg)
if(npcHandler.focus ~= cid) then
   return 0
end

local keywords = {
["job"] = {response = "I make instruments and sometimes I'm wandering through the lands of Tibia as a bard."},
["name"] = {response = "My name is Quero."},
["time"] = {response = "Sorry, I don't know what time it is."},
["music"] = {response = "I love the music of the elves."},
["elf"] = {response = "They live in the northeast of Tibia."},
["elves"] = {response = "They live in the northeast of Tibia."},
["bard"] = {response = "Selling instruments isn't enough to live on and I love music. That's why I wander through the lands from time to time."},
["benjamin"] = {response = "He's nice."},
["offer"] = {response = "You can buy a lyre, lute, drum, and simple fanfare."},
["goods"] = {response = "You can buy a lyre, lute, drum, and simple fanfare."},
["do you sell"] = {response = "You can buy a lyre, lute, drum, and simple fanfare."},
["do you have"] = {response = "You can buy a lyre, lute, drum, and simple fanfare."},
["instrument"] = {response = "You can buy a lyre, lute, drum, and simple fanfare."},
}
  for v in pairs(keywords) do
    if (msgcontains(msg, v)) then
        npcHandler:say(keywords[v].response, cid)
        npcHandler:doTopic(cid, 0)
    end
  end
  return 1
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, QueroBehaviour)
npcHandler:addModule(FocusModule:new())