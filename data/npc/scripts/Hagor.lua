local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)			npcHandler:onCreatureAppear(cid)			end
function onCreatureDisappear(cid)		npcHandler:onCreatureDisappear(cid)			end
function onCreatureSay(cid, type, msg)		npcHandler:onCreatureSay(cid, type, msg)		end
function onThink()				npcHandler:onThink()					end

-- Spellbook (auto-generated): teach all spells of this NPC vocation
Spellbook.teach(npcHandler, keywordHandler, 3, Spellbook.paladin)

npcHandler:setMessage(MESSAGE_GREET, "Greetings, |PLAYERNAME|. I teach paladin {spells}. What would you like to learn?")

npcHandler:addModule(FocusModule:new())
