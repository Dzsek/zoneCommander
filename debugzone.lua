ev = {}
  function ev:onEvent(event)
  	if event.id == 26 then
  		if event.text=='debug' then
  			local z = bc:getZoneOfPoint(event.pos)
  			if z then
				env.info('-----------------------------------debug '..z.zone..'------------------------------------------')
  				for i,v in pairs(z.built) do
                    local gr = Group.getByName(v)
                    if gr then
                        env.info(gr:getName()..' '..gr:getSize()..'/'..gr:getInitialSize())
  						for i2,v2 in ipairs(gr:getUnits()) do
  							env.info('-'..v2:getName()..' '..v2:getLife()..'/'..v2:getLife0(),30)
  						end
                    end	
                end
				env.info('-----------------------------------end debug '..z.zone..'------------------------------------------')
  
				trigger.action.removeMark(event.idx)
  			end
  		end
		
		if event.text=='kill' then
  			local z = bc:getZoneOfPoint(event.pos)
  			if z then
				z:killAll()
				trigger.action.removeMark(event.idx)
  			end
  		end
		
		if event.text=='spawn' then
  			local z = bc:getZoneOfPoint(event.pos)
  			if z then
				for i,v in ipairs(z.groups) do
					if v.state == 'inhangar' or v.state == 'dead' then
						v.lastStateTime = v.lastStateTime - (24*60*60)
					end
				end
				trigger.action.removeMark(event.idx)
  			end
  		end
		
		if event.text:find('^capture\:') then
  			local s = event.text:gsub('^capture\:', '')
  			local side = tonumber(s)
			if side == 1 or side == 2 then
				local z = bc:getZoneOfPoint(event.pos)
				if z then
					z:capture(side)
					trigger.action.removeMark(event.idx)
				end
			end
  		end
		
		if event.text=='upgrade' then
			local z = bc:getZoneOfPoint(event.pos)
			if z then
				z:upgrade()
				trigger.action.removeMark(event.idx)
			end
  		end
		
		if event.text:find('^creditsB\:') then
  			local s = event.text:gsub('^creditsB\:', '')
  			local ammount = tonumber(s)
			if s then
				bc:addFunds(2, s)
				trigger.action.removeMark(event.idx)
			end
  		end
		
		if event.text:find('^creditsR\:') then
  			local s = event.text:gsub('^creditsR\:', '')
  			local ammount = tonumber(s)
			if s then
				bc:addFunds(1, s)
				trigger.action.removeMark(event.idx)
			end
  		end
		
		if event.text=='resetsave' then
			if bc and bc.saveFile then
				Utils.saveTable(bc.saveFile, 'zonePersistance', {})
				trigger.action.removeMark(event.idx)
			end
		end
		
		if event.text=='event' then
  			for i,v in ipairs(evc.events) do
				env.info(v.id)
			end
			trigger.action.removeMark(event.idx)
  		end
		
		if event.text:find('^event\:') then
  			local s = event.text:gsub('^event\:', '')
  			local eventname = s
			evc:triggerEvent(eventname)
			trigger.action.removeMark(event.idx)
  		end
  	end
  end
  
  world.addEventHandler(ev)
  
  
  trigger.action.outText('Development version. Please do not distribute', 60);
  trigger.action.outText('Debug tools loaded.', 60);