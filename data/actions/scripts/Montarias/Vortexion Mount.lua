local config = {
	storage = 31015,
	outfit_male = 127,
	outfit_female = 126,
	outfit_name = "Vortexion Mount",
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