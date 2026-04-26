local cfg = {
	-- info da stamina para melhor precisão
	stamina_bonus_premium = getConfigValue("staminaThresholdOnlyPremium") or true,
	stamina_limit_top = getConfigValue("staminaRatingLimitTop") or 2460,
	stamina_limit_bottom = getConfigValue("staminaRatingLimitBottom") or 840,
	stamina_rate_above = getConfigValue("rateStaminaAboveNormal") or 1.5,
	stamina_rate_under = getConfigValue("rateStaminaUnderNormal") or 0.5,

	-- não mexa
	last_update = 0,
	boosts = nil
}

function onLogin(cid)
	registerCreatureEvent(cid, "MonsterBoost_kill")
	return true
end

function onKill(cid, target, damage, flags)
	local isLastHit = (bit.band(flags, 1) ~= 0)
	if (isLastHit and isMonster(target) and not getCreatureMaster(target)) then
		local lastUpdate = MonsterBoost:getLastUpdate()
		if (not cfg.boosts or lastUpdate ~= cfg.last_update) then
			cfg.last_update = lastUpdate
			cfg.boosts = MonsterBoost:getBoosts()
		end

		local name = getCreatureName(target)
		local boost = nil
		for i = 1, #cfg.boosts do
			local t = cfg.boosts[i]
			if (name == t.name) then
				boost = t
				break
			end
		end

		if (not boost) then
			return true
		end

		local monster_info = getMonsterInfo(name)
		if (not monster_info) then
			return true
		end

		local experience = monster_info.experience * getPlayerRates(cid)[8] * (boost.exp / 100)
		if (not getPlayerFlagValue(cid, PlayerFlag_HasInfiniteStamina)) then
			local stamina_minutes = getPlayerStamina(cid)
			if (stamina_minutes >= cfg.stamina_limit_top) then
				if (isPremium(cid) or not cfg.stamina_bonus_premium) then
					experience = experience * cfg.stamina_rate_above
				end
			elseif (stamina_minutes < cfg.stamina_limit_bottom and stamina_minutes > 0) then
				experience = experience * cfg.stamina_rate_under
			elseif (stamina_minutes <= 0) then
				experience = 0
			end
		elseif (isPremium(cid) or not cfg.stamina_bonus_premium) then
			experience = experience * cfg.stamina_rate_above
		end

		local vocation_info = getVocationInfo(getPlayerVocation(cid))
		if (vocation_info) then
			experience = experience * vocation_info.experienceMultiplier
		end

		experience = math.floor(experience * getExperienceStage(getPlayerLevel(cid)))
		if (experience > 0) then
			doPlayerAddExperience(cid, experience)
			doPlayerSendTextMessage(cid, MESSAGE_STATUS_DEFAULT, "Você matou um monstro boostado e ganhou +" .. experience .. " pontos de experiência (" .. boost.exp .. "%).")
		end
	end
	return true
end
