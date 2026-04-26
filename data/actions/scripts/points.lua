local cfg = {
    amount = 1       -- here how many points you want
  }



function onUse(cid, item, fromPosition, itemEx, toPosition)  
  
                if getPlayerLevel(cid) > 1 then
                doAccountAddPoints(cid, cfg.amount)
                doCreatureSay(cid, "You have received 1 premium point in website!. ", TALKTYPE_ORANGE_1)
                doSendMagicEffect(getCreaturePosition(cid), 14)
                doRemoveItem(item.uid,1)
                else
                doPlayerSendCancel(cid,"You need level 1 or higher to use this item.")
                end
                return TRUE
                end