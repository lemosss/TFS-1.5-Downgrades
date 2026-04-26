local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)				npcHandler:onCreatureAppear(cid) end
function onCreatureDisappear(cid) 			npcHandler:onCreatureDisappear(cid) end
function onCreatureSay(cid, type, msg) 	npcHandler:onCreatureSay(cid, type, msg) end
function onThink() 						npcHandler:onThink() end

function ConnyBehaviour (cid, type, msg)

npcHandler:AddFocus({"hi", "hello"}, "Oh, please come in, |PLAYERNAME|. What do you need?", 0, cid, msg)
npcHandler:AddQueue({"hi", "hello"}, "Sorry |PLAYERNAME|, I am already talking to a customer. Wait a moment.", 0, cid, msg)
npcHandler:RemoveFocus({"bye", "farewell"}, "Good bye.", 0, cid, msg)

if(not npcHandler:isFocused(cid)) then
   return 0
end

local keywords = {
["job"] = {response = "I am selling equipment of all kinds. Do you need anything?"},
["name"] = {response = "I am Conny. My goods are known all over Tibia."},
["time"] = {response = "It is exactly "..getTime()..". Maybe you want to buy a watch?"},
["food"] = {response = "If you are looking for food, go to Frodo's Hut."},
["king"] = {response = "The king supports Tibia's economy a lot."},
["tibianus"] = {response = "The king supports Tibia's economy a lot."},
["quentin"] = {response = "He advices newcomers to buy at my store. I love that guy!"},
["lynda"] = {response = "That's a pretty one."},
["harkath"] = {response = "I hardly know him." },
["army"] = {response = "Armies are too hierarchical for my taste."},
["ferumbras"] = {response = "We had a clash or two in the old days."},
["general"] = {response = "I don't like titles." },
["sam"] = {response = "Strong as an ox, could armwrestle a minotaur, I bet."},
["frodo"] = {response = "Frodo is a jolly fellow."},
["elane"] = {response = "Elane is the leader of the paladin guild."},
["paladin"] = {response = "Elane is the leader of the paladin guild."},
["muriel"] = {response = "You can find Muriel in the sorcerer guild."},
["sorcerer"] = {response = "You can find Muriel in the sorcerer guild."},
["gregor"] = {response = "Even the strong knights need my equipment on their travels though Tibia."},
["knight"] = {response = "Even the strong knights need my equipment on their travels though Tibia."},
["marvik"] = {response = "These druids are nice people, you will find them in the east of the town."},
["druid"] = {response = "These druids are nice people, you will find them in the east of the town."},
["bozo"] = {response = "Bah! Go away with this bozoguy."},
["baxter"] = {response = "Old Baxter was a rowdy, once. In our youth we shared some adventures and women." },
["oswald"] = {response = "This Oswald has not enough to work and too much time to spread rumours." },
["sherry"] = {response = "I hardly know the McRonalds." },
["donald"] = {response = "I hardly know the McRonalds." },
["mcronald"] = {response = "I hardly know the McRonalds."  },
["lugri"] = {response = "Never heared that name."},
["excalibug"] = {response = "I would pay thousands of gold coins for this weapon."},
["news"] = {response = "Taxes will increase soon, so buy as much as you can right now."},
["offer"] = {response = "My inventory is large, just have a look at the blackboards."},
["goods"] = {response = "My inventory is large, just have a look at the blackboards."},
["do you sell"] = {response = "My inventory is large, just have a look at the blackboards."},
["do you have"] = {response = "My inventory is large, just have a look at the blackboards."},
["equipment"] = {response = "My inventory is large, just have a look at the blackboards."},
["ammunition"] = {response = "Galuna sells them now in her own shop. Go and ask her about that."},
["bow"] = {response = "Galuna sells them now in her own shop. Go and ask her about that."},
["crossbow"] = {response = "Galuna sells them now in her own shop. Go and ask her about that."},
["arrow"] = {response = "Galuna sells them now in her own shop. Go and ask her about that."},
["bolt"] = {response = "Galuna sells them now in her own shop. Go and ask her about that."},
["galuna"] = {response = "In the past she delivered me with all the bows and arrows. She has now her own shop at the paladin guild."},
["magic"] = {response = "Magic? Ask a sorcerer or druid about that."},
["fluid"] = {response = "Find the magic shop."},
["xodet"] = {response = "He owns the magic shop here. But be aware: The prices are enormous."},
["book"] = {response = "I offer different kind of books: brown, black and small books. Which book do you want?"},
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

------BUY_ABLE_ITEMS-----
 
shopModule:addBuyableItem({'torch'},		2050, 2)
shopModule:addBuyableItem({'bag'},		1987, 4)
shopModule:addBuyableItem({'backpack'},		1988, 20)
shopModule:addBuyableItem({'present'},		1990, 10)
shopModule:addBuyableItem({'scroll'},		1949, 5)
shopModule:addBuyableItem({'document'},		1952, 12)
shopModule:addBuyableItem({'parchment'},	1951, 8)
shopModule:addBuyableItem({'bucket'},		2005, 4, 0, "Do you want to buy a bucket for |TOTALCOST| gold?", "Do you want to buy |ITEMCOUNT| buckets for |TOTALCOST| gold?")
shopModule:addBuyableItem({'bottle'},		2007, 3, 0, "Do you want to buy a bottle for |TOTALCOST| gold?", "Do you want to buy |ITEMCOUNT| bottles for |TOTALCOST| gold?")
shopModule:addBuyableItem({'mug'},		2012, 4, 0, "Do you want to buy a mug for |TOTALCOST| gold?", "Do you want to buy |ITEMCOUNT| mugs for |TOTALCOST| gold?")
shopModule:addBuyableItem({'cup'},		2013, 2, 0, "Do you want to buy a cup for |TOTALCOST| gold?", "Do you want to buy |ITEMCOUNT| cups for |TOTALCOST| gold?")
shopModule:addBuyableItem({'jug'},		2014, 10, 0, "Do you want to buy a jug for |TOTALCOST| gold?", "Do you want to buy |ITEMCOUNT| jugs for |TOTALCOST| gold?")
shopModule:addBuyableItem({'plate'},		2035, 6)
shopModule:addBuyableItem({'watch'},		2036, 20)
shopModule:addBuyableItem({'football'},		2109, 111)
shopModule:addBuyableItem({'rope'},		2120, 50)
shopModule:addBuyableItem({'machete'},		2420, 40)
shopModule:addBuyableItem({'scythe'},		2550, 50)
shopModule:addBuyableItem({'pick'},		2553, 50)
shopModule:addBuyableItem({'shovel'},		2554, 50)
shopModule:addBuyableItem({'rod'},	        2580, 150)
shopModule:addBuyableItem({'brown book'},	1971, 15)
shopModule:addBuyableItem({'black book'},	1972, 15)
shopModule:addBuyableItem({'small book'},	1973, 15)

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, ConnyBehaviour)