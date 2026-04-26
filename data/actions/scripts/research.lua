function onUse(cid, item, frompos, item2, topos)
if item.actionid == 32344 then
	if getPlayerStorageValue(cid,93939158) <= 0 then
		doPlayerSendTextMessage(cid,22,"You have found a research notes.")
		doPlayerAddItem(cid, 8331, 1)
		setPlayerStorageValue(cid,93939158,1)
    else		
		doPlayerSendTextMessage(cid,22,"it's empty.")
	end
end
return true
end