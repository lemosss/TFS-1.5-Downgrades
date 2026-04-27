-- OTX 'Simple Task' mod (Vodkart) — config block ported into TFS 1.5.
-- Original file: solebraserver/otserv1/mods/task.xml (config name="task_func").
-- Loaded via the domodlib stub in data/npc/lib/npc.lua and the matching
-- KillTask creaturescript in data/creaturescripts/scripts/task_kill.lua.

max_task_per_time = 3

tasktabble = {
	["trolls"]            = {monster_race={"troll","frost troll","furious troll","island troll","swamp troll","troll champion","troll legionnaire"}, storage_site=800201, storage_start=200201, storage=91001, count=100, exp=10000,  money=2000},
	["goblins"]           = {monster_race={"goblin","goblin assassin","goblin leader"}, storage_site=800202, storage_start=200202, storage=91002, count=100, exp=10000,  money=2000},
	["rotworms"]          = {monster_race={"rotworm","carrion worm"}, storage_site=800203, storage_start=200203, storage=91003, count=150, exp=15500,  money=2000},
	["cyclops"]           = {monster_race={"cyclops","cyclops smith","cyclops drone"}, storage_site=800204, storage_start=200204, storage=91004, count=500, exp=150000, money=10000},
	["dwarf guards"]      = {monster_race={"dwarf guard"}, storage_site=800205, storage_start=200205, storage=91005, count=500, exp=200000, money=15000},
	["orc warlords"]      = {monster_race={"orc warlord"}, storage_site=800206, storage_start=200248, storage=91048, count=250, exp=18000},
	["dwarfs"]            = {monster_race={"dwarf guard","dwarf","dwarf soldier"}, storage_site=800207, storage_start=200249, storage=91049, count=250, exp=30000,  money=2000},
	["orcs"]              = {monster_race={"orc","orc warrior","orc warlord","orc shaman","orc rider","orc leader","orc berserker","orc spearman"}, storage_site=800208, storage_start=200206, storage=91006, count=150, exp=10000,  money=3000},
	["tarantulas"]        = {monster_race={"tarantula"}, storage_site=800209, storage_start=200207, storage=91007, count=200, exp=55000,  money=5000},
	["demon skeletons"]   = {monster_race={"demon skeleton"}, storage_site=800210, storage_start=200208, storage=91008, count=200, exp=120000},
	["minotaurs"]         = {monster_race={"minotaur","minotaur archer","minotaur mage","minotaur guard"}, storage_site=800211, storage_start=200209, storage=91009, count=500, exp=75000,  money=10000},
	["necromancers"]      = {monster_race={"necromancer","priestess"}, storage_site=800212, storage_start=200210, storage=91010, count=350, exp=350000, reward={{2195,1}}},
	["carniphilas"]       = {monster_race={"carniphila"}, storage_site=800213, storage_start=200211, storage=91011, count=75,  exp=35000},
	["apes"]              = {monster_race={"kongra","sibang","merlkin"}, storage_site=800214, storage_start=200212, storage=91012, count=450, exp=200000, money=10000},
	["fire elementals"]   = {monster_race={"fire elemental"}, storage_site=800215, storage_start=200213, storage=91013, count=150, exp=110000},
	["dragons"]           = {monster_race={"dragon"}, storage_site=800216, storage_start=200214, storage=91014, count=300, exp=350000},
	["pandas"]            = {monster_race={"panda"}, storage_site=800217, storage_start=200215, storage=91015, count=50,  exp=5500,   money=5000},
	["giant spiders"]     = {monster_race={"giant spider"}, storage_site=800218, storage_start=200216, storage=91016, count=350, exp=350000, money=20000},
	["hydras"]            = {monster_race={"hydra"}, storage_site=800219, storage_start=200217, storage=91017, count=350, exp=850000},
	["serpent spawns"]    = {monster_race={"serpent spawn"}, storage_site=800220, storage_start=200218, storage=91018, count=450, exp=930000},
	["behemoths"]         = {monster_race={"behemoth"}, storage_site=800221, storage_start=200219, storage=91019, count=500, exp=950000},
	["crocodiles"]        = {monster_race={"crocodile"}, storage_site=800222, storage_start=200220, storage=91020, count=150, exp=11000,  money=2500},
	["demons"]            = {monster_race={"demon"}, storage_site=800223, storage_start=200221, storage=91021, count=666, exp=1900000},
	["terror birds"]      = {monster_race={"terror bird"}, storage_site=800224, storage_start=200222, storage=91022, count=50,  exp=80000,  money=10000},
	["larvas"]            = {monster_race={"larva"}, storage_site=800225, storage_start=200223, storage=91023, count=200, exp=20000,  money=2000},
	["humans"]            = {monster_race={"smuggler","bandit","amazon","assassin","hero","black knight","stalker","hunter","valkyrie","dark monk","monk","necromancer","witch","wild warrior","priestess"}, storage_site=800226, storage_start=200224, storage=91024, count=500, exp=50000,  money=15000},
	["scarabs"]           = {monster_race={"scarab","ancient scarab"}, storage_site=800227, storage_start=200225, storage=91025, count=300, exp=55000,  money=5000},
	["vampires"]          = {monster_race={"vampire"}, storage_site=800228, storage_start=200226, storage=91026, count=500, exp=350000, reward={{2534,1}}},
	["ancient scarabs"]   = {monster_race={"ancient scarab"}, storage_site=800229, storage_start=200227, storage=91027, count=300, exp=300000, money=15000},
	["heros"]             = {monster_race={"hero"}, storage_site=800230, storage_start=200228, storage=91028, count=100, exp=250000, reward={{2488,1}}},
	["black knights"]     = {monster_race={"black knight"}, storage_site=800231, storage_start=200229, storage=91029, count=50,  exp=250000, reward={{2414,1}}},
	["dragon lords"]      = {monster_race={"dragon lord"}, storage_site=800232, storage_start=200230, storage=91030, count=550, exp=850000},
	["warlocks"]          = {monster_race={"warlock"}, storage_site=800233, storage_start=200231, storage=91031, count=400, exp=1100000},
	["lost souls"]        = {monster_race={"lost soul"}, storage_site=800234, storage_start=200232, storage=91032, count=150, exp=920000},
	["nightmares"]        = {monster_race={"nightmare"}, storage_site=800235, storage_start=200233, storage=91033, count=100, exp=890000},
	["dark torturers"]    = {monster_race={"dark torturer"}, storage_site=800236, storage_start=200234, storage=91034, count=250, exp=1250000},
	["plaguesmiths"]      = {monster_race={"plaguesmith"}, storage_site=800237, storage_start=200235, storage=91035, count=350, exp=950000},
	["defilers"]          = {monster_race={"defiler"}, storage_site=800238, storage_start=200236, storage=91036, count=250, exp=950000},
	["hellfire fighters"] = {monster_race={"hellfire fighter"}, storage_site=800239, storage_start=200237, storage=91037, count=250, exp=1500000},
	["destroyers"]        = {monster_race={"destroyer"}, storage_site=800240, storage_start=200238, storage=91038, count=200, exp=900000},
	["diabolic imps"]     = {monster_race={"diabolic imp"}, storage_site=800241, storage_start=200239, storage=91039, count=150, exp=700000},
	["hellhounds"]        = {monster_race={"hellhound"}, storage_site=800242, storage_start=200240, storage=91040, count=500, exp=1700000},
	["blightwalkers"]     = {monster_race={"blightwalker"}, storage_site=800243, storage_start=200241, storage=91041, count=200, exp=950000},
	["hand of cursed fates"] = {monster_race={"hand of cursed fate"}, storage_site=800244, storage_start=200242, storage=91042, count=150, exp=1200000},
	["son of verminors"]  = {monster_race={"son of verminor"}, storage_site=800245, storage_start=200243, storage=91043, count=150, exp=500000},
	["juggernauts"]       = {monster_race={"juggernaut"}, storage_site=800246, storage_start=200244, storage=91044, count=200, exp=1550000},
	["undead dragons"]    = {monster_race={"undead dragon"}, storage_site=800247, storage_start=200245, storage=91045, count=200, exp=1300000},
	["betrayed wraiths"]  = {monster_race={"betrayed wraith"}, storage_site=800248, storage_start=200246, storage=91046, count=200, exp=900000},
	["phantasms"]         = {monster_race={"phantasm"}, storage_site=800249, storage_start=200247, storage=91047, count=180, exp=850000},
	["ghouls"]            = {monster_race={"ghoul"}, storage_site=800250, storage_start=200250, storage=91050, count=300, exp=60000,  money=5000},
	["lizards"]           = {monster_race={"lizard sentinel","lizard snakecharmer","lizard templar"}, storage_site=800251, storage_start=200251, storage=91051, count=450, exp=105000, money=10000},
	["orc berserkers"]    = {monster_race={"orc berserker"}, storage_site=800252, storage_start=200252, storage=91052, count=350, exp=95000,  money=5000},
	["orc leaders"]       = {monster_race={"orc leader"}, storage_site=800253, storage_start=200253, storage=91053, count=350, exp=105000, money=5000},
	["frost dragons"]     = {monster_race={"frost dragon"}, storage_site=800255, storage_start=200255, storage=91055, count=500, exp=500000, reward={{2492,1}}}
}

