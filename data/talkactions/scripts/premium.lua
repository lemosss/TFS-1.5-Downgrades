local points = 100   -- how many points it cost.
local item = 8351   -- what item it gived.
    
function onSay(cid, words, param)
if getAccountPoints(cid) < points then
doPlayerSendCancel(cid,'This item cost 100 premium points.')
else

doPlayerGiveItem(cid, item, 1)
doSendMagicEffect(getPlayerPosition(cid), 28)
doPlayerSendTextMessage(cid,MESSAGE_EVENT_ADVANCE, 'You have bought scroll.')
doAccountRemovePoints(cid, points)
    



end
return TRUE
end