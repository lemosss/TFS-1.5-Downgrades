local positions = {
	------------------------------------ Templo ------------------------------------	
	

	
	{pos = {x = 32350, y = 32230, z = 5}, text = "Casino", effect = 100, color = COLOR_YELLOW},
    --{pos = {x = 32350, y = 32230, z = 5}, text = "Casino", effect = 25, color = COLOR_YELLOW},--
}


function onThink(interval, lastExecution)
	for i = 1, #positions do
		if positions[i].effect ~= -1 then
			doSendMagicEffect(positions[i].pos, positions[i].effect)
		end
		if positions[i].color == RANDOM then
			doSendAnimatedText(positions[i].pos, positions[i].text, math.random(1, 255))
		else
			doSendAnimatedText(positions[i].pos, positions[i].text, positions[i].color)
		end
	end
	return true
end

