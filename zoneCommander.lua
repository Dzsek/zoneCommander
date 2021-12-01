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
	
	Utils.canAccessFS = true
	function Utils.saveTable(filename, variablename, data)
		if not Utils.canAccessFS then 
			return
		end
		
		if not io then
			Utils.canAccessFS = false
			trigger.action.outText('Persistance disabled', 30)
			return
		end
	
		local str = variablename..' = {}'
		for i,v in pairs(data) do
			str = str..'\n'..variablename..'[\''..i..'\'] = '..Utils.serializeValue(v)
		end
	
		File = io.open(filename, "w")
		File:write(str)
		File:close()
	end
	
	function Utils.serializeValue(value)
		local res = ''
		if type(value)=='number' or type(value)=='boolean' then
			res = res..tostring(value)
		elseif type(value)=='string' then
			res = res..'\''..value..'\''
		elseif type(value)=='table' then
			res = res..'{ '
			for i,v in pairs(value) do
				if type(i)=='number' then
					res = res..'['..i..']='..Utils.serializeValue(v)..','
				else
					res = res..'[\''..i..'\']='..Utils.serializeValue(v)..','
				end
			end
			res = res:sub(1,-2)
			res = res..' }'
		end
		return res
	end
	
	function Utils.loadTable(filename)
		if not Utils.canAccessFS then 
			return
		end
		
		if not lfs then
			Utils.canAccessFS = false
			trigger.action.outText('Persistance disabled', 30)
			return
		end
		
		if lfs.attributes(filename) then
			dofile(filename)
		end
	end
end

GlobalSettings = {}
do
	GlobalSettings.blockedDespawnTime = 10*60 --used to despawn aircraft that are stuck taxiing for some reason
	GlobalSettings.landedDespawnTime = 1*60
	
	GlobalSettings.respawnTimers = {
		supply = { dead=40*60, hangar=25*60},
		patrol = { dead=40*60, hangar=2*60},
		attack = { dead=40*60, hangar=2*60}
	}
end

