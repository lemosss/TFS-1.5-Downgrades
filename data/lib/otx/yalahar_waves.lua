YalaharWaves = {
	global_storages = {
		-- storages globais (apenas mude se você estiver tendo algum problema com as storages)
		running = "YW_Running", -- storage global se o evento começou
		serial = "YW_serial" -- storage global do serial
	},

	area = {from = {x = 31321, y = 31059, z = 10}, to = {x = 31329, y = 31071, z = 10}}, -- area da arena
	exit_position = {x = 31325, y = 31079, z = 9}, -- posição de saída ao terminar as waves

	defender = {
		pre = "Azerus Defender", -- defender ao começar arena
		post = "Azerus Broken", -- defender ao chegar na ultima wave
		position = {x = 31325, y = 31059, z = 10} -- posição que ele é criado
	},

	gain_storage = {15200, 1}, -- storage e valor ganho ao vencer as waves

	waves = {
		-- ondas
		[1] = {
			next_interval = 10, -- intervalo em segundos para proxima wave
			monsters = {
				-- monstros que nascem e quantidade
				{name = "Rift Worm", count = 5},
			}
		},
		[2] = {
			next_interval = 10,
			monsters = {
				{name = "Demon", count = 1},
			}
		},
		[3] = {
			next_interval = 10,
			monsters = {
				{name = "Hydra", count = 1},
			}
		},
		[4] = {
			next_interval = 10,
			monsters = {
				{name = "Dragon Lord", count = 2},
			}
		},
		[5] = {
			next_interval = 10,
			monsters = {
				{name = "War Golem", count = 5},
			}
		},
	}
}

math.randomseed(os.mtime())

local function isWalkable(position)
	errors(false)
	local tileInfo = getTileInfo(position)
	errors(true)
	if (not tileInfo or tileInfo.protection) then
		return false
	end

	local checkProps = {0, 7, 12, 13}
	local tmpPosition = {x = position.x, y = position.y, z = position.z}
	for stackpos = 0, 255 do
		tmpPosition.stackpos = stackpos
		local thing = getThingFromPosition(tmpPosition)
		if (thing.uid == 0) then
			break
		end

		if (thing.itemid > 1) then
			for i = 1, #checkProps do
				if (hasItemProperty(thing.uid, checkProps[i])) then
					return false
				end
			end
		end
	end
	return true
end

