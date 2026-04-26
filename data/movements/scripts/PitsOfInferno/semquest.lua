function onStepIn(cid, item, position, fromPosition)
	if not isPlayer(cid) then
		return true
	end

	if getPlayerStorageValue(cid,9999) == 1 then
		doPlayerSendTextMessage(cid,19,'This path will take you to the dreaded pits of hell room.')
	else
		doTeleportThing(cid,fromPosition)
		doPlayerSendTextMessage(cid,22,"You did not complete The Pits of Inferno Quest.")
	end
	return true
end
