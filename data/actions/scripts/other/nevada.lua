--Example change voc and masterpos--

function onUse(cid, item, frompos, item2, topos)
	if item.uid==50109 then
		newpos = {x=32084, y=31651, z=7}
		doPlayerSetTown(cid, 8)
		doPlayerSendTextMessage(cid,22,"You have changed your residence to Nevada.")
		doTeleportThing(cid,newpos)
		doSendMagicEffect(newpos,12)
		return 1
	end
end