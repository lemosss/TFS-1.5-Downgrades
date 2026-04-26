function onUse(cid, item, fromPosition, itemEx, toPosition)
	if (YalaharWaves:isRunning()) then
		doPlayerSendCancel(cid, "As waves já foram ativadas.")
		doSendMagicEffect(getThingPosition(cid), CONST_ME_POFF)
		return true
	end

	if (not YalaharWaves:start()) then
		doPlayerSendCancel(cid, "Não foi possível iniciar as waves.")
		doSendMagicEffect(getThingPosition(cid), CONST_ME_POFF)
		return true
	end
	return true
end
