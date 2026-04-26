BossAnniha = {
	global_storages = {
		serial = "DA_Serial", -- storage global do serial
	},

	action_ids = {
		lever = 12351, -- action id da alavanca
		chest = 12352, -- action id do bau
	},

	death_event = "BossAnniDeathe", -- nome do evento de death do creaturescripts
	min_players = 1, -- minimo de jogadores para poder ir
	time_limit = 60, -- limite de tempo em minutos

	exit_position = {x = 31961, y = 32198, z = 14}, -- posição de saida

	places = {
		boss_room = {
			-- sala do boss
			destination = {x = 31962, y = 32174, z = 14}, -- posição do destino (onde boss é criado)
			area = {from = {x = 31946, y = 32149, z = 14}, to = {x = 31976, y = 32182, z = 14}} -- area
		},
		reward_room = {
			-- sala de recompensa
			destination = {x = 31969, y = 32139, z = 14}, -- posição do destino (onde os players vão)
			area = {from = {x = 31963, y = 32132, z = 14}, to = {x = 31975, y = 32144, z = 14}} -- area
		},
	},

	tiles = {
		-- posição do piso e destino
		{position = {x = 31972, y = 32196, z = 14}, destination = {x = 31965, y = 32153, z = 14}},
		{position = {x = 31971, y = 32196, z = 14}, destination = {x = 31964, y = 32153, z = 14}},
		{position = {x = 31970, y = 32196, z = 14}, destination = {x = 31963, y = 32153, z = 14}},
		{position = {x = 31969, y = 32196, z = 14}, destination = {x = 31962, y = 32153, z = 14}},
		{position = {x = 31968, y = 32196, z = 14}, destination = {x = 31961, y = 32153, z = 14}}
	},

	items_needed = {
		-- items necessario para poder entrar
		{id = 7234, count = 1}
	},

	bosses = {
		-- nome do boss e chance de aparecer (em caso de todas as chances falharem-
		-- os bosses com a maior chance serão escolhidos)
		{name = "Abaddon", chance = 100},
	},

	rewards = {
		-- recompensas que podem vir ao pegar o bau
		{id = "8425", count = {1, 2}, chance = 90},
		{id = "2152", count = {1, 5}, chance = 65},
		{id = "2388", count = {1, 1}, chance = 20},
		{id = "2412", count = {1, 1}, chance = 19},
		{id = "2398", count = {1, 1}, chance = 18},
		{id = "8102", count = {1, 1}, chance = 3},
		{id = "8103", count = {1, 1}, chance = 2.8},
		{id = "8104", count = {1, 1}, chance = 2.7},
		{id = "8105", count = {1, 1}, chance = 2.6},
		{id = "8106", count = {1, 1}, chance = 2.5},
		{id = "8380", count = {1, 1}, chance = 2.4},
	},

	messages = {
		ON_ENTER = {"Time limit to kill the boss: %s.", MESSAGE_EVENT_ADVANCE},
		ON_KILL = {"Congratulations, you managed to defeat the boss! You can get the reward from the chest.", MESSAGE_EVENT_ADVANCE},
		BAD_LUCK = {"You didn't get any items, better luck next time...", MESSAGE_EVENT_ADVANCE},
		GAIN_REWARD = {"You won %s.", MESSAGE_EVENT_ADVANCE},
		MUST_BE_IN_TILE = {"You need to be on the floor.", MESSAGE_STATUS_SMALL},
		NOT_ENOUGH_PLAYERS = {"Must have at least %d player%s.", MESSAGE_STATUS_SMALL},
		BOSS_IS_BUSY = {"There are players doing the boss, wait a while.", MESSAGE_STATUS_SMALL},
		PLAYERS_NEED_ITEM = {"All players must have %s.", MESSAGE_EVENT_ADVANCE},
		TIME_OUT = {"Time ran out... More luck next time.", MESSAGE_EVENT_ADVANCE},
	}
}

