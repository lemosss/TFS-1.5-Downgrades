local combat = createCombatObject()
setCombatParam(combat, COMBAT_PARAM_EFFECT, CONST_ME_STUN)

local arr = {
{1, 1, 1},
{1, 3, 1},
{1, 1, 1}
}

local area = createCombatArea(arr)
setCombatArea(combat, area)

local parameters = {
	{key = CONDITION_PARAM_TICKS, value = 3 * 1000},
	{key = CONDITION_PARAM_SKILL_SHIELDPERCENT, value = 70}
}

function onTargetCreature(cid, target)
	setCombatParam(target, parameters)
end

setCombatParam(combat, CALLBACK_PARAM_TARGETCREATURE, "onTargetCreature")

function onCastSpell(cid, var)
	return doCombat(cid, combat, var)
end
