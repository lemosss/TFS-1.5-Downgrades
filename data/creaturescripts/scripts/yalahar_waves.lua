function onLogin(cid)
	registerCreatureEvent(cid, "YalaharWaves_death")
	return true
end

function onDeath(cid, corpse, deathList)
	if (YalaharWaves:isInArena(cid)) then
		if (isPlayer(cid)) then
			local spectators = YalaharWaves:getSpectators()
			if (#spectators.players == 1) then
				YalaharWaves:stop()
			end
		elseif (isMonster(cid) and getCreatureName(cid) == YalaharWaves.defender.post) then
			YalaharWaves:finish()
		end
	end
	return true
end
