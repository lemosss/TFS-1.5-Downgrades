local keywordHandler = KeywordHandler:new()
local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)
function onCreatureAppear(cid)                  npcHandler:onCreatureAppear(cid)                        end
function onCreatureDisappear(cid)               npcHandler:onCreatureDisappear(cid)                     end
function onCreatureSay(cid, type, msg)  npcHandler:onCreatureSay(cid, type, msg)        end
function onThink()                                              npcHandler:onThink()    end
 
function DianeBehaviour (cid, type, msg)

npcHandler:AddFocus({"hi", "hello"}, "Be greeted, dear |PLAYERNAME|. Have a look at our offers.", 0, cid, msg)
npcHandler:AddQueue({"hi", "hello"}, "I am deeply sorry, dear |PLAYERNAME|, but I am busy with a customer. Please wait a moment.", 0, cid, msg)
npcHandler:RemoveFocus({"bye", "farewell"}, "Farewell.", 0, cid, msg)

local keywords = {
["job"] = {response = "I am responsible for buying and selling gems, pearls, and the like."},
["name"] = {response = "I am Diane Taleris, it's a pleasure to meet you."},
["time"] = {response = "It's "..getTime().."."},
["offer"] = {response = "We offer a great assortment of gems and pearls."},
["goods"] = {response = "We offer a great assortment of gems and pearls."},
["do you sell"] = {response = "We offer a great assortment of gems and pearls."},
["do you have"] = {response = "We offer a great assortment of gems and pearls."},
["gem"] = {response = "We trade small diamonds, sapphires, rubies, emeralds, and amethysts."},
["pearl"] = {response = "We trade white and black pearls."},
}
  for v in pairs(keywords) do
    if (msgcontains(msg, v)) and npcHandler:isFocused(cid) then
        npcHandler:say(keywords[v].response, cid)
    end
  end
  return 1
end

------BUYABLE_ITEMS-----
 
local shopModule = ShopModule:new()
npcHandler:addModule(shopModule)

shopModule:addBuyableItem({'white pearl'},		2143, 320)
shopModule:addBuyableItem({'black pearl'},		2144, 560)
shopModule:addBuyableItem({'small diamond'},		2145, 600)
shopModule:addBuyableItem({'small sapphire'},		2146, 500)
shopModule:addBuyableItem({'small ruby'},		2147, 500)
shopModule:addBuyableItem({'small emerald'},	        2149, 500)
shopModule:addBuyableItem({'small amethyst'},		2150, 400)

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, DianeBehaviour)