function onUse(cid, item, frompos, item2, topos)
if item.actionid == 10055 then
	if getPlayerStorageValue(cid,798999) <= 0 then
		doPlayerSendTextMessage(cid,22,"You have found a Demon legs.")
		doPlayerAddItem(cid, 2495, 1)
		setPlayerStorageValue(cid,798999,1)
    else		
		doPlayerSendTextMessage(cid,22,"it's empty.")
	end
elseif item.actionid == 10056 then
	if getPlayerStorageValue(cid,798999) <= 0 then
		doPlayerSendTextMessage(cid,22,"You have found a Rainbow shield.")
		doPlayerAddItem(cid, 8169, 1)
		setPlayerStorageValue(cid,798999,1)
    else		
		doPlayerSendTextMessage(cid,22,"it's empty.")
	end	
elseif item.actionid == 10057 then
	if getPlayerStorageValue(cid,798999) <= 0 then
		doPlayerSendTextMessage(cid,22,"You have found a Crossbow of Legolas.")
		doPlayerAddItem(cid, 5793, 1)
		setPlayerStorageValue(cid,798999,1)
    else		
		doPlayerSendTextMessage(cid,22,"it's empty.")
	end
elseif item.actionid == 10058 then
	if getPlayerStorageValue(cid,798999) <= 0 then
		doPlayerSendTextMessage(cid,22,"You have found a Malphas Spellbook.")
		doPlayerAddItem(cid, 5805, 1)
		setPlayerStorageValue(cid,798999,1)
    else		
		doPlayerSendTextMessage(cid,22,"it's empty.")
	end
elseif item.actionid == 10059 then
	if getPlayerStorageValue(cid,798988) <= 0 then
		doPlayerSendTextMessage(cid,22,"You have found a outfit.")
		doPlayerAddItem(cid, 2361, 1)
		setPlayerStorageValue(cid,798988,1)
    else		
		doPlayerSendTextMessage(cid,22,"it's empty.")
	end	
end	
return true	
end	