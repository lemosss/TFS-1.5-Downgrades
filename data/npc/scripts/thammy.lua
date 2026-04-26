local keywordHandler = KeywordHandler:new()
local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)
function onCreatureAppear(cid)                  npcHandler:onCreatureAppear(cid)                        end
function onCreatureDisappear(cid)               npcHandler:onCreatureDisappear(cid)                     end
function onCreatureSay(cid, type, msg)  npcHandler:onCreatureSay(cid, type, msg)        end
function onThink()                                              npcHandler:onThink()    end
 
function ThammyBehaviour (cid, type, msg)

npcHandler:AddFocus({"hi", "hello"}, "Greetings, traveller.", 0, cid, msg)
npcHandler:AddQueue({"hi", "hello"}, "Sorry, I'm too busy now.", 0, cid, msg)
npcHandler:RemoveFocus({"bye", "farewell"}, "Goodbye, traveller.", 0, cid, msg)

  if(not npcHandler:isFocused(cid)) then
     return 0
  end

local keywords = {
["name"] = {response = "I'm called Anthony."},
["job"] = {response = "I sell various foods."},
["time"] = {response = "Sorry, I don't know."},
["king"] = {response = "I don't know much about the king, sorry."},
["tibianus"] = {response = "I don't know much about the king, sorry."},
["army"] = {response = "I sometimes heal soldiers with my herbal mixtures."},
["heal"] = {response = "I sometimes heal soldiers with my herbal mixtures."},
["ferumbras"] = {response = "Mentioning his name makes me shiver."},
["excalibug"] = {response = "I am not an expert for weapons."},
["thais"] = {response = "I prefer the wilderness to cities."},
["tibia"] = {response = "I prefer the wilderness to cities."},
["carlin"] = {response = "I prefer the wilderness to cities."},
["edron"] = {response = "I prefer the wilderness to cities."},
["news"] = {response = "I fear I know nothing new that is of any importance."},
["rumors"] = {response = "I fear I know nothing new that is of any importance."},
["mushroom"] = {response = "I have white, red, and brown mushrooms. Which one do you want?"},

}
  for v in pairs(keywords) do
    if (msgcontains(msg, v)) then
        npcHandler:say(keywords[v].response, cid)
    end
  end
  return 1
end

local shopModule = ShopModule:new()
npcHandler:addModule(shopModule)

shopModule:addBuyableItem({"white"}, 2787, 6,  "Do you want to buy one of the white mushrooms for |TOTALCOST| gold?", "Do you want to buy |ITEMCOUNT| of the white mushrooms for |TOTALCOST| gold?")
shopModule:addBuyableItem({"red"}, 2788, 12, "Do you want to buy one of the red mushrooms for |TOTALCOST| gold?", "Do you want to buy |ITEMCOUNT| of the red mushrooms for |TOTALCOST| gold?")
shopModule:addBuyableItem({"brown"}, 2789, 10, "Do you want to buy one of the brown mushrooms for |TOTALCOST| gold?", "Do you want to buy |ITEMCOUNT| of the brown mushrooms for |TOTALCOST| gold?")

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, ThammyBehaviour)