local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)				npcHandler:onCreatureAppear(cid) end
function onCreatureDisappear(cid) 			npcHandler:onCreatureDisappear(cid) end
function onCreatureSay(cid, type, msg) 	npcHandler:onCreatureSay(cid, type, msg) end
function onThink() 						npcHandler:onThink() end

function OttoBehaviour (cid, type, msg)

npcHandler:AddFocus({"hi", "hello"}, "Hello, |PLAYERNAME|. Can I be of any assistance?", 0, cid, msg)
npcHandler:AddQueue({"hi", "hello"}, "I'm so sorry, but I simply must talk to this customer first. Please wait a moment", 0, cid, msg)
npcHandler:RemoveFocus({"bye", "farewell"}, "Good bye. Do come again!", 0, cid, msg)

if(not npcHandler:isFocused(cid)) then
   return 0
end
        if(msgcontains(msg, 'rumour') or msgcontains(msg, 'news') or msgcontains(msg, 'gossip')) and (npcHandler:isFocused(cid)) then
                npcHandler:say("You know a rumour? Well then - don't keep it to yourself.",cid)
                npcHandler:doTopic(cid, 1)
        elseif (npcHandler.Topic == 1) and (npcHandler:isFocused(cid)) then
	        npcHandler:say("Go on! I can't wait to hear more!",cid)
                npcHandler:doTopic(cid, 0)
        end

local keywords = {
["job"] = {response = "I am the blacksmith. If you need weapons or armor - just ask me."},
["how are you"] = {response = "I'm just fine and dandy, thank you for asking."},
["job"] = {response = "It is an absolute honour to provide weaponry and armor to the courageous adventurers of Thais, just so long as you have the gold to pay for it."},
["name"] = {response = "Some call me Otto. Actually, everybody calls me Otto."},
["time"] = {response = "It is nearly time for my afternoon nap, so please hurry!"},
["help"] = {response = "Help to self-help - that is my motto."},
["monster"] = {response = "There is a monster here? HERE?! Time to double the prices!"},
["dungeon"] = {response = "If you want to see dungeons go and insult the guards.  On second thoughts - don't do that."},
["sewer"] = {response = "It is very effective, but attracts almost as many wannabe heroes as it does rats."},
["assistant"] = {response = "I am not a mere assistant! I have a job of great responsibility! But mostly I keep annoying personages away from my boss."},
["annoying"] = {response = "Oh gosh - I could tell you some stories. But I won't."},
["thank you"] = {response = "So polite . . . bless you!"},
["god"] = {response = "The Gods of Tibia play games with the fate of Tibians - but they haven't bothered to read the instructions."},
["king"] = {response = "Ah, yes, yes, hail to King Tibianus! May he in his infinite wisdom reduce my taxes... and so on..."},
["sam"] = {response = "A simple shopkeeper, who was last in the queue when they were handing out intelligence."},
["benjamin"] = {response = "Ah, such a shame about poor Benjamin. Lost it a bit after receiving one too many blows to the head."},
["gorn"] = {response = "He does a good line in second-rate scrolls for first-rate prices." },
["quentin"] = {response = "You can't tech an old monk new tricks. He is stubborn to the extreme and overly concerned about Thais. He should care more about his gods and less about that king."},
["bozo"] = {response = "Bozo - such a tragic story. If only I could remember it." },
["weapon"] = {response = "The word on the street is that Sam does not forge all his weapons himself, but buys them from his cousin, who is married to a cyclops."},
["magic"] = {response = "Magic is a thing of the past. Why bother with a colourful bit of rock and a few fancy words when you can have a foot of razor-sharp steel in your hand?!"},
["power"] = {response = "There are people who talk about a rebellion against King Tibianus."},
["rebellion"] = {response = "Well, Venore is richer than Thais, and some people want to live in a democracy free from an oppressive tyrant - I mean monarch. I'm not one of them."},
["spell"] = {response = "Spells - dodgy mumbo jumbo if you ask me. A sword never backfires on its user!"},
["elane"] = {response = "A true tragedy - she has lost so many husbands in such unusual circumstances." },
["venore"] = {response = "Ah... Venore - a wonderful city! Full of culture! So many friendly faces! So unlike Thais!"},
["thais"] = {response = "Thais is OK - I suppose. Not as nice as Venore, but good for business."},
["carlin"] = {response = "Those women really know how to run things - look at how well the trade is going there!"},
["kazordoon"] = {response = "You need to shrink before you go there - they say the dwarves aren't too keen on sharing their mountain with us Tibians."},
["dwarves"] = {response = "I don't know much about them - there are some civilised dwarves, of course, but I can never tell whether they are male or female."},
["Ab'dendriel"] = {response = "Aah... a beautiful leafy city. Shame about the elves."},
["elves"] = {response = "Elves are good with a bow and arrow, or so I am told. Shame that they are no good at peace-making."},
["chester"] = {response = "I have never heard any rumours concerning him, isn't that odd?"},
["ardua"] = {response = "Well - she isn't really my kind of person. Please don't mention her name again."},
["partos"] = {response = "Some thief they caught for all I know."},
["gamel"] = {response = "Some sinister guy that is. He's not allowed to enter that markethall and thats for a good reason."},
["gamon"] = {response = "Shhh! He's a spy! He watches us all the time! Just keep smiling and he'll go away!"},
["quest"] = {response = "Hmmm yes. I think Topsy might have something for you."},
["offer"] = {response = "My offers are weapons, armors, helmets, legs, and shields."},
["do you sell"] = {response = "My offers are weapons, armors, helmets, legs, and shields."},
["do you have"] = {response = "My offers are weapons, armors, helmets, legs, and shields."},
["weapon"] = {response = "I have hand axes, axes, spears, maces, battle hammers, swords, rapiers, daggers, and sabres. What's your choice?"},
["helmet"] = {response = "I am selling leather helmets and chain helmets. What do you want?"},
["armor"] = {response = "I am selling leather, chain, and brass armor. What do you need?"},
["shield"] = {response = "I am selling wooden shields and steel shields. What do you want?"},
["trousers"] = {response = "I am selling chain legs. Do you want to buy any?"},
["legs"] = {response = "I am selling chain legs. Do you want to buy any?"},
}
  for v in pairs(keywords) do
    if (msgcontains(msg, v)) and (npcHandler:isFocused(cid)) then
        npcHandler:say(keywords[v].response, cid)
        npcHandler:doTopic(cid, 0)
    end
  end
  return 1
