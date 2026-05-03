local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)			npcHandler:onCreatureAppear(cid)			end
function onCreatureDisappear(cid)		npcHandler:onCreatureDisappear(cid)			end
function onCreatureSay(cid, type, msg)		npcHandler:onCreatureSay(cid, type, msg)		end
function onThink()				npcHandler:onThink()					end

local function greetCallback(cid)
	if Player(cid):getCondition(CONDITION_DRUNK) then
		npcHandler:setMessage(MESSAGE_GREET, 'Hey t-there, you look like someone who enjoys a good {booze}.')
	else
		npcHandler:say('Oh, two t-trolls. Hellooo, wittle twolls. <hicks>', cid)
		return false
	end
	return true
end

keywordHandler:addKeyword({'booze'}, StdModule.say, {npcHandler = npcHandler, text = 'Did I say booze? I meant, {flamingo}. <hicks> Pink birds are kinda cool, don\'t you think? Especially on a painting.'})
keywordHandler:addKeyword({'flamingo'}, StdModule.say, {npcHandler = npcHandler, text = 'You have to enjoy the word. Like, {flayyyminnngoooo}. Say it with me. <hicks>'})
keywordHandler:addKeyword({'flayyyminnngoooo'}, StdModule.say, {npcHandler = npcHandler, text = 'Yes, you got it! Hahaha, we understand each other. Good {job}. <hicks>'})
keywordHandler:addKeyword({'job'}, StdModule.say, {npcHandler = npcHandler, text = 'I\'m a killer! Yeshindeed! A masterful assassin. I prefer that too \'Peekay\'. <hicks>'})

npcHandler:setMessage(MESSAGE_FAREWELL, 'T-time for another b-beer. <hicks>')
npcHandler:setMessage(MESSAGE_WALKAWAY, 'Oh, two t-trolls. Hellooo, wittle twolls. <hicks>')

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:addModule(FocusModule:new())