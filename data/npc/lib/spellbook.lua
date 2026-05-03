-- Spellbook: shared catalogue of every learnable spell per vocation, with
-- Cipsoft 8.0 reference prices. Each NPC who teaches spells just calls
-- Spellbook.teach(npcHandler, keywordHandler, vocId, Spellbook.<voc>) and gets
-- the full keyword tree wired up.
--
-- Server policy: every NPC of a given vocation teaches the FULL spell list
-- of that class. There are no premium-only spells; free and premium accounts
-- buy from the same NPCs at the same prices. Premium only gates city access
-- via captains (see data/lib/miscellaneous/free_cities.lua).
--
-- Vocation ids (TFS): 1=sorc, 2=druid, 3=pal, 4=knight (5-8 are the promoted
-- variants; passing the base id is fine, learnSpell handles inheritance).

Spellbook = {}

-- {name, words, price, level}
Spellbook.sorcerer = {
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

Spellbook.druid = {
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
	{'Food',                 'exevo pan',         300,   14},
	{'Haste',                'utani hur',         600,   14},
	{'Magic Shield',         'utamo vita',        450,   14},
	{'Poison Field',         'adevo grav pox',   1500,   14},
	{'Light Magic Missile',  'adori',             500,   15},
	{'Fire Field',           'adevo grav flam',  1500,   15},
	{'Antidote Rune',        'adana pox',         200,   15},
	{'Intense Healing Rune', 'adura gran',        600,   15},
	{'Convince Creature',    'adeta sio',         800,   16},
	{'Destroy Field',        'adito grav',       1500,   17},
	{'Heal Friend',          'exura sio',         600,   18},
	{'Energy Field',         'adevo grav vis',   1500,   18},
	{'Strong Haste',         'utani gran hur',   1300,   20},
	{'Ultimate Healing',     'exura vita',       1000,   20},
	{'Envenom',              'adevo res pox',    1500,   21},
	{'Disintegrate',         'adito tera',       2000,   21},
	{'Creature Illusion',    'utevo res ina',    1500,   23},
	{'Ultimate Healing Rune','adura vita',       1000,   24},
	{'Summon Creature',      'utevo res',         600,   25},
	{'Heavy Magic Missile',  'adori gran',       1500,   25},
	{'Poison Bomb',          'adevo mas pox',    1000,   25},
	{'Ultimate Light',       'utevo vis lux',    1500,   26},
	{'Firebomb',             'adevo mas flam',   1500,   27},
	{'Soulfire',             'adevo res flam',    800,   27},
	{'Animate Dead',         'adana mort',       4000,   27},
	{'Chameleon',            'adevo ina',        2000,   27},
	{'Wild Growth',          'adevo grav vita',  2300,   27},
	{'Poison Wall',          'adevo mas grav pox',2900,  29},
	{'Explosion',            'adevo mas hur',    1800,   31},
	{'Fire Wall',            'adevo mas grav flam',2900, 33},
	{'Invisibility',         'utana vid',        2000,   35},
	{'Mass Healing',         'exura gran mas res',4000,  36},
	{'Energy Wall',          'adevo mas grav vis',2900,  41},
	{'Poison Storm',         'exevo gran mas pox',7500,  50},
	{'Paralyze',             'adana ani',       13200,   54},
	{'Blank Rune',           'adori blank',       100,    1},
}

Spellbook.paladin = {
	{'Light',                'utevo lux',           0,    8},
	{'Find Person',          'exiva',              80,    8},
	{'Light Healing',        'exura',             170,    9},
	{'Magic Rope',           'exani tera',        200,    9},
	{'Cure Poison',          'exana pox',         150,   10},
	{'Intense Healing',      'exura gran',        350,   11},
	{'Levitate',             'exani hur',         500,   12},
	{'Conjure Arrow',        'exevo con',         450,   13},
	{'Great Light',          'utevo gran lux',    500,   13},
	{'Haste',                'utani hur',         600,   14},
	{'Conjure Poisoned Arrow','exevo con pox',    700,   16},
	{'Conjure Bolt',         'exevo con mort',    750,   17},
	{'Destroy Field',        'adito grav',       1500,   17},
	{'Disintegrate',         'adito tera',       2000,   21},
	{'Ethereal Spear',       'exori con',        1900,   23},
	{'Conjure Sniper Arrow', 'exevo con hur',    1100,   24},
	{'Conjure Explosive Arrow','exevo con flam', 1450,   25},
	{'Cancel Invisibility',  'exana ina',        2200,   26},
	{'Conjure Piercing Bolt','exevo con grav',   1300,   33},
	{'Enchant Spear',        'exeta con',        1700,   45},
	{'Conjure Power Bolt',   'exevo con vis',    4500,   59},
	{'Blank Rune',           'adori blank',       100,    1},
}

Spellbook.knight = {
	{'Find Person',          'exiva',              80,    8},
	{'Light',                'utevo lux',           0,    8},
	{'Light Healing',        'exura',             170,    9},
	{'Magic Rope',           'exani tera',        200,    9},
	{'Cure Poison',          'exana pox',         150,   10},
	{'Levitate',             'exani hur',         500,   12},
	{'Great Light',          'utevo gran lux',    500,   13},
	{'Haste',                'utani hur',         600,   14},
	{'Whirlwind Throw',      'exori hur',        1500,   15},
	{'Challenge',            'exeta res',         600,   20},
	{'Groundshaker',         'exori mas',        1500,   33},
	{'Berserk',              'exori',            2500,   35},
	{'Fierce Berserk',       'exori gran',       7500,   70},
}

-- Vocation labels and example spells (4 short names per voc, picked across the
-- level range so the player gets a sense of what's available).
Spellbook.vocLabel = {[1]='sorcerer', [2]='druid', [3]='paladin', [4]='knight'}
Spellbook.vocExamples = {
	[1] = {'fireball', 'ultimate healing', 'magic wall', 'sudden death'},
	[2] = {'ultimate healing rune', 'mass healing', 'wild growth', 'paralyze'},
	[3] = {'ethereal spear', 'conjure arrow', 'cancel invisibility', 'enchant spear'},
	[4] = {'challenge', 'whirlwind throw', 'berserk', 'fierce berserk'},
}

-- Wire one keyword node per spell in the catalogue. Player triggers a node
-- by saying either the spell NAME ("fireball") or the incantation
-- ("adori flam"). Substring matching means longer names must register first,
-- otherwise "great fireball" would match "fireball". Sort the catalogue by
-- name length DESC before iterating.
function Spellbook.teach(npcHandler, keywordHandler, vocId, catalogue)
	local sorted = {}
	for i, e in ipairs(catalogue) do sorted[i] = e end
	table.sort(sorted, function(a, b) return #a[1] > #b[1] end)

	for _, e in ipairs(sorted) do
		local name, words, price, level = e[1], e[2], e[3], e[4]
		local lower = string.lower(name)
		local node = keywordHandler:addKeyword({lower}, StdModule.say, {
			npcHandler = npcHandler, onlyFocus = true,
			text = 'Would you like to learn ' .. name .. ' for ' .. price .. ' gold coins?'
		})
		node:addChildKeyword({'yes'}, StdModule.learnSpell, {
			npcHandler = npcHandler, premium = false,
			spellName = name, vocation = vocId, price = price, level = level
		})
		node:addChildKeyword({'no'}, StdModule.say, {
			npcHandler = npcHandler, onlyFocus = true,
			text = 'Maybe another time then.', reset = true
		})
		if string.lower(words) ~= lower then
			keywordHandler:addAliasKeyword({string.lower(words)})
		end
	end

	-- Generic 'spells' help keyword. Saying "spells" lists what the NPC teaches
	-- with a few clickable example names. Registered once per handler — for
	-- hybrid NPCs (Eroth/Rahkem teach sorc+druid) we append the second voc.
	local label = Spellbook.vocLabel[vocId] or 'all'
	if not npcHandler._spellbookHelpRegistered then
		local examples = Spellbook.vocExamples[vocId]
		local exText = examples
			and (' Try one of these to start: {' .. table.concat(examples, '}, {') .. '}.')
			or  ''
		keywordHandler:addKeyword({'spells'}, StdModule.say, {
			npcHandler = npcHandler, onlyFocus = true,
			text = 'I teach all ' .. label .. ' spells. Just tell me the spell name to learn it.' .. exText
		})
		npcHandler._spellbookHelpRegistered = label
	elseif npcHandler._spellbookHelpRegistered ~= label then
		-- Hybrid NPC: replace the help with a combined text the second time.
		local combined = npcHandler._spellbookHelpRegistered .. ' and ' .. label
		keywordHandler:addKeyword({'spells'}, StdModule.say, {
			npcHandler = npcHandler, onlyFocus = true,
			text = 'I teach all ' .. combined .. ' spells. Just tell me the spell name to learn it.'
		})
		npcHandler._spellbookHelpRegistered = combined
	end
end
