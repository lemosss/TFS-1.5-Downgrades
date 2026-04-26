local config = {
	storage = 31016,
	outfit_male = 131,
	outfit_female = 139,
	outfit_name = "Ursagrodon Mount",
}

function onUse(cid, item, frompos, item2, topos)

	if getPlayerStorageValue(cid, config.storage) < 1 then
		doPlayerSendTextMessage(cid,22, "Você ganhou o ".. config.outfit_name ..".")
		doRemoveItem(item.uid,1)
		doPlayerAddOutfit(cid, config.outfit_male, 1)
		doPlayerAddOutfit(cid, config.outfit_male, 2)
		doPlayerAddOutfit(cid, config.outfit_female, 1)
		doPlayerAddOutfit(cid, config.outfit_female, 2)
		setPlayerStorageValue(cid, config.storage, 1)
	else
		doPlayerSendCancel(cid, "Você já pegou essa montaria.")
	end
	
	return true
end