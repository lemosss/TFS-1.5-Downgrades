local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)            npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)         npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)    npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                        npcHandler:onThink()                        end

keywordHandler:addKeyword({'job'}, StdModule.say, {
	npcHandler = npcHandler, onlyFocus = true,
	text = 'I am a knight instructor. I teach my fellow knights their {spells}.'
})

-- Spellbook (auto-generated): teach all spells of this NPC vocation
Spellbook.teach(npcHandler, keywordHandler, 4, Spellbook.knight)

npcHandler:setMessage(MESSAGE_GREET, "Greetings, |PLAYERNAME|. I teach knight {spells}. What would you like to learn?")

npcHandler:addModule(FocusModule:new())
