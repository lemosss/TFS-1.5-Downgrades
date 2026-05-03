local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)			npcHandler:onCreatureAppear(cid)			end
function onCreatureDisappear(cid)		npcHandler:onCreatureDisappear(cid)			end
function onCreatureSay(cid, type, msg)		npcHandler:onCreatureSay(cid, type, msg)		end
function onThink()		npcHandler:onThink()		end

local voices = { {text = 'Stop by and rest a while, tired adventurer! Have a look at my wares!'} }
npcHandler:addModule(VoiceModule:new(voices))

keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I am selling equipment for adventurers. If you need anything, let me know.'})
keywordHandler:addKeyword({'dog'}, StdModule.say, {npcHandler = npcHandler, text = 'This is Ruffy my dog, please don\'t do him any harm.'})
keywordHandler:addKeyword({'offer'}, StdModule.say, {npcHandler = npcHandler, text = 'I sell torches, fishing rods, worms, ropes, water hoses, backpacks, apples, and maps.'})
keywordHandler:addKeyword({'name'}, StdModule.say, {npcHandler = npcHandler, text = 'I am Lubo, the owner of this shop.'})
keywordHandler:addKeyword({'maps'}, StdModule.say, {npcHandler = npcHandler, text = 'Oh! I\'m sorry, I sold the last one just five minutes ago.'})
keywordHandler:addKeyword({'hat'}, StdModule.say, {npcHandler = npcHandler, text = 'My hat? Hanna made this one for me.'})
keywordHandler:addKeyword({'finger'}, StdModule.say, {npcHandler = npcHandler, text = 'Oh, you sure mean this old story about the mage Dago, who lost two fingers when he conjured a dragon.'})
keywordHandler:addKeyword({'pet'}, StdModule.say, {npcHandler = npcHandler, text = 'There are some strange stories about a magicians pet names. Ask Hoggle about it.'})

npcHandler:setMessage(MESSAGE_GREET, 'Welcome to my adventurer shop, |PLAYERNAME|! What do you need? Ask me for a {trade} to look at my wares.')
npcHandler:setMessage(MESSAGE_FAREWELL, 'Good bye, |PLAYERNAME|.')
npcHandler:setMessage(MESSAGE_WALKAWAY, 'Good bye.')

npcHandler:addModule(FocusModule:new())
