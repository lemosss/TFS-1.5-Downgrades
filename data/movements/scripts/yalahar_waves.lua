local cfg = {
	entrance_aid = 10535, -- action id do piso/teleport de entrada
	exit_aid = 10536, -- action id do piso/teleport de saída

	entrance_position = {x = 31326, y = 31073, z = 10}, -- posição de entrada
	exit_position = {x = 31326, y = 31077, z = 9} -- posição de saída
}

function onStepIn(cid, item, position, lastPosition, fromPosition, toPosition, actor)
	if (not isPlayer(cid)) then
		doTeleportThing(cid, fromPosition, false)
		return true
	end

	if (item.actionid == cfg.entrance_aid) then
		if (YalaharWaves:isRunning()) then
			doTeleportThing(cid, fromPosition, false)
			doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Wait for the arena to be finished.")
			return true
		end

		doTeleportThing(cid, cfg.entrance_position, false)
		doSendMagicEffect(toPosition, CONST_ME_TELEPORT)
		doSendMagicEffect(cfg.entrance_position, CONST_ME_TELEPORT)

	elseif (item.actionid == cfg.exit_aid) then
		if (YalaharWaves:isRunning()) then
			doTeleportThing(cid, fromPosition, false)
			doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "You can't leave now.")
			return true
		end

		doTeleportThing(cid, cfg.exit_position, false)
		doSendMagicEffect(toPosition, CONST_ME_TELEPORT)
		doSendMagicEffect(cfg.exit_position, CONST_ME_TELEPORT)
	end
	return true
end
