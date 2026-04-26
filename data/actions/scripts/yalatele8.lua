local possto = {x=31398,y=31151,z=5} -- Posição para onde os players vão ser teleportados!!

function onUse(cid, item, fromPosition, itemEx, toPosition)
doTeleportThing(cid, possto)
doSendMagicEffect(getThingPos(cid), 10)
return true
end