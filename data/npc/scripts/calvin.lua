local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

npcHandler:setMessage(MESSAGE_GREET, "I greet thee, my loyal subject.")
npcHandler:setMessage(MESSAGE_WALKAWAY, "What a lack of manners!")
npcHandler:setMessage(MESSAGE_FAREWELL, "Good bye, |PLAYERNAME|!")

function onCreatureAppear(cid)                  npcHandler:onCreatureAppear(cid)                        end
function onCreatureDisappear(cid)               npcHandler:onCreatureDisappear(cid)                     end
function onCreatureSay(cid, type, msg)  npcHandler:onCreatureSay(cid, type, msg)        end
function onThink()                                              npcHandler:onThink()    end
 
function TibianusSayCallback (cid, type, msg)

     if (msgcontains(msg:lower(),"hello") or msgcontains(msg:lower(),'hail') or msgcontains(msg:lower(),'salutations')) and (msgcontains(msg:lower(),'king')) and (npcHandler.focus == 0) then
           npcHandler:greet(cid)
     elseif (msgcontains(msg:lower(),'bye') or msgcontains(msg:lower(),'farewell')) and (npcHandler.focus > 0) and (npcHandler.focus == cid) then
           npcHandler:onFarewell(cid)

	elseif(msgcontains(msg:lower(),"promotion") or msgcontains(msg:lower(),"promot")) and (npcHandler.focus == cid) then
                        npcHandler:say("Do you want to be promoted in your vocation for "..getConfigValue("PromotionCost").." gold?")
                        npcHandler:doTopic(cid, 1)
	elseif(msgcontains(msg:lower(),"yes")) and (npcHandler.Topic == 1) and (npcHandler.focus == cid) then
                        npcHandler:doTopic(cid, 0)
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
                        npcHandler:doTopic(cid, 0)
	    end

	elseif (npcHandler.Topic == 1) and (npcHandler.focus == cid) then
		npcHandler:say("Ok, then not.", cid)
                npcHandler:doTopic(cid, 0)
	end
