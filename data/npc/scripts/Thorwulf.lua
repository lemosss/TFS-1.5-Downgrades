local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)			npcHandler:onCreatureAppear(cid)			end
function onCreatureDisappear(cid)		npcHandler:onCreatureDisappear(cid)			end
function onCreatureSay(cid, type, msg)		npcHandler:onCreatureSay(cid, type, msg)		end
function onThink()				npcHandler:onThink()					end

npcHandler:setMessage(MESSAGE_GREET, "Greetings, |PLAYERNAME|. I teach knight {spells}. What would you like to learn?")
npcHandler:setMessage(MESSAGE_FAREWELL, 'Bye |PLAYERNAME|.')
npcHandler:setMessage(MESSAGE_WALKAWAY, 'Bye.')

-- Spellbook (auto-generated): teach all spells of this NPC vocation
Spellbook.teach(npcHandler, keywordHandler, 4, Spellbook.knight)

npcHandler:addModule(FocusModule:new())