-- ----- Player-facing helpers -----

function checkTasks(cid)
	local tasks = {}
	for k, v in pairs(tasktabble) do
		if getPlayerStorageValue(cid, v.storage_start) >= 1 then
			tasks[#tasks + 1] = {k, v}
		end
	end
	return tasks
end

function isOnScreen(position, comparePosition)
	if math.abs(position.y - comparePosition.y) > 6
		or math.abs(position.x - comparePosition.x) > 7
		or position.z ~= comparePosition.z then
		return false
	end
	return true
end

-- Adds items from a list to the player. Stacks stackable items, tries to fit.
function doAddItemsFromList(cid, items)
	if not items or #items == 0 then return end
	local p = Player(cid)
	if not p then return end
	for i = 1, #items do
		local id, count = items[i][1], items[i][2] or 1
		p:addItem(id, count)
	end
end

-- Called by NPC when finishing the LAST possible task (all 50 tasks completed).
function finisheAllTask(cid)
	local config = {
		exp     = {true, 1000000},
		money   = {true, 200000},
		items   = {false, {{5537,1},{5538,1}}},
		premium = {true, 10},
	}

	local x = true
	for _, v in pairs(tasktabble) do
		if tonumber(getPlayerStorageValue(cid, v.storage_site)) <= 0 then
			x = false
			break
		end
	end

	if not x then return end

	setPlayerStorageValue(cid, 521456, 0)
	local b = Game.getStorageValue(63005)
	if b == -1 then b = 1 end
	if b < 11 then
		Game.setStorageValue(63005, b + 1)
		Game.broadcastMessage('[Task Mission Complete] '..getCreatureName(cid)..' was the '..b..' to finish the task!.')
		local p = Player(cid)
		if p then
			if config.premium[1] then p:addPremiumDays(config.premium[2]) end
			if config.exp[1]     then p:addExperience(config.exp[2]) end
			if config.money[1]   then p:addMoney(config.money[2]) end
			if config.items[1]   then doAddItemsFromList(cid, config.items[2]) end
			local trophy = p:addItem(7369, 1)
			if trophy then
				trophy:setAttribute(ITEM_ATTRIBUTE_NAME, "trophy "..p:getName().." completed all the task.")
			end
		end
	end
end

-- Reward delivery for a single completed task. Called from the NPC dialog
-- when the player asks to collect a finished task.
function giveTaskReward(cid, race)
	local mob = tasktabble[race]
	if not mob then return false end
	local p = Player(cid)
	if not p then return false end
	if mob.exp     and mob.exp > 0     then p:addExperience(mob.exp) end
	if mob.money   and mob.money > 0   then p:addMoney(mob.money) end
	if mob.reward then doAddItemsFromList(cid, mob.reward) end
	-- Mark as completed (storage = 'finished' sentinel) and clear the active flag.
	setPlayerStorageValue(cid, mob.storage, 'finished')
	setPlayerStorageValue(cid, mob.storage_start, 0)
	setPlayerStorageValue(cid, mob.storage_site, 1)
	return true
end
