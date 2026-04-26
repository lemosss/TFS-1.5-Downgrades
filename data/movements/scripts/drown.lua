local condition = createConditionObject(CONDITION_DROWN)
setConditionParam(condition, CONDITION_PARAM_PERIODICDAMAGE, -20)
setConditionParam(condition, CONDITION_PARAM_TICKS, -1)
setConditionParam(condition, CONDITION_PARAM_TICKINTERVAL, 2000)

local combat = createCombatObject()
setCombatParam(combat, COMBAT_PARAM_AGGRESSIVE, 0)
local condition2 = createConditionObject(CONDITION_HASTE)
setConditionParam(condition2, CONDITION_PARAM_TICKS, -1)
setConditionFormula(condition2, 0.7, -56, 0.7, -56)
setCombatCondition(combat, condition2)


function onStepIn(cid, item, position, fromPosition)
if(isPlayer(cid)) and getPlayerSlotItem(cid, CONST_SLOT_HEAD).itemid == 8332 then
doAddCondition(cid, condition2)
else
doAddCondition(cid, condition)
return true
end
return false
end

function onStepOut(cid, item, position, fromPosition)
doRemoveCondition(cid, CONDITION_DROWN)
doRemoveCondition(cid, CONDITION_HASTE)

return true
end