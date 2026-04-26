function onSay(cid, words, param, channel)
	if (param:lower():trim() == "update") then
		MonsterBoost:update(false)
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_ORANGE, "Monstros boostados atualizados.")
		return true
	end

	doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Parametro invalido.")
	return true
end
