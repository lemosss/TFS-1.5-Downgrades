local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)
local talkState = {}
local talkUser = NPCHANDLER_CONVBEHAVIOR == CONVERSATION_DEFAULT and 0 or cid 

npcHandler:setMessage(MESSAGE_GREET, "I greet thee, my loyal subject.")
npcHandler:setMessage(MESSAGE_FAREWELL, "Farewell, |PLAYERNAME|!")

function onCreatureAppear(cid)                  npcHandler:onCreatureAppear(cid)          end
function onCreatureDisappear(cid)               npcHandler:onCreatureDisappear(cid)       end
function onCreatureSay(cid, type, msg)          npcHandler:onCreatureSay(cid, type, msg)  end
function onThink()                              npcHandler:onThink()                      end
 
function LanaGreetCallback(cid)
 if (isFemale(cid) == TRUE) then
    npcHandler:setMessage(MESSAGE_WALKAWAY, "What a strange behaviour for a lady!")
 else
    npcHandler:setMessage(MESSAGE_WALKAWAY, "Typical behaviour for males!")
 end
 talkState[talkUser] = 0
 return 1
end

function LanaSayCallback (cid, type, msg)

     if (msgcontains(msg:lower(),"hello") or msgcontains(msg:lower(),'hail') or msgcontains(msg:lower(),'salutations')) and (msgcontains(msg:lower(),'queen')) and (npcHandler.focus == 0) then
           npcHandler:greet(cid)
     elseif (msgcontains(msg:lower(),'bye') or msgcontains(msg:lower(),'farewell')) and (npcHandler.focus > 0) and (npcHandler.focus == cid) then
           npcHandler:onFarewell(cid)

	elseif(msgcontains(msg:lower(),"promotion") or msgcontains(msg:lower(),"promot")) and (npcHandler.focus == cid) then
                        npcHandler:say("Do you want to be promoted in your vocation for "..getConfigValue("PromotionCost").." gold?")
                        talkState[talkUser] = 1
	elseif(msgcontains(msg:lower(),"yes")) and (talkState[talkUser] == 1) and (npcHandler.focus == cid) then
                        talkState[talkUser] = 0
	    if getPlayerVocation(cid) > 4 then
                        npcHandler:say("You are already promoted.")
	       elseif (19 > getPlayerLevel(cid)) then
			npcHandler:say("You need to be at least level 20 in order to be promoted.")
	       elseif (getConfigValue("PromotionCost") > getPlayerMoney(cid)) then
			npcHandler:say("You do not have enough money.")
	       elseif (isPremium(cid) == false) then
		        npcHandler:say("You need a premium account in order to promote.")
	    else
			doPlayerSetVocation(cid, getPlayerVocation(cid)+4)
			doPlayerRemoveMoney(cid, getConfigValue("PromotionCost"))
                        doPlayerUpdateLevelLossPercent(cid)
                        doSendMagicEffect(getPlayerPosition(cid),12)
		        npcHandler:say("Congratulations! You are now promoted. Visit the sage Eremo for new spells.")
                        talkState[talkUser] = 0
	    end
	end
