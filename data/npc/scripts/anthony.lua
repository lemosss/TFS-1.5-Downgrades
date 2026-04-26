local keywordHandler = KeywordHandler:new()
local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)
function onCreatureAppear(cid)                  npcHandler:onCreatureAppear(cid)                        end
function onCreatureDisappear(cid)               npcHandler:onCreatureDisappear(cid)                     end
function onCreatureSay(cid, type, msg)  npcHandler:onCreatureSay(cid, type, msg)        end
function onThink()                                              npcHandler:onThink()    end
 
function AnthonyBehaviour (cid, type, msg)

npcHandler:AddFocus({"hi", "hello"}, "Pshhhht! Not that loud ... but welcome.", 0, cid, msg)
npcHandler:AddQueue({"hi", "hello"}, "Just a moment.", 0, cid, msg)
npcHandler:RemoveFocus({"bye", "farewell"}, "Please come back, but don't tell others.", 0, cid, msg)

  if(not npcHandler:isFocused(cid)) then
     return 0
  end

local keywords = {
["job"] = {response = "I am the responsible for our ... uhm ... resistance."},
["saloon"] = {response = "I am the responsible for our ... uhm ... resistance."},
["resistance"] = {response = "We fight the opression of the males and male needs by the women. This is our secret headquarters."},
["headquarters"] = {response = "Well its more a hidden tavern, so to say."},
["tavern"] = {response = "Our offers are limited but here a man can buy what a man needs." },
["name"] = {response = "I won't tell you my name."},
["queen"] = {response = "Well, shes not that bad ... but some of her laws are."},
["eloise"] = {response = "Well, shes not that bad ... but some of her laws are."},
["laws"] = {response = "Those crazy women forbid us alcohol in the city! Imagine that!"},
["needs"] = {response = "Those crazy women forbid us alcohol in the city! Imagine that!"},
["opression"] = {response = "Those crazy women forbid us alcohol in the city! Imagine that!"},
["alcohol"] = {response = "Those crazy women forbid us alcohol in the city! Imagine that!"},
["army"] = {response = "They are the tools of opression. Hunting down every alcohol smuggler they can get."},
["smuggler"] = {response = "We collected money and hired one of the best smuggler in the whole land. His name is Todd."},
["Todd"] = {response = "A true fighter for malehood. He will bring us all the hard stuff from Thais and even contact the king there to support us." },
["king"] = {response = "I'm sure if the king learns about our tragedy, he will support us with alcohol."},
["hard stuff"] = {response = "Todd took all the money we could gather to buy us the best stuff on the whole continent."},
["hugo"] = {response = "I think Todd mentioned a Hugo once."},
["news"] = {response = "Some travelers from Edron told about a great treasure guarded by cruel demons in the dungeons there."},
["rumors"] = {response = "Some travelers from Edron told about a great treasure guarded by cruel demons in the dungeons there."},
["buy"] = {response = "I can offer you beer. For wine and realy hard stuff we have to wait for Todd."},
["offers"] = {response = "I can offer you beer. For wine and realy hard stuff we have to wait for Todd."},
["do you sell"] = {response = "I can offer you beer. For wine and realy hard stuff we have to wait for Todd."},
["do you have"] = {response = "I can offer you beer. For wine and realy hard stuff we have to wait for Todd."},
}
  for v in pairs(keywords) do
    if (msgcontains(msg, v)) then
        npcHandler:say(keywords[v].response, cid)
        npcHandler:doTopic(cid, 0)
    end
  end
  return 1
end

local shopModule = ShopModule:new()
npcHandler:addModule(shopModule)

shopModule:addBuyableItem({"beer"}, 2012, 20, 3, "Do you want to buy a mug of beer for |TOTALCOST| gold?", "Do you want to buy |ITEMCOUNT| mugs of beer for |TOTALCOST| gold?")

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, AnthonyBehaviour)