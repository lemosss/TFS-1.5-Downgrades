function onStepIn(cid, item, position, fromPosition)

	if not(isPlayer(cid) == TRUE) then
		return FALSE
	end

local voc1 = 3
local voc2 = 7
local pvoc = getPlayerVocation(cid)

	if item.uid == 3033 then
		if pvoc == voc1 or pvoc == voc2 then
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -300, -300, 15)
		else
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -300, -300, 15)
			doCreatureSay(cid, "You seem to be on the wrong path.", TALKTYPE_ORANGE_1 )
		end
	elseif item.uid == 3034 then
		if pvoc == voc1 or pvoc == voc2 then
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -300, -300, 15)
		else
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -300, -300, 15)
			doCreatureSay(cid, "You seem to be on the wrong path.", TALKTYPE_ORANGE_1 )
		end
	elseif item.uid == 3035 then
		if pvoc == voc1 or pvoc == voc2 then
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -300, -300, 15)
		else
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -600, -600, 15)
			doCreatureSay(cid, "You seem to be on the wrong path.", TALKTYPE_ORANGE_1 )
		end
	elseif item.uid == 3036 then
		if pvoc == voc1 or pvoc == voc2 then
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -300, -300, 15)
		else
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -600, -600, 15)
			doCreatureSay(cid, "You seem to be on the wrong path.", TALKTYPE_ORANGE_1 )
		end
	elseif item.uid == 3037 then
		if pvoc == voc1 or pvoc == voc2 then
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -300, -300, 15)
		else
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -1200, -1200, 15)
			doCreatureSay(cid, "You seem to be on the wrong path.", TALKTYPE_ORANGE_1 )
		end
	elseif item.uid == 3038 then
		if pvoc == voc1 or pvoc == voc2 then
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -300, -300, 15)
		else
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -1200, -1200, 15)
			doCreatureSay(cid, "You seem to be on the wrong path.", TALKTYPE_ORANGE_1 )
		end
	elseif item.uid == 3039 then
		if pvoc == voc1 or pvoc == voc2 then
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -300, -300, 15)
		else
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -1200, -1200, 15)
			doCreatureSay(cid, "You seem to be on the wrong path.", TALKTYPE_ORANGE_1 )
		end
	elseif item.uid == 3040 then
		if pvoc == voc1 or pvoc == voc2 then
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -300, -300, 15)
		else
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -2400, -2400, 15)
			doCreatureSay(cid, "You seem to be on the wrong path.", TALKTYPE_ORANGE_1 )
		end
	elseif item.uid == 3041 then
		if pvoc == voc1 or pvoc == voc2 then
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -300, -300, 15)
		else
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -4800, -4800, 15)
			doCreatureSay(cid, "You seem to be on the wrong path.", TALKTYPE_ORANGE_1 )
		end
	elseif item.uid == 3042 then
		if pvoc == voc1 or pvoc == voc2 then
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -300, -300, 15)
		else
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -9600, -9600, 15)
			doCreatureSay(cid, "You seem to be on the wrong path.", TALKTYPE_ORANGE_1 )
		end
	elseif item.uid == 3043 then
		if pvoc == voc1 or pvoc == voc2 then
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -300, -300, 15)
		else
			doTargetCombatHealth(0, cid, COMBAT_FIREDAMAGE, -19200, -19200, 15)
			doCreatureSay(cid, "You seem to be on the wrong path.", TALKTYPE_ORANGE_1 )
		end
	end
return 1
end