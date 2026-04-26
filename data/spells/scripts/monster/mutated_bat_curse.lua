local combat = createCombatObject()
setCombatParam(combat, COMBAT_PARAM_TYPE, COMBAT_DEATHDAMAGE)
setCombatParam(combat, COMBAT_PARAM_EFFECT, CONST_ME_SMALLCLOUDS)
setCombatParam(combat, COMBAT_PARAM_DISTANCEEFFECT, CONST_ANI_DEATH)

local arr = {
{0, 1, 0},
{0, 1, 0},
{0, 1, 0},
{0, 1, 0},
{0, 3, 0},
}

local area = createCombatArea(arr)
setCombatArea(combat, area)

function onTargetCreature(cid, target)
	setCombatParam(target, CONDITION_CURSED, DAMAGELIST_EXPONENTIAL_DAMAGE, math.random(10, 21))
end

setCombatParam(combat, CALLBACK_PARAM_TARGETCREATURE, "onTargetCreature")

function onCastSpell(cid, var)
	return doCombat(cid, combat, var)
end
