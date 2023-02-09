--[[
~~~Description~~~
ZoneCommander provides classes and utilities for building dynamic missions, with an enemy that reacts to the changing battlefield.

Needs MIST: https://github.com/mrSkortch/MissionScriptingTools/tree/master

~~~Github~~~
Repo & documentation: https://github.com/Dzsek/zoneCommander

~~~Author~~
Dzsekeb
]]

CustomZone = {}
do
	function CustomZone:getByName(name)
		obj = {}
		obj.name = name
		
		local zd = nil
		for _,v in ipairs(env.mission.triggers.zones) do
			if v.name == name then
				zd = v
				break
			end
		end
		
		if not zd then
			return nil
		end
		
		obj.type = zd.type -- 2 == quad, 0 == circle
		if obj.type == 2 then
			obj.vertices = {}
			for _,v in ipairs(zd.verticies) do
				local vertex = {
					x = v.x,
					y = 0,
					z = v.y
				}
				table.insert(obj.vertices, vertex)
			end
		end
		
		obj.radius = zd.radius
		obj.point = {
			x = zd.x,
			y = 0,
			z = zd.y
		}
		
		setmetatable(obj, self)
		self.__index = self
		return obj
	end
	
	function CustomZone:isQuad()
		return self.type==2
	end
	
	function CustomZone:isCircle()
		return self.type==0
	end
	
	function CustomZone:isInside(point)
		if self:isCircle() then
			local dist = mist.utils.get2DDist(point, self.point)
			return dist<self.radius
		elseif self:isQuad() then
			return mist.pointInPolygon(point, self.vertices)
		end
	end
	
	function CustomZone:draw(id, border, background)
		if self:isCircle() then
			trigger.action.circleToAll(-1,id,self.point, self.radius,border,background,1)
		elseif self:isQuad() then
			trigger.action.quadToAll(-1,id,self.vertices[4], self.vertices[3], self.vertices[2], self.vertices[1],border,background,1)
		end
	end
	
	function CustomZone:getRandomSpawnZone()
		local spawnZones = {}
		for i=1,100,1 do
			local zname = self.name..'-'..i
			if trigger.misc.getZone(zname) then
				table.insert(spawnZones, zname)
			else
				break
			end
		end
		
		if #spawnZones == 0 then return nil end
		
		local choice = math.random(1, #spawnZones)
		return spawnZones[choice]
	end
	
	function CustomZone:spawnGroup(grname, forceFirst)
		local spname = self.name
		local spawnzone = nil
		
		if forceFirst and trigger.misc.getZone(spname..'-0')then
			spawnzone = spname..'-0'
		end
		
		if not spawnzone then
			spawnzone = self:getRandomSpawnZone()
		end
		
		if spawnzone then
			spname = spawnzone
		end
	
		local pnt = mist.getRandomPointInZone(spname)
		local vars = {
			groupName = grname,
			point = pnt,
			action = 'clone',
			disperse = true,
			initTasks = true
		}
		
		local newgr = mist.teleportToPoint(vars)
		
		if not newgr then
			newgr = mist.cloneInZone(grname, spname, true, nil, {initTasks = true})
		end
		
		return newgr
	end
end

Utils = {}
do
	function Utils.getPointOnSurface(point)
		return {x = point.x, y = land.getHeight({x = point.x, y = point.z}), z= point.z}
	end
	
	function Utils.getTableSize(tbl)
		local cnt = 0
		for i,v in pairs(tbl) do cnt=cnt+1 end
		return cnt
	end
	
	function Utils.getBearing(fromvec, tovec)
		local fx = fromvec.x
		local fy = fromvec.z
		
		local tx = tovec.x
		local ty = tovec.z
		
		local brg = math.atan2(ty - fy, tx - fx)
		if brg < 0 then
			 brg = brg + 2 * math.pi
		end
		
		brg = brg * 180 / math.pi
		return brg
	end
	
	function Utils.getAGL(object)
		local pt = object:getPoint()
		return pt.y - land.getHeight({ x = pt.x, y = pt.z })
	end
	
	function Utils.isLanded(unit, ignorespeed)
		--return (Utils.getAGL(unit)<5 and mist.vec.mag(unit:getVelocity())<0.10)
		
		if ignorespeed then
			return not unit:inAir()
		else
			return (not unit:inAir() and mist.vec.mag(unit:getVelocity())<1)
		end
	end
	
	function Utils.isGroupActive(group)
		if group and group:getSize()>0 and group:getController():hasTask() then 
			return not Utils.allGroupIsLanded(group, true)
		else
			return false
		end
	end
	
	function Utils.isInAir(unit)
		--return Utils.getAGL(unit)>5
		return unit:inAir()
	end
	
	function Utils.isInZone(unit, zonename)
		local zn = CustomZone:getByName(zonename)
		if zn then
			return zn:isInside(unit:getPosition().p)
		end
		
		return false
	end
	
	function Utils.isCrateSettledInZone(crate, zonename)
		local zn = CustomZone:getByName(zonename)
		if zn and crate then
			return (zn:isInside(crate:getPosition().p) and Utils.getAGL(crate)<1)
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
	
	function Utils.allGroupIsLanded(group, ignorespeed)
		for i,v in pairs(group:getUnits()) do
			if not Utils.isLanded(v, ignorespeed) then
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

JTAC = {}
do
	JTAC.categories = {}
	JTAC.categories['SAM'] = {'SAM SR', 'SAM TR', 'IR Guided SAM','SAM LL','SAM CC'}
	JTAC.categories['Infantry'] = {'Infantry'}
	JTAC.categories['Armor'] = {'Tanks','IFV','APC'}
	JTAC.categories['Support'] = {'Unarmed vehicles','Artillery'}
	
	--{name = 'groupname'}
	function JTAC:new(obj)
		obj = obj or {}
		obj.lasers = {tgt=nil, ir=nil}
		obj.target = nil
		obj.timerReference = nil
		obj.tgtzone = nil
		obj.priority = nil
		obj.jtacMenu = nil
		obj.laserCode = 1688
		obj.side = Group.getByName(obj.name):getCoalition()
		setmetatable(obj, self)
		self.__index = self
		obj:initCodeListener()
		return obj
	end
	
	function JTAC:initCodeListener()
		local ev = {}
		ev.context = self
		function ev:onEvent(event)
			if event.id == 26 then
				if event.text:find('^jtac%-code:') then
					local s = event.text:gsub('^jtac%-code:', '')
					local code = tonumber(s)
					if code>=1111 and code <= 1788 then
						self.context.laserCode = code
						trigger.action.outTextForCoalition(self.context.side, 'JTAC code set to '..code, 10)
						trigger.action.removeMark(event.idx)
					end
				end
			end
		end
		
		world.addEventHandler(ev)
	end
	
	function JTAC:showMenu()
		local gr = Group.getByName(self.name)
		if not gr then
			return
		end
		
		if not self.jtacMenu then
			self.jtacMenu = missionCommands.addSubMenuForCoalition(self.side, 'JTAC')
			
			missionCommands.addCommandForCoalition(self.side, 'Target report', self.jtacMenu, function(dr)
				if Group.getByName(dr.name) then
					dr:printTarget(true)
				else
					missionCommands.removeItemForCoalition(dr.side, dr.jtacMenu)
					dr.jtacMenu = nil
				end
			end, self)
			
			missionCommands.addCommandForCoalition(self.side, 'Next Target', self.jtacMenu, function(dr)
				if Group.getByName(dr.name) then
					dr:searchTarget()
				else
					missionCommands.removeItemForCoalition(dr.side, dr.jtacMenu)
					dr.jtacMenu = nil
				end
			end, self)
			
			missionCommands.addCommandForCoalition(self.side, 'Deploy Smoke', self.jtacMenu, function(dr)
				if Group.getByName(dr.name) then
					local tgtunit = Unit.getByName(dr.target)
					if tgtunit then
						trigger.action.smoke(tgtunit:getPosition().p, 3)
						trigger.action.outTextForCoalition(dr.side, 'JTAC target marked with ORANGE smoke', 10)
					end
				else
					missionCommands.removeItemForCoalition(dr.side, dr.jtacMenu)
					dr.jtacMenu = nil
				end
			end, self)
			
			local priomenu = missionCommands.addSubMenuForCoalition(self.side, 'Set Priority', self.jtacMenu)
			for i,v in pairs(JTAC.categories) do
				missionCommands.addCommandForCoalition(self.side, i, priomenu, function(dr, cat)
					if Group.getByName(dr.name) then
						dr:setPriority(cat)
						dr:searchTarget()
					else
						missionCommands.removeItemForCoalition(dr.side, dr.jtacMenu)
						dr.jtacMenu = nil
					end
				end, drone, i)
			end
			
			missionCommands.addCommandForCoalition(self.side, "Clear", priomenu, function(dr)
				if Group.getByName(dr.name) then
					dr:clearPriority()
					dr:searchTarget()
				else
					missionCommands.removeItemForCoalition(dr.side, dr.jtacMenu)
					dr.jtacMenu = nil
				end
			end, drone)
		end
	end
	
	function JTAC:setPriority(prio)
		self.priority = JTAC.categories[prio]
		self.prioname = prio
	end
	
	function JTAC:clearPriority()
		self.priority = nil
	end
	
	function JTAC:setTarget(unit)
		
		if self.lasers.tgt then
			self.lasers.tgt:destroy()
			self.lasers.tgt = nil
		end
		
		if self.lasers.ir then
			self.lasers.ir:destroy()
			self.lasers.ir = nil
		end
		
		local me = Group.getByName(self.name)
		if not me then return end
		
		local pnt = unit:getPoint()
		self.lasers.tgt = Spot.createLaser(me:getUnit(1), { x = 0, y = 2.0, z = 0 }, pnt, self.laserCode)
		self.lasers.ir = Spot.createInfraRed(me:getUnit(1), { x = 0, y = 2.0, z = 0 }, pnt)
		
		self.target = unit:getName()
	end
	
	function JTAC:printTarget(makeitlast)
		local toprint = ''
		if self.target and self.tgtzone then
			local tgtunit = Unit.getByName(self.target)
			if tgtunit then
				local pnt = tgtunit:getPoint()
				local tgttype = tgtunit:getTypeName()
				
				if self.priority then
					toprint = 'Priority targets: '..self.prioname..'\n'
				end
				
				toprint = toprint..'Lasing '..tgttype..' at '..self.tgtzone.zone..'\nCode: '..self.laserCode..'\n'
				local lat,lon,alt = coord.LOtoLL(pnt)
				local mgrs = coord.LLtoMGRS(coord.LOtoLL(pnt))
				toprint = toprint..'\nDDM:  '.. mist.tostringLL(lat,lon,3)
				toprint = toprint..'\nDMS:  '.. mist.tostringLL(lat,lon,2,true)
				toprint = toprint..'\nMGRS: '.. mist.tostringMGRS(mgrs, 5)
				toprint = toprint..'\n\nAlt: '..math.floor(alt)..'m'..' | '..math.floor(alt*3.280839895)..'ft'
			else
				makeitlast = false
				toprint = 'No Target'
			end
		else
			makeitlast = false
			toprint = 'No target'
		end
		
		local gr = Group.getByName(self.name)
		if makeitlast then
			trigger.action.outTextForCoalition(gr:getCoalition(), toprint, 60)
		else
			trigger.action.outTextForCoalition(gr:getCoalition(), toprint, 10)
		end
	end
	
	function JTAC:clearTarget()
		self.target = nil
	
		if self.lasers.tgt then
			self.lasers.tgt:destroy()
			self.lasers.tgt = nil
		end
		
		if self.lasers.ir then
			self.lasers.ir:destroy()
			self.lasers.ir = nil
		end
		
		if self.timerReference then
			mist.removeFunction(self.timerReference)
			self.timerReference = nil
		end
		
		local gr = Group.getByName(self.name)
		if gr then
			gr:destroy()
			missionCommands.removeItemForCoalition(self.side, self.jtacMenu)
			self.jtacMenu = nil
		end
	end
	
	function JTAC:searchTarget()
		local gr = Group.getByName(self.name)
		if gr then
			if self.tgtzone and self.tgtzone.side~=0 and self.tgtzone.side~=gr:getCoalition() then
				local viabletgts = {}
				for i,v in pairs(self.tgtzone.built) do
					local tgtgr = Group.getByName(v)
					if tgtgr and tgtgr:getSize()>0 then
						for i2,v2 in ipairs(tgtgr:getUnits()) do
							if v2:getLife()>=1 then
								table.insert(viabletgts, v2)
							end
						end
					end
				end
				
				if self.priority then
					local priorityTargets = {}
					for i,v in ipairs(viabletgts) do
						for i2,v2 in ipairs(self.priority) do
							if v:hasAttribute(v2) and v:getLife()>=1 then
								table.insert(priorityTargets, v)
								break
							end
						end
					end
					
					if #priorityTargets>0 then
						viabletgts = priorityTargets
					else
						self:clearPriority()
						trigger.action.outTextForCoalition(gr:getCoalition(), 'JTAC: No priority targets found', 10)
					end
				end
				
				if #viabletgts>0 then
					local chosentgt = math.random(1, #viabletgts)
					self:setTarget(viabletgts[chosentgt])
					self:printTarget()
				else
					self:clearTarget()
				end
			else
				self:clearTarget()
			end
		end
	end
	
	function JTAC:searchIfNoTarget()
		if Group.getByName(self.name) then
			if not self.target or not Unit.getByName(self.target) then
				self:searchTarget()
			elseif self.target then
				local un = Unit.getByName(self.target)
				if un then
					if un:getLife()>=1 then
						self:setTarget(un)
					else
						self:searchTarget()
					end
				end
			end
		else
			self:clearTarget()
		end
	end
	
	function JTAC:deployAtZone(zoneCom)
		self.tgtzone = zoneCom
		local p = CustomZone:getByName(self.tgtzone.zone).point
		local vars = {}
		vars.gpName = self.name
		vars.action = 'respawn' 
		vars.point = {x=p.x, y=5000, z = p.z}
		mist.teleportToPoint(vars)
		
		mist.scheduleFunction(self.setOrbit, {self, self.tgtzone.zone, p}, timer.getTime()+1)
		
		if not self.timerReference then
			self.timerReference = mist.scheduleFunction(self.searchIfNoTarget, {self}, timer.getTime()+5, 5)
		end
	end
	
	function JTAC:setOrbit(zonename, point)
		local gr = Group.getByName(self.name)
		if not gr then 
			return
		end
		
		local cnt = gr:getController()
		cnt:setCommand({ 
			id = 'SetInvisible', 
			params = { 
				value = true 
			} 
		})
  
		cnt:setTask({ 
			id = 'Orbit', 
			params = { 
				pattern = 'Circle',
				point = {x = point.x, y=point.z},
				altitude = 5000
			} 
		})
		
		self:searchTarget()
	end
end

GlobalSettings = {}
do
	GlobalSettings.blockedDespawnTime = 10*60 --used to despawn aircraft that are stuck taxiing for some reason
	GlobalSettings.landedDespawnTime = 1*60
	GlobalSettings.initialDelayVariance = 30 -- minutes
	
	GlobalSettings.messages = {
		grouplost = false,
		captured = true,
		upgraded = true,
		repaired = true,
		zonelost = true,
		disabled = true
	}
	
	GlobalSettings.defaultRespawns = {}
	GlobalSettings.defaultRespawns[1] = {
		supply = { dead=35*60, hangar=20*60, preparing=5*60},
		patrol = { dead=38*60, hangar=2*60, preparing=2*60},
		attack = { dead=38*60, hangar=2*60, preparing=2*60}
	}
	
	GlobalSettings.defaultRespawns[2] = {
		supply = { dead=35*60, hangar=20*60, preparing=5*60},
		patrol = { dead=38*60, hangar=2*60, preparing=2*60},
		attack = { dead=38*60, hangar=2*60, preparing=2*60}
	}
	
	GlobalSettings.respawnTimers = {}
	
	function GlobalSettings.resetDifficultyScaling()
		GlobalSettings.respawnTimers[1] = {
			supply = { 
				dead = GlobalSettings.defaultRespawns[1].supply.dead, 
				hangar = GlobalSettings.defaultRespawns[1].supply.hangar, 
				preparing = GlobalSettings.defaultRespawns[1].supply.preparing
			},
			patrol = { 
				dead = GlobalSettings.defaultRespawns[1].patrol.dead, 
				hangar = GlobalSettings.defaultRespawns[1].patrol.hangar, 
				preparing = GlobalSettings.defaultRespawns[1].patrol.preparing
			},
			attack = { 
				dead = GlobalSettings.defaultRespawns[1].attack.dead, 
				hangar = GlobalSettings.defaultRespawns[1].attack.hangar, 
				preparing = GlobalSettings.defaultRespawns[1].attack.preparing
			}
		}
		
		GlobalSettings.respawnTimers[2] = {
			supply = { 
				dead = GlobalSettings.defaultRespawns[2].supply.dead, 
				hangar = GlobalSettings.defaultRespawns[2].supply.hangar, 
				preparing = GlobalSettings.defaultRespawns[2].supply.preparing
			},
			patrol = { 
				dead = GlobalSettings.defaultRespawns[2].patrol.dead, 
				hangar = GlobalSettings.defaultRespawns[2].patrol.hangar, 
				preparing = GlobalSettings.defaultRespawns[2].patrol.preparing
			},
			attack = { 
				dead = GlobalSettings.defaultRespawns[2].attack.dead, 
				hangar = GlobalSettings.defaultRespawns[2].attack.hangar, 
				preparing = GlobalSettings.defaultRespawns[2].attack.preparing
			}
		}
	end
	
	function GlobalSettings.setDifficultyScaling(value, coalition)
		GlobalSettings.resetDifficultyScaling()
		for i,v in pairs(GlobalSettings.respawnTimers[coalition]) do
			for i2,v2 in pairs(v) do
				GlobalSettings.respawnTimers[coalition][i][i2] = math.floor(GlobalSettings.respawnTimers[coalition][i][i2] * value)
			end
		end
	end
	
	GlobalSettings.resetDifficultyScaling()
end

BattleCommander = {}
do
	BattleCommander.zones = {}
	BattleCommander.indexedZones = {}
	BattleCommander.connections = {}
	BattleCommander.accounts = { [1]=0, [2]=0} -- 1 = red coalition, 2 = blue coalition
	BattleCommander.shops = {[1]={}, [2]={}}
	BattleCommander.shopItems = {}
	BattleCommander.monitorROE = {}
	BattleCommander.playerContributions = {[1]={}, [2]={}}
	BattleCommander.playerRewardsOn = false
	BattleCommander.rewards = {}
	BattleCommander.creditsCap = nil
	BattleCommander.difficultyModifier = 0
	BattleCommander.lastDiffChange = 0
	
	function BattleCommander:new(savepath, updateFrequency, saveFrequency, difficulty) -- difficulty = {start = 1.4, min = -0.5, max = 0.5, escalation = 0.1, fade = 0.1, fadeTime = 30*60, coalition=1} --coalition 1:red 2:blue
		local obj = {}
		obj.saveFile = 'zoneCommander.lua'
		if savepath then
			obj.saveFile = savepath
		end

		if not updateFrequency then updateFrequency = 10 end
		if not saveFrequency then saveFrequency = 60 end
		
		obj.difficulty = difficulty
		obj.updateFrequency = updateFrequency
		obj.saveFrequency = saveFrequency
		
		
		setmetatable(obj, self)
		self.__index = self
		return obj
	end
	
	--difficulty scaling
	
	function BattleCommander:increaseDifficulty()
		self.difficultyModifier = math.max(self.difficultyModifier-self.difficulty.escalation, self.difficulty.min)
		GlobalSettings.setDifficultyScaling(self.difficulty.start + self.difficultyModifier, self.difficulty.coalition)
		self.lastDiffChange = timer.getAbsTime()
		env.info('increasing diff: '..self.difficultyModifier)
	end
	
	function BattleCommander:decreaseDifficulty()
		self.difficultyModifier = math.min(self.difficultyModifier+self.difficulty.fade, self.difficulty.max)
		GlobalSettings.setDifficultyScaling(self.difficulty.start + self.difficultyModifier,self.difficulty.coalition)
		self.lastDiffChange = timer.getAbsTime()
		env.info('decreasing diff: '..self.difficultyModifier)
	end
	
	--end difficulty scaling
	
	-- shops and currency functions
	function BattleCommander:registerShopItem(id, name, cost, action, altAction)
		self.shopItems[id] = { name=name, cost=cost, action=action, altAction = altAction }
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
	
	function BattleCommander:removeShopItem(coalition, id)
		self.shops[coalition][id] = nil
		self:refreshShopMenuForCoalition(coalition)
	end
	
	function BattleCommander:addFunds(coalition, ammount)
		local newAmmount = math.max(self.accounts[coalition] + ammount,0)
		if self.creditsCap then
			newAmmount = math.min(newAmmount, self.creditsCap)
		end
		
		self.accounts[coalition] = newAmmount
	end
	
	function BattleCommander:printShopStatus(coalition)
		local text = 'Credits: '..self.accounts[coalition]
		if self.creditsCap then
			text = text..'/'..self.creditsCap
		end
		
		text = text..'\n'
		
		local sorted = {}
		for i,v in pairs(self.shops[coalition]) do table.insert(sorted,{i,v}) end
		table.sort(sorted, function(a,b) return a[2].name < b[2].name end)
		
		for i2,v2 in pairs(sorted) do
			local i = v2[1]
			local v = v2[2]
			text = text..'\n[Cost: '..v.cost..'] '..v.name
			if v.stock ~= -1 then
				text = text..' [Available: '..v.stock..']'
			end
		end
		
		if self.playerContributions[coalition] then
			for i,v in pairs(self.playerContributions[coalition]) do
				if v>0 then
					text = text..'\n\nUnclaimed credits'
					break
				end
			end
			
			for i,v in pairs(self.playerContributions[coalition]) do
				if v>0 then
					text = text..'\n '..i..' ['..v..']'
				end
			end
		end
		
		trigger.action.outTextForCoalition(coalition, text, 10)
	end
	
	function BattleCommander:buyShopItem(coalition, id, alternateParams)
		local item = self.shops[coalition][id]
		if item then
			if self.accounts[coalition] >= item.cost then
				if item.stock == -1 or item.stock > 0 then
					local success = true
					local sitem = self.shopItems[id]
					
					if alternateParams~=nil and type(sitem.altAction)=='function' then
						success = sitem:altAction(alternateParams)
					elseif type(sitem.action)=='function' then
						success = sitem:action()
					end
					
					if success == true or success == nil then
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
					else
						if type(success) == 'string' then
							trigger.action.outTextForCoalition(coalition, success,5)
						else
							trigger.action.outTextForCoalition(coalition, 'Not available at the current time',5)
						end
						
						return success
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
		local sub1
		local count = 0
		
		local sorted = {}
		for i,v in pairs(self.shops[coalition]) do table.insert(sorted,{i,v}) end
		table.sort(sorted, function(a,b) return a[2].name < b[2].name end)
		
		for i2,v2 in pairs(sorted) do
			local i = v2[1]
			local v = v2[2]
			count = count +1
			if count<10 then
				missionCommands.addCommandForCoalition(coalition, '['..v.cost..'] '..v.name, shopmenu, self.buyShopItem, self, coalition, i)
			elseif count==10 then
				sub1 = missionCommands.addSubMenuForCoalition(coalition, "More", shopmenu)
				missionCommands.addCommandForCoalition(coalition, '['..v.cost..'] '..v.name, sub1, self.buyShopItem, self, coalition, i)
			elseif count%9==1 then
				sub1 = missionCommands.addSubMenuForCoalition(coalition, "More", sub1)
				missionCommands.addCommandForCoalition(coalition, '['..v.cost..'] '..v.name, sub1, self.buyShopItem, self, coalition, i)
			else
				missionCommands.addCommandForCoalition(coalition, '['..v.cost..'] '..v.name, sub1, self.buyShopItem, self, coalition, i)
			end
		end
	end
	
	-- end shops and currency
	
	function BattleCommander:addMonitoredROE(groupname)
		table.insert(self.monitorROE, groupname)
	end
	
	function BattleCommander:checkROE(groupname)
		local gr = Group.getByName(groupname)
		if gr then
			local controller = gr:getController()
			if controller:hasTask() then
				controller:setOption(0, 2) -- roe = open fire
			else
				controller:setOption(0, 4) -- roe = weapon hold
			end
		end
	end
	
	--targetzoneside = 1=red, 2=blue, 0=neutral, nil = all
	function BattleCommander:showTargetZoneMenu(coalition, menuname, action, targetzoneside)
		local executeAction = function(act, params)
			local err = act(params.zone, params.menu) 
			if not err then
				missionCommands.removeItemForCoalition(params.coalition, params.menu)
			end
		end
	
		local menu = missionCommands.addSubMenuForCoalition(coalition, menuname)
		local sub1
		local zones = bc:getZones()
		local count = 0
		for i,v in ipairs(zones) do
			if targetzoneside == nil or v.side == targetzoneside then
				count = count + 1
				if count<10 then
					missionCommands.addCommandForCoalition(coalition, v.zone, menu, executeAction, action, {zone = v.zone, menu=menu, coalition=coalition})
				elseif count==10 then
					sub1 = missionCommands.addSubMenuForCoalition(coalition, "More", menu)
					missionCommands.addCommandForCoalition(coalition, v.zone, sub1, executeAction, action, {zone = v.zone, menu=menu, coalition=coalition})
				elseif count%9==1 then
					sub1 = missionCommands.addSubMenuForCoalition(coalition, "More", sub1)
					missionCommands.addCommandForCoalition(coalition, v.zone, sub1, executeAction, action, {zone = v.zone, menu=menu, coalition=coalition})
				else
					missionCommands.addCommandForCoalition(coalition, v.zone, sub1, executeAction, action, {zone = v.zone, menu=menu, coalition=coalition})
				end
			end
		end
		
		return menu
	end
	
	function BattleCommander:getRandomSurfaceUnitInZone(tgtzone, myside)
		local zn = self:getZoneByName(tgtzone)
		
		local selectedUnit = nil
		
		local units = {}
		for _,v in pairs(zn.built) do
			local g = Group.getByName(v)
			if g and g:getCoalition() ~= myside then
				for _,unit in ipairs(g:getUnits()) do
					table.insert(units, unit)
				end
			end
		end
		
		for _,v in ipairs(zn.groups) do
			local g = Group.getByName(v.name)
			
			if g and v.type == 'surface' and v.side ~= myside then
				for _,unit in ipairs(g:getUnits()) do
					table.insert(units, unit)
				end
			end
		end
		
		
		if #units > 0 then
		 return units[math.random(1, #units)]
		end
	end
	
	function BattleCommander:moveToUnit(tgtunitname, groupname)
		timer.scheduleFunction(function(params, time)
			local group = Group.getByName(params.groupname)
			local unit = Unit.getByName(params.tgtunitname)
			
			if not group or not unit then return end -- do not recalculate route, either target or hunter stopped existing
			
			local pos = unit:getPoint()
			local cnt = group:getController()
			local task = {
				id = "Mission",
				params = {
					airborne = false,
					route = {
						points = {
							[1] = { 
								type=AI.Task.WaypointType.TURNING_POINT, 
								action=AI.Task.TurnMethod.FLY_OVER_POINT,
								speed = 100, 
								x = pos.x + math.random(-100,100), 
								y = pos.z + math.random(-100,100)
							}
						}
					}
				}
			}
			
			cnt:setTask(task)
			return time+50
		end, {tgtunitname = tgtunitname, groupname = groupname}, timer.getTime() + 2)
	end
	
	
	function BattleCommander:startHuntUnitsInZone(tgtzone, groupname)
		if not self.huntedunits then self.huntedunits = {} end
		
		timer.scheduleFunction(function(param, time)
			local group = Group.getByName(param.group)
			
			if not group then 
				param.context.huntedunits[param.group] = nil
				return -- group stopped existing, shut down the hunt
			end
			
			local huntedunit = param.context.huntedunits[param.group]
			if huntedunit and Unit.getByName(huntedunit) then return time+60 end -- hunted unit still exists, check again in a minute
		
			local tgtunit = param.context:getRandomSurfaceUnitInZone(param.zone, group:getCoalition())
			if tgtunit then
				param.context.huntedunits[param.group] = tgtunit:getName()
				param.context:moveToUnit(tgtunit:getName(), param.group)
				return time+120 -- new unit selected, check again in 2 minutes if we should select a new one
			else
				return time+600 -- no unit in zone, try again in 10 minutes
			end
					
		end, {context = self, zone = tgtzone, group = groupname}, timer.getTime()+2)
	end
	
	function BattleCommander:engageZone(tgtzone, groupname, expendAmmount, weapon)
		local zn = self:getZoneByName(tgtzone)
		local group = Group.getByName(groupname)
		
		if group and zn.side == group:getCoalition() then
			return 'Can not engage friendly zone'
		end
		
		if not group then
			return 'Not available'
		end
		
		local cnt=group:getController()
		cnt:popTask()
		
		local expCount = AI.Task.WeaponExpend.ONE
		if expendAmmount then
			expCount = expendAmmount
		end
		
		local wepType = Weapon.flag.AnyWeapon
		if weapon then
			wepType = weapon
		end
		
		for i,v in pairs(zn.built) do
			local g = Group.getByName(v)
			if g then
				local task = { 
				  id = 'AttackGroup', 
				  params = { 
					groupId = g:getID(),
					expend = expCount,
					weaponType = wepType,
					groupAttack = true
				  } 
				}
				
				cnt:pushTask(task)
			else
				local s = StaticObject.getByName(v)
				if s then
					local task = { 
					  id = 'AttackUnit', 
					  params = { 
						groupId = s:getID(),
						expend = expCount,
						weaponType = wepType,
						groupAttack = true
					  } 
					}
					
					cnt:pushTask(task)
				end
			end
		end
	end
	
	function BattleCommander:carpetBombRandomUnitInZone(tgtzone, groupname)
		local zn = self:getZoneByName(tgtzone)
		local group = Group.getByName(groupname)
		
		if group and zn.side == group:getCoalition() then
			return 'Can not engage friendly zone'
		end
		
		if not group then
			return 'Not available'
		end
		
		local cnt=group:getController()
		
		local viabletgts = {}
		for i,v in pairs(zn.built) do
			local g = Group.getByName(v)
			if g then
				for i2,v2 in ipairs(g:getUnits()) do
					table.insert(viabletgts, v2)
				end
			else
				local s = StaticObject.getByName(v)
				if s then
					table.insert(viabletgts,s)
				end
			end
		end
		
		local choice = viabletgts[math.random(1,#viabletgts)]
		local p = choice:getPoint()
		
		local task = { 
		  id = 'CarpetBombing', 
		  params = { 
			attackType = 'Carpet',
			carpetLength = 1000,
			expend = AI.Task.WeaponExpend.ALL,
			weaponType = Weapon.flag.AnyUnguidedBomb,
			groupAttack = true,
			attackQty = 1,
			altitudeEnabled = true,
			altitude = 9144,
			point = {x=p.x, y=p.z}
		  } 
		}
		cnt:popTask()
		cnt:pushTask(task)
	end
	
	function BattleCommander:jamRadarsAtZone(groupname, zonename)
		local gr = Group.getByName(groupname)
		local zn = self:getZoneByName(zonename)
		if not gr then return 'EW group dead' end
		if not zn then return 'Zone not found' end
		if zn.side == gr:getCoalition() then return 'Can not jam friendly zone' end
		
		timer.scheduleFunction(function (param, time)
			local gr = Group.getByName(param.ewgroup)
			local zn = param.context:getZoneByName(param.target)
			if not Utils.isGroupActive(gr) or zn.side == gr:getCoalition() then
				for i,v in pairs(zn.built) do
					local g = Group.getByName(v)
					if g then
						for i2,v2 in ipairs(g:getUnits()) do
							if v2:hasAttribute('SAM SR') or v2:hasAttribute('SAM TR') then
								v2:getController():setOption(0,2)
								v2:getController():setOption(9,2)
							end
						end
					end
				end
				return nil
			else
				for i,v in pairs(zn.built) do
					local g = Group.getByName(v)
					if g then
						for i2,v2 in ipairs(g:getUnits()) do
							if v2:hasAttribute('SAM SR') or v2:hasAttribute('SAM TR') then
								v2:getController():setOption(0,4)
								v2:getController():setOption(9,1)
							end
						end
					end
				end
			end
			
			return time+10
		end, {ewgroup = groupname, target = zonename, context = self}, timer.getTime()+10)
	end
	
	function BattleCommander:startFiringAtZone(groupname, zonename, minutes)
		timer.scheduleFunction(function(param, time)
			local gr = Group.getByName(param.group)
			local abu = param.context:getZoneByName(param.zone)
			
			if not abu or abu.side ~= 2 then return nil end
			if not gr then return nil end
			
			param.context:fireAtZone(abu.zone, param.group, true, 1, 50)
			return time+(param.period*60)
			
		end, {group = groupname, zone = zonename, context=self, period = minutes}, timer.getTime()+5)
	end
	
	function BattleCommander:fireAtZone(tgtzone, groupname, precise, ammount, ammountPerTarget)
		local zn = self:getZoneByName(tgtzone)
		local launchers = Group.getByName(groupname)
		
		if launchers and zn.side == launchers:getCoalition() then
			return 'Can not launch attack on friendly zone'
		end
		
		if not launchers then
			return 'Not available'
		end
		
		if ammountPerTarget==nil then
			ammountPerTarget = 1
		end
		
		if precise then
			local units = {}
			for i,v in pairs(zn.built) do
				local g = Group.getByName(v)
				if g then
					for i2,v2 in ipairs(g:getUnits()) do
						table.insert(units, v2)
					end
				else
					local s = StaticObject.getByName(v)
					if s then
						table.insert(units, s)
					end
				end
			end
			
			if #units == 0 then
				return 'No targets found within zone'
			end
			
			local selected = {}
			for i=1,ammount,1 do
				if #units == 0 then 
					break
				end
				
				local tgt = math.random(1,#units)
				
				table.insert(selected, units[tgt])
				table.remove(units, tgt)
			end
			
			while #selected < ammount do
				local ind = math.random(1,#selected)
				table.insert(selected, selected[ind])
			end
			
			for i,v in ipairs(selected) do
				local unt = v
				if unt then
					local target = {}
					target.x = unt:getPosition().p.x
					target.y = unt:getPosition().p.z
					target.radius = 100
					target.expendQty = ammountPerTarget
					target.expendQtyEnabled = true
					local fire = {id = 'FireAtPoint', params = target}
					
					launchers:getController():pushTask(fire)
				end
			end
		else
			local tz = CustomZone:getByName(zn.zone)
			local target = {}
			target.x = tz.point.x
			target.y = tz.point.y
			target.radius = tz.radius
			target.expendQty = ammount
			target.expendQtyEnabled = true
			local fire = {id = 'FireAtPoint', params = target}
			
			local launchers = Group.getByName(groupname)
			launchers:getController():pushTask(fire)
		end
	end
	
	function BattleCommander:getStateTable()
		local states = {zones={}, accounts={}}
		for i,v in ipairs(self.zones) do
			
			unitTable = {}
			for i2,v2 in pairs(v.built) do
				unitTable[i2] = {}
				local gr = Group.getByName(v2)
				if gr then
					for i3,v3 in ipairs(gr:getUnits()) do
						local desc = v3:getDesc()
						table.insert(unitTable[i2], desc['typeName'])
					end
				end
			end
		
			states.zones[v.zone] = { side = v.side, level = Utils.getTableSize(v.built), remainingUnits = unitTable, destroyed=v:getDestroyedCriticalObjects(), active = v.active, triggers = {} }
			
			for i2,v2 in ipairs(v.triggers) do
				if v2.id then
					states.zones[v.zone].triggers[v2.id] = v2.hasRun
				end
			end
		end
		
		states.accounts = self.accounts
		states.shops = self.shops
		states.difficultyModifier = self.difficultyModifier
		states.playerStats = {}
		if self.playerStats then
			for i,v in pairs(self.playerStats) do
				local sanitized = i:gsub("\\","\\\\")
				sanitized = sanitized:gsub("'","\\'")
				states.playerStats[sanitized] = v
			end
		end
		
		return states
	end
	
	function BattleCommander:getZoneOfUnit(unitname)
		local un = Unit.getByName(unitname)
		
		if not un then 
			return nil
		end
		
		for i,v in ipairs(self.zones) do
			if Utils.isInZone(un, v.zone) then
				return v
			end
		end
		
		return nil
	end
	
	function BattleCommander:getZoneOfWeapon(weapon)
		if not weapon then 
			return nil
		end
		
		for i,v in ipairs(self.zones) do
			if Utils.isInZone(weapon, v.zone) then
				return v
			end
		end
		
		return nil
	end
	
	function BattleCommander:getZoneOfPoint(point)
		for i,v in ipairs(self.zones) do
			local z = CustomZone:getByName(v.zone)
			if z and z:isInside(point) then
				return v
			end
		end
		
		return nil
	end
	
	function BattleCommander:addZone(zone)
		table.insert(self.zones, zone)
		zone.index = self:getZoneIndexByName(zone.zone)+3000
		zone.battleCommander = self
		self.indexedZones[zone.zone] = zone
	end
	
	function BattleCommander:getZoneByName(name)
		return self.indexedZones[name]
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
					local zn = CustomZone:getByName(v2.zone)
					local pos3d = {
						x = v.units[1].point.x,
						y = 0,
						z = v.units[1].point.y
					}
					
					if zn and zn:isInside(pos3d) then
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
	
	function BattleCommander:startMonitorPlayerMarkers()
		markEditedEvent = {}
		markEditedEvent.context = self
		function markEditedEvent:onEvent(event)
			if event.id == 26 and event.text and (event.coalition == 1 or event.coalition == 2) then -- mark changed
				local success = false
				
				if event.text=='help' then
					local toprint = 'Available Commands:'
					toprint = toprint..'\nbuy - display available support items'
					toprint = toprint..'\nbuy:item - buy support item'
					toprint = toprint..'\nstatus - display zone status for 60 seconds'
					toprint = toprint..'\nstats - display complete leaderboard'
					toprint = toprint..'\ntop - display top 5 players from leaderboard'
					toprint = toprint..'\nmystats - display your personal statistics (only in MP)'
					toprint = toprint..'\njtac-code:1234 - change laser code of JTAC (Valid codes: 1111-1788)'
					
					if event.initiator then
						trigger.action.outTextForGroup(event.initiator:getGroup():getID(), toprint, 20)
					else
						trigger.action.outTextForCoalition(event.coalition, toprint, 20)
					end
					
					success = true
				end
				
				if event.text:find('^buy') then
					if event.text == 'buy' then
						local toprint = 'Credits: '..self.context.accounts[event.coalition]
						if self.context.creditsCap then
							toprint = toprint..'/'..self.context.creditsCap
						end
						
						toprint = toprint..'\n'
						local sorted = {}
						for i,v in pairs(self.context.shops[event.coalition]) do table.insert(sorted,{i,v}) end
						table.sort(sorted, function(a,b) return a[2].name < b[2].name end)
						
						for i2,v2 in pairs(sorted) do
							local i = v2[1]
							local v = v2[2]
							toprint = toprint..'\n[Cost: '..v.cost..'] '..v.name..'   buy:'..i
							if v.stock ~= -1 then
								toprint = toprint..' [Available: '..v.stock..']'
							end
						end
						
						if event.initiator then
							trigger.action.outTextForGroup(event.initiator:getGroup():getID(), toprint, 20)
						else
							trigger.action.outTextForCoalition(event.coalition, toprint, 20)
						end
						
						success = true
					elseif event.text:find('^buy\:') then
						local item = event.text:gsub('^buy\:', '')
						local zn = self.context:getZoneOfPoint(event.pos)
						self.context:buyShopItem(event.coalition,item,{zone = zn, point=event.pos})
						success = true
					end
				end
				
				if event.text=='status' then
					local zn = self.context:getZoneOfPoint(event.pos)
					if zn then
						if event.initiator then
							zn:displayStatus(event.initiator:getGroup():getID(), 60)
						else
							zn:displayStatus(nil, 60)
						end
						
						success = true
					else
						success = true
						if event.initiator then
							trigger.action.outTextForGroup(event.initiator:getGroup():getID(), 'Status command only works inside a zone', 20)
						else
							trigger.action.outTextForCoalition(event.coalition, 'Status command only works inside a zone', 20)
						end
					end
				end
				
				if event.text=='stats' then
					if event.initiator then
						self.context:printStats(event.initiator:getID())
						success = true
					else
						self.context:printStats()
						success = true
					end
				end
				
				if event.text=='top' then
					if event.initiator then
						self.context:printStats(event.initiator:getID(), 5)
						success = true
					else
						self.context:printStats(nil, 5)
						success = true
					end
				end
				
				if event.text=='mystats' then
					if event.initiator then
						self.context:printMyStats(event.initiator:getID(), event.initiator:getPlayerName())
						success = true
					end
				end
				
				
				if success then
					trigger.action.removeMark(event.idx)
				end
			end
		end
		
		world.addEventHandler(markEditedEvent)
	end
	
	function BattleCommander:init()
		self:startMonitorPlayerMarkers()
		self:initializeRestrictedGroups()
		
		if self.difficulty then
			self.lastDiffChange = timer.getAbsTime()
		end
		
		table.sort(self.zones, function (a,b) return a.zone < b.zone end)
		
		local main =  missionCommands.addSubMenu('Zone Status')
		local sub1
		for i,v in ipairs(self.zones) do
			v:init()
			if i<10 then
				missionCommands.addCommand(v.zone, main, v.displayStatus, v)
			elseif i==10 then
				sub1 = missionCommands.addSubMenu("More", main)
				missionCommands.addCommand(v.zone, sub1, v.displayStatus, v)
			elseif i%9==1 then
				sub1 = missionCommands.addSubMenu("More", sub1)
				missionCommands.addCommand(v.zone, sub1, v.displayStatus, v)
			else
				missionCommands.addCommand(v.zone, sub1, v.displayStatus, v)
			end
		end
		
		for i,v in ipairs(self.connections) do
			local from = CustomZone:getByName(v.from)
			local to = CustomZone:getByName(v.to)
			
			trigger.action.lineToAll(-1, 1000+i, from.point, to.point, {1,1,1,0.5}, 2)
		end
		
		missionCommands.addCommandForCoalition(1, 'Budget overview', nil, self.printShopStatus, self, 1)
		missionCommands.addCommandForCoalition(2, 'Budget overview', nil, self.printShopStatus, self, 2)
		
		self:refreshShopMenuForCoalition(1)
		self:refreshShopMenuForCoalition(2)
		
		mist.scheduleFunction(self.update, {self}, timer.getTime() + 1, self.updateFrequency)
		mist.scheduleFunction(self.saveToDisk, {self}, timer.getTime() + 30, self.saveFrequency)
		
		local ev = {}
		function ev:onEvent(event)
			if event.id==20 and event.initiator and event.initiator:getCategory() == Object.Category.UNIT and (event.initiator:getDesc().category == Unit.Category.AIRPLANE or event.initiator:getDesc().category == Unit.Category.HELICOPTER)  then
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
	
	function BattleCommander:addTempStat(playerName, statKey, value)
		self.tempStats = self.tempStats or {}
		self.tempStats[playerName] = self.tempStats[playerName] or {}
		self.tempStats[playerName][statKey] = self.tempStats[playerName][statKey] or 0
		self.tempStats[playerName][statKey] = self.tempStats[playerName][statKey] + value
	end
	
	function BattleCommander:addStat(playerName, statKey, value)
		self.playerStats = self.playerStats or {}
		self.playerStats[playerName] = self.playerStats[playerName] or {}
		self.playerStats[playerName][statKey] = self.playerStats[playerName][statKey] or 0
		self.playerStats[playerName][statKey] = self.playerStats[playerName][statKey] + value
	end
	
	function BattleCommander:resetTempStats(playerName)
		self.tempStats = self.tempStats or {}
		self.tempStats[playerName] = {}
	end
	
	function BattleCommander:printTempStats(side, player)
		self.tempStats = self.tempStats or {}
		self.tempStats[player] = self.tempStats[player] or {}
		local sorted = {}
		for i,v in pairs(self.tempStats[player]) do table.insert(sorted,{i,v}) end
		table.sort(sorted, function(a,b) return a[1] < b[1] end)
		
		local message = '['..player..']'
		for i,v in ipairs(sorted) do
			message = message..'\n+'..v[2]..' '..v[1]
		end
		
		trigger.action.outTextForCoalition(side, message , 10)
	end
	
	function BattleCommander:printMyStats(unitid,player)
		self.playerStats = self.playerStats or {}
		self.playerStats[player] = self.playerStats[player] or {}
		
		local rank = nil
		local sorted2 = {}
		for i,v in pairs(self.playerStats) do table.insert(sorted2,{i,v}) end
		table.sort(sorted2, function(a,b) return (a[2]['Points'] or 0) > (b[2]['Points'] or 0)end)
		for i,v in ipairs(sorted2) do
			if v[1] == player then 
				rank = i
				break
			end
		end
		
		local sorted = {}
		for i,v in pairs(self.playerStats[player]) do table.insert(sorted,{i,v}) end
		table.sort(sorted, function(a,b) return a[1] < b[1] end)
		
		local message = rank..' ['..player..']'
		for i,v in ipairs(sorted) do
			message = message..'\n'..v[1]..': '..v[2]
		end
		
		trigger.action.outTextForUnit(unitid, message , 10)
	end
	
	function BattleCommander:printStats(unitid, top)
		self.playerStats = self.playerStats or {}
		local sorted = {}
		for i,v in pairs(self.playerStats) do table.insert(sorted,{i,v}) end
		table.sort(sorted, function(a,b) return (a[2]['Points'] or 0) > (b[2]['Points'] or 0)end)
		
		local message = '[Leaderboards]'
		if top then message = '[Top '..top..' players]' end
		local counter = 0
		for i,v in ipairs(sorted) do
			counter = counter + 1
			if top and counter>top then break end
			
			message = message..'\n\n'..i..'. ['..v[1]..']\n'
  			local sorted2 = {}
            for i,v in pairs(v[2]) do table.insert(sorted2,{i,v}) end
            table.sort(sorted2, function(a,b) 
  				if a[1] == 'Points' then return false end
  				if b[1] == 'Points' then return true end
  				return a[1] < b[1] 
			end)
  			for i2,v2 in ipairs(sorted2) do
  				message = message..' '..v2[1]..':'..v2[2]
  			end
		end
		
		if unitid then
			trigger.action.outTextForUnit(unitid, message , 30)
		else
			trigger.action.outText(message , 30)
		end
	end
	
	function BattleCommander:commitTempStats(playerName)
		self.tempStats = self.tempStats or {}
		local stats = self.tempStats[playerName]
		if stats then
			for key,value in pairs(stats) do
				self:addStat(playerName, key, value)
			end
			
			self:resetTempStats(playerName)
		end
	end
	
	-- defaultReward - base pay, rewards = {airplane=0, helicopter=0, ground=0, ship=0, structure=0, infantry=0, sam=0, crate=0, rescue=0} - overrides
	function BattleCommander:startRewardPlayerContribution(defaultReward, rewards)
		self.playerRewardsOn = true
		self.rewards = rewards
		self.defaultReward = defaultReward
		
		local ev = {}
		ev.context = self
		ev.rewards = rewards
		ev.default = defaultReward
		function ev:onEvent(event)
			local unit = event.initiator
			if unit and unit:getCategory() == Object.Category.UNIT and (unit:getDesc().category == Unit.Category.AIRPLANE or unit:getDesc().category == Unit.Category.HELICOPTER)then
				local side = unit:getCoalition()
				local groupid = unit:getGroup():getID()
				local pname = unit:getPlayerName()
				if pname then
					if (event.id==6) then --pilot ejected
						if self.context.playerContributions[side][pname] ~= nil and self.context.playerContributions[side][pname]>0 then
							local tenp = math.floor(self.context.playerContributions[side][pname]*0.25)
							self.context:addFunds(side, tenp)
							trigger.action.outTextForCoalition(side, '['..pname..'] ejected. +'..tenp..' credits (25% of earnings). Kill statistics lost.', 5)
							self.context:addStat(pname, 'Points', tenp)
							self.context.playerContributions[side][pname] = 0
						end
					end
					
					if (event.id==15) then  -- spawned
						self.context.playerContributions[side][pname] = 0
						self.context:resetTempStats(pname)
					end
					
					if (event.id==28) then --killed unit
						if event.target.getCoalition and side ~= event.target:getCoalition() then
							if self.context.playerContributions[side][pname] ~= nil then
								local earning,message,stat = self.context:objectToRewardPoints2(event.target)
								
								if earning and message then
									trigger.action.outTextForGroup(groupid,'['..pname..'] '..message, 5)
									self.context.playerContributions[side][pname] = self.context.playerContributions[side][pname] + earning
								end
								
								if stat then
									self.context:addTempStat(pname,stat,1)
								end
							end
						end
					end
					
					if (event.id==4) then --landed
						if self.context.playerContributions[side][pname] and self.context.playerContributions[side][pname] > 0 then
							for i,v in ipairs(self.context:getZones()) do
								if side==v.side and Utils.isInZone(unit, v.zone) then
									trigger.action.outTextForGroup(groupid, '['..pname..'] landed at '..v.zone..'.\nWait 10 seconds to claim credits...', 5)
									
									local claimfunc = function(context, zone, player, unitname)
										local un = Unit.getByName(unitname)
										if un and Utils.isInZone(un,zone.zone) and Utils.isLanded(un, true) and un:getPlayerName()==player then
											if un:getLife() > 0 then
												context:addFunds(zone.side, context.playerContributions[zone.side][player])
												trigger.action.outTextForCoalition(zone.side, '['..player..'] redeemed '..context.playerContributions[zone.side][player]..' credits', 5)
												context:printTempStats(zone.side,player)
												context:addTempStat(player, 'Points', context.playerContributions[zone.side][player])
												context:commitTempStats(player)
												context.playerContributions[zone.side][player] = 0
												
												context:saveToDisk() -- save persistance data to enable ending mission after cashing money
											end
										end
									end
									
									mist.scheduleFunction(claimfunc, {self.context, v, pname, unit:getName() }, timer.getTime()+10)
									break
								end
							end
						end
					end
				end
			end
		end
		
		world.addEventHandler(ev)
		
		local resetPoints = function(context, side)
			local plys =  coalition.getPlayers(side)
			
			local players = {}
			for i,v in pairs(plys) do
				local nm = v:getPlayerName()
				if nm then
					players[nm] = true
				end
			end

			for i,v in pairs(context.playerContributions[side]) do
				if not players[i] then
					context.playerContributions[side][i] = 0
				end
			end
		end
		
		mist.scheduleFunction(resetPoints, {self, 1}, timer.getTime() + 1, 60)
		mist.scheduleFunction(resetPoints, {self, 2}, timer.getTime() + 1, 60)
	end
	
	function BattleCommander:objectToRewardPoints(object) -- returns points,message
		if object:getCategory() == Object.Category.UNIT then
			local targetType = object:getDesc().category
			local earning = self.defaultReward
			local message = 'Unit kill +'..earning..' credits'
			
			if targetType == Unit.Category.AIRPLANE and self.rewards.airplane then
				earning = self.rewards.airplane
				message = 'Aircraft kill +'..earning..' credits'
			elseif targetType == Unit.Category.HELICOPTER and self.rewards.helicopter then
				earning = self.rewards.helicopter
				message = 'Helicopter kill +'..earning..' credits'
			elseif targetType == Unit.Category.GROUND_UNIT then
				if object:hasAttribute('Infantry') and self.rewards.infantry then
					earning = self.rewards.infantry
					message = 'Infantry kill +'..earning..' credits'
				elseif (object:hasAttribute('SAM SR') or object:hasAttribute('SAM TR') or object:hasAttribute('IR Guided SAM')) and self.rewards.sam then
					earning = self.rewards.sam
					message = 'SAM kill +'..earning..' credits'
				else
					earning = self.rewards.ground
					message = 'Ground kill +'..earning..' credits'
				end
			elseif targetType == Unit.Category.SHIP and self.rewards.ship then
				earning = self.rewards.ship
				message = 'Ship kill +'..earning..' credits'
			elseif targetType == Unit.Category.STRUCTURE and self.rewards.structure then
				earning = self.rewards.structure
				message = 'Structure kill +'..earning..' credits'
			end
			
			return earning,message
		end
	end
	
	function BattleCommander:objectToRewardPoints2(object) -- returns points,message
		local earning = self.defaultReward
		local message = 'Unit kill +'..earning..' credits'
		local statname = 'Veh'
		
		if object:hasAttribute('Planes') and self.rewards.airplane then
			earning = self.rewards.airplane
			message = 'Aircraft kill +'..earning..' credits'
			statname = 'Air'
		elseif object:hasAttribute('Helicopters') and self.rewards.helicopter then
			earning = self.rewards.helicopter
			message = 'Helicopter kill +'..earning..' credits'
			statname = 'Helo'
		elseif object:hasAttribute('Infantry') and self.rewards.infantry then
			earning = self.rewards.infantry
			message = 'Infantry kill +'..earning..' credits'
			statname = 'Inf'
		elseif (object:hasAttribute('SAM SR') or object:hasAttribute('SAM TR') or object:hasAttribute('IR Guided SAM')) and self.rewards.sam then
			earning = self.rewards.sam
			message = 'SAM kill +'..earning..' credits'
			statname = 'SAM'
		elseif object:hasAttribute('Ships') and self.rewards.ship then
			earning = self.rewards.ship
			message = 'Ship kill +'..earning..' credits'
			statname = 'Ship'
		elseif object:hasAttribute('Ground Units') then
			earning = self.rewards.ground
			message = 'Vehicle kill +'..earning..' credits'
			statname = 'Veh'
		elseif object:hasAttribute('Buildings') and self.rewards.structure then
			earning = self.rewards.structure
			message = 'Structure kill +'..earning..' credits'
			statname = 'Struct'
		else
			return -- object does not have any of the attributes
		end
		
		return earning,message,statname
	end
	
	function BattleCommander:update()
		for i,v in ipairs(self.zones) do
			v:update()
		end
		
		for i,v in ipairs(self.monitorROE) do
			self:checkROE(v)
		end
		
		if self.difficulty then
			if timer.getAbsTime()-self.lastDiffChange > self.difficulty.fadeTime then
				self:decreaseDifficulty()
			end
		end
	end
	
	function BattleCommander:saveToDisk()
		local statedata = self:getStateTable()
		Utils.saveTable(self.saveFile, 'zonePersistance', statedata)
	end
	
	function BattleCommander:loadFromDisk()
		Utils.loadTable(self.saveFile)
		if zonePersistance then
			if zonePersistance.zones then
				for i,v in pairs(zonePersistance.zones) do
					local zn = self:getZoneByName(i)
					if zn then
						zn.side = v.side
						zn.level = v.level
						
						if v.remainingUnits then
							zn.remainingUnits = v.remainingUnits
						end
						
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
						
						if v.triggers then
							for i2,v2 in ipairs(zn.triggers) do
								local tr = v.triggers[v2.id]
								if tr then
									v2.hasRun = tr
								end
							end
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
			
			if zonePersistance.difficultyModifier then
				self.difficultyModifier = zonePersistance.difficultyModifier
				if self.difficulty then
					GlobalSettings.setDifficultyScaling(self.difficulty.start + self.difficultyModifier, self.difficulty.coalition)
				end
			end
			
			if zonePersistance.playerStats then
				self.playerStats = zonePersistance.playerStats
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
	
	function ZoneCommander:markWithSmoke(requestingCoalition)
		if requestingCoalition and (self.side ~= requestingCoalition and self.side ~= 0) then
			return
		end
	
		local zone = CustomZone:getByName(self.zone)
		local p = Utils.getPointOnSurface(zone.point)
		trigger.action.smoke(p, 0)
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
	function ZoneCommander:registerTrigger(eventType, action, id, timesToRun)
		table.insert(self.triggers, {eventType = eventType, action = action, id = id, timesToRun = timesToRun, hasRun=0})
	end
	
	--return true from eventhandler to end event after run
	function ZoneCommander:runTriggers(eventType)
		for i,v in ipairs(self.triggers) do
			if v.eventType == eventType then
				if not v.timesToRun or v.hasRun < v.timesToRun then
					v.action(v,self)
					v.hasRun = v.hasRun + 1
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
				
				if not gr then
					local st = StaticObject.getByName(v)
					if st and st:getLife() < 1 then
						st:destroy()
					end
				end
				
				self.built[i] = nil	
			end
			
			self.side = 0
			self.active = false
			if GlobalSettings.messages.disabled then trigger.action.outText(self.zone..' has been destroyed', 5) end
			trigger.action.setMarkupColorFill(self.index, {0.1,0.1,0.1,0.3})
			trigger.action.setMarkupColor(self.index, {0.1,0.1,0.1,0.3})
			self:runTriggers('destroyed')
		end
	end
	
	function ZoneCommander:displayStatus(grouptoshow, messagetimeout)
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
			count = Utils.getTableSize(self.built)
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
				else
					local st = StaticObject.getByName(v)
					if st then
						status = status..'\n  '..v..' 100%'
					end
				end
			end
		end
		
		if self.flavorText then
			status = status..'\n\n'..self.flavorText
		end
		
		if not self.active then
			status = status..'\n\n WARNING: This zone has been irreparably damaged and is no longer of any use'
		end
		
		local zn = CustomZone:getByName(self.zone);
		if zn then
			local pnt = zn.point;
			local lat,lon = coord.LOtoLL(pnt)
			local mgrs = coord.LLtoMGRS(coord.LOtoLL(pnt))
			local alt = land.getHeight({ x = pnt.x, y = pnt.z })
			
			status = status..'\n'
			status = status..'\nDDM:  '.. mist.tostringLL(lat,lon,3)
			status = status..'\nDMS:  '.. mist.tostringLL(lat,lon,2,true)
			status = status..'\nMGRS: '.. mist.tostringMGRS(mgrs, 5)
			status = status..'\n\nAlt: '..math.floor(alt)..'m'..' | '..math.floor(alt*3.280839895)..'ft'
		end
		
		local timeout = 15
		if messagetimeout then
			timeout = messagetimeout
		end
		
		if grouptoshow then
			trigger.action.outTextForGroup(grouptoshow, status, timeout)
		else
			trigger.action.outText(status, timeout)
		end
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
	
	
		local zone = CustomZone:getByName(self.zone)
		if not zone then
			trigger.action.outText('ERROR: zone ['..self.zone..'] can not be found in the mission', 60)
			env.info('ERROR: zone ['..self.zone..'] can not be found in the mission')
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
		
		zone:draw(self.index, color, color)
		trigger.action.textToAll(-1,2000+self.index,zone.point, {0,0,0,0.5}, {0,0,0,0}, 15, true, '')
		trigger.action.setMarkupText(2000+self.index, self.zone)
		
		local upgrades
		if self.side == 1 then
			upgrades = self.upgrades.red
		elseif self.side == 2 then
			upgrades = self.upgrades.blue
		else
			upgrades = {}
		end
		
		if self.remainingUnits then
			for i,v in pairs(self.remainingUnits) do
				if not self.built[i] then
					local upg = upgrades[i]
					local gr = zone:spawnGroup(upg, i==1)
					self.built[i] = gr.name
				end
			end
			
			self:weedOutRemainingUnits()
		else
			if Utils.getTableSize(self.built) < self.level then
				for i,v in pairs(upgrades) do
					if not self.built[i] and i<=self.level then
						local gr = zone:spawnGroup(v, i==1)
						self.built[i] = gr.name
					end
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
	
	function ZoneCommander:weedOutRemainingUnits()
		local destroyPersistedUnits = function(context)
			if context.remainingUnits then
				for i2,v2 in pairs(context.built) do
					local bgr = Group.getByName(v2)
					if bgr then
						for i3,v3 in ipairs(bgr:getUnits()) do
							local budesc = v3:getDesc()
							local found = false
							if context.remainingUnits[i2] then
								local delindex = nil
								for i4,v4 in ipairs(context.remainingUnits[i2]) do
									if v4 == budesc['typeName'] then
										delindex = i4
										found = true
										break
									end
								end
								
								if delindex then
									table.remove(context.remainingUnits[i2], delindex)
								end
							end
							
							if not found then
								v3:destroy()
							end
						end
					else
						--todo: do we need to handle statics?
					end
				end
			end	
		end
		
		mist.scheduleFunction(destroyPersistedUnits, {self}, timer.getTime() + 5)
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
			local st = StaticObject.getByName(v)
			if gr and gr:getSize() == 0 then
				gr:destroy()
			end
			
			if not gr then
				if st and st:getLife()<1 then
					st:destroy()
				end
			end
			
			if not gr and not st then
				self.built[i] = nil
				if GlobalSettings.messages.grouplost then trigger.action.outText(self.zone..' lost group '..v, 5) end
			end		
			
			if gr and gr:getSize() == 0 then
				self.built[i] = nil
				if GlobalSettings.messages.grouplost then trigger.action.outText(self.zone..' lost group '..v, 5) end
			end	
			
			if st and st:getLife()<1 then
				self.built[i] = nil
				if GlobalSettings.messages.grouplost then trigger.action.outText(self.zone..' lost group '..v, 5) end
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
			if self.battleCommander.difficulty and self.side == self.battleCommander.difficulty.coalition then
				self.battleCommander:increaseDifficulty()
			end
		
			self.side = 0
			
			if GlobalSettings.messages.zonelost then trigger.action.outText(self.zone..' is now neutral ', 5) end
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
						if self.battleCommander.playerRewardsOn then
							self.battleCommander:addFunds(self.side, self.battleCommander.rewards.crate)
							trigger.action.outTextForCoalition(self.side,'Capture +'..self.battleCommander.rewards.crate..' credits',5)
						end
					elseif self.side == crate:getCoalition() then
						if self.battleCommander.playerRewardsOn then
							if self:canRecieveSupply() then
								self.battleCommander:addFunds(self.side, self.battleCommander.rewards.crate)
								trigger.action.outTextForCoalition(self.side,'Resupply +'..self.battleCommander.rewards.crate..' credits',5)
							else
								local reward = self.battleCommander.rewards.crate * 0.25
								self.battleCommander:addFunds(self.side, reward)
								trigger.action.outTextForCoalition(self.side,'Resupply +'..reward..' credits (-75% due to no demand)',5)
							end
						end
						
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
	
	function ZoneCommander:killAll()
		for i,v in pairs(self.built) do
			local gr = Group.getByName(v)
			if gr then
				gr:destroy()
			else
				local st = StaticObject.getByName(v)
				if st then
					st:destroy()
				end
			end
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
			
			if GlobalSettings.messages.captured then trigger.action.outText(self.zone..' captured by '..sidename, 5) end
			trigger.action.setMarkupColorFill(self.index, color)
			trigger.action.setMarkupColor(self.index, color)
			self:runTriggers('captured')
			self:upgrade()
			
			for _,v in ipairs(self.groups) do  -- reset group timers to random times so that they don't all spawn immediatly
				if v.state == 'inhangar' or v.state == 'dead' then
					v.lastStateTime = timer.getAbsTime() + math.random(60,GlobalSettings.initialDelayVariance*60)
				end
			end
			
			if self.battleCommander.difficulty and newside == self.battleCommander.difficulty.coalition then
				self.battleCommander:decreaseDifficulty()
			end
		end
		
		if not self.active then
			if GlobalSettings.messages.disabled then trigger.action.outText(self.zone..' has been destroyed and can no longer be captured', 5) end
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
			
		if Utils.getTableSize(self.built) < #upgrades then
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
					if GlobalSettings.messages.repaired then trigger.action.outText('Group '..v..' at '..self.zone..' was repaired', 5) end
					self:runTriggers('repaired')
					complete = true
					break
				end
			end
			
			if not complete and Utils.getTableSize(self.built) < #upgrades then
				local zone = CustomZone:getByName(self.zone)
				for i,v in pairs(upgrades) do
					if not self.built[i] then
						local gr = zone:spawnGroup(v, i==1)
						self.built[i] = gr.name
						if GlobalSettings.messages.upgraded then trigger.action.outText(self.zone..' defenses upgraded', 5) end
						self:runTriggers('upgraded')
						break
					end
				end			
			end
		end
		
		if not self.active then
			if GlobalSettings.messages.disabled then trigger.action.outText(self.zone..' has been destroyed and can no longer be upgraded', 5) end
		end
	end
end

GroupCommander = {}
do
	--{ name='groupname', mission=['patrol', 'supply', 'attack'], targetzone='zonename', type=['air','carrier_air','surface'] }
	function GroupCommander:new(obj)
		obj = obj or {}
		if not obj.type then
			obj.type = 'air'
		end
		obj.state = 'inhangar'
		obj.lastStateTime = timer.getAbsTime()
		obj.zoneCommander = {}
		obj.landsatcarrier = obj.type == 'carrier_air'
		obj.side = 0
		setmetatable(obj, self)
		self.__index = self
		return obj
	end
	
	function GroupCommander:init()
		self.state = 'inhangar'
		self.lastStateTime = timer.getAbsTime() + math.random(1,GlobalSettings.initialDelayVariance*60)
		local gr = Group.getByName(self.name)
		if gr then
			self.side = gr:getCoalition()
			gr:destroy()
		else
			trigger.action.outText('ERROR: group ['..self.name..'] can not be found in the mission', 60)
			env.info('ERROR: group ['..self.name..'] can not be found in the mission')
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
	
	function GroupCommander:processAir()-- states: [inhangar, preparing, takeoff, inair, landed, dead]
		local gr = Group.getByName(self.name)
		local coalition = self.side
		if not gr or gr:getSize()==0 then
			if gr and gr:getSize()==0 then
				gr:destroy()
			end
		
			if self.state ~= 'inhangar' and self.state ~= 'preparing' and self.state ~= 'dead' then
				self.state = 'dead'
				self.lastStateTime = timer.getAbsTime()
			end
		end
		
		if self.state == 'inhangar' then
			if timer.getAbsTime() - self.lastStateTime > GlobalSettings.respawnTimers[coalition][self.mission].hangar then
				if self:shouldSpawn() then
					self.state = 'preparing'
					self.lastStateTime = timer.getAbsTime()
				end
			end
		elseif self.state == 'preparing' then
			if timer.getAbsTime() - self.lastStateTime > GlobalSettings.respawnTimers[coalition][self.mission].preparing then
				if self:shouldSpawn() then
					mist.respawnGroup(self.name,true)
					self.state = 'takeoff'
					self.lastStateTime = timer.getAbsTime()
				end
			end
		elseif self.state =='takeoff' then
			if timer.getAbsTime() - self.lastStateTime > GlobalSettings.blockedDespawnTime then
				if gr and Utils.allGroupIsLanded(gr, self.landsatcarrier) then
					gr:destroy()
					self.state = 'inhangar'
					self.lastStateTime = timer.getAbsTime()
				end
			elseif gr and Utils.someOfGroupInAir(gr) then
				self.state = 'inair'
				self.lastStateTime = timer.getAbsTime()
			end
		elseif self.state =='inair' then
			if gr and Utils.allGroupIsLanded(gr, self.landsatcarrier) then
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
			if timer.getAbsTime() - self.lastStateTime > GlobalSettings.respawnTimers[coalition][self.mission].dead then
				if self:shouldSpawn() then
					self.state = 'preparing'
					self.lastStateTime = timer.getAbsTime()
				end
			end
		end
	end
	
	function GroupCommander:processSurface()-- states: [inhangar, preparing, dead, enroute, atdestination]
		local gr = Group.getByName(self.name)
		local coalition = self.side
		if not gr or gr:getSize()==0 then
			if gr and gr:getSize()==0 then
				gr:destroy()
			end
		
			if self.state ~= 'inhangar' and self.state ~= 'preparing' and self.state ~= 'dead' then
				self.state = 'dead'
				self.lastStateTime = timer.getAbsTime()
			end
		end
	
		if self.state == 'inhangar' then
			if timer.getAbsTime() - self.lastStateTime > GlobalSettings.respawnTimers[coalition][self.mission].hangar then
				if self:shouldSpawn() then
					self.state = 'preparing'
					self.lastStateTime = timer.getAbsTime()
				end
			end
		elseif self.state == 'preparing' then
			if timer.getAbsTime() - self.lastStateTime > GlobalSettings.respawnTimers[coalition][self.mission].preparing then
				if self:shouldSpawn() then
					mist.respawnGroup(self.name,true)
					self.state = 'enroute'
					self.lastStateTime = timer.getAbsTime()
				end
			end
		elseif self.state =='enroute' then
			local tg = self.zoneCommander.battleCommander:getZoneByName(self.targetzone)
			if tg and gr and Utils.someOfGroupInZone(gr, tg.zone) then
				self.state = 'atdestination'
				self.lastStateTime = timer.getAbsTime()
			end
		elseif self.state =='atdestination' then
			if self.mission == 'supply' then
				if timer.getAbsTime() - self.lastStateTime > GlobalSettings.landedDespawnTime then
					local tg = self.zoneCommander.battleCommander:getZoneByName(self.targetzone)
					if gr and tg and Utils.someOfGroupInZone(gr, tg.zone) then
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
			elseif self.mission == 'attack' then
				if timer.getAbsTime() - self.lastStateTime > GlobalSettings.landedDespawnTime then
					local tg = self.zoneCommander.battleCommander:getZoneByName(self.targetzone)
					if gr and tg and Utils.someOfGroupInZone(gr, tg.zone) then
						if tg.side == 0 then
							tg:capture(self.side)
							gr:destroy()
							self.state = 'inhangar'
							self.lastStateTime = timer.getAbsTime()
						end
					end
				end
			end
			
		elseif self.state =='dead' then
			if timer.getAbsTime() - self.lastStateTime > GlobalSettings.respawnTimers[coalition][self.mission].dead then
				if self:shouldSpawn() then
					self.state = 'preparing'
					self.lastStateTime = timer.getAbsTime()
				end
			end
		end
	end
	
	function GroupCommander:update()
		if self.type == 'air' or self.type == 'carrier_air' then
			self:processAir()
		elseif self.type == 'surface' then
			self:processSurface()
		end
	end
end

BudgetCommander = {}
do
	--{ battleCommander = object, side=coalition, decissionFrequency=seconds, decissionVariance=seconds, skipChance=percent}
	function BudgetCommander:new(obj)
		obj = obj or {}
		setmetatable(obj, self)
		self.__index = self
		return obj
	end
	
	function BudgetCommander:update()
		local budget = self.battleCommander.accounts[self.side]
		local options = self.battleCommander.shops[self.side]
		local canAfford = {}
		for i,v in pairs(options) do
			if v.cost<=budget and (v.stock==-1 or v.stock>0) then
				table.insert(canAfford, i)
			end
		end
		
		local dice = math.random(1,100)
		if dice > self.skipChance then
			for i=1,10,1 do
				local choice = math.random(1, #canAfford)
				local err = self.battleCommander:buyShopItem(self.side, canAfford[choice])
				if not err then
					break
				else
					canAfford[choice]=nil
				end
			end
		end
	end
	
	function BudgetCommander:scheduleDecission()
		local variance = math.random(1, self.decissionVariance)
		mist.scheduleFunction(self.update, {self}, timer.getTime() + variance)
	end
	
	function BudgetCommander:init()
		mist.scheduleFunction(self.scheduleDecission, {self}, timer.getTime() + self.decissionFrequency, self.decissionFrequency)
	end
end

EventCommander = {}
do
	--{ decissionFrequency=seconds, decissionVariance=seconds, skipChance=percent}
	function EventCommander:new(obj)
		obj = obj or {}
		obj.events = {}
		setmetatable(obj, self)
		self.__index = self
		return obj
	end
	
	function EventCommander:addEvent(event)--{id=string, action=function, canExecute=function}
		table.insert(self.events, event)
	end
	
	function EventCommander:triggerEvent(id)
		for _,v in ipairs(self.events) do
			if v.id == id and v:canExecute() then
				v:action()
				break
			end
		end
	end
	
	function EventCommander:chooseAndStart(time)
		local canRun = {}
		for i,v in ipairs(self.events) do
			if v:canExecute() then
				table.insert(canRun, v)
			end
		end
		
		if #canRun == 0 then return end
		
		local dice = math.random(1,100)
		if dice > self.skipChance then
			local choice = math.random(1, #canRun)
			local err = canRun[choice]:action()
		end
	end
	
	function EventCommander:scheduleDecission(time)
		local variance = math.random(1, self.decissionVariance)
		timer.scheduleFunction(self.chooseAndStart, self, time + variance)
		return time + self.decissionFrequency + variance
	end
	
	function EventCommander:init()
		timer.scheduleFunction(self.scheduleDecission, self, timer.getTime() + self.decissionFrequency)
	end
end

LogisticCommander = {}
do
	LogisticCommander.allowedTypes = {}
	LogisticCommander.allowedTypes['Ka-50'] = true
	LogisticCommander.allowedTypes['Ka-50_3'] = true
	LogisticCommander.allowedTypes['Mi-24P'] = true
	LogisticCommander.allowedTypes['SA342Mistral'] = true
	LogisticCommander.allowedTypes['SA342L'] = true
	LogisticCommander.allowedTypes['SA342M'] = true
	LogisticCommander.allowedTypes['SA342Minigun'] = true
	LogisticCommander.allowedTypes['UH-60L'] = true
	LogisticCommander.allowedTypes['AH-64D_BLK_II'] = true
	LogisticCommander.allowedTypes['UH-1H'] = true
	LogisticCommander.allowedTypes['Mi-8MT'] = true
	LogisticCommander.allowedTypes['Hercules'] = true
	
	LogisticCommander.maxCarriedPilots = 4
	
	--{ battleCommander = object, supplyZones = { 'zone1', 'zone2'...}}
	function LogisticCommander:new(obj)
		obj = obj or {}
		obj.groupMenus = {} -- groupid = path
		obj.carriedCargo = {} -- groupid = source
		obj.ejectedPilots = {}
		obj.carriedPilots = {} -- groupid = count
		
		setmetatable(obj, self)
		self.__index = self
		return obj
	end
	
	function LogisticCommander:loadSupplies(groupName)
		local gr = Group.getByName(groupName)
		if gr then
			local un = gr:getUnit(1)
			if un then
				if Utils.isInAir(un) then
					trigger.action.outTextForGroup(gr:getID(), 'Can not load supplies while in air', 10)
					return
				end
				
				local zn = self.battleCommander:getZoneOfUnit(un:getName())
				if not zn then
					trigger.action.outTextForGroup(gr:getID(), 'Can only load supplies while within a friendly supply zone', 10)
					return
				end
				
				if zn.side ~= un:getCoalition() then
					trigger.action.outTextForGroup(gr:getID(), 'Can only load supplies while within a friendly supply zone', 10)
					return
				end
				
				if self.carriedCargo[gr:getID()] then
					trigger.action.outTextForGroup(gr:getID(), 'Supplies already loaded', 10)
					return
				end
				
				for i,v in ipairs(self.supplyZones) do
					if v == zn.zone then
						self.carriedCargo[gr:getID()] = zn.zone
						trigger.action.setUnitInternalCargo(un:getName(), 800)
						trigger.action.outTextForGroup(gr:getID(), 'Supplies loaded', 10)
						return
					end
				end
				
				trigger.action.outTextForGroup(gr:getID(), 'Can only load supplies while within a friendly supply zone', 10)
				return
			end
		end
	end
	
	function LogisticCommander:unloadSupplies(groupName)
		local gr = Group.getByName(groupName)
		if gr then
			local un = gr:getUnit(1)
			if un then
				if Utils.isInAir(un) then
					trigger.action.outTextForGroup(gr:getID(), 'Can not unload supplies while in air', 10)
					return
				end
				
				local zn = self.battleCommander:getZoneOfUnit(un:getName())
				if not zn then
					trigger.action.outTextForGroup(gr:getID(), 'Can only unload supplies while within a friendly or neutral zone', 10)
					return
				end
				
				if not(zn.side == un:getCoalition() or zn.side == 0)then
					trigger.action.outTextForGroup(gr:getID(), 'Can only unload supplies while within a friendly or neutral zone', 10)
					return
				end
				
				if not self.carriedCargo[gr:getID()] then
					trigger.action.outTextForGroup(gr:getID(), 'No supplies loaded', 10)
					return
				end
				
				trigger.action.outTextForGroup(gr:getID(), 'Supplies unloaded', 10)
				if self.carriedCargo[gr:getID()] ~= zn.zone then
					if zn.side == 0 and zn.active then 
						if self.battleCommander.playerRewardsOn then
							self.battleCommander:addFunds(un:getCoalition(), self.battleCommander.rewards.crate)
							trigger.action.outTextForCoalition(un:getCoalition(),'Capture +'..self.battleCommander.rewards.crate..' credits',5)
						end
						
						zn:capture(un:getCoalition())
					elseif zn.side == un:getCoalition() then
						if self.battleCommander.playerRewardsOn then
							if zn:canRecieveSupply() then
								self.battleCommander:addFunds(un:getCoalition(), self.battleCommander.rewards.crate)
								trigger.action.outTextForCoalition(un:getCoalition(),'Resupply +'..self.battleCommander.rewards.crate..' credits',5)
							else
								local reward = self.battleCommander.rewards.crate * 0.25
								self.battleCommander:addFunds(un:getCoalition(), reward)
								trigger.action.outTextForCoalition(un:getCoalition(),'Resupply +'..reward..' credits (-75% due to no demand)',5)
							end
						end
						
						zn:upgrade()
					end
				end
				
				self.carriedCargo[gr:getID()] = nil
				trigger.action.setUnitInternalCargo(un:getName(), 0)
				return
			end
		end
	end
	
	function LogisticCommander:listSupplyZones(groupName)
		local gr = Group.getByName(groupName)
		if gr then
			local msg = 'Friendly supply zones:'
			for i,v in ipairs(self.supplyZones) do
				local z = self.battleCommander:getZoneByName(v)
				if z and z.side == gr:getCoalition() then
					msg = msg..'\n'..v
				end
			end
			
			trigger.action.outTextForGroup(gr:getID(), msg, 15)
		end
	end
	
	function LogisticCommander:loadPilot(groupname)
		local gr = Group.getByName(groupname)
		local groupid = gr:getID()
		if gr then
			local un = gr:getUnit(1)
			if Utils.getAGL(un) > 50 then
				trigger.action.outTextForGroup(groupid, "You are too high", 15)
				return
			end
			
			if mist.vec.mag(un:getVelocity())>5 then
				trigger.action.outTextForGroup(groupid, "You are moving too fast", 15)
				return
			end
			
			if self.carriedPilots[groupid] >= LogisticCommander.maxCarriedPilots then
				trigger.action.outTextForGroup(groupid, "At max capacity", 15)
				return
			end
		
			for i,v in ipairs(self.ejectedPilots) do
				local dist = mist.utils.get3DDist(un:getPoint(),v:getPoint())
				if dist<150 then
					self.carriedPilots[groupid] = self.carriedPilots[groupid] + 1
					table.remove(self.ejectedPilots, i)
					v:destroy()
					trigger.action.outTextForGroup(groupid, "Pilot onboard ["..self.carriedPilots[groupid]..'/'..LogisticCommander.maxCarriedPilots..']', 15)
					return
				end
			end
			
			trigger.action.outTextForGroup(groupid, "No ejected pilots nearby", 15)
		end
	end
	
	function LogisticCommander:unloadPilot(groupname)
		local gr = Group.getByName(groupname)
		local groupid = gr:getID()
		if gr then
			local un = gr:getUnit(1)
			
			if self.carriedPilots[groupid] == 0 then
				trigger.action.outTextForGroup(groupid, "No one onboard", 15)
				return
			end
			
			if Utils.isInAir(un) then
				trigger.action.outTextForGroup(groupid, "Can not drop off pilots while in air", 15)
				return
			end
			
			local zn = self.battleCommander:getZoneOfUnit(un:getName())
			if zn and zn.active and zn.side == gr:getCoalition() then
				local count = self.carriedPilots[groupid]
				trigger.action.outTextForGroup(groupid, "Pilots dropped off", 15)
				
				if self.battleCommander.playerRewardsOn then
					self.battleCommander:addFunds(un:getCoalition(), self.battleCommander.rewards.rescue*count)
					trigger.action.outTextForCoalition(un:getCoalition(),count..' pilots were rescued. +'..self.battleCommander.rewards.rescue*count..' credits',5)
				end
				
				self.carriedPilots[groupid] = 0
				
				return
			end
			
			trigger.action.outTextForGroup(groupid, "Can only drop off pilots in a friendly zone", 15)
		end
	end
	
	function LogisticCommander:markPilot(groupname)
		local gr = Group.getByName(groupname)
		if gr then
			local un = gr:getUnit(1)
			
			local maxdist = 300000
			local targetpilot = nil
			for i,v in ipairs(self.ejectedPilots) do
				local dist = mist.utils.get3DDist(un:getPoint(),v:getPoint())
				if dist<maxdist then
					maxdist = dist
					targetpilot = v
				end
			end
			
			if targetpilot then
				trigger.action.smoke(targetpilot:getPoint(), 4)
				trigger.action.outTextForGroup(gr:getID(), 'Ejected pilot has been marked with blue smoke', 15)
			else
				trigger.action.outTextForGroup(gr:getID(), 'No ejected pilots nearby', 15)
			end
		end
	end
	
	function LogisticCommander:flarePilot(groupname)
		local gr = Group.getByName(groupname)
		if gr then
			local un = gr:getUnit(1)
			
			local maxdist = 300000
			local targetpilot = nil
			for i,v in ipairs(self.ejectedPilots) do
				local dist = mist.utils.get3DDist(un:getPoint(),v:getPoint())
				if dist<maxdist then
					maxdist = dist
					targetpilot = v
				end
			end
			
			if targetpilot then
				trigger.action.signalFlare(targetpilot:getPoint(), 0, math.floor(math.random(0,359)))
			else
				trigger.action.outTextForGroup(gr:getID(), 'No ejected pilots nearby', 15)
			end
		end
	end
	
	function LogisticCommander:infoPilot(groupname)
		local gr = Group.getByName(groupname)
		if gr then
			local un = gr:getUnit(1)
			
			local maxdist = 300000
			local targetpilot = nil
			for i,v in ipairs(self.ejectedPilots) do
				local dist = mist.utils.get3DDist(un:getPoint(),v:getPoint())
				if dist<maxdist then
					maxdist = dist
					targetpilot = v
				end
			end
			
			if targetpilot then
				self:printPilotInfo(targetpilot, gr:getID(), un, 60)
			else
				trigger.action.outTextForGroup(gr:getID(), 'No ejected pilots nearby', 15)
			end
		end
	end
	
	function LogisticCommander:printPilotInfo(pilotObj, groupid, referenceUnit, duration)
		local pnt = pilotObj:getPoint()
		local toprint = 'Pilot in need of extraction:'
		
		local lat,lon,alt = coord.LOtoLL(pnt)
		local mgrs = coord.LLtoMGRS(coord.LOtoLL(pnt))
		toprint = toprint..'\nDDM:  '.. mist.tostringLL(lat,lon,3)
		toprint = toprint..'\nDMS:  '.. mist.tostringLL(lat,lon,2,true)
		toprint = toprint..'\nMGRS: '.. mist.tostringMGRS(mgrs, 5)
		toprint = toprint..'\n\nAlt: '..math.floor(alt)..'m'..' | '..math.floor(alt*3.280839895)..'ft'
		
		if referenceUnit then
			local dist = mist.utils.get3DDist(referenceUnit:getPoint(),pilotObj:getPoint())
			local dstkm = string.format('%.2f',dist/1000)
			local dstnm = string.format('%.2f',dist/1852)
			toprint = toprint..'\n\nDist: '..dstkm..'km'..' | '..dstnm..'nm'
			
			local brg =  Utils.getBearing(referenceUnit:getPoint(), pnt)
			toprint = toprint..'\nBearing: '..math.floor(brg)
		end
		
		trigger.action.outTextForGroup(groupid, toprint, duration)
	end
	
	function LogisticCommander:update()
		local tocleanup = {}
		for i,v in ipairs(self.ejectedPilots) do
			if v:isExist() then
				local epside = v:getCoalition()
				for i2,v2 in ipairs(self.battleCommander.zones) do
					if v2.active and v2.side~= 0 then
						if Utils.isInZone(v, v2.zone) then
							table.insert(tocleanup, i)
							break
						end
					end
				end
			end
		end
		
		for i,v in ipairs(tocleanup) do
			self.ejectedPilots[v]:destroy()
			table.remove(self.ejectedPilots, v)
		end
	end
	
	function LogisticCommander:init()
		local ev = {}
		ev.context = self
		function ev:onEvent(event)
			if event.id == 15 and event.initiator and event.initiator.getPlayerName then
				local player = event.initiator:getPlayerName()
				if player then
					local unitType = event.initiator:getDesc()['typeName']
					local groupid = event.initiator:getGroup():getID()
					local groupname = event.initiator:getGroup():getName()
					
					if self.context.allowedTypes[unitType] then
						self.context.carriedPilots[groupid] = 0
						
						if not self.context.groupMenus[groupid] then
							local size = event.initiator:getGroup():getSize()
							if size > 1 then
								trigger.action.outText('WARNING: group '..groupname..' has '..size..' units. Logistics will only function for group leader', 10)
							end
							
							local cargomenu = missionCommands.addSubMenuForGroup(groupid, 'Logistics')
							missionCommands.addCommandForGroup(groupid, 'Load supplies', cargomenu, self.context.loadSupplies, self.context, groupname)
							missionCommands.addCommandForGroup(groupid, 'Unload supplies', cargomenu, self.context.unloadSupplies, self.context, groupname)
							missionCommands.addCommandForGroup(groupid, 'List supply zones', cargomenu, self.context.listSupplyZones, self.context, groupname)
							
							local csar = missionCommands.addSubMenuForGroup(groupid, 'CSAR', cargomenu)
							missionCommands.addCommandForGroup(groupid, 'Pick up pilot', csar, self.context.loadPilot, self.context, groupname)
							missionCommands.addCommandForGroup(groupid, 'Drop off pilot', csar, self.context.unloadPilot, self.context, groupname)
							missionCommands.addCommandForGroup(groupid, 'Info on closest pilot', csar, self.context.infoPilot, self.context, groupname)
							missionCommands.addCommandForGroup(groupid, 'Deploy smoke at closest pilot', csar, self.context.markPilot, self.context, groupname)
							missionCommands.addCommandForGroup(groupid, 'Deploy flare at closest pilot', csar, self.context.flarePilot, self.context, groupname)
							
							local main = missionCommands.addSubMenuForGroup(groupid, 'Mark Zone', cargomenu)
							local sub1
							for i,v in ipairs(self.context.battleCommander.zones) do
								if i<10 then
									missionCommands.addCommandForGroup(groupid, v.zone, main, v.markWithSmoke, v, event.initiator:getCoalition())
								elseif i==10 then
									sub1 = missionCommands.addSubMenuForGroup(groupid, "More", main)
									missionCommands.addCommandForGroup(groupid, v.zone, sub1, v.markWithSmoke, v, event.initiator:getCoalition())
								elseif i%9==1 then
									sub1 = missionCommands.addSubMenuForGroup(groupid, "More", sub1)
									missionCommands.addCommandForGroup(groupid, v.zone, sub1, v.markWithSmoke, v, event.initiator:getCoalition())
								else
									missionCommands.addCommandForGroup(groupid, v.zone, sub1, v.markWithSmoke, v, event.initiator:getCoalition())
								end
							end
							
							self.context.groupMenus[groupid] = cargomenu
						end
						
						if self.context.carriedCargo[groupid] then
							self.context.carriedCargo[groupid] = nil
						end
					end
				end
			end
			
			if event.id == world.event.S_EVENT_LANDING_AFTER_EJECTION then
				table.insert(self.context.ejectedPilots, event.initiator)
				
				for i,v in pairs(self.context.groupMenus) do
					self.context:printPilotInfo(event.initiator, i, nil, 15)
				end
			end
		end
		
		world.addEventHandler(ev)
		
		mist.scheduleFunction(self.update, {self}, timer.getTime() + 10, 10)
	end
end

HercCargoDropSupply = {}
do
	HercCargoDropSupply.allowedCargo = {}
	HercCargoDropSupply.allowedCargo['weapons.bombs.Generic Crate [20000lb]'] = true
	HercCargoDropSupply.herculesRegistry = {} -- {takeoffzone = string, lastlanded = time}

	HercCargoDropSupply.battleCommander = nil
	function HercCargoDropSupply.init(bc)
		HercCargoDropSupply.battleCommander = bc
		
		cargodropev = {}
		function cargodropev:onEvent(event)
			if event.id == world.event.S_EVENT_SHOT then
				local name = event.weapon:getDesc().typeName
				if HercCargoDropSupply.allowedCargo[name] then
					local alt = Utils.getAGL(event.weapon)
					if alt < 5 then
						HercCargoDropSupply.ProcessCargo(event)
					else
						timer.scheduleFunction(HercCargoDropSupply.CheckCargo, event, timer.getTime() + 0.1)
					end
				end
			end
			
			if event.id == world.event.S_EVENT_TAKEOFF then
				if event.initiator and event.initiator:getDesc().typeName == 'Hercules' then
					local herc = HercCargoDropSupply.herculesRegistry[event.initiator:getName()]
					
					local zn = HercCargoDropSupply.battleCommander:getZoneOfUnit(event.initiator:getName())
					if zn then
						if not herc then
							HercCargoDropSupply.herculesRegistry[event.initiator:getName()] = {takeoffzone = zn.zone}
						elseif not herc.lastlanded or (herc.lastlanded+30)<timer.getTime() then
							HercCargoDropSupply.herculesRegistry[event.initiator:getName()].takeoffzone = zn.zone
						end
						
					end
				end
			end
			
			if event.id == world.event.S_EVENT_LAND then
				if event.initiator and event.initiator:getDesc().typeName == 'Hercules' then
					local herc = HercCargoDropSupply.herculesRegistry[event.initiator:getName()]
					
					if not herc then
						HercCargoDropSupply.herculesRegistry[event.initiator:getName()] = {}
					end
					
					HercCargoDropSupply.herculesRegistry[event.initiator:getName()].lastlanded = timer.getTime()
				end
			end
		end
		
		world.addEventHandler(cargodropev)
	end

	function HercCargoDropSupply.ProcessCargo(shotevent)
		local cargo = shotevent.weapon
		local zn = HercCargoDropSupply.battleCommander:getZoneOfWeapon(cargo)
		if zn and zn.active and shotevent.initiator and shotevent.initiator:isExist() then
			local herc = HercCargoDropSupply.herculesRegistry[shotevent.initiator:getName()]
			if not herc or herc.takeoffzone == zn.zone then
				cargo:destroy()
				return
			end
			
			local cargoSide = cargo:getCoalition()
			if zn.side == 0 then
				if HercCargoDropSupply.battleCommander.playerRewardsOn then
					HercCargoDropSupply.battleCommander:addFunds(cargoSide, HercCargoDropSupply.battleCommander.rewards.crate)
					trigger.action.outTextForCoalition(cargoSide,'Capture +'..HercCargoDropSupply.battleCommander.rewards.crate..' credits',5)
				end
				
				zn:capture(cargoSide)
			elseif zn.side == cargoSide then
				if HercCargoDropSupply.battleCommander.playerRewardsOn then
					if zn:canRecieveSupply() then
						HercCargoDropSupply.battleCommander:addFunds(cargoSide, HercCargoDropSupply.battleCommander.rewards.crate)
						trigger.action.outTextForCoalition(cargoSide,'Resupply +'..HercCargoDropSupply.battleCommander.rewards.crate..' credits',5)
					else
						local reward = HercCargoDropSupply.battleCommander.rewards.crate * 0.25
						HercCargoDropSupply.battleCommander:addFunds(cargoSide, reward)
						trigger.action.outTextForCoalition(cargoSide,'Resupply +'..reward..' credits (-75% due to no demand)',5)
					end
				end
				
				zn:upgrade()
			end
			
			cargo:destroy()
		end
	end
	
	function HercCargoDropSupply.CheckCargo(shotevent, time)
		local cargo = shotevent.weapon
		if not cargo:isExist() then
			return nil
		end
		
		local alt = Utils.getAGL(cargo)
		if alt < 5 then
			HercCargoDropSupply.ProcessCargo(shotevent)
			return nil
		end
		return time+0.1
	end
end

MissionCommander = {}
do
	--{side = int, battleCommander = bc, checkFrequency = int}
	function MissionCommander:new(obj)
		obj = obj or {}
		obj.missions = {}
		
		if obj.checkFrequency then
			obj.checkFrequency = 30
		end
		
		setmetatable(obj, self)
		self.__index = self
		return obj
	end
	
	--[[
		{ 
			messageStart="string, function", 
			messageEnd="string, function", 
			title="string, function", 
			description="string, function", 
			isActive = function,
			startAction = function,
			endAction = function,
			reward=int
		}
	--]]
	function MissionCommander:trackMission(params)
		params.isRunning = false
		table.insert(self.missions, params)
	end
	
	function MissionCommander:printMissions()
		local output = 'Active missions'
		output = output..'\n------------------------------------------------'
		for _,v in ipairs(self.missions) do
			if v.isRunning then
				output = output..'\n['..self:decodeMessage(v.title)..']'
				output = output..'\n'..self:decodeMessage(v.description)
				output = output..'\n------------------------------------------------'
			end
		end
		
		trigger.action.outTextForCoalition(self.side, output, 30)
	end
	
	function MissionCommander:checkMissions(time)
		for _,v in ipairs(self.missions) do
			if v.isRunning then
				if not v:isActive() then
					if v.messageEnd then trigger.action.outTextForCoalition(self.side, self:decodeMessage(v.messageEnd), 30) end
					if v.reward then self.battleCommander:addFunds(self.side, v.reward) end
					if v.endAction then v.endAction() end
					v.isRunning = false
					return time+2 --to prevent all ended missions to show at once
				end
			else
				if v:isActive() then
					if v.messageStart then trigger.action.outTextForCoalition(self.side, self:decodeMessage(v.messageStart), 30) end
					if v.startAction then v.startAction() end
					v.isRunning = true
					return time+2 --to prevent all new missions starting all at once
				end
			end
		end
		
		return time + self.checkFrequency
	end
	
	function MissionCommander:init()
		missionCommands.addCommandForCoalition(self.side, 'Missions', nil, self.printMissions, self)
		timer.scheduleFunction(self.checkMissions, self, timer.getTime() + 15)
	end
	
	function MissionCommander:decodeMessage(param)
		if type(param) == "function" then
			return param()
		elseif type(param) == "string" then
			return param
		end
	end
end