Utils = {}
do
	function Utils.getPointOnSurface(point)
		return {x = point.x, y = land.getHeight({x = point.x, y = point.z}), z= point.z}
	end
	
	function Utils.getAGL(object)
		local pt = object:getPoint()
		return pt.y - land.getHeight({ x = pt.x, y = pt.z })
	end
	
	function Utils.isLanded(unit)
		return (Utils.getAGL(unit)<5 and mist.vec.mag(unit:getVelocity())<0.10)
	end
	
	function Utils.isInAir(unit)
		return Utils.getAGL(unit)>5
	end
	
	function Utils.isInZone(unit, zonename)
		local zn = trigger.misc.getZone(zonename)
		if zn then
			local dist = mist.utils.get3DDist(unit:getPosition().p,zn.point)
			return dist<zn.radius
		end
		
		return false
	end
	
	function Utils.isCrateSettledInZone(crate, zonename)
		local zn = trigger.misc.getZone(zonename)
		if zn and crate then
			local dist = mist.utils.get3DDist(crate:getPosition().p,zn.point)
			return (dist<zn.radius and Utils.getAGL(crate)<1)
		end
		
		return false
	end
	
	function Utils.someOfGroupInZone(group, zonename)
		for i,v in pairs(group:getUnits()) do
			if Utils.isInZone(v, zonename) then
				return true
			end
		end
		
		return false
	end
	
	function Utils.allGroupIsLanded(group)
		for i,v in pairs(group:getUnits()) do
			if not Utils.isLanded(v) then
				return false
			end
		end
		
		return true
	end
	
	function Utils.someOfGroupInAir(group)
		for i,v in pairs(group:getUnits()) do
			if Utils.isInAir(v) then
				return true
			end
		end
		
		return false
	end
end

GlobalSettings = {}
do
	GlobalSettings.blockedDespawnTime = 10*60
	GlobalSettings.hangarRespawnTime = 2*60
	GlobalSettings.deadRespawnTime = 15*60
	GlobalSettings.landedDespawnTime = 1*60
end


BattleCommander = {}
do
	BattleCommander.zones = {}
	BattleCommander.connections = {}
	
	function BattleCommander:new()
		local obj = {}
		setmetatable(obj, self)
		self.__index = self
		return obj
	end
	
	function BattleCommander:addZone(zone)
		table.insert(self.zones, zone)
		zone.index = self:getZoneIndexByName(zone.zone)
		zone.battleCommander = self
	end
	
	function BattleCommander:getZoneByName(name)
		for i,v in ipairs(self.zones) do
			if v.zone == name then
				return v
			end
		end
	end
	
	function BattleCommander:addConnection(f, t)
		table.insert(self.connections, {from=f, to=t})
	end
	
	function BattleCommander:getZoneIndexByName(name)
		for i,v in ipairs(self.zones) do
			if v.zone == name then
				return i
			end
		end
	end
	
	function BattleCommander:getZones()
		return self.zones
	end
	
	function BattleCommander:initializeRestrictedGroups()
		for i,v in pairs(mist.DBs.groupsByName) do
			if v.units[1].skill == 'Client' then
				for i2,v2 in ipairs(self.zones) do
					local zn = trigger.misc.getZone(v2.zone)
					if zn and mist.utils.get2DDist(v.units[1].point, zn.point) < zn.radius then
						local coa = 0
						if v.coalition=='blue' then
							coa = 2
						elseif v.coalition=='red' then
							coa = 1
						end
						
						v2:addRestrictedPlayerGroup({name=i, side=coa})
					end
				end
			end
		end
	end
	
	function BattleCommander:init()
		self:initializeRestrictedGroups()
	
		local main =  missionCommands.addSubMenu('Zone Status')
		local sub1
		for i,v in ipairs(self.zones) do
			v:init()
			if i<11 then
				missionCommands.addCommand(v.zone, main, v.displayStatus, v)
			elseif i==11 then
				sub1 = missionCommands.addSubMenu("More", main)
				missionCommands.addCommand(v.zone, sub1, v.displayStatus, v)
			else
				missionCommands.addCommand(v.zone, sub1, v.displayStatus, v)
			end
		end
		
		for i,v in ipairs(self.connections) do
			local from = trigger.misc.getZone(v.from)
			local to = trigger.misc.getZone(v.to)
			
			trigger.action.lineToAll(-1, 1000+i, from.point, to.point, {1,1,1,0.5}, 2)
		end
		
		mist.scheduleFunction(self.update, {self}, timer.getTime() + 1, 10)
		
		local ev = {}
		function ev:onEvent(event)
			if (event.id==20) and event.initiator and (event.initiator:getCategory() == Unit.Category.AIRPLANE or event.initiator:getCategory() == Unit.Category.HELICOPTER)  then
				local pname = event.initiator:getPlayerName()
				if pname then
					local gr = event.initiator:getGroup()
					if trigger.misc.getUserFlag(gr:getName())==1 then
						trigger.action.outTextForGroup(gr:getID(), 'Can not spawn as '..gr:getName()..' in enemy/neutral zone',5)
						event.initiator:destroy()
					end
				end
			end
		end
		
		world.addEventHandler(ev)
	end
	
	function BattleCommander:update()
		for i,v in ipairs(self.zones) do
			v:update()
		end
	end
