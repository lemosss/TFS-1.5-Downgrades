-- Fire axe Dragon Cave Quest --

function onUse(cid, item, frompos, item2, topos)
if item.uid == 25252 then
  queststatus = getPlayerStorageValue(cid,25252)
   local um_um = {1,2,3,4,5,6,7,8,9,0}
	um = um_um[math.random(1, #um_um)]
	local dois_dois = {1,2,3,4,5,6,7,8,9,0}
	dois = dois_dois[math.random(1, #dois_dois)]
	local tres_tres = {1,2,3,4,5,6,7,8,9,0}
	tres = tres_tres[math.random(1, #tres_tres)]
	local quatro_quatro = {1,2,3,4,5,6,7,8,9,0}
	quatro = quatro_quatro[math.random(1, #quatro_quatro)]
  if queststatus == -1 or queststatus == 0 then
  if getPlayerFreeCap(cid) <= 100 then
doPlayerSendTextMessage(cid,22,"You need 100 cap or more to loot this!")
return TRUE
end
   doPlayerSendTextMessage(cid,22,"You have found a bag.")
 doItemSetAttribute(item, "description", "PROTECTION SYSTEM: "..getPlayerName(cid).. " - ID: ".. um .. '' .. dois .. '' .. tres .. '' .. quatro ..".")
container = doPlayerAddItem(cid, 1987, 1) 
doAddContainerItem(container, 2152, 100)

   setPlayerStorageValue(cid,25252,1)

  else
   doPlayerSendTextMessage(cid,22,"it\'s empty.")
  end
else
  return 0
end
return 1
end

