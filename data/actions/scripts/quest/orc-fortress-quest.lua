-- Fire axe Dragon Cave Quest --
function onUse(cid, item, fromPosition, itemEx, toPosition)
    if item.uid == 15080 then
        if getPlayerStorageValue(cid, 15080) == -1 then
			local um_um = {1,2,3,4,5,6,7,8,9,0}
			um = um_um[math.random(1, #um_um)]
			local dois_dois = {1,2,3,4,5,6,7,8,9,0}
			dois = dois_dois[math.random(1, #dois_dois)]
			local tres_tres = {1,2,3,4,5,6,7,8,9,0}
			tres = tres_tres[math.random(1, #tres_tres)]
			local quatro_quatro = {1,2,3,4,5,6,7,8,9,0}
			quatro = quatro_quatro[math.random(1, #quatro_quatro)]
            local item = doCreateItemEx(2430, 1)
            doItemSetAttribute(item, "description", "PROTECTION SYSTEM: "..getPlayerName(cid).. " - ID: ".. um .. '' .. dois .. '' .. tres .. '' .. quatro ..".")
            doPlayerAddItemEx(cid, item, 1)
            setPlayerStorageValue(cid, 15080, 1)
            doPlayerSendTextMessage(cid, 25, "You have found a Knight axe!")
        else
            doPlayerSendTextMessage(cid, 25, "it\'s empty.")
        end
        return true
    end
 end
