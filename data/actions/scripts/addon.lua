function onUse(cid, item, frompos, item2, topos)
if getPlayerStorageValue(cid,8488998) <= 0 then
        setPlayerStorageValue(cid,8488998, 1)
        doPlayerAddOutfit(cid,316, 3)
        doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, 'You have received all addons of summoner.')
        doRemoveItem(item.uid, 1)
else
doPlayerSendTextMessage(cid,22,"You already got this addon.")
end
return true
end