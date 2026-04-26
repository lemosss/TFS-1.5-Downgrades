function onStepIn(cid, item, position, fromPosition)

	if not(isPlayer(cid) == TRUE) then
		return FALSE
	end

local voc1 = 4
local voc2 = 8
local pvoc = getPlayerVocation(cid)

	if item.uid == 2033 then
		if pvoc == voc1 or pvoc == voc2 then
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -300, -300, 15)
		else
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -300, -300, 15)
			doCreatureSay(cid, "You seem to be on the wrong path.", TALKTYPE_ORANGE_1 )
		end
	elseif item.uid == 2034 then
		if pvoc == voc1 or pvoc == voc2 then
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -300, -300, 15)
		else
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -300, -300, 15)
			doCreatureSay(cid, "You seem to be on the wrong path.", TALKTYPE_ORANGE_1 )
		end
	elseif item.uid == 2035 then
		if pvoc == voc1 or pvoc == voc2 then
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -300, -300, 15)
		else
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -600, -600, 15)
			doCreatureSay(cid, "You seem to be on the wrong path.", TALKTYPE_ORANGE_1 )
		end
	elseif item.uid == 2036 then
		if pvoc == voc1 or pvoc == voc2 then
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -300, -300, 15)
		else
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -600, -600, 15)
			doCreatureSay(cid, "You seem to be on the wrong path.", TALKTYPE_ORANGE_1 )
		end
	elseif item.uid == 2037 then
		if pvoc == voc1 or pvoc == voc2 then
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -300, -300, 15)
		else
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -1200, -1200, 15)
			doCreatureSay(cid, "You seem to be on the wrong path.", TALKTYPE_ORANGE_1 )
		end
	elseif item.uid == 2038 then
		if pvoc == voc1 or pvoc == voc2 then
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -300, -300, 15)
		else
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -1200, -1200, 15)
			doCreatureSay(cid, "You seem to be on the wrong path.", TALKTYPE_ORANGE_1 )
		end
	elseif item.uid == 2039 then
		if pvoc == voc1 or pvoc == voc2 then
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -300, -300, 15)
		else
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -1200, -1200, 15)
			doCreatureSay(cid, "You seem to be on the wrong path.", TALKTYPE_ORANGE_1 )
		end
	elseif item.uid == 2040 then
		if pvoc == voc1 or pvoc == voc2 then
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -300, -300, 15)
		else
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -2400, -2400, 15)
			doCreatureSay(cid, "You seem to be on the wrong path.", TALKTYPE_ORANGE_1 )
		end
	elseif item.uid == 2041 then
		if pvoc == voc1 or pvoc == voc2 then
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -300, -300, 15)
		else
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -4800, -4800, 15)
			doCreatureSay(cid, "You seem to be on the wrong path.", TALKTYPE_ORANGE_1 )
		end
	elseif item.uid == 2042 then
		if pvoc == voc1 or pvoc == voc2 then
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -300, -300, 15)
		else
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -9600, -9600, 15)
			doCreatureSay(cid, "You seem to be on the wrong path.", TALKTYPE_ORANGE_1 )
		end
	elseif item.uid == 2043 then
		if pvoc == voc1 or pvoc == voc2 then
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -300, -300, 15)
		else
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -19200, -19200, 15)
			doCreatureSay(cid, "You seem to be on the wrong path.", TALKTYPE_ORANGE_1 )
		end
	end
return 1
end