-- OTX shared libs imported during the OTX-into-TFS port (Etapa H).
-- Each lib is wrapped in pcall so a single broken lib doesn't kill the
-- whole interpreter — we'd rather see the per-lib error and keep booting.

local function safeDofile(path)
	local ok, err = pcall(dofile, path)
	if not ok then
		print(string.format("[OTX lib] %s failed to load: %s", path, tostring(err)))
	end
end

-- Core OTX globals (must load first; the bosses/yalahar libs use them)
safeDofile('data/lib/otx/exhaustion.lua')
safeDofile('data/lib/otx/ppoints.lua')

safeDofile('data/lib/otx/lib_mounts.lua')
-- monster_boost feature removed: depends on OTX-only `global_storage` table
-- and a hardcoded showcase room layout that doesn't exist in our map.
safeDofile('data/lib/otx/yalahar_waves.lua')
safeDofile('data/lib/otx/arena.lua')
safeDofile('data/lib/otx/boss_annihi.lua')
safeDofile('data/lib/otx/boss_carlin.lua')
safeDofile('data/lib/otx/boss_port.lua')
safeDofile('data/lib/otx/boss_dwarfbridge.lua')
safeDofile('data/lib/otx/boss_poh.lua')
safeDofile('data/lib/otx/boss_rook.lua')
