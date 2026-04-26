function onUse(cid, item, frompos, item2, topos)
	if frompos.x == 65535 then
		doPlayerSendCancel(cid, "Put the construction kit on the ground first.")
		return 1
	end
if (getTilePzInfo(getPlayerPosition(cid)) == TRUE) then
	doSendMagicEffect(topos,2)
	if item.itemid == 3901 then
		doTransformItem(item.uid,1652)
	elseif item.itemid == 3902 then
		doTransformItem(item.uid,1658)
	elseif item.itemid == 3903 then
		doTransformItem(item.uid,1666)
	elseif item.itemid == 3904 then
		doTransformItem(item.uid,1670)
	elseif item.itemid == 3905 then
		doTransformItem(item.uid,3813)
	elseif item.itemid == 3906 then
		doTransformItem(item.uid,3817)
	elseif item.itemid == 3908 then
		doTransformItem(item.uid,2602)
	elseif item.itemid == 3909 then
		doTransformItem(item.uid,1614)
	elseif item.itemid == 3910 then
		doTransformItem(item.uid,1615)
	elseif item.itemid == 3911 then
		doTransformItem(item.uid,1616)
	elseif item.itemid == 3912 then
		doTransformItem(item.uid,1619)
	elseif item.itemid == 3913 then
		doTransformItem(item.uid,3805)
	elseif item.itemid == 3914 then
		doTransformItem(item.uid,3807)
	elseif item.itemid == 3917 then
		doTransformItem(item.uid,2084)
	elseif item.itemid == 3918 then
		doTransformItem(item.uid,2095)
	elseif item.itemid == 3919 then
		doTransformItem(item.uid,3809)
	elseif item.itemid == 3926 then
		doTransformItem(item.uid,2080)
	elseif item.itemid == 3927 then
		doTransformItem(item.uid,2098)
	elseif item.itemid == 3928 then
		doTransformItem(item.uid,2104)
	elseif item.itemid == 3929 then
		doTransformItem(item.uid,2101)
	elseif item.itemid == 3931 then
		doTransformItem(item.uid,2105)
	elseif item.itemid == 3932 then
        doTransformItem(item.uid,1724)
	elseif item.itemid == 3933 then
		doTransformItem(item.uid,1728)
	elseif item.itemid == 3935 then
		doTransformItem(item.uid,1775)
	elseif item.itemid == 3937 then
		doTransformItem(item.uid,2064)
	elseif item.itemid == 3907 then
        doTransformItem(item.uid,3821)
	elseif item.itemid == 3915 then
		doTransformItem(item.uid,1738)
	elseif item.itemid == 3920 then
		doTransformItem(item.uid,3811)
	elseif item.itemid == 3921 then
		doTransformItem(item.uid,1716)
	elseif item.itemid == 3923 then
		doTransformItem(item.uid,1774)
	elseif item.itemid == 3934 then
		doTransformItem(item.uid,1732)
	elseif item.itemid == 3936 then
		doTransformItem(item.uid,3832)
	elseif item.itemid == 3938 then
		doTransformItem(item.uid,1750)
	elseif item.itemid == 5086 then
		doTransformItem(item.uid,1774)
	elseif item.itemid == 3916 then
		doTransformItem(item.uid,1442)
	elseif item.itemid == 3930 then
		doTransformItem(item.uid,1447)
	elseif item.itemid == 3925 then
		doTransformItem(item.uid,1446)
	elseif item.itemid == 3922 then
		doTransformItem(item.uid,2117)
	elseif item.itemid == 8172 then
		doTransformItem(item.uid,8175)
	elseif item.itemid == 8181 then
		doTransformItem(item.uid,8179)
	elseif item.itemid == 8182 then
		doTransformItem(item.uid,8199)
	elseif item.itemid == 8183 then
		doTransformItem(item.uid,8200)
	elseif item.itemid == 8184 then
		doTransformItem(item.uid,8202)
	elseif item.itemid == 8187 then
		doTransformItem(item.uid,8216)
	elseif item.itemid == 8188 then
		doTransformItem(item.uid,8218)
	elseif item.itemid == 8189 then
		doTransformItem(item.uid,8220)
	elseif item.itemid == 8190 then
		doTransformItem(item.uid,8224)
	elseif item.itemid == 8191 then
		doTransformItem(item.uid,8226)
	elseif item.itemid == 8192 then
		doTransformItem(item.uid,8228)
	elseif item.itemid == 8194 then
		doTransformItem(item.uid,8242)
	elseif item.itemid == 8195 then
		doTransformItem(item.uid,8246)
	elseif item.itemid == 8196 then
		doTransformItem(item.uid,8248)
	elseif item.itemid == 8197 then
		doTransformItem(item.uid,8250)	
	elseif item.itemid == 8265 then
		doTransformItem(item.uid,8252)	
	elseif item.itemid == 8266 then
		doTransformItem(item.uid,8256)	
	elseif item.itemid == 8267 then
		doTransformItem(item.uid,8287)	
	elseif item.itemid == 8268 then
		doTransformItem(item.uid,8289)	
	elseif item.itemid == 8269 then
		doTransformItem(item.uid,8291)	
	elseif item.itemid == 8270 then
		doTransformItem(item.uid,8293)	
	elseif item.itemid == 8271 then
		doTransformItem(item.uid,8294)	
	elseif item.itemid == 8272 then
		doTransformItem(item.uid,8295)	
	elseif item.itemid == 8273 then
		doTransformItem(item.uid,8296)
	elseif item.itemid == 8274 then
		doTransformItem(item.uid,8298)	
	elseif item.itemid == 8275 then
		doTransformItem(item.uid,8300)	
	elseif item.itemid == 8276 then
		doTransformItem(item.uid,8302)			
	else
		return 0
	end
	return 1
else
doPlayerSendCancel(cid, "You can only open this packet in protection zone!")
end
end