BattleCommander = {}
do
	BattleCommander.zones = {}
	BattleCommander.connections = {}
	BattleCommander.accounts = { [1]=0, [2]=0} -- 1 = red coalition, 2 = blue coalition
	BattleCommander.shops = {[1]={}, [2]={}}
	BattleCommander.shopItems = {}
	
	function BattleCommander:new()
		local obj = {}
		setmetatable(obj, self)
		self.__index = self
		return obj
	end
	
	-- shops and currency functions
	function BattleCommander:registerShopItem(id, name, cost, action)
		self.shopItems[id] = { name=name, cost=cost, action=action }
	end
	
	function BattleCommander:addShopItem(coalition, id, ammount)
		local item = self.shopItems[id]
		local sitem = self.shops[coalition][id]
		
		if item then
			if sitem then
				if ammount == -1 then
					sitem.stock = -1
				else
					sitem.stock = sitem.stock+ammount
				end
			else
				self.shops[coalition][id] = { name=item.name, cost=item.cost, stock=ammount }
				self:refreshShopMenuForCoalition(coalition)
			end
		end
	end
	
	function BattleCommander:addFunds(coalition, ammount)
		self.accounts[coalition] = self.accounts[coalition] + ammount
	end
	
	function BattleCommander:printShopStatus(coalition)
		local text = 'Credits: '..self.accounts[coalition]..'\n'
		
		for i,v in pairs(self.shops[coalition]) do
			text = text..'\n[Cost: '..v.cost..'] '..i
			if v.stock ~= -1 then
				text = text..' [Available: '..v.stock..']'
			end
		end
		
		trigger.action.outTextForCoalition(coalition, text, 10)
	end
	
	function BattleCommander:buyShopItem(coalition, id)
		local item = self.shops[coalition][id]
		if item then
			if self.accounts[coalition] >= item.cost then
				if item.stock == -1 or item.stock > 0 then
					self.accounts[coalition] = self.accounts[coalition] - item.cost
					if item.stock > 0 then
						item.stock = item.stock - 1
					end
					
					if item.stock == 0 then
						self.shops[coalition][id] = nil
						self:refreshShopMenuForCoalition(coalition)
					end
					
					trigger.action.outTextForCoalition(coalition, 'Bought ['..item.name..'] for '..item.cost..'\n'..self.accounts[coalition]..' credits remaining',5)
					if item.stock == 0 then
						trigger.action.outTextForCoalition(coalition, '['..item.name..'] went out of stock',5)
					end
					
					local sitem = self.shopItems[id]
					if type(sitem.action)=='function' then
						sitem:action()
					end
				else
					trigger.action.outTextForCoalition(coalition,'Not available', 5)
				end
			else
				trigger.action.outTextForCoalition(coalition,'Can not afford ['..item.name..']', 5)
			end
		end
	end
	
	function BattleCommander:refreshShopMenuForCoalition(coalition)
		missionCommands.removeItemForCoalition(coalition, {[1]='Support'})
		
		local shopmenu = missionCommands.addSubMenuForCoalition(coalition, 'Support')
		missionCommands.addCommandForCoalition(coalition, 'Inventory', shopmenu, self.printShopStatus, self, coalition)
		local purchasemenu = missionCommands.addSubMenuForCoalition(coalition, 'Purchase', shopmenu)
		local sub1
		local count = 0
		for i,v in pairs(self.shops[coalition]) do
			count = count +1
			if count<10 then
				missionCommands.addCommandForCoalition(coalition, v.name, purchasemenu, self.buyShopItem, self, coalition, i)
			elseif count==10 then
				sub1 = missionCommands.addSubMenuForCoalition("More", purchasemenu)
				missionCommands.addCommandForCoalition(coalition, v.name, sub1, self.buyShopItem, self, coalition, i)
			else
				missionCommands.addCommandForCoalition(coalition, v.name, sub1, self.buyShopItem, self, coalition, i)
			end
		end
	end
	
	-- end shops and currency
	
	function BattleCommander:getStateTable()
		local states = {zones={}, accounts={}}
		for i,v in ipairs(self.zones) do
			states.zones[v.zone] = { side = v.side, level = #v.built, destroyed=v:getDestroyedCriticalObjects(), active = v.active }
		end
		
		states.accounts = self.accounts
		states.shops = self.shops
		
		return states
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
			if i<10 then
				missionCommands.addCommand(v.zone, main, v.displayStatus, v)
			elseif i==10 then
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
		
		
		self:refreshShopMenuForCoalition(1)
		self:refreshShopMenuForCoalition(2)
		
		mist.scheduleFunction(self.update, {self}, timer.getTime() + 1, 10)
		mist.scheduleFunction(self.saveToDisk, {self}, timer.getTime() + 60, 60)
		
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
	
	function BattleCommander:saveToDisk()
		local statedata = self:getStateTable()
		Utils.saveTable('zoneComPersistance.lua', 'zonePersistance', statedata)
	end
	
	function BattleCommander:loadFromDisk()
		Utils.loadTable('zoneComPersistance.lua')
		if zonePersistance then
			if zonePersistance.zones then
				for i,v in pairs(zonePersistance.zones) do
					local zn = self:getZoneByName(i)
					if zn then
						zn.side = v.side
						zn.level = v.level
						
						if type(v.active)=='boolean' then
							zn.active = v.active
						end
						
						if not zn.active then
							zn.side = 0
							zn.level = 0
						end
						
						if v.destroyed then
							zn.destroyOnInit = v.destroyed
						end
					end
				end
			end
			
			if zonePersistance.accounts then
				self.accounts = zonePersistance.accounts
			end
			
			if zonePersistance.shops then
				self.shops = zonePersistance.shops
			end
		end
	end
end

ZoneCommander = {}
do
	--{ zone='zonename', side=[0=neutral, 1=red, 2=blue], level=int, upgrades={red={}, blue={}}, crates={}, flavourtext=string, income=number }
	function ZoneCommander:new(obj)
		obj = obj or {}
		obj.built = {}
		obj.index = -1
		obj.battleCommander = {}
		obj.groups = {}
		obj.restrictedGroups = {}
		obj.criticalObjects = {}
		obj.active = true
		obj.destroyOnInit = {}
		obj.triggers = {}
		setmetatable(obj, self)
		self.__index = self
		return obj
	end
	
	function ZoneCommander:addRestrictedPlayerGroup(groupinfo)
		table.insert(self.restrictedGroups, groupinfo)
	end
	
	--if all critical onjects are lost in a zone, that zone turns neutral and can never be recaptured
	function ZoneCommander:addCriticalObject(staticname)
		table.insert(self.criticalObjects, staticname)
	end
	
	function ZoneCommander:getDestroyedCriticalObjects()
		local destroyed = {}
		for i,v in ipairs(self.criticalObjects) do
			local st = StaticObject.getByName(v)
			if not st or st:getLife()<1 then
				table.insert(destroyed, v)
			end
		end
		
		return destroyed
	end
	
	--zone triggers 
	-- trigger types= captured, upgraded, repaired, lost, destroyed
	function ZoneCommander:registerTrigger(eventType, action)
		table.insert(self.triggers, {eventType = eventType, action = action})
	end
	
	--return true from eventhandler to end event after run
	function ZoneCommander:runTriggers(eventType)
		for i,v in ipairs(self.triggers) do
			if v.eventType == eventType then
				local endme = v.action(eventType, self)
				
				if endme then
					self.triggers[i] = nil
				end
			end
		end
	end
	--end zone triggers
	
	function ZoneCommander:disableZone()
		if self.active then
			for i,v in pairs(self.built) do
				local gr = Group.getByName(v)
				if gr and gr:getSize() == 0 then
					gr:destroy()
				end
				
				self.built[i] = nil	
			end
			
			self.side = 0
			self.active = false
			trigger.action.outText(self.zone..' has been destroyed', 5)
			trigger.action.setMarkupColorFill(self.index, {0.1,0.1,0.1,0.3})
			trigger.action.setMarkupColor(self.index, {0.1,0.1,0.1,0.3})
			self:runTriggers('destroyed')
		end
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
		
		if not self.active then
			sidename = 'None'
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
		
		if self.flavorText then
			status = status..'\n\n'..self.flavorText
		end
		
		if not self.active then
			status = status..'\n\n WARNING: This zone has been irreparably damaged and is no longer of any use'
		end
		
		trigger.action.outText(status, 15)
	end

	function ZoneCommander:init()
		if self.destroyOnInit then
			for i,v in pairs(self.destroyOnInit) do
				local st = StaticObject.getByName(v)
				if st then
					--trigger.action.explosion(st:getPosition().p, st:getLife())
					st:destroy()
				end
			end
		end
	
	
		local zone = trigger.misc.getZone(self.zone)
		if not zone then
			trigger.action.outText('ERROR: zone ['..self.zone..'] can not be found in the mission', 60)
		end
		
		local color = {0.7,0.7,0.7,0.3}
		if self.side == 1 then
			color = {1,0,0,0.3}
		elseif self.side == 2 then
			color = {0,0,1,0.3}
		end
		
		if not self.active then
			color = {0.1,0.1,0.1,0.3}
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
					local gr = mist.cloneInZone(v, self.zone, true, nil, {initTasks=true, validTerrain={'LAND'}})
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
	
	function ZoneCommander:checkCriticalObjects()
		if not self.active then
			return
		end
		
		local stillactive = false
		if self.criticalObjects and #self.criticalObjects > 0 then
			for i,v in ipairs(self.criticalObjects) do
				local st = StaticObject.getByName(v)
				if st and st:getLife()>1 then
					stillactive = true
				end
				
				--clean up statics that still exist for some reason even though they're dead
				--if st and st:getLife()<1 then
					--st:destroy()
				--end
			end
		else
			stillactive = true
		end
		
		if not stillactive then
			self:disableZone()
		end
	end
	
	function ZoneCommander:update()
		self:checkCriticalObjects()
	
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
		
		if empty and self.side ~= 0 and self.active then
			self.side = 0
			
			trigger.action.outText(self.zone..' is now neutral ', 5)
			trigger.action.setMarkupColorFill(self.index, {0.7,0.7,0.7,0.3})
			trigger.action.setMarkupColor(self.index, {0.7,0.7,0.7,0.3})
			self:runTriggers('lost')
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
		
		if self.income and self.side ~= 0 and self.active then
			self.battleCommander:addFunds(self.side, self.income)
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
		if self.active and self.side == 0 and newside ~= 0 then
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
			self:runTriggers('captured')
			self:upgrade()
		end
		
		if not self.active then
			trigger.action.outText(self.zone..' has been destroyed and can no longer be captured', 5)
		end
	end
	
	function ZoneCommander:canRecieveSupply()
		if not self.active then
			return false
		end
	
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
		
		for i,v in pairs(self.built) do
			local gr = Group.getByName(v)
			if gr and gr:getSize() < gr:getInitialSize() then
				return true
			end
		end
			
		if #self.built < #upgrades then
			return true
		end
		
		return false
	end
	
	function ZoneCommander:upgrade()
		if self.active and self.side ~= 0 then
			local upgrades
			if self.side == 1 then
				upgrades = self.upgrades.red
			elseif self.side == 2 then
				upgrades = self.upgrades.blue
			else
				upgrades = {}
			end
			
			local complete = false
			for i,v in pairs(self.built) do
				local gr = Group.getByName(v)
				if gr and gr:getSize() < gr:getInitialSize() then
					mist.respawnGroup(v, true)
					trigger.action.outText('Group '..v..' at '..self.zone..' was repaired', 5)
					self:runTriggers('repaired')
					complete = true
					break
				end
			end
				
			if not complete and #self.built < #upgrades then
				for i,v in pairs(upgrades) do
					if not self.built[i] then
						local gr = mist.cloneInZone(v, self.zone, true, nil, {initTasks=true, validTerrain={'LAND'}})
						self.built[i] = gr.name
						trigger.action.outText(self.zone..' defenses upgraded', 5)
						self:runTriggers('upgraded')
						break
					end
				end			
			end
		end
		
		if not self.active then
			trigger.action.outText(self.zone..' has been destroyed and can no longer be upgraded', 5)
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
		else
			if not zone then
				trigger.action.outText('ERROR: group ['..self.name..'] can not be found in the mission', 60)
			end
		end
	end
	
	function GroupCommander:shouldSpawn()
		if not self.zoneCommander.active then
			return false
		end
		
		if self.side ~= self.zoneCommander.side then
			return false
		end
		
		local tg = self.zoneCommander.battleCommander:getZoneByName(self.targetzone)
		if tg and tg.active then
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
			if timer.getAbsTime() - self.lastStateTime > GlobalSettings.respawnTimers[self.mission].hangar then
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
					self.state = 'inhangar'
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
			if timer.getAbsTime() - self.lastStateTime > GlobalSettings.respawnTimers[self.mission].dead then
				if self:shouldSpawn() then
					mist.respawnGroup(self.name,true)
					self.state = 'takeoff'
					self.lastStateTime = timer.getAbsTime()
				end
			end
		end
	end
end



