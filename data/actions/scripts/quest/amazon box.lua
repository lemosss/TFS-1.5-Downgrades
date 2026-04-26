function onUse(cid, item, frompos, item2, topos)
if item.uid == 25086 then
  queststatus = getPlayerStorageValue(cid,25086)
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
   doPlayerSendTextMessage(cid,22,"You have found a letter, bring it back to Alph!")
   	doItemSetAttribute(item, "description", "PROTECTION SYSTEM: "..getPlayerName(cid).. " - ID: ".. um .. '' .. dois .. '' .. tres .. '' .. quatro ..".")
   item_uid = doPlayerAddItem(cid,2598,1)
   
   setPlayerStorageValue(cid,25086,1)
   setPlayerStorageValue(cid,26006,600)
      setPlayerStorageValue(cid,25064,3)
	  newpos = {x=32866, y=31920, z=8}
				doTeleportThing(cid,newpos)
  else
   doPlayerSendTextMessage(cid,22,"it\'s empty.")
  end
else
  return 0
end
return 1
end

