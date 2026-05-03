local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)			npcHandler:onCreatureAppear(cid)			end
function onCreatureDisappear(cid)		npcHandler:onCreatureDisappear(cid)			end
function onCreatureSay(cid, type, msg)		npcHandler:onCreatureSay(cid, type, msg)		end
function onThink()		npcHandler:onThink()		end

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end

	local player = Player(cid)
	if msgcontains(msg, '') or msgcontains(msg, '') then
		if not player:hasMount(11) then
				npcHandler:say('You did bring all the items I requqested, cuild. Good. Shall I travel to the spirit realm and try finding a stampor compasion for you?', cid)
				npcHandler.topic[cid] = 1
		else
			npcHandler:say('You already have stampor mount.', cid)
			npcHandler.topic[cid] = 0
		end
	elseif msgcontains(msg, 'yes') then
		if npcHandler.topic[cid] == 1 then
			if player:removeItem(13299, 50) and player:removeItem(13301, 30) and player:removeItem(13300, 100) then
				npcHandler:say({
					'Ohhhhh Mmmmmmmmmmmm Ammmmmgggggggaaaaaaa ...',
					'Aaaaaaaaaahhmmmm Mmmaaaaaaaaaa Kaaaaaamaaaa ...',
					'Brrt! I think it worked! It\'s a male stampor. I linked this spirit to yours. You can probably already summon him to you ...',
					'So, since me are done here... I need to prepare another ritual, so please let me work, cuild.'
				}, cid)
				player:addMount(11)
				player:getPosition():sendMagicEffect(CONST_ME_MAGIC_RED)
			else
				npcHandler:say('Sorry you don\'t have the necessary items.', cid)
			end
			npcHandler.topic[cid] = 0
		end
	elseif msgcontains(msg, 'no') and npcHandler.topic[cid] > 2 then
		npcHandler:say('Maybe next time.', cid)
		npcHandler.topic[cid] = 0
	end
	return true
end

-- Wooden Stake
keywordHandler:addKeyword({'stake'}, StdModule.say, {npcHandler = npcHandler, text = 'Ten prayers for a blessed stake? Don\'t tell me they made you travel whole Tibia for it! Listen, child, if you bring me a wooden stake, I\'ll bless it for you. <chuckles>'},
	function(player) return player:getStorageValue(Storage.FriendsandTraders.TheBlessedStake) == 11 end,
	function(player) player:setStorageValue(Storage.FriendsandTraders.TheBlessedStake, 12) player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE) end
)

local stakeKeyword = keywordHandler:addKeyword({'stake'}, StdModule.say, {npcHandler = npcHandler, text = 'Would you like to receive a spiritual prayer to bless your stake?'},
		function(player) return player:getStorageValue(Storage.FriendsandTraders.TheBlessedStake) == 12 end
	)

	stakeKeyword:addChildKeyword({'yes'}, StdModule.say, {npcHandler = npcHandler, text = 'You don\'t have a wooden stake.', reset = true}, function(player) return player:getItemCount(5941) == 0 end)

	stakeKeyword:addChildKeyword({'yes'}, StdModule.say, {npcHandler = npcHandler, text = 'Sorry, but I\'m still exhausted from the last ritual. Please come back later.', reset = true},
		function(player) return player:getStorageValue(Storage.FriendsandTraders.TheBlessedStakeWaitTime) >= os.time() end)

	stakeKeyword:addChildKeyword({'yes'}, StdModule.say, {npcHandler = npcHandler, text = '<mumblemumble> Sha Kesh Mar!', reset = true},
		function(player) return player:getItemCount(5941) > 0 end,
		function(player) player:setStorageValue(Storage.FriendsandTraders.TheBlessedStakeWaitTime, os.time() + 7 * 86400) player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE) player:removeItem(5941, 1) player:addItem(5942, 1) end
	)
	stakeKeyword:addChildKeyword({''}, StdModule.say, {npcHandler = npcHandler, text = 'Maybe another time.', reset = true})

-- Counterspell
keywordHandler:addKeyword({'counterspell'}, StdModule.say, {npcHandler = npcHandler, text = 'You should not talk about things you don\'t know anything about.'}, function(player) return player:getStorageValue(Storage.TheShatteredIsles.DragahsSpellbook) == -1 end)
keywordHandler:addAliasKeyword({'energy field'})