local function genSerial()
	local serial = "S"
	for _ = 1, 11 do
		local bytechar = math.random(33, 126)
		if (bytechar == 92 --[[ "\" char ]]) then
			bytechar = 47 -- "/" char
		end
		serial = serial .. string.char(bytechar)
	end
	return serial
end

function YalaharWaves:hasDone(cid)
	return (tonumber(getCreatureStorage(cid, self.gain_storage[1])) or -1) >= self.gain_storage[2]
end

function YalaharWaves:isRunning()
	return (tonumber(getStorage(self.global_storages.running)) or 0) > 0
end

function YalaharWaves:setRunning(running)
	doSetStorage(self.global_storages.running, (running == true and 1 or 0))
end

function YalaharWaves:getSerial()
	return getStorage(self.global_storages.serial)
end

function YalaharWaves:setSerial(serial)
	doSetStorage(self.global_storages.serial, serial)
end

function YalaharWaves:isInArena(cid)
	return isInRange(getThingPosition(cid), self.area.from, self.area.to)
end

function YalaharWaves:getSpectators()
	local data = {
		creatures = {},
		players = {},
		monsters = {},
		summons = {}
	}

	local rangeX = math.ceil((self.area.to.x - self.area.from.x) / 2)
	local rangeY = math.ceil((self.area.to.y - self.area.from.y) / 2)
	local center = {x = self.area.from.x + rangeX, y = self.area.from.y + rangeY}
	for floor = self.area.from.z, self.area.to.z do
		center.z = floor
		local spectators = getSpectators(center, rangeX, rangeY, false)
		if (spectators) then
			for i = 1, #spectators do
				local cid = spectators[i]
				data.creatures[#data.creatures + 1] = cid
				if (isPlayer(cid)) then
					data.players[#data.players + 1] = cid
				elseif (isMonster(cid)) then
					if (getCreatureMaster(cid)) then
						data.summons[#data.summons + 1] = cid
					else
						data.monsters[#data.monsters + 1] = cid
					end
				end
			end
		end
	end
	return data
end

function YalaharWaves:cacheWalkableTiles()
	self.walkable_tiles = {}
	for x = self.area.from.x, self.area.to.x do
		for y = self.area.from.y, self.area.to.y do
			for z = self.area.from.z, self.area.to.z do
				local tmpPosition = {x = x, y = y, z = z}
				if (isWalkable(tmpPosition)) then
					self.walkable_tiles[#self.walkable_tiles + 1] = tmpPosition
				end
			end
		end
	end
end

function YalaharWaves:start()
	if (self:isRunning()) then
		return false
	end

	if (not self.walkable_tiles) then
		self:cacheWalkableTiles()
	end

	if (#self.walkable_tiles == 0) then
		print("[YalaharWaves:start - Error] There is not walkable tiles in area")
		return false
	end

	local serial = genSerial()
	self:setSerial(serial)
	self:setRunning(true)
	self:startWave(1, serial)
	return true
end

function YalaharWaves:stop()
	local spectators = self:getSpectators()
	for i = 1, #spectators.monsters do
		local mid = spectators.monsters[i]
		doSendMagicEffect(getThingPosition(mid), CONST_ME_TELEPORT)
		doRemoveCreature(mid)
	end

	self:setSerial(nil)
	self:setRunning(false)
end

function YalaharWaves:finish()
	local spectators = self:getSpectators()
	for i = 1, #spectators.players do
		local pid = spectators.players[i]
		local position = getThingPosition(pid)
		doCreatureSetStorage(pid, self.gain_storage[1], self.gain_storage[2])
	--	doTeleportThing(pid, self.exit_position, false)
		doSendMagicEffect(position, CONST_ME_TELEPORT)
	--	doSendMagicEffect(self.exit_position, CONST_ME_TELEPORT)
		doPlayerSendTextMessage(pid, MESSAGE_EVENT_ADVANCE, "A arena foi finalizada com sucesso.")
	end

	for i = 1, #spectators.monsters do
		local mid = spectators.monsters[i]
		doSendMagicEffect(getThingPosition(mid), CONST_ME_TELEPORT)
		doRemoveCreature(mid)
	end

	self:setSerial(nil)
	self:setRunning(false)
end

function YalaharWaves:startWave(wave, serial)
	if (not self:isRunning() or serial ~= self:getSerial()) then
		return
	end

	local t = self.waves[wave]
	if (not t) then
		return
	end

	for i = 1, #t.monsters do
		local mt = t.monsters[i]
		for _ = 1, mt.count or 1 do
			local position
			if (mt.position) then
				position = mt.position
			else
				position = self.walkable_tiles[math.random(1, #self.walkable_tiles)]
			end

			doCreateMonster(mt.name, position, false, true)
			doSendMagicEffect(position, CONST_ME_TELEPORT)
		end
	end

	if (wave == #self.waves) then
		local created = false
		local spectators = self:getSpectators()
		for i = 1, #spectators.monsters do
			local mid = spectators.monsters[i]
			if (getCreatureName(mid) == self.defender.pre) then
				local position = getThingPosition(mid)
				doRemoveCreature(mid)
				doCreateMonster(self.defender.post, position, false, true)
				doSendMagicEffect(position, CONST_ME_TELEPORT)
				created = true
				break
			end
		end

		if (not created) then
			doCreateMonster(self.defender.post, self.defender.position, false, true)
			doSendMagicEffect(self.defender.position, CONST_ME_TELEPORT)
		end
	elseif (wave == 1) then
		doCreateMonster(self.defender.pre, self.defender.position, false, true)
		doSendMagicEffect(self.defender.position, CONST_ME_TELEPORT)
	end

	addEvent(self.startWave, t.next_interval * 1000, self, wave + 1, serial)
end
