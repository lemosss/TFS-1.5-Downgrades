function onStartup()
	MonsterBoost:update(false)
	return true
end

local lastUpdate = 0
local boosts = nil
function onThink(interval)
	local boost_lastupdate = MonsterBoost:getLastUpdate()
	if (not boosts or boost_lastupdate ~= lastUpdate) then
		lastUpdate = boost_lastupdate
		boosts = MonsterBoost:getBoosts()
	end

	for i = 1, #boosts do
		local boost = boosts[i]
		local t = boost.t
		for j = 1, #t.showcase_room.animated_texts do
			local ani_text = t.showcase_room.animated_texts[j]
			if (ani_text.show_exp) then
				doSendAnimatedText(ani_text.position, ("xp+" .. boost.exp .. "%"), ani_text.color)
			else
				doSendAnimatedText(ani_text.position, ani_text.text, ani_text.color)
			end
		end
	end
	return true
end

function onTime(time)
	MonsterBoost:update(true)
	return true
end
