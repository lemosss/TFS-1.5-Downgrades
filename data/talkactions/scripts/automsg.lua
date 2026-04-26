local players = {}

local FOODS, MAX_FOOD = {
    [2328] = {84, "Gulp."},  [2362] = {48, "Yum."}, [2666] = {180, "Munch."}, [2667] = {144, "Munch."},
    [2668] = {120, "Mmmm."}, [2669] = {204, "Munch."}, [2670] = {48, "Gulp."}, [2671] = {360, "Chomp."},
    [2672] = {720, "Chomp."}, [2673] = {60, "Yum."}, [2674] = {72, "Yum."}, [2675] = {156, "Yum."},
    [2676] = {96, "Yum."}, [2677] = {12, "Yum."}, [2678] = {216, "Slurp."}, [2679] = {12, "Yum."},
    [2680] = {24, "Yum."}, [2681] = {108, "Yum."}, [2682] = {240, "Yum."}, [2683] = {204, "Munch."},
    [2684] = {60, "Crunch."}, [2685] = {72, "Munch."}, [2686] = {108, "Crunch."}, [2687] = {24, "Crunch."},
    [2688] = {24, "Mmmm."}, [2689] = {120, "Crunch."}, [2690] = {72, "Crunch."}, [2691] = {96, "Crunch."},
    [2695] = {72, "Gulp."}, [2696] = {108, "Smack."}, [8112] = {108, "Urgh."}, [2787] = {108, "Crunch."},
    [2788] = {48, "Munch."}, [2789] = {264, "Munch."}, [2790] = {360, "Crunch."}, [2791] = {108, "Crunch."},
    [2792] = {72, "Crunch."}, [2793] = {144, "Crunch."}, [2794] = {36, "Crunch."}, [2795] = {432, "Crunch."},
    [2796] = {300, "Crunch."}
}, 1200

local function autoEat(cid)

for food, foodinfo in pairs(FOODS) do
if getPlayerItemCount(cid, food) > 0 then
if getPlayerFood(cid) + foodinfo[1] * 3 < MAX_FOOD then
doPlayerFeed(cid, foodinfo[1])
doPlayerRemoveItem(cid, food, 1)
doCreatureSay(cid, foodinfo[2], TALKTYPE_MONSTER)
end
end
end

end

local function trainMana(cid, startTime)

if not isPlayer(cid) then
players[cid] = nil
return
end

if not players[cid] or players[cid][3] ~= startTime then
players[cid] = nil
return
end

if getCreatureMana(cid) >= players[cid][2] then
if not doCreatureCastSpell(cid, players[cid][1]) then
players[cid] = nil
return
end

local mana = getInstantSpellInfo(cid, players[cid][1]).mana
doCreatureAddMana(cid, -(mana), false)
doPlayerAddSpentMana(cid, mana, true)
doCreatureSay(cid, getInstantSpellInfo(cid, players[cid][1]).words, TALKTYPE_MONSTER_SAY)
end

autoEat(cid)

addEvent(trainMana, 3000, cid, startTime)

end

local function showSpellList(cid)

local t = {}

for i = 0, getPlayerInstantSpellCount(cid) - 1 do
local spell = getPlayerInstantSpellInfo(cid, i)
if(spell.mlevel ~= 0) then
if(spell.manapercent > 0) then
spell.mana = spell.manapercent .. "%"
end
    
table.insert(t, spell)
end
end
    
table.sort(t, function(a, b) return a.mlevel < b.mlevel end)

local text, prevLevel = "", -1

for i, spell in ipairs(t) do
local line = ""
if(prevLevel ~= spell.mlevel) then
if(i ~= 1) then
line = "\n"
end

line = line .. "Spells for Magic Level " .. spell.mlevel .. "\n"
prevLevel = spell.mlevel

end

text = text .. line .. "  " .. spell.words .. " - " .. spell.name .. " : " .. spell.mana .. "\n"

end

doShowTextDialog(cid, 2175, text)

end


function onSay(cid, words, param, channel)

if players[cid] then
if players[cid][3] == os.time() then
doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Training cannot be stopped this quickly. Please wait a few seconds.")

return true
end

players[cid] = nil
doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Training has been stopped.")

return true
end
 
if param == "" then
doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Spell name and mana threshold required. Ex: !train Light Healing, 400 | !train list -> will show list of owned spells")
return true

elseif param == "list" then
doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Here is a list of your current spells.")
showSpellList(cid)

return true
end
    
local t = string.explode(param, ",")

if t[1] == nil or t[2] == nil then
doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Spell name and mana threshold required. Ex: !train Light Healing, 400")
return true
end

t[1] = t[1]:lower()
    
local spell

for i = 0, getPlayerInstantSpellCount(cid) - 1 do
spell = getPlayerInstantSpellInfo(cid, i)
if spell.name:lower() == t[1] or spell.words:lower() == t[1] then
t[1] = spell.name:lower()
spell = true
break
end
end
    
if spell ~= true then
doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "The spell (" .. t[1] .. ") does not exist.")
return true
end
    
local manaThreshold = tonumber(t[2])

if manaThreshold == nil then
doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "The mana threshold chosen (" .. t[2] .. ") is not a known number. Mana threshold has been set to your maximum mana.")
manaThreshold = getCreatureMaxMana(cid)
end
    
manaThreshold = math.floor(manaThreshold) -- to get rid of any decimals player might have thrown in

if manaThreshold < 0 or manaThreshold < getInstantSpellInfo(cid, t[1]).mana then

doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "The mana threshold chosen (" .. t[2] .. ") is lower then the spell cost of the spell (" .. t[1] .. "). Mana threshold has been set to your maximum mana.")
manaThreshold = getCreatureMaxMana(cid)

elseif manaThreshold > getCreatureMaxMana(cid) then

doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "The mana threshold chosen (" .. t[2] .. ") is higher then your maxmimum mana. Mana threshold has been set to your maximum mana.")
manaThreshold = getCreatureMaxMana(cid)

end
    
players[cid] = {getInstantSpellInfo(cid, t[1]).name, manaThreshold, os.time()}   
doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Training has started! Spell: (" .. t[1] .. "), Mana Threshold: " .. manaThreshold .. "")
trainMana(cid, os.time())

return true
end