do
	local str = ""
	for i = 1, #BossAnniha.items_needed do
		local item = BossAnniha.items_needed[i]
		local itemInfo = getItemInfo(item.id)
		str = str .. item.count .. " " .. (itemInfo and (item.count > 1 and itemInfo.plural or itemInfo.name) or "UNK_ITEM") .. ", "
	end

	BossAnniha.items_description = (str:sub(1, #str - 2):gsub("(.+), ", "%1 e ", 1))
end

math.randomseed(os.mtime())

function BossAnniha:genSerial()
	local serial = "S"
	for _ = 1, 11 do
		local bytechar = math.random(33, 126)
		if (bytechar == 92 --[[ "\" char ]]) then
			bytechar = 47 -- "/" char
		end

		serial = serial .. string.char(bytechar)
	end

	doSetStorage(self.serial_storage, serial)
	return serial
end

function BossAnniha:getSerial()
	return getStorage(self.serial_storage)
end

function BossAnniha:getSpectators(place, getPlayers, getMonsters)
	local t = self.places[place]
	if (not t) then
		error("Place '" .. tostring(place) .. "' does not exists.")
	end

	local creatures = {}
	if (not getPlayers and not getMonsters) then
		return creatures
	end

	local rangeX = math.ceil((t.area.to.x - t.area.from.x) / 2)
	local rangeY = math.ceil((t.area.to.y - t.area.from.y) / 2)
	local center = {x = t.area.from.x + rangeX, y = t.area.from.y + rangeY}
	for floor = t.area.from.z, t.area.to.z do
		center.z = floor
		local spectators = getSpectators(center, rangeX, rangeY, false)
		if (spectators) then
			for i = 1, #spectators do
				local cid = spectators[i]
				if ((getPlayers == true and isPlayer(cid))
					or (getMonsters == true and isMonster(cid))) then
					creatures[#creatures + 1] = cid
				end
			end
		end
	end
	return creatures
end

function BossAnniha:getRandomBoss()
	local chance = nil
	local highestChance = nil

	local bosses = {}
	local highestBosses = {}

	local rand = math.random(1, 10000)
	for i = 1, #self.bosses do
		local boss = self.bosses[i]
		local bossChance = boss.chance * 100
		if (bossChance >= rand) then
			if (not chance) then
				chance = bossChance
			end

			if (bossChance < chance) then
				chance = bossChance
				bosses = {boss.name}

			elseif (bossChance == chance) then
				bosses[#bosses + 1] = boss.name
			end
		end

		if (not highestChance) then
			highestChance = bossChance
		end

		if (bossChance > highestChance) then
			highestChance = bossChance
			highestBosses = {boss.name}

		elseif (bossChance == highestChance) then
			highestBosses[#highestBosses + 1] = boss.name
		end
	end

	if (#bosses ~= 0) then
		return bosses[math.random(1, #bosses)]

	elseif (#highestBosses ~= 0) then
		return highestBosses[math.random(1, #highestBosses)]
	end

	-- isso não deveria acontecer
	error("There is no boss to select...")
end

function BossAnniha:createBoss(name)
	local boss = doCreateMonster(name, self.places.boss_room.destination, true)
	if (type(boss) ~= "number") then
		boss = doCreateMonster(name, self.places.boss_room.destination, false, true)
		if (type(boss) ~= "number") then
			error("Could not create boss '" .. tostring(name) .. "'.")
		end
	end

	registerCreatureEvent(boss, self.death_event)
end

function BossAnniha:timeOut()
	local creatures = self:getSpectators("boss_room", true, true)
	for i = 1, #creatures do
		local cid = creatures[i]
		if (isPlayer(cid)) then
			doTeleportThing(cid, self.exit_position, false)
			doPlayerSendTextMessage(cid, self.messages.TIME_OUT[2], self.messages.TIME_OUT[1])
		elseif (isMonster(cid)) then
			doRemoveCreature(cid)
		end
	end
end

-- CALLBACKS
function BossAnniha:onUse(cid, item, fromPosition, itemEx, toPosition, isHotkey)
	-- Alavanca
	if (item.actionid == self.action_ids.lever) then
		local isInTile = false
		local tilePlayers = {}
		for i = 1, #self.tiles do
			local tile = self.tiles[i]
			local topCreature = getTopCreature(tile.position)
			if (topCreature.uid ~= 0 and isPlayer(topCreature.uid)) then
				tilePlayers[#tilePlayers + 1] = {id = topCreature.uid, t = tile}
				if (topCreature.uid == cid) then
					isInTile = true
				end
			end
		end

		if (not isInTile) then
			doPlayerSendTextMessage(cid, self.messages.MUST_BE_IN_TILE[2], self.messages.MUST_BE_IN_TILE[1])
			doSendMagicEffect(getThingPosition(cid), CONST_ME_POFF)
			return true
		end

		if (#tilePlayers < self.min_players) then
			doPlayerSendTextMessage(cid,
				self.messages.NOT_ENOUGH_PLAYERS[2],
				self.messages.NOT_ENOUGH_PLAYERS[1]:format(self.min_players, self.min_players > 1 and "es" or "")
			)
			doSendMagicEffect(getThingPosition(cid), CONST_ME_POFF)
			return true
		end

		local roomPlayers = self:getSpectators("boss_room", true, false)
		if (#roomPlayers ~= 0) then
			doPlayerSendTextMessage(cid, self.messages.BOSS_IS_BUSY[2], self.messages.BOSS_IS_BUSY[1])
			doSendMagicEffect(getThingPosition(cid), CONST_ME_POFF)
			return true
		end

		for i = 1, #tilePlayers do
			local t = tilePlayers[i]
			for k = 1, #self.items_needed do
				local itemNeeded = self.items_needed[k]
				if (getPlayerItemCount(t.id, itemNeeded.id) < itemNeeded.count) then
					doPlayerSendTextMessage(cid,
						self.messages.PLAYERS_NEED_ITEM[2],
						self.messages.PLAYERS_NEED_ITEM[1]:format(self.items_description)
					)
					doSendMagicEffect(getThingPosition(cid), CONST_ME_POFF)
					return true
				end
			end
		end

		-- tudo parece OK, vamos remover os items, teleportar os players e colocar o boss
		local roomMonsters = self:getSpectators("boss_room", false, true)
		for i = 1, #roomMonsters do
			-- só para ter certeza...
			doRemoveCreature(roomMonsters[i])
		end

		for i = 1, #tilePlayers do
			local t = tilePlayers[i]
			for k = 1, #self.items_needed do
				local itemNeeded = self.items_needed[k]
				doPlayerRemoveItem(t.id, itemNeeded.id, itemNeeded.count)
			end

			doTeleportThing(t.id, t.t.destination, false)
			doPlayerSendTextMessage(cid,
				self.messages.ON_ENTER[2],
				self.messages.ON_ENTER[1]:format(self.time_limit .. " minutes" .. (self.time_limit > 1 and "s" or ""))
			)
		end

		self:createBoss(self:getRandomBoss())

		local serial = self:genSerial()
		addEvent(function()
			if (self:getSerial() == serial) then
				self:timeOut()
			end
		end, self.time_limit * 60000)

	-- Baú
	elseif (item.actionid == self.action_ids.chest) then
		local rewardedItems = {}
		for i = 1, #self.rewards do
			local reward = self.rewards[i]
			local count = math.random(reward.count[1], reward.count[2])
			if (count > 0 and (reward.chance * 100) >= math.random(1, 10000)) then
				rewardedItems[#rewardedItems + 1] = {id = reward.id, count = count}
			end
		end

		doTeleportThing(cid, self.exit_position, false)
		if (#rewardedItems ~= 0) then
			local str = ""
			for i = 1, #rewardedItems do
				local reward = rewardedItems[i]
				doPlayerAddItem(cid, reward.id, reward.count, true)

				local itemInfo = getItemInfo(reward.id)
				str = str .. reward.count .. " " .. (itemInfo and (reward.count > 1 and itemInfo.plural or itemInfo.name) or "UNK_ITEM") .. ", "
			end

			str = (str:sub(1, #str - 2):gsub("(.+), ", "%1 e ", 1))
			doPlayerSendTextMessage(cid,
				self.messages.GAIN_REWARD[2],
				self.messages.GAIN_REWARD[1]:format(str)
			)
		else
			doPlayerSendTextMessage(cid, self.messages.BAD_LUCK[2], self.messages.BAD_LUCK[1])
		end
	end
	return true
end

function BossAnniha:onDeath(cid, corpse, deathList)
	local creatures = self:getSpectators("boss_room", true, true)
	for i = 1, #creatures do
		local id = creatures[i]
		if (isPlayer(id)) then
			doTeleportThing(id, self.places.reward_room.destination, false)
			doPlayerSendTextMessage(id, self.messages.ON_KILL[2], self.messages.ON_KILL[1])
		elseif (isMonster(id)) then
			doRemoveCreature(id)
		end
	end
	return true
end
