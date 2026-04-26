local possto = {x=32672,y=32069,z=8} -- Posição para onde os players vão ser teleportados!!

function onUse(cid, item, fromPosition, itemEx, toPosition)
doTeleportThing(cid, possto)
doSendMagicEffect(getThingPos(cid), 10)
return true
end