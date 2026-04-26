local possto = {x=32775,y=32397,z=8} -- Posição para onde os players vão ser teleportados!!

function onUse(cid, item, fromPosition, itemEx, toPosition)

	if getPlayerStorageValue(cid,811355) == 1 then
		doTeleportThing(cid, possto)
		doSendMagicEffect(getThingPos(cid), 10)
        else
		doPlayerSendTextMessage(cid,22,"You did not complete Demon Oak Quest")
    return true
end
end