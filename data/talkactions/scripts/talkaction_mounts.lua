function onSay(cid, words, param, channel)

-- CASO QUEIRA COLOCAR EXHAUST, DESCOMENTE AS DUAS LINHAS ABAIXO:
--if getPlayerStorageValue(cid,mounts_exhaust) >= os.time() then return doPlayerSendCancel(cid,"Utilize esse comando a cada "..mounts_time.." seg.. ") end
--setPlayerStorageValue(cid,mounts_exhaust,os.time()+mounts_time)


    outfit = getCreatureOutfit(cid)

    if getPlayerStorageValue(cid,sto_outfit_looktype) < 1 then 
        coluna=1
        for mar,cos in pairs(mounts) do
            setPlayerStorageValue(cid, cos[coluna] + 10000,1)
        end
        setPlayerStorageValue(cid, sto_outfit_looktype, 258) 
    end

    if mounts[outfit.lookType] ~= nil then
        setPlayerStorageValue(cid, sto_outfit_looktype, outfit.lookType)
    end
	
	
	
	
	outfit = getCreatureOutfit(cid)

    if getPlayerStorageValue(cid,sto_outfit_looktype) < 1 then 
        coluna=1
        for mar,cos in pairs(mounts) do
            setPlayerStorageValue(cid, cos[coluna] + 10000,1)
        end
        setPlayerStorageValue(cid, sto_outfit_looktype, 267) 
    end

    if mounts[outfit.lookType] ~= nil then
        setPlayerStorageValue(cid, sto_outfit_looktype, outfit.lookType)
    end

    

    --contador> menor q 1 ou maior q o maior valor das mounts de outfits, zera o contador.
    if  ((getPlayerStorageValue(cid, mounts_storage) < 1) or (getPlayerStorageValue(cid, mounts_storage) >= #mounts[getPlayerStorageValue(cid,sto_outfit_looktype)] )) then 
      setPlayerStorageValue(cid,mounts_storage,0) 
    end
    setPlayerStorageValue(cid,mounts_storage, getPlayerStorageValue(cid, mounts_storage) + 1)
    
    while ((getPlayerStorageValue(cid,mounts[getPlayerStorageValue(cid,sto_outfit_looktype)][getPlayerStorageValue(cid, mounts_storage)] + 10000)) < 1) do
             if  ((getPlayerStorageValue(cid, mounts_storage) < 1) or (getPlayerStorageValue(cid, mounts_storage) >= #mounts[getPlayerStorageValue(cid,sto_outfit_looktype)] )) then 
                setPlayerStorageValue(cid,mounts_storage,0) 
             end
        setPlayerStorageValue(cid,mounts_storage, getPlayerStorageValue(cid, mounts_storage) + 1)
    end
        
        

    outfit.lookType = mounts[getPlayerStorageValue(cid,sto_outfit_looktype)][getPlayerStorageValue(cid, mounts_storage)]
    doCreatureChangeOutfit(cid, outfit)
    doSendMagicEffect(getThingPos(cid), CONST_ME_MAGIC_RED)

        return true
end


--	obs:    --PARA ADICIONAR STORAGES, SELECIONA A COLUNA DA NOVA MOUNT E PRONTO! JOGUE EM ACTION OU COISA PARECIDA.
   
      -- montaria = 1  --(É o valor igual correspondente à montaria na coluna da tabela "mounts" em: data/lib/lib_mounts.lua)
		  
       -- for mar,cos in pairs(mounts) do
        --    setPlayerStorageValue(cid, cos[montaria] + 10000,1)
        --end
		
		
--<talkaction words="/mount;!mount"  event="script" value="talkaction_mounts.lua"/>
--<action itemid="2160;2148;2157" event="script" value="action_mounts.lua"/>
