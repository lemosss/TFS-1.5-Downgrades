local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)            npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)         npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)    npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                        npcHandler:onThink()                        end

local voices = { {text = '<mumble>'} }
npcHandler:addModule(VoiceModule:new(voices))

-- Sorcerer Guild Leader of Liberty Bay. The spell list lives in
-- data/npc/lib/spellbook.lua and is wired up via Spellbook.teach below.

keywordHandler:addKeyword({'job'}, StdModule.say, {
	npcHandler = npcHandler, onlyFocus = true,
	text = 'I am the Sorcerer Guild Leader of Liberty Bay, sent by the Edron Magical Academy. I teach sorcerer {spells}.'
})
keywordHandler:addKeyword({'magic'}, StdModule.say, {
	npcHandler = npcHandler, onlyFocus = true,
	text = 'Magic is the gift of those who walk the path of the sorcerer. Ask me to teach you any {spell} you want to learn.'
})
keywordHandler:addKeyword({'name'}, StdModule.say, {
	npcHandler = npcHandler, onlyFocus = true,
	text = 'My name is Malunga. I run the sorcerer guild here.'
})

npcHandler:setMessage(MESSAGE_GREET, "Greetings, |PLAYERNAME|. I teach sorcerer {spells}. What would you like to learn?")
npcHandler:setMessage(MESSAGE_FAREWELL, "Farewell, |PLAYERNAME|.")
npcHandler:setMessage(MESSAGE_WALKAWAY, "Hmpf.")

-- Spellbook (auto-generated): teach all spells of this NPC vocation
Spellbook.teach(npcHandler, keywordHandler, 1, Spellbook.sorcerer)

npcHandler:addModule(FocusModule:new())
