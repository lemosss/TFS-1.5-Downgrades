MonsterBoost = {
	config = {
		update_storage = 751000, -- storage do tempo que foi atualizado

		-- monstros que podem ser escolhidos
		monsters = {"Troll", "Goblin", "Rotworm", "Cyclops", "Dwarf Guard", "Dwarf Guard", "Dwarf", "Orc Warlord", "Orc", "Tarantula", "Demon Skeleton", "Minotaur", "Necromancer", "Carniphila", "Fire Elemental", "Dragon", "Giant Spider", "Hydra", "Serpent Spawn", "Behemoth", "Demon", "Terror Bird", "Larva", "Scarab", "Vampire", "Ancient Scarab", "Hero", "Black Knight", "Dragon Lord", "Warlock", "Lost Soul", "Nightmare", "Dark Torturer", "Plaguesmith", "Defiler", "Diabolic Imp", "Hellhound", "Blightwalker", "Juggernaut", "Undead Dragon", "Betrayed Wraith", "Ghoul", "Orc Berserker", "Orc Leader", "Frost Dragon"},

		-- quantos criam e informações de cada
		create = {
			-- [numero do monstros] (NOTA: precisa ser em ordem numérica)
			[1] = {
				name_storage = 752000, -- storage do monstro escolhido
				exp_storage = 752001, -- storage da exp escolhida

				exp_percent = {3, 5}, -- porcentagem random de X a Y que pode ter

				-- sala de mostruário
				showcase_room = {
					position = {x = 32340, y = 31541, z = 7}, -- posição que o monstro vai ficar
					direction = SOUTH, -- direção que o monstro vai ficar virado
					animated_texts = {
						-- posições do texto animado
						{text = "Boosted!", color = 210, position = {x = 32340, y = 31541, z = 7}},
						{show_exp = true, color = 180, position = {x = 32340, y = 31541, z = 7}}
					},
					area = { -- area da sala
						from = {x = 32338, y = 31541, z = 7},
						to = {x = 32342, y = 31541, z = 7}
					}
				}
			},

			[2] = {
				name_storage = 752002, -- storage do monstro escolhido
				exp_storage = 752003, -- storage da exp escolhida

				exp_percent = {5, 7}, -- porcentagem random de X a Y que pode ter

				-- sala de mostruário
				showcase_room = {
					position = {x = 32340, y = 31541, z = 7}, -- posição que o monstro vai ficar
					direction = SOUTH, -- direção que o monstro vai ficar virado
					animated_texts = {
						-- posições do texto animado
						{text = "Boosted!", color = 210, position = {x = 32340, y = 31543, z = 7}},
						{show_exp = true, color = 180, position = {x = 32340, y = 31543, z = 7}}
					},
					area = { -- area da sala
						from = {x = 32338, y = 31543, z = 7},
						to = {x = 32343, y = 31543, z = 7}
					}
				}
			},
		}

	}
}

math.randomseed(os.mtime())

local function removeCreaturesFromTile(position)
	local topCreature = getTopCreature(position)
	while (topCreature.uid ~= 0) do
		if (isPlayer(topCreature.uid)) then
			doTeleportThing(topCreature.uid, getTownTemplePosition(getPlayerTown(topCreature.uid)), false)
		else
			doRemoveCreature(topCreature.uid)
		end

		topCreature = getTopCreature(position)
	end
end

local function removeCreaturesFromArea(area)
	local position = {}
	for x = area.from.x, area.to.x do
		position.x = x
		for y = area.from.y, area.to.y do
			position.y = y
			for z = area.from.z, area.to.z do
				position.z = z
				removeCreaturesFromTile(position)
			end
		end
	end
end

function MonsterBoost:getLastUpdate()
	return tonumber(getStorage(self.config.update_storage)) or 0
end

function MonsterBoost:setLastUpdate(time)
	doSetStorage(self.config.update_storage, time)
end

function MonsterBoost:update(sendMessage)
	self:setLastUpdate(os.time())

	local monsters = {}
	for i = 1, #self.config.monsters do
		monsters[i] = {name = self.config.monsters[i], index = i}
	end

	local chosen = {}
	for i = 1, #self.config.create do
		local t = self.config.create[i]
		removeCreaturesFromArea(t.showcase_room.area)

		if (#chosen < #monsters) then
			local monster_index = math.random(1, #monsters)
			local monster_info = monsters[monster_index]
			table.remove(monsters, monster_index)

			local monster = doCreateMonster(monster_info.name, t.showcase_room.position, false, true)
			doCreatureSetLookDirection(monster, t.showcase_room.direction)

			local exp = math.random(t.exp_percent[1], t.exp_percent[2])
			doSetStorage(t.name_storage, monster_info.index)
			doSetStorage(t.exp_storage, exp)
			chosen[#chosen + 1] = {name = getCreatureName(monster), exp = exp}
		else
			print("[MonsterBoost:update - Error] Falha ao criar o " .. i .. "° monstro.")
			doSetStorage(t.name_storage, nil)
			doSetStorage(t.exp_storage, nil)
		end
	end

	-- update database
	if (#chosen > 0) then
		for i = 1, #chosen do
			local key = 1000 + i
			local result = db.getResult("SELECT * FROM `global_storage` WHERE `key` = "..key..";")
			if (result:getID() == -1) then
				db.executeQuery("INSERT INTO `global_storage` VALUES (" ..key.. ", 0, 0); ")
			else
				result:free()
			end
			db.executeQuery("UPDATE `global_storage` SET `value` = '"..chosen[i].name..":"..chosen[i].exp.."' WHERE `key` = "..key..";")
		end
	end

	if (sendMessage) then
		doBroadcastMessage("Daily monster boosts have been updated.", MESSAGE_EVENT_ADVANCE)
	end
end

function MonsterBoost:getBoosts()
	local ret = {}
	for i = 1, #self.config.create do
		local t = self.config.create[i]
		ret[i] = {
			name = self.config.monsters[tonumber(getStorage(t.name_storage))],
			exp = tonumber(getStorage(t.exp_storage)) or 0,
			t = t
		}
	end
	return ret
end