end

ZoneCommander = {}
do
	--{ zone='zonename', side=[0=neutral, 1=red, 2=blue], level=int, upgrades={red={}, blue={}}, crates={} }
	function ZoneCommander:new(obj)
		obj = obj or {}
		obj.built = {}
		obj.index = -1
		obj.battleCommander = {}
		obj.groups = {}
		obj.restrictedGroups = {}
		setmetatable(obj, self)
		self.__index = self
		return obj
	end
	
	function ZoneCommander:addRestrictedPlayerGroup(groupinfo)
		table.insert(self.restrictedGroups, groupinfo)
	end
	
	function ZoneCommander:displayStatus()
		local upgrades = 0
		local sidename = 'Neutral'
		if self.side == 1 then
			sidename = 'Red'
			upgrades = #self.upgrades.red
		elseif self.side == 2 then
			sidename = 'Blue'
			upgrades = #self.upgrades.blue
		end
		
		local count = 0
		if self.built then
			count = #self.built
		end
		
		local status = self.zone..' status\n Controlled by: '..sidename
		if self.side ~= 0 then
			status = status..'\n Upgrades: '..count..'/'..upgrades
		end
		
		if self.built and count>0 then
			status = status..'\n Groups:'
			for i,v in pairs(self.built) do
				local gr = Group.getByName(v)
				if gr then
					local grhealth = math.ceil((gr:getSize()/gr:getInitialSize())*100)
					grhealth = math.min(grhealth,100)
					grhealth = math.max(grhealth,1)
					status = status..'\n  '..v..' '..grhealth..'%'
				end
			end
		end
		
		trigger.action.outText(status, 15)
	end

	function ZoneCommander:init()
		local zone = trigger.misc.getZone(self.zone)
		local color = {0.7,0.7,0.7,0.3}
		if self.side == 1 then
			color = {1,0,0,0.3}
		elseif self.side == 2 then
			color = {0,0,1,0.3}
		end
		
		trigger.action.circleToAll(-1,self.index,zone.point, zone.radius,color,color,1)
		trigger.action.textToAll(-1,2000+self.index,zone.point, {0,0,0,0.5}, {0,0,0,0}, 15, true, self.zone)
		
		if #self.built < self.level then
			local upgrades
			if self.side == 1 then
				upgrades = self.upgrades.red
			elseif self.side == 2 then
				upgrades = self.upgrades.blue
			else
				upgrades = {}
			end
			
			for i,v in pairs(upgrades) do
				if not self.built[i] and i<=self.level then
					local gr = mist.cloneInZone(v, self.zone, nil, nil, {initTasks=true, validTerrain={'LAND'}})
					self.built[i] = gr.name
				end
			end
		end
		
		for i,v in ipairs(self.restrictedGroups) do
			trigger.action.setUserFlag(v.name, v.side ~= self.side)
		end
		
		for i,v in ipairs(self.groups) do
			v:init()
		end
	end
	
	function ZoneCommander:update()
		for i,v in pairs(self.built) do
			local gr = Group.getByName(v)
			if gr and gr:getSize() == 0 then
				gr:destroy()
			end
			
			if not gr or gr:getSize() == 0 then
				self.built[i] = nil
				trigger.action.outText(self.zone..' lost group '..v, 5)
			end		
		end
		
		local empty = true
		for i,v in pairs(self.built) do
			if v then
				empty = false
				break
			end
		end
		
		if empty and self.side ~= 0 then
			self.side = 0
			trigger.action.outText(self.zone..' is now neutral ', 5)
			trigger.action.setMarkupColorFill(self.index, {0.7,0.7,0.7,0.3})
			trigger.action.setMarkupColor(self.index, {0.7,0.7,0.7,0.3})
		end
		
		for i,v in ipairs(self.groups) do
			v:update()
		end
		
		if self.crates then
			for i,v in ipairs(self.crates) do
				local crate = StaticObject.getByName(v)
				if crate and Utils.isCrateSettledInZone(crate, self.zone) then
					if self.side == 0 then
						self:capture(crate:getCoalition())
					elseif self.side == crate:getCoalition() then
						self:upgrade()
					end
					
					crate:destroy()
				end
			end
		end
		
		for i,v in ipairs(self.restrictedGroups) do
			trigger.action.setUserFlag(v.name, v.side ~= self.side)
		end
	end
	
	function ZoneCommander:addGroup(group)
		table.insert(self.groups, group)
		group.zoneCommander = self
	end
	
	function ZoneCommander:addGroups(groups)
		for i,v in ipairs(groups) do
			table.insert(self.groups, v)
			v.zoneCommander = self
		end
	end
	
	function ZoneCommander:capture(newside)
		if self.side == 0 and newside ~= 0 then
			self.side = newside
			
			local sidename = ''
			local color = {0.7,0.7,0.7,0.3}
			if self.side==1 then
				sidename='RED'
				color = {1,0,0,0.3}
			elseif self.side==2 then
				sidename='BLUE'
				color = {0,0,1,0.3}
			end
			
			trigger.action.outText(self.zone..' captured by '..sidename, 5)
			trigger.action.setMarkupColorFill(self.index, color)
			trigger.action.setMarkupColor(self.index, color)
			
			self:upgrade()
		end
	end
	
	function ZoneCommander:canRecieveSupply()
		if self.side == 0 then 
			return true
		end
		
		local upgrades
		if self.side == 1 then
			upgrades = self.upgrades.red
		elseif self.side == 2 then
			upgrades = self.upgrades.blue
		else
			upgrades = {}
		end
			
		if #self.built < #upgrades then
			return true
		end
		
		for i,v in pairs(self.built) do
			local gr = Group.getByName(v)
			if gr and gr:getSize() < gr:getInitialSize() then
				return true
			end
		end
		
		return false
	end
	
	function ZoneCommander:upgrade()
		if self.side ~= 0 then
			local upgrades
			if self.side == 1 then
				upgrades = self.upgrades.red
			elseif self.side == 2 then
				upgrades = self.upgrades.blue
			else
				upgrades = {}
			end
				
			if #self.built < #upgrades then
				for i,v in pairs(upgrades) do
					if not self.built[i] then
						local gr = mist.cloneInZone(v, self.zone, nil, nil, {initTasks=true, validTerrain={'LAND'}})
						self.built[i] = gr.name
						trigger.action.outText(self.zone..' defenses upgraded', 5)
						break
					end
				end
			else
				for i,v in pairs(self.built) do
					local gr = Group.getByName(v)
					if gr and gr:getSize() < gr:getInitialSize() then
						mist.respawnGroup(v, true)
						trigger.action.outText(self.zone..' resupplied group '..v, 5)
						break
					end
				end
			end
		end
	end
