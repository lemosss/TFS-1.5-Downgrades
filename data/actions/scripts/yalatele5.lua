local possto = {x=31321,y=31044,z=5} -- Posição para onde os players vão ser teleportados!!

function onUse(cid, item, fromPosition, itemEx, toPosition)
doTeleportThing(cid, possto)
doSendMagicEffect(getThingPos(cid), 10)
return true
end