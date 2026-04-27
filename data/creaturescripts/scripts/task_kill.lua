-- OTX 'Simple Task' kill event ported to TFS 1.5.
-- Original: solebraserver/otserv1/mods/task.xml (event KillTask).
-- The data table 'tasktabble' lives in data/mods/task_func.lua. We load
-- it directly here because creaturescripts use a separate Lua interpreter
-- from NPCs (so the NPC's domodlib() call doesn't reach this scope).
dofile('data/mods/task_func.lua')

function onKill(cid, target, damage, flags)
	if not isMonster(target) then return true end
	-- flags & 1 == 1 means the killer dealt the final blow / had top damage.
	-- TFS 1.5 passes flags differently (often a table of {LastHit=true}); the
	-- per-bit check below stays compatible with both old (numeric) and modern
	-- (table) calling conventions.
	local lastHit = true
	if type(flags) == "number" then
		lastHit = (flags % 2) == 1
	elseif type(flags) == "table" then
		lastHit = flags.LastHit ~= false
	end
	if not lastHit then return true end

	local n = string.lower(getCreatureName(target))
	local targetPos = getCreaturePosition(target)

	for race, mob in pairs(tasktabble) do
		if getPlayerStorageValue(cid, mob.storage_start) >= 1 then
			for i = 1, #mob.monster_race do
				if n == mob.monster_race[i] then
					local contagem = getPlayerStorageValue(cid, mob.storage)
					if contagem == -1 then contagem = 1 end
					if not tonumber(contagem) then return true end
					contagem = math.floor(contagem)
					if contagem > mob.count then return true end

					setPlayerStorageValue(cid, mob.storage, contagem + 1)
					doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR,
						(contagem == mob.count
							and "Congratulations! You finished the task of "..race.."."
							or string.format("Defeated. Total [%d/%d] %s.", contagem, mob.count, race)))

					-- Party share: anyone in the party within screen distance
					-- gets credit too, matching the original OTX behaviour.
					local party = getPlayerParty(cid)
					if party then
						local members = getPartyMembers(party) or {}
						for _, pid in ipairs(members) do
							if cid ~= pid and isOnScreen(targetPos, getCreaturePosition(pid)) then
								local pc = getPlayerStorageValue(pid, mob.storage)
								if pc == -1 then pc = 1 end
								pc = math.floor(pc)
								if tonumber(pc) and pc <= mob.count then
									setPlayerStorageValue(pid, mob.storage, pc + 1)
									doPlayerSendTextMessage(pid, MESSAGE_INFO_DESCR,
										(pc == mob.count
											and "Congratulations! You finished the task of "..race.."."
											or "Defeated. Total ["..pc.."/"..mob.count.."] "..race.."."))
								end
							end
						end
					end
				end
			end
		end
	end
	return true
end