end

local shopModule = ShopModule:new()
npcHandler:addModule(shopModule)

------BUY_ABLE_ITEMS-----

shopModule:addBuyableItem({'dagger'},		        2379, 5)
shopModule:addBuyableItem({'hand axe'},		        2380, 8)
shopModule:addBuyableItem({'spear'},		        2389, 10)
shopModule:addBuyableItem({'rapier'},		 	2384, 15)
shopModule:addBuyableItem({'sabre'},		 	2385, 35)
shopModule:addBuyableItem({'mace'},		 	2398, 90)
shopModule:addBuyableItem({'throwing knife'},		2410, 25)
shopModule:addBuyableItem({'battle hammer'},		2417, 350)
shopModule:addBuyableItem({'axe'},		        2386, 20)
shopModule:addBuyableItem({'sword'},		        2376, 85)

shopModule:addBuyableItem({'chain armor'},		2464, 200)
shopModule:addBuyableItem({'brass armor'},		2465, 450)
shopModule:addBuyableItem({'leather armor'},		2467, 35)
shopModule:addBuyableItem({'chain helmet'},		2458, 52)
shopModule:addBuyableItem({'leather helmet'},	        2461, 12)
shopModule:addBuyableItem({'steel shield'},		2509, 240)
shopModule:addBuyableItem({'wooden shield'},		2512, 15)
shopModule:addBuyableItem({'chain legs'},		2648, 80)
shopModule:addBuyableItem({'sabre'},		 	2385, 12)

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, OttoBehaviour)