local cfg = {
	--[action id]
	[10538] = {
		is_vertical = false, -- a porta é vertical? (false = horizontal)
		need_storage = {52200, 1}, -- storage e valor necessário
		fail_message = {"You need to speak to the Palimuth to gain access to this room..", MESSAGE_INFO_DESCR} -- mensagem caso não ter a storage
	},
	[10539] = {
		is_vertical = true,
		need_storage = {15200, 1},
		fail_message = {"You need to finish the waves in the arena to gain access to this room..", MESSAGE_INFO_DESCR}
	},
}

function onUse(cid, item, fromPosition, itemEx, toPosition)
	local t = cfg[item.actionid]
	if (not t) then
		return false
	end

	local storageValue = tonumber(getCreatureStorage(cid, t.need_storage[1])) or -1
	if (storageValue < t.need_storage[2]) then
		doPlayerSendTextMessage(cid, t.fail_message[2], t.fail_message[1])
		return true
	end

	local position = getThingPosition(cid)
	local destination = {x = position.x, y = position.y, z = position.z}
	if (t.is_vertical) then
		destination.y = toPosition.y
		destination.x = destination.x + ((toPosition.x - position.x) * 2)
	else
		destination.x = toPosition.x
		destination.y = destination.y + ((toPosition.y - position.y) * 2)
	end

	doTeleportThing(cid, destination, false)
	doSendMagicEffect(position, CONST_ME_TELEPORT)
	doSendMagicEffect(destination, CONST_ME_TELEPORT)
	return true
end
