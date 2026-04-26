local possto = {x=31325,y=31016,z=7} -- Posição para onde os players vão ser teleportados!!

function onUse(cid, item, fromPosition, itemEx, toPosition)
doTeleportThing(cid, possto)
doSendMagicEffect(getThingPos(cid), 10)
return true
end