local keywords = {
["job"] = {response = "I am your sovereign, King Tibianus III, and it's my duty to provide justice and guidance for my subjects."},
["justice"] = {response = "I try my best to be just and fair to our citizens. The army and the TBI are a great help for fulfilling this duty."},
["name"] = {response = "It's hard to believe that you don't know your own king!"},
["news"] = {response = "The latest news are usually brought to our magnificent town by brave adventurers. They spread tales of their journeys at Frodo's tavern."},
["tibia"] = {response = "Soon the whole land will be ruled by me once again!"},
["land"] = {response = "Soon the whole land will be ruled by me once again!"},
["how are you"] = {response = "Thank you, I'm fine."},
["castle"] = {response = "Rain Castle is my home."},
["sell"] = {response = "Sell? Sell what? My kingdom isn't for sale!"},
["god"] = {response = "Honor the gods and pay your taxes."},
["zathroth"] = {response = "Please ask a priest about the gods."},
["citizen"] = {response = "The citizens of Tibia are my subjects. Ask the old monk Quentin to learn more about them."},
["sam"] = {response = "He is a skilled blacksmith and a loyal subject."},
["frodo"] = {response = "He is the owner of Frodo's Hut and a faithful tax-payer."},
["gorn"] = {response = "He was once one of Tibia's greatest fighters. Now he is selling equipment."},
["benjamin"] = {response = "He was once my greatest general. Now he is very old and senile but we entrusted him with work for the Royal Tibia Mail."},
["harkath"] = {response = "Harkath Bloodblade is the general of our glorious army."},
["bloodblade"] = {response = "Harkath Bloodblade is the general of our glorious army."},
["general"] = {response = "Harkath Bloodblade is the general of our glorious army."},
["noodles"] = {response = "The royal poodle Noodles is my greatest treasure!"},
["ferumbras"] = {response = "He is a follower of the evil god Zathroth and responsible for many attacks on us. Kill him on sight!"},
["bozo"] = {response = "He is my royal jester and cheers me up now and then."},
["treasure"] = {response = "The royal poodle Noodles is my greatest treasure!"},
["monster"] = {response = "Go and hunt them! For king and country!"},
["help"] = {response = "Visit Quentin, the monk, for help."},
["quest"] = {response = "I will call for heroes as soon as the need arises again and then reward them appropriately."},
["mission"] = {response = "I will call for heroes as soon as the need arises again and then reward them appropriately."},
["gold"] = {response = "To pay your taxes, visit the royal tax collector."},
["money"] = {response = "To pay your taxes, visit the royal tax collector."},
["tax"] = {response = "To pay your taxes, visit the royal tax collector."},
["sewer"] = {response = "What a disgusting topic!"},
["dungeon"] = {response = "Dungeons are no places for kings."},
["equipment"] = {response = "Feel free to buy it in our town's fine shops."},
["food"] = {response = "Ask the royal cook for some food."},
["time"] = {response = "It's a time for heroes, that's for sure!"},
["heroes"] = {response = "It's a time for heroes, that's for sure!"},
["hero"] = {response = "It's a time for heroes, that's for sure!"},
["adventurer"] = {response = "It's a time for heroes, that's for sure!"},
["tax collector"] = {response = "He has been lazy lately. I bet you have not payed any taxes at all."},
["king"] = {response = "I am the king, so mind your words!"},
["army"] = {response =  "Ask the soldiers about that topic."},
["enemy"] = {response = "Our enemies are numerous. The evil minotaurs, Ferumbras, and the renegade city of Carlin to the north are just some of them."},
["enemies"] = {response = "Our enemies are numerous. The evil minotaurs, Ferumbras, and the renegade city of Carlin to the north are just some of them." },
["city north"] = {response = "They dare to reject my reign over the whole continent!"},
["carlin"] = {response = "They dare to reject my reign over the whole continent!"},
["meadowfield"] = {response = "Our beloved city has some fine shops, guildhouses, and a modern system of sewers."},
["city"] = {response = "Our beloved city has some fine shops, guildhouses, and a modern system of sewers."},
["shop"] = {response = "Visit the shops of our merchants and craftsmen."},
["merchant"] = {response = "Ask around about them."},
["craftsmen"] = {response = "Ask around about them."},
["guild"] = {response = "The four major guilds are the knights, the paladins, the druids, and the sorcerers."},
["minotaur"] = {response = "Vile monsters, but I must admit they are strong and sometimes even cunning ... in their own bestial way."},
["paladin"] = {response = "The paladins are great protectors for meadowfield."},
["elane"] = {response = "The paladins are great protectors for meadowfield."},
["knight"] = {response = "The brave knights are necessary for human survival in meadowfield."},
["gregor"] = {response = "The brave knights are necessary for human survival in meadowfield."},
["sorcerer"] = {response = "The magic of the sorcerers is a powerful tool to smite our enemies."},
["muriel"] = {response = "The magic of the sorcerers is a powerful tool to smite our enemies."},
["druid"] = {response = "We need the druidic healing powers to fight evil."},
["marvik"] = {response = "We need the druidic healing powers to fight evil."},
["good"] = {response = "The forces of good are hard pressed in these dark times."},
["evil"] = {response = "We need all strength we can muster to smite evil!"},
["order"] = {response = "We need order to survive!"},
["chaos"] = {response = "Chaos arises from selfishness, and that's its weakness."},
["excalibug"] = {response = "It's the sword of the kings. If you could return this weapon to me I would reward you beyond your dreams."},
["reward"] = {response = "Well, if you want a reward, go on a quest to bring me Excalibug!"},
["chester"] = {response = "A very competent person. A little nervous but very competent."},
["tbi"] = {response = "This organisation is important in holding our enemies in check. Its headquarter is located in the bastion in the northwall."},
["eremo"] = {response = "It is said that he lives on a small island near Edron. Maybe the people there know more about him."},
}
  for v in pairs(keywords) do
    if (msgcontains(msg, v)) and (npcHandler.focus == cid) then
        npcHandler:say(keywords[v].response, cid)
        npcHandler:doTopic(cid, 0)
    end
  end
  return 1
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, TibianusSayCallback)