local keywords = {
["job"] = {response = "I am Queen Lana. It is my duty to reign over this marvellous city and the lands of the north."},
["justice"] = {response = "We women try to bring justice and wisdom to all, even to males."},
["name"] = {response = "I am Queen Lana. For you it's 'My Queen' or 'Your Majesty', of course."},
["news"] = {response = "I don't care about gossip like a simpleminded male would do."},
["tibia"] = {response = "Soon the whole land will be ruled by women at last!"},
["land"] = {response = "Soon the whole land will be ruled by women at last!"},
["how are you"] = {response = "Thank you, I'm fine."},
["castle"] = {response = "It's my humble domain."},
["god"] = {response = "We honor the gods of good in our fair city, especially Crunor, of course."},
["citizen"] = {response = "All citizens of Carlin are my subjects. I see them more as my childs, though, epecially the male population."},
["noodles"] = {response = "This beast scared my cat away on my last diplomatic mission in this filthy town."},
["ferumbras"] = {response = "He is the scourge of the whole continent!"},
["treasure"] = {response = "The royal treasure is hidden beyond the grasps of any thieves by magical means."},
["monster"] = {response = "Go and hunt them! For queen and country!"},
["help"] = {response = "Visit the church or the townguards for help."},
["quest"] = {response = "I will call for heroes as soon as the need arises again."},
["mission"] = {response = "I will call for heroes as soon as the need arises again."},
["gold"] = {response = "Our city is rich and prospering."},
["money"] = {response = "Our city is rich and prospering."},
["tax"] = {response = "Our city is rich and prospering."},
["sewer"] = {response = "I don't want to talk about 'sewers'."},
["dungeon"] = {response = "Dungeons are places where males crawl around and look for trouble."},
["equipment"] = {response = "Feel free to visit our town's magnificent shops."},
["food"] = {response = "Feel free to visit our town's magnificent shops."},
["time"] = {response = "Don't worry about time in the presence of your Queen."},
["hero"] = {response = "We need the assistance of heroes now and then. Even males prove useful now and then."},
["adventurer"] = {response = "We need the assistance of heroes now and then. Even males prove useful now and then."},
["tax collector"] = {response = "The taxes in Carlin are not high, more a symbol than a sacrifice."},
["queen"] = {response = "I am the Queen, the only rightful ruler on the continent!"},
["army"] = {response = "Ask one of the soldiers about that."},
["enemy"] = {response = "Our enemies are numerous. We have to fight vile monsters and have to watch this silly king in the south carefully."}, 
["enemies"] = {response = "Our enemies are numerous. We have to fight vile monsters and have to watch this silly king in the south carefully." },
["thais"] = {response = "They dare to reject my reign over them!"},
["city south"] = {response = "They dare to reject my reign over them!"},
["carlin"] = {response = "Isn't our city marvellous? Have you noticed the lovely gardens on the roofs?"},
["city"] = {response = "Isn't our city marvellous? Have you noticed the lovely gardens on the roofs?"},
["shop"] = {response = "My subjects maintain many fine shops. Go and have a look at their wares."},
["merchant"] = {response = "Ask around about them."},
["craftsmen"] = {response = "Ask around about them."},
["guild"] = {response = "The four major guilds are the Knights, the Paladins, the Druids, and the Sorcerers."},
["minotaur"] = {response = "They havn't troubled our city lately. I guess, they fear the wrath of our druids."},
["paladin"] = {response = "The paladins are great hunters."},
["legola"] = {response = "The paladins are great hunters."},
["elane"] = {response = "It's a shame that the High Paladin does not reside in Carlin."},
["knight"] = {response = "The knights of Carlin are the bravest."},
["trisha"] = {response = "The knights of Carlin are the bravest."},
["sorceror"] = {response = "The sorcerers have a small isle for their guild. So if they blow something up it does not burn the whole city to ruins."},
["lea"] = {response = "The sorcerers have a small isle for their guild. So if they blow something up it does not burn the whole city to ruins."},
["druid"] = {response = "The druids of Carlin are our protectors and advisors. Their powers provide us with wealth and food."},
["padreia"] = {response = "The druids of Carlin are our protectors and advisors. Their powers provide us with wealth and food."},
["good"] = {response = "Carlin is a center of the forces of good, of course."},
["evil"] = {response = "The forces of evil have a firm grip on this puny city to the south."},
["order"] = {response = "The order, Crunor gives the world, is essential for survival."},
["chaos"] = {response = "Chaos is common in the southern regions, where they allow a man to reign over a realm."},
["excalibug"] = {response = "A mans tale ... that means 'nonsense', of course."},
["reward"] = {response = "If you want a reward, go and bring me something this silly King Tibianus wants dearly!"},
["tbi"] = {response = "A dusgusting organisation, which could be only created by men."},
}
  for v in pairs(keywords) do
    if (msgcontains(msg, v)) then
        npcHandler:say(keywords[v].response, cid)
    end
  end
  return 1
end


npcHandler:setCallback(CALLBACK_GREET, LanaGreetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, LanaSayCallback)