local possto = {x=31288,y=31057,z=5} -- Posição para onde os players vão ser teleportados!!

function onUse(cid, item, fromPosition, itemEx, toPosition)
doTeleportThing(cid, possto)
doSendMagicEffect(getThingPos(cid), 10)
return true
end