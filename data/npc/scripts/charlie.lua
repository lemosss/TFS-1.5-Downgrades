local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)
local Count, Money
function onCreatureAppear(cid)                  npcHandler:onCreatureAppear(cid)                        end
function onCreatureDisappear(cid)               npcHandler:onCreatureDisappear(cid)                     end
function onCreatureSay(cid, type, msg)  npcHandler:onCreatureSay(cid, type, msg)        end
function onThink()                                            npcHandler:onThink()    end

function CharlieBehaviour (cid, type, msg)
  if(not npcHandler:isFocused(cid)) then
     return 0
  end
             if (getCount(msg) > 1) and (msgcontains(msg, "parcel")) then
               if (getPlayerStorageValue(cid, 666) == 1) then
                   Count = getCount(msg)
                   Money = 10
                 npcHandler:say("Do you want to buy "..Count.." parcels for "..Money*Count.." gold?")
                 npcHandler:doTopic(cid, 1)
               else
                   Count = getCount(msg)
                   Money = 15
                 npcHandler:say("Do you want to buy "..Count.." parcels for "..Money*Count.." gold?")
                 npcHandler:doTopic(cid, 1)
               end
             elseif (msgcontains(msg, "parcel")) then
               if (getPlayerStorageValue(cid, 666) == 1) then
                   Count = 1
                   Money = 10
                 npcHandler:say("Do you want to buy a parcel for "..Money.." gold?")
                 npcHandler:doTopic(cid, 1)
               else
                   Count = 1
                   Money = 15
                 npcHandler:say("Do you want to buy a parcel for "..Money.." gold?")
                 npcHandler:doTopic(cid, 1)
               end
             elseif (msgcontains(msg, "yes")) and (npcHandler.Topic == 1) then
                 if (doPlayerRemoveMoney(cid,Money*Count) == 1) then
	              for i=1, Count do
		         doPlayerAddItem(cid, 2595)
		         doPlayerAddItem(cid, 2599)
                      end
                     npcHandler:say("Here you are. Don't forget to write the name and the address of the receiver on the label. The label has to be in the parcel before you put the parcel in a mailbox.")
                 else
                     npcHandler:say("Oh, you do not have enough gold to buy a parcel.")
                 end
                     npcHandler:doTopic(cid, 0)

             elseif (getCount(msg) > 1) and (msgcontains(msg, "letter")) then
               if (getPlayerStorageValue(cid, 666) == 1) then
                   Count = getCount(msg)
                   Money = 5
                 npcHandler:say("Do you want to buy "..Count.." letters for "..Money*Count.." gold?")
                 npcHandler:doTopic(cid, 2)
               else
                   Count = getCount(msg)
                   Money = 8
                 npcHandler:say("Do you want to buy "..Count.." letters for "..Money*Count.." gold?")
                 npcHandler:doTopic(cid, 2)
               end
             elseif (msgcontains(msg, "letter")) then
               if (getPlayerStorageValue(cid, 666) == 1) then
                   Count = 1
                   Money = 5
                 npcHandler:say("Do you want to buy a letter for "..Money.." gold?")
                 npcHandler:doTopic(cid, 2)
               else
                   Count = 1
                   Money = 8
                 npcHandler:say("Do you want to buy a letter for "..Money.." gold?")
                 npcHandler:doTopic(cid, 2)
               end
             elseif (msgcontains(msg, "yes")) and (npcHandler.Topic == 2) then
                 if (doPlayerRemoveMoney(cid,Money*Count) == 1) then
	              for i=1, Count do
		         doPlayerAddItem(cid, 2597)
                      end
                     npcHandler:say("Here it is. Don't forget to write the name of the receiver in the first line and the address in the second one before you put the letter in a mailbox.")
                 else
                     npcHandler:say("Oh, you do not have enough gold to buy a letter.")
                 end
                     npcHandler:doTopic(cid, 0)

            elseif (npcHandler.Topic == 1) or (npcHandler.Topic == 2) then
                    npcHandler:doTopic(cid, 0)
                    npcHandler:say("Ok.")
            elseif (msgcontains(msg, 'mail')) then
                    npcHandler:doTopic(cid, 5)
                    npcHandler:say("Our mail system is unique! And everyone can use it. Do you want to know more about it?.")
            elseif (msgcontains(msg, 'yes')) and (npcHandler.Topic == 5) then
                    npcHandler:doTopic(cid, 0)
                    npcHandler:say("The Tibia Mail System enables you to send and receive letters and parcels. You can buy them here if you want.")
            elseif (npcHandler.Topic == 5) then
                    npcHandler:doTopic(cid, 0)
                    npcHandler:say("Is there anything else I can do for you?")

            elseif(msgcontains(msg:lower(),'measurements')) and (getPlayerStorageValue(cid, 682) > 0) and (getPlayerStorageValue(cid, 684) < 0) then
                   npcHandler:say("Oh they dont change that much since in the old days as... <tells a boring and confusing story about a cake, a parcel, himself and two squirrels, at least he tells you his measurements in the end>",cid)
                   setPlayerStorageValue(cid,684,1)
                   setPlayerStorageValue(cid,682,(getPlayerStorageValue(cid, 682)+1))
	    end

