domodlib('task_func')

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

local talkState = {}
local tasksPlayer = {}

function onCreatureAppear(cid) npcHandler:onCreatureAppear(cid) end
function onCreatureDisappear(cid) npcHandler:onCreatureDisappear(cid) end
function onCreatureSay(cid, type, msg) npcHandler:onCreatureSay(cid, type, msg) end
function onThink() npcHandler:onThink() end

function greetCallback(talkUser)
    if talkState[talkUser] ~= nil then
        talkState[talkUser] = nil
    end
    if tasksPlayer[talkUser] ~= nil then
        tasksPlayer[talkUser] = nil
    end
    return true
end

function creatureSayCallback(cid, type, msg)
    if(not npcHandler:isFocused(cid)) then
        return false
    end
    local talkUser = NPCHANDLER_CONVBEHAVIOR == CONVERSATION_DEFAULT and 0 or cid
    local msg = string.lower(msg)
    if isInArray({"task"}, msg) then
        npcHandler:say("Which mode are you interested on: easy, medium, hard or very hard", cid)
        talkState[talkUser] = 1
    elseif isInArray({"easy"}, msg) then
        npcHandler:say("Tell me the name of the monster you want to make the task: Dwarfs, Goblins, Humans, Larvas, Minotaurs, Rotworms, Orcs, Pandas, Scarabs, Tarantulas and Trolls", cid)
        talkState[talkUser] = 1
    elseif isInArray({"medium"}, msg) then
        npcHandler:say("Tell me the name of the monster you want to make the task: Ancient Scarabs, Apes, Black Knights, Cyclops, Demon Skeletons, Dragons, Dwarf Guards, Fire Elementals, Giant Spiders, Heros, Necromancers, Orc Warlords, Terror Birds And Vampires", cid)
        talkState[talkUser] = 1
    elseif isInArray({"hard"}, msg) then
        npcHandler:say("Tell me the name of the monster you want to make the task: Behemoths, Dragon Lords, Demons, Frost Dragons, Hydras, Serpent Spawns, warlocks!", cid)
        talkState[talkUser] = 1
    elseif isInArray({"very hard"}, msg) then
        npcHandler:say("Tell me the name of the monster you want to make the task: Betrayed Wraiths, Blightwalkers, Dark Torturers, Defilers, Destroyers, Diabolic Imps, Hand of Cursed Fates, Hellhounds, Hellfire Fighters, Juggernauts, Lost Souls, Nightmares, Plaguesmiths, Son of Verminors, Undead Dragons, ", cid)
        talkState[talkUser] = 1
    elseif talkState[talkUser] == 1 then
        if tasktabble[msg] then
            local tasks, count = checkTasks(cid)
            if (#tasks < max_task_per_time) then
                local contagem = getPlayerStorageValue(cid, tasktabble[msg].storage)
                if (contagem == -1) then contagem = 1 end
                if not tonumber(contagem) then return npcHandler:say('You already finished the '..msg..' task.', cid) end

                setPlayerStorageValue(cid, tasktabble[msg].storage_start, 1)
                npcHandler:say("Great! Come back once you killed "..string.sub(((contagem)-1)-tasktabble[msg].count, 2).." "..msg..".", cid)
                talkState[talkUser] = 0
            else
                npcHandler:say('You can only have '..max_task_per_time..' tasks per time.', cid)
                talkState[talkUser] = 0
            end
        else
            npcHandler:say('This task name does not exist, please try again.', cid)
            talkState[talkUser] = 1
        end
    elseif isInArray({"receber","reward","recompensa","report","reportar","receiver"}, msg) then
        local tasks = checkTasks(cid)
        if #tasks > 0 then
            local task = {}
            for i = 1, #tasks do task[#task + 1] = tasks[i][1] end
            npcHandler:say('Which task reward would you like to get: '..table.concat(task, ", "), cid)
            talkState[talkUser] = 3
            tasksPlayer[talkUser] = task
        else
            talkState[talkUser] = 0
            npcHandler:say("You dont have any task mission.", cid)
        end
    elseif talkState[talkUser] == 3 and isInArray(tasksPlayer[talkUser], msg) then
        local tasks = checkTasks(cid)
        for i = 1, #tasks do
            local k, v = tasks[i][1], tasks[i][2]
            if (k == msg) then
                local contagem = getPlayerStorageValue(cid, v.storage)
                if (contagem == -1) then contagem = 1 end

                if (((contagem) - 1) >= v.count) then
                    local reward = {}
                    if (v.exp) then doPlayerAddExp(cid, v.exp) reward[#reward + 1] = v.exp.." experience points" end
                    if (v.money) then doPlayerAddMoney(cid, v.money) reward[#reward + 1] = v.money.." gold coins" end
                    if (v.reward) then
                        for j = 1, #v.reward do
                            reward[#reward + 1] = (v.reward[j][2] > 1 and v.reward[j][2].." " or "") .. getItemNameById(v.reward[j][1]):lower()
                            doPlayerAddItem(cid, v.reward[j][1], v.reward[j][2])
                        end
                    end
                    npcHandler:say("Congratulations! You have finished "..k.." task and your reward is "..table.concat(reward, ", "):gsub("(.*),", "%1 and")..".", cid)
                    setPlayerStorageValue(cid, v.storage, "Finished")
                    setPlayerStorageValue(cid, v.storage_start, 0)
                    setPlayerStorageValue(cid, v.storage_site, 1)
                    setPlayerStorageValue(cid, 521456, math.max(0, tonumber(getPlayerStorageValue(cid, 521456))) + 1)
                    finisheAllTask(cid)
                    talkState[talkUser] = 0
                    break
                else
                    npcHandler:say('Your '..k..' task is not completed yet, you just killed '..((contagem)-1)..'/'..v.count..' '..k..'.', cid)
                end
            end
        end
    elseif isInArray({"cancel","sair","leave","exit"}, msg) then
        local tasks = checkTasks(cid)
        if #tasks > 0 then
            local task = {}
            for i = 1, #tasks do task[#task + 1] = tasks[i][1] end
            npcHandler:say('Which task would you like to cancel: '..table.concat(task, ", "), cid)
            talkState[talkUser] = 2
            tasksPlayer[talkUser] = task
        else
            talkState[talkUser] = 0
            npcHandler:say("You dont have any task mission.", cid)
        end
    elseif talkState[talkUser] == 2 and isInArray(tasksPlayer[talkUser], msg) then
        local tasks = checkTasks(cid)
        for i = 1, #tasks do
            local k, v = tasks[i][1], tasks[i][2]
            if (k == msg) then
                setPlayerStorageValue(cid, v.storage_start, 0)
                setPlayerStorageValue(cid, v.storage, 1)
                npcHandler:say("Your "..k.." task has been canceled.", cid)
                talkState[talkUser] = 0
                break
            end
        end
    elseif (msg == "no") then
        selfSay(((talkState[talkUser] and talkState[talkUser] > 0) and "Alright then." or "No what?"), cid)
        talkState[talkUser] = 0  
    end
    return true
end

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())