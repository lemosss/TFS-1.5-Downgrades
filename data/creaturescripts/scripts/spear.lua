function onAttack(cid, target)

 

if isPlayer(cid) and isCreature(target) then

 

if getPlayerVocation(cid) == 3 or getPlayerVocation(cid) == 7 then

 

if getPlayerSlotItem(cid, CONST_SLOT_RIGHT).itemid == 2389 then

if getPlayerStorageValue(cid, 12432) <= 5 then

setPlayerStorageValue(cid, 12432, getPlayerStorageValue(cid, 12432) + 1)

else

doPlayerRemoveItem(cid, 2389, 1, CONST_SLOT_RIGHT)

setPlayerStorageValue(cid, 12432, 0)

doCreateItem(2389,1,getCreaturePosition(target))
end

end

 

if getPlayerSlotItem(cid, CONST_SLOT_LEFT).itemid == 2389 then

if getPlayerStorageValue(cid, 12432) <= 5 then

setPlayerStorageValue(cid, 12432, getPlayerStorageValue(cid, 12432) + 1)

else

doPlayerRemoveItem(cid, 2389, 1, CONST_SLOT_LEFT)

setPlayerStorageValue(cid, 12432, 0)

doCreateItem(2389,1,getCreaturePosition(target))
end

end

 

 

end

end

 

return true

end