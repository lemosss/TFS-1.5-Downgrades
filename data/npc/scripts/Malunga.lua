local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)            npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)         npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)    npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                        npcHandler:onThink()                        end

local voices = { {text = '<mumble>'} }
npcHandler:addModule(VoiceModule:new(voices))

-- Sorcerer Guild Leader of Liberty Bay. Teaches every sorcerer-only instant
-- spell available in the server's spells.xml. Pricing follows the standard
-- 8.0 Cipsoft pricing pattern.

local SORC = 1  -- vocation 1 = Sorcerer (Master Sorcerer 5 covered automatically)

local function teach(name, words, price, level)
	-- Player triggers the keyword by saying the spell NAME (e.g. "fireball"),
	-- not the incantation. Spell name is also accepted via the incantation as
	-- a fallback so "exura vita" works the same as "ultimate healing".
	local lower = string.lower(name)
	local node = keywordHandler:addKeyword({lower}, StdModule.say, {
		npcHandler = npcHandler, onlyFocus = true,
		text = 'Would you like to learn ' .. name .. ' for ' .. price .. ' gold coins?'
	})
	node:addChildKeyword({'yes'}, StdModule.learnSpell, {
		npcHandler = npcHandler, premium = false,
		spellName = name, vocation = SORC, price = price, level = level
	})
	node:addChildKeyword({'no'}, StdModule.say, {
		npcHandler = npcHandler, onlyFocus = true,
		text = 'Maybe another time then.', reset = true
	})
	-- Also bind the incantation as alias to the same parent (yes/no children inherit).
	if string.lower(words) ~= lower then
		keywordHandler:addAliasKeyword({string.lower(words)})
	end
end

-- Spell catalogue: { name, words, price, level }. Keyword handler does
-- substring matching, so a player saying "great fireball" would match
-- the shorter "fireball" keyword first. Fix: sort by name length DESC so
-- the longer/more-specific keyword registers first and wins the match.
local CATALOG = {
	{'Light',                'utevo lux',           0,    8},
	{'Find Person',          'exiva',              80,    8},
	{'Light Healing',        'exura',             170,    9},
	{'Magic Rope',           'exani tera',        200,    9},
	{'Cure Poison',          'exana pox',         150,   10},
	{'Force Strike',         'exori mort',        800,   11},
	{'Intense Healing',      'exura gran',        350,   11},
	{'Energy Strike',        'exori vis',         800,   12},
	{'Flame Strike',         'exori flam',        800,   12},
	{'Levitate',             'exani hur',         500,   12},
	{'Great Light',          'utevo gran lux',    500,   13},
	{'Haste',                'utani hur',         600,   14},
	{'Magic Shield',         'utamo vita',        450,   14},
	{'Poison Field',         'adevo grav pox',   1500,   14},
	{'Light Magic Missile',  'adori',             500,   15},
	{'Fire Field',           'adevo grav flam',  1500,   15},
	{'Destroy Field',        'adito grav',       1500,   17},
	{'Fire Wave',            'exevo flam hur',    850,   18},
	{'Energy Field',         'adevo grav vis',   1500,   18},
	{'Strong Haste',         'utani gran hur',   1300,   20},
	{'Ultimate Healing',     'exura vita',       1000,   20},
	{'Envenom',              'adevo res pox',    1500,   21},
	{'Disintegrate',         'adito tera',       2000,   21},
	{'Creature Illusion',    'utevo res ina',    1500,   23},
	{'Energy Beam',          'exevo vis lux',    2000,   23},
	{'Summon Creature',      'utevo res',         600,   25},
	{'Heavy Magic Missile',  'adori gran',       1500,   25},
	{'Ultimate Light',       'utevo vis lux',    1500,   26},
	{'Fireball',             'adori flam',       1200,   27},
	{'Firebomb',             'adevo mas flam',   1500,   27},
	{'Soulfire',             'adevo res flam',    800,   27},
	{'Animate Dead',         'adana mort',       4000,   27},
	{'Great Energy Beam',    'exevo gran vis lux',3500,  29},
	{'Poison Wall',          'adevo mas grav pox',2900,  29},
	{'Great Fireball',       'adori gran flam',  1200,   30},
	{'Explosion',            'adevo mas hur',    1800,   31},
	{'Magic Wall',           'adevo grav tera',  1900,   32},
	{'Fire Wall',            'adevo mas grav flam',2900, 33},
	{'Invisibility',         'utana vid',        2000,   35},
	{'Energybomb',           'adevo mas vis',    1500,   37},
	{'Energy Wave',          'exevo mort hur',   2500,   38},
	{'Enchant Staff',        'exeta vis',        2000,   41},
	{'Energy Wall',          'adevo mas grav vis',2900,  41},
	{'Sudden Death',         'adori vita vis',   3000,   45},
	{'Ultimate Explosion',   'exevo gran mas vis',5000,  60},
	{'Blank Rune',           'adori blank',       100,    1},
}

-- Register longest spell-name first so substring matches resolve correctly.
table.sort(CATALOG, function(a, b) return #a[1] > #b[1] end)
for _, e in ipairs(CATALOG) do
	teach(e[1], e[2], e[3], e[4])
end

keywordHandler:addKeyword({'spells'}, StdModule.say, {
	npcHandler = npcHandler, onlyFocus = true,
	text = 'I teach all sorcerer spells. Just tell me the spell name (e.g. {fireball}, {ultimate healing}, {magic wall}, {sudden death}).'
})
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

npcHandler:addModule(FocusModule:new())