local keywords = {
["kevin"] = {response = "That name sounds familiar... who might that be..."},
["postner"] = {response = "That name sounds familiar... who might that be..."},
["postmasters guild"] = {response = "Hm, I think I heard about that guild... oh wait, I am a member!"},
["join"] = {response = "Uh... oh... Uhm... Join what?" },
["headquarter"] = {response = "Its just... I mean... there was that road, oh yes, its that house at that road."},
["job"] = {response = "I am working here at the post office. If you have questions about the Royal Tibia Mail System or the depots ask me."},
["office"] = {response = "I am always in my office. You are welcome at any time."},
["name"] = {response = "My name is Charlie."},
["time"] = {response = "Now it's "..getTime()..". Maybe you want to buy a watch?"},
["depot"] = {response = "The depots are very easy to use. Just step in front of them and you will find your items in them. They are free for all tibian citizens. Hail our king!"},
["king"] = {response = "Oops, the king? I... can't remember his name..."},
["Calvin"] = {response = "Ah, King Calvin II, our wise ruler. He is sick for some time, isn't he?"},
["quentin"] = {response = "Ooooh, nice man, visits me often... I think."},
["lynda"] = {response = "She is SO pretty!"},
["harkath"] = {response = "Oh, young Harkath will be a fine warrior some day." },
["army"] = {response = "TO THE ARMS! MAN THE WALLS! FERUMBRAS IS NEAR!", Idle = 1},
["ferumbras"] = {response = "TO THE ARMS! MAN THE WALLS! FERUMBRAS IS NEAR!", Idle = 1},
["general"] = {response = "TO THE ARMS! MAN THE WALLS! FERUMBRAS IS NEAR!", Idle = 1},
["sam"] = {response = "Ham? No thanks, I ate fish already."},
["frodo"] = {response = "Frodo... Frodo... ? Uhm... isn't that the man that brings me food at lunchtime?"},
["gorn"] = {response = "He sells equipment." },
["elane"] = {response = "Oh, she lives next door. I think she's a dentist, I sometimes hear some cries."},
["muriel"] = {response = "This Muriel has a lot of correspondence."},
["gregor"] = {response = "Never heared of him."},
["marvik"] = {response = "He is always talking of healing me but I am fine... I fear he is a little nuts, poor man."},
["bozo"] = {response = "He hangs around here quite often. He claimes, I inspire him."},
["baxter"] = {response = "This naughty child, always stealing apples!" },
["sherry"] = {response = "I don't drink alcohol while on duty." },
["lugri"] = {response = "NO! NO! NO! GO AWAY!.", Idle = 1},
["excalibug"] = {response = "I can't remember that someone named like that lives here."},
["news"] = {response = "Sorry, I don't read the letters we transmit."},
["Meadowfield "] = {response = "This is the town you are currently in."},
["carlin"] = {response = "You can sent letters and parcels to Carlin."},
["xodet"] = {response = "The young sorcerer is a good businessman."},
["quero"] = {response = "I love his music! He is my best friend and I visit him as often as I can."},
}
  for v in pairs(keywords) do
    if (msgcontains(msg, v)) then
      if (keywords[v].Idle == 1) then
          npcHandler:say(keywords[v].response, cid)
          npcHandler:Idle(cid, 4)
      else
          npcHandler:say(keywords[v].response, cid)
          npcHandler:doTopic(cid, 0)	
      end
    end
  end
  return 1
end
 
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, CharlieBehaviour)
npcHandler:addModule(FocusModule:new())