end

GroupCommander = {}
do
	--{ name='groupname', mission=['patrol', 'supply', 'attack'], targetzone='zonename' }
	function GroupCommander:new(obj)
		obj = obj or {}
		obj.state = 'inhangar'
		obj.lastStateTime = timer.getAbsTime()
		obj.zoneCommander = {}
		obj.side = 0
		setmetatable(obj, self)
		self.__index = self
		return obj
	end
	
	function GroupCommander:init()
		self.state = 'inhangar'
		self.lastStateTime = timer.getAbsTime()
		local gr = Group.getByName(self.name)
		if gr then
			self.side = gr:getCoalition()
			gr:destroy()
		end
	end
	
	function GroupCommander:shouldSpawn()
		if self.side ~= self.zoneCommander.side then
			return false
		end
		
		local tg = self.zoneCommander.battleCommander:getZoneByName(self.targetzone)
		if tg then
			if self.mission=='patrol' then
				if tg.side == self.side then
					return true
				end
			elseif self.mission=='attack' then
				if tg.side ~= self.side and tg.side ~= 0 then
					return true
				end
			elseif self.mission=='supply' then
				if tg.side == self.side or tg.side == 0 then
					return tg:canRecieveSupply()
				end
			end
		end
		
		return false
	end
	
	function GroupCommander:update()
		local gr = Group.getByName(self.name)
		if not gr or gr:getSize()==0 then
			if gr and gr:getSize()==0 then
				gr:destroy()
			end
		
			if self.state ~= 'inhangar' and self.state ~= 'dead' then
				self.state = 'dead'
				self.lastStateTime = timer.getAbsTime()
			end
		end
	
		if self.state == 'inhangar' then
			if timer.getAbsTime() - self.lastStateTime > GlobalSettings.hangarRespawnTime then
				if self:shouldSpawn() then
					mist.respawnGroup(self.name,true)
					self.state = 'takeoff'
					self.lastStateTime = timer.getAbsTime()
				end
			end
		elseif self.state =='takeoff' then
			if timer.getAbsTime() - self.lastStateTime > GlobalSettings.blockedDespawnTime then
				if gr and Utils.allGroupIsLanded(gr) then
					gr:destroy()
					self.state = 'inhangar'
					self.lastStateTime = timer.getAbsTime()
				end
			elseif gr and Utils.someOfGroupInAir(gr) then
				self.state = 'inair'
				self.lastStateTime = timer.getAbsTime()
			end
		elseif self.state =='inair' then
			if gr and Utils.allGroupIsLanded(gr) then
				self.state = 'landed'
				self.lastStateTime = timer.getAbsTime()
			end
		elseif self.state =='landed' then
			if self.mission == 'supply' then
				local tg = self.zoneCommander.battleCommander:getZoneByName(self.targetzone)
				if tg and gr and Utils.someOfGroupInZone(gr, tg.zone) then
					gr:destroy()
					self.state = 'dead'
					self.lastStateTime = timer.getAbsTime()
					if tg.side == 0 then
						tg:capture(self.side)
					elseif tg.side == self.side then
						tg:upgrade()
					end
				end
			end
			
			if timer.getAbsTime() - self.lastStateTime > GlobalSettings.landedDespawnTime then
				if gr then 
					gr:destroy()
					self.state = 'inhangar'
					self.lastStateTime = timer.getAbsTime()
				end
			end
		elseif self.state =='dead' then
			if timer.getAbsTime() - self.lastStateTime > GlobalSettings.deadRespawnTime then
				if self:shouldSpawn() then
					mist.respawnGroup(self.name,true)
					self.state = 'takeoff'
					self.lastStateTime = timer.getAbsTime()
				end
			end
		end
	end
end



