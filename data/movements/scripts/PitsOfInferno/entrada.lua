local lapidePosition = { x = 32791, y = 32333, z = 9, stackpos = 1 }
local destinationPosition = { x = 32791, y = 32334, z = 10 }
function onStepIn(cid, item, position, fromPosition)
    sangueTile = getThingfromPos(lapidePosition)
    if isPlayer(cid) and sangueTile and sangueTile.itemid == 2025 and sangueTile.type == 2 then
        doTeleportThing(cid, destinationPosition)
    else
        doPlayerSendCancel(cid,"Sorry, not possible.")
    end
end 