-- Start mission
local counterspellKeyword = keywordHandler:addKeyword({'counterspell'}, StdModule.say, {npcHandler = npcHandler, text = 'You mean, you are interested in a counterspell to cross the energy barrier on Goroma?'}, function(player) return player:getStorageValue(Storage.TheShatteredIsles.TheCounterspell) == -1 end)
	local acceptKeyword = counterspellKeyword:addChildKeyword({'yes'}, StdModule.say, {npcHandler = npcHandler, text = 'This is really not advisable. Behind this barrier, strong forces are raging violently. Are you sure that you want to go there?'})
		acceptKeyword:addChildKeyword({'yes'}, StdModule.say, {npcHandler = npcHandler,
			text = {
				'I guess I cannot stop you then. Since you told me about my apprentice, it\'s my turn to help you. I\'ll perform a ritual for you, but I need a few ingredients. ...',
				'Bring me one fresh dead chicken, one fresh dead rat and one fresh dead black sheep, in that order.'
			}, reset = true}, nil, function(player) player:setStorageValue(Storage.TheShatteredIsles.TheCounterspell, 1) end
		)
		acceptKeyword:addChildKeyword({'no'}, StdModule.say, {npcHandler = npcHandler, text = 'It\'s much safer for you to stay here anyway, trust me.', reset = true})

	counterspellKeyword:addChildKeyword({'no'}, StdModule.say, {npcHandler = npcHandler, text = 'It\'s much safer for you to stay here anyway, trust me.', reset = true})

-- Deliver in corpses
local function addCounterspellKeyword(text, value, itemId)
	local counterspellKeyword = keywordHandler:addKeyword({'counterspell'}, StdModule.say, {npcHandler = npcHandler, text = text[1]}, function(player) return player:getStorageValue(Storage.TheShatteredIsles.TheCounterspell) == value end)
		counterspellKeyword:addChildKeyword({'yes'}, StdModule.say, {npcHandler = npcHandler, text = text[2], reset = true}, function(player) return player:getItemCount(itemId) > 0 end, function(player) player:removeItem(itemId, 1) player:setStorageValue(Storage.TheShatteredIsles.TheCounterspell, value + 1) end)
end

addCounterspellKeyword({'Did you bring the fresh dead chicken?', 'Very good! <mumblemumble> \'Your soul shall be protected!\' Now, I need a fresh dead rat.'}, 1, 4265)
addCounterspellKeyword({'Did you bring the fresh dead rat?', 'Very good! <chants and dances> \'You shall face black magic without fear!\' Now, I need a fresh dead black sheep.'}, 2, 2813)
addCounterspellKeyword({'Did you bring the fresh dead black sheep?', 'Very good! <stomps staff on ground> \'EVIL POWERS SHALL NOT KEEP YOU ANYMORE! SO BE IT!\''}, 3, 2914)

-- Completed the Counterspell
keywordHandler:addKeyword({'counterspell'}, StdModule.say, {npcHandler = npcHandler, text = 'Hm. I don\'t think you need another one of my counterspells to cross the barrier on Goroma.'})

-- Spellbook
keywordHandler:addKeyword({'spellbook'}, StdModule.say, {npcHandler = npcHandler, text = 'Ah, thank you very much! I\'ll honour his memory.'}, function(player) return player:getItemCount(6120) > 0 end, function(player) player:removeItem(6120, 1) player:setStorageValue(Storage.TheShatteredIsles.DragahsSpellbook, 1) end)

-- Energy Field
keywordHandler:addKeyword({'energy field'}, StdModule.say, {npcHandler = npcHandler, text = 'Ah, the energy barrier set up by the cult is maintained by lousy magic, but it\'s still effective. Without a proper counterspell, you won\'t be able to pass it.'})

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
-- Spellbook (auto-generated): teach all spells of this NPC vocation
Spellbook.teach(npcHandler, keywordHandler, 2, Spellbook.druid)

npcHandler:setMessage(MESSAGE_GREET, "Greetings, |PLAYERNAME|. I teach druid {spells} and {trade} a few items. What would you like?")

npcHandler:addModule(FocusModule:new())
