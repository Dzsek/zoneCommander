function merge(tbls)
	local res = {}
	for i,v in ipairs(tbls) do
		for i2,v2 in ipairs(v) do
			table.insert(res,v2)
		end
	end
	
	return res
end

function allExcept(tbls, except)
	local tomerge = {}
	for i,v in pairs(tbls) do
		if i~=except then
			table.insert(tomerge, v)
		end
	end
	return merge(tomerge)
end


airfield = {
	blue = { "bInfantry", "bArmor", "bSam", "bSam2", "bSam3"},
	red = {"rInfantry", "rArmor", "rSam", "rSam2", "rSam3" }
}

farp = {
	blue = {"bInfantry", "bArmor", "bSam"},
	red = {"rInfantry", "rArmor", "rSam" }
}

special = {
	blue = {"bInfantry", "bArmor", "bSamIR"},
	red = {"rInfantry", "rArmor", "rSamIR" }
}

specialSAM = {
	blue = {"bInfantry", "bSamIR","bInfantry", "bInfantry", "bSamBig" },
	red = {"rInfantry", "rSamIR", "rInfantry", "rInfantry", "rSamBig" }
}

specialKrasnodar = {
	blue = {"bInfantry", "bSamIR","bSam2", "bSam3", "bSamBig", "bSamFinal" },
	red = {"rInfantry", "rSamIR", "rSam2", "rSam3", "rSamBig", "rSamFinal" }
}

convoy = {
	blue = {"bInfantry", "bInfantry", "bArmor"},
	red = {"rInfantry", "rInfantry", "rArmor"}
}

cargoSpawns = {
	["Anapa"] = {"c1","c2","c3"},
	["Bravo"] = {"c6","c7"},
	["Krymsk"] = {"c8","c9","c10"},
	["Factory"] = {"c4","c5","c11"},
	["Echo"] = {"c12","c13"}
}

farpSupply = {
	["Bravo"] = {"bravoFuelAndAmmo"},
	["Echo"] = {"echoFuelAndAmmo"}
}

cargoAccepts = {
	anapa = allExcept(cargoSpawns, 'Anapa'),
	bravo =  allExcept(cargoSpawns, 'Bravo'),
	krymsk =  allExcept(cargoSpawns, 'Krymsk'),
	factory =  allExcept(cargoSpawns, 'Factory'),
	echo =  allExcept(cargoSpawns, 'Echo'),
	general = allExcept(cargoSpawns)
}

flavor = {
	anapa = 'Home base',
	alpha='Defensive position next to the town of Natuhaevskaya',
	bravo='FARP next to the town of Damanka.\nWill let us launch helicopter attacks from a bit closer to the action.',
	charlie='Defensive position next to an old TV tower.\nWill provide allied air patrol to help capture Bravo',
	convoy='Supply convoy detained north of Bravo.\nKeep damage to the trucks to a minimum while liberating this area.\nWe could really use the supplies.',
	krymsk='Airbase next to the city of Krymsk.\nCapturing it will provide us with valuable aircraft to use for our cause.',
	radio='Radio atenna on the outskirts of Krymsk.\nIf we capture it, we can launch AWACS from the nearby airport\nto get some much needed intel on the enemy.',
	oilfields='Oil extraction and Refinery north of Krymsk.\nCapture it to get a steady stream of income, or just destroy it to put a hole in the enemy wallet.',
	delta='Defensive position out in the middle of nowhere',
	factory='Weapon factory next to the town of Homskiy.\nWe can use it to resupply nearby bases.\nIt will also provide a steady stream of income.',
	samsite='Home to an old SA-2 site.\nIf we capture it, we might be able to get some use out of it.',
	foxtrot='Defensive position with a nice view of a lake',
	echo='FARP next to the city of Krasnodar.\nCapturing it will let us operate our helicopters in the area.',
	krasnodar='Airbase next to the city of Krasnodar.\nThe home base of our enemy. Capture it to deprive them of their most valuable asset.'
}

bc = BattleCommander:new()
anapa = ZoneCommander:new({zone='Anapa', side=2, level=5, upgrades=airfield, crates=cargoAccepts.anapa, flavorText=flavor.anapa})
alpha = ZoneCommander:new({zone='Alpha', side=0, level=0, upgrades=farp, crates=cargoAccepts.general, flavorText=flavor.alpha})
bravo = ZoneCommander:new({zone='Bravo', side=1, level=3, upgrades=farp, crates=cargoAccepts.bravo, flavorText=flavor.bravo})
charlie = ZoneCommander:new({zone='Charlie', side=0, level=0, upgrades=farp, crates=cargoAccepts.general, flavorText=flavor.charlie})
convoy = ZoneCommander:new({zone='Convoy', side=1, level=3, upgrades=convoy, crates=cargoAccepts.general, flavorText=flavor.convoy})
krymsk = ZoneCommander:new({zone='Krymsk', side=1, level=5, upgrades=airfield, crates=cargoAccepts.krymsk, flavorText=flavor.krymsk})
oilfields = ZoneCommander:new({zone='Oil Fields', side=1, level=3, upgrades=farp, crates=cargoAccepts.general, flavorText=flavor.oilfields, income=2})
radio = ZoneCommander:new({zone='Radio Tower', side=1, level=1, upgrades=special, crates=cargoAccepts.general, flavorText=flavor.radio})
delta = ZoneCommander:new({zone='Delta', side=1, level=1, upgrades=farp, crates=cargoAccepts.general, flavorText=flavor.delta})
factory = ZoneCommander:new({zone='Factory', side=1, level=1, upgrades=special, crates=cargoAccepts.factory, flavorText=flavor.factory, income=2})
samsite = ZoneCommander:new({zone='SAM Site', side=0, level=0, upgrades=specialSAM, crates=cargoAccepts.general, flavorText=flavor.samsite})
foxtrot = ZoneCommander:new({zone='Foxtrot', side=1, level=3, upgrades=farp, crates=cargoAccepts.general, flavorText=flavor.foxtrot})
echo = ZoneCommander:new({zone='Echo', side=1, level=3, upgrades=farp, crates=cargoAccepts.echo, flavorText=flavor.echo})
krasnodar = ZoneCommander:new({zone='Krasnodar', side=1, level=6, upgrades=specialKrasnodar, crates=cargoAccepts.general, flavorText=flavor.krasnodar})

radio:addCriticalObject('RadioTower')
samsite:addCriticalObject('CommandCenter')
factory:addCriticalObject('FactoryBuilding1')
factory:addCriticalObject('FactoryBuilding2')
convoy:addCriticalObject('convoy1')
convoy:addCriticalObject('convoy2')
convoy:addCriticalObject('convoy3')
convoy:addCriticalObject('convoy4')

local oilbuildings = {'derrick1','derrick2','derrick3','pump1','pump2','pump3','pump4','pump5','pump6','pump7','pump8','tank1','tank2','tank3','tank4','oilref1','oilref2'}
for i,v in ipairs(oilbuildings) do
	oilfields:addCriticalObject(v)
end

dispatch = {
	krymsk = {
		GroupCommander:new({name='krym1', mission='supply', targetzone='Bravo'}),
		GroupCommander:new({name='krym2', mission='attack', targetzone='Bravo'}),
		GroupCommander:new({name='krym3', mission='patrol', targetzone='Bravo'}),
		GroupCommander:new({name='krym4', mission='patrol', targetzone='Krymsk'}),
		GroupCommander:new({name='krym5', mission='supply', targetzone='Radio Tower'}),
		GroupCommander:new({name='krym6', mission='attack', targetzone='Radio Tower'}),
		GroupCommander:new({name='krym7', mission='patrol', targetzone='Radio Tower'}),
		GroupCommander:new({name='krym8', mission='patrol', targetzone='Bravo'}),
		GroupCommander:new({name='krym9', mission='patrol', targetzone='Krymsk'}),
		GroupCommander:new({name='krym10', mission='supply', targetzone='Bravo'}),
		GroupCommander:new({name='krym11', mission='supply', targetzone='Radio Tower'}),
		GroupCommander:new({name='krym12', mission='supply', targetzone='Delta'}),
		GroupCommander:new({name='krym13', mission='attack', targetzone='Delta'}),
		GroupCommander:new({name='krym14', mission='supply', targetzone='Factory'}),
		GroupCommander:new({name='krym15', mission='attack', targetzone='Factory'}),
		GroupCommander:new({name='krym16', mission='supply', targetzone='Delta'}),
		GroupCommander:new({name='krym17', mission='supply', targetzone='Factory'}),
		GroupCommander:new({name='krym18', mission='supply', targetzone='SAM Site'}),
		GroupCommander:new({name='krym19', mission='supply', targetzone='SAM Site'}),
		GroupCommander:new({name='krym20', mission='attack', targetzone='SAM Site'}),
		GroupCommander:new({name='krym21', mission='patrol', targetzone='Delta'}),
		GroupCommander:new({name='krym22', mission='supply', targetzone='Oil Fields'}),
		GroupCommander:new({name='krym23', mission='supply', targetzone='Oil Fields'}),
		GroupCommander:new({name='krym24', mission='attack', targetzone='Oil Fields'})
	},
	bravo = {
		GroupCommander:new({name='bravo1', mission='supply', targetzone='Alpha'}),
		GroupCommander:new({name='bravo2', mission='attack', targetzone='Alpha'}),
		GroupCommander:new({name='bravo6', mission='supply', targetzone='Charlie'}),
		GroupCommander:new({name='bravo7', mission='attack', targetzone='Charlie'}),
		GroupCommander:new({name='bravo4', mission='supply', targetzone='Krymsk'}),
		GroupCommander:new({name='bravo5', mission='attack', targetzone='Krymsk'}),
		GroupCommander:new({name='bravo8', mission='supply', targetzone='Krymsk'}),
		GroupCommander:new({name='bravo10', mission='supply', targetzone='Charlie'}),
		GroupCommander:new({name='bravo9', mission='supply', targetzone='Alpha'}),
		GroupCommander:new({name='bravo11', mission='supply', targetzone='Oil Fields'}),
		GroupCommander:new({name='bravo12', mission='supply', targetzone='Oil Fields'}),
		GroupCommander:new({name='bravo13', mission='attack', targetzone='Oil Fields'})
	},
	anapa = {
		GroupCommander:new({name='anapa1', mission='supply', targetzone='Alpha'}),
		GroupCommander:new({name='anapa3', mission='supply', targetzone='Bravo'}),
		GroupCommander:new({name='anapa2', mission='supply', targetzone='Charlie'}),
		GroupCommander:new({name='anapa5', mission='patrol', targetzone='Bravo'})
	},
	charlie={
		GroupCommander:new({name='anapa6', mission='attack', targetzone='Bravo'})
	},
	factory={
		GroupCommander:new({name='factory1', mission='supply', targetzone='Krymsk'}),
		GroupCommander:new({name='factory2', mission='supply', targetzone='Krymsk'}),
		GroupCommander:new({name='factory3', mission='supply', targetzone='Delta'}),
		GroupCommander:new({name='factory4', mission='supply', targetzone='Delta'}),
		GroupCommander:new({name='factory5', mission='supply', targetzone='Foxtrot'}),
		GroupCommander:new({name='factory6', mission='supply', targetzone='Foxtrot'}),
		GroupCommander:new({name='factory7', mission='supply', targetzone='Echo'}),
		GroupCommander:new({name='factory8', mission='supply', targetzone='Echo'})
	},
	echo={
		GroupCommander:new({name='echo1', mission='supply', targetzone='SAM Site'}),
		GroupCommander:new({name='echo2', mission='supply', targetzone='SAM Site'}),
		GroupCommander:new({name='echo3', mission='attack', targetzone='Delta'}),
		GroupCommander:new({name='echo4', mission='supply', targetzone='Delta'}),
		GroupCommander:new({name='echo5', mission='supply', targetzone='Delta'}),
		GroupCommander:new({name='echo6', mission='supply', targetzone='Factory'}),
		GroupCommander:new({name='echo7', mission='supply', targetzone='Factory'}),
		GroupCommander:new({name='echo8', mission='attack', targetzone='Factory'}),
		GroupCommander:new({name='echo9', mission='supply', targetzone='Foxtrot'}),
		GroupCommander:new({name='echo10', mission='supply', targetzone='Foxtrot'}),
		GroupCommander:new({name='echo11', mission='attack', targetzone='Foxtrot'}),
		GroupCommander:new({name='echo12', mission='supply', targetzone='Krasnodar'}),
		GroupCommander:new({name='echo13', mission='supply', targetzone='Krasnodar'}),
		GroupCommander:new({name='echo14', mission='supply', targetzone='Krasnodar'})
	},
	krasnodar={
		GroupCommander:new({name='kras1', mission='supply', targetzone='Echo'}),
		GroupCommander:new({name='kras2', mission='supply', targetzone='Echo'}),
		GroupCommander:new({name='kras3', mission='supply', targetzone='Foxtrot'}),
		GroupCommander:new({name='kras4', mission='supply', targetzone='Foxtrot'}),
		GroupCommander:new({name='kras5', mission='attack', targetzone='SAM Site'}),
		GroupCommander:new({name='kras6', mission='attack', targetzone='Krymsk'}),
		GroupCommander:new({name='kras7', mission='attack', targetzone='Radio Tower'}),
		GroupCommander:new({name='kras8', mission='attack', targetzone='Factory'}),
		GroupCommander:new({name='kras9', mission='attack', targetzone='Echo'}),
		GroupCommander:new({name='kras10', mission='attack', targetzone='Foxtrot'}),
		GroupCommander:new({name='kras11', mission='patrol', targetzone='Echo'}),
		GroupCommander:new({name='kras12', mission='patrol', targetzone='Delta'}),
		GroupCommander:new({name='kras13', mission='patrol', targetzone='Factory'})
	}
}


anapa:addGroups(dispatch.anapa)
bravo:addGroups(dispatch.bravo)
krymsk:addGroups(dispatch.krymsk)
charlie:addGroups(dispatch.charlie)
factory:addGroups(dispatch.factory)
echo:addGroups(dispatch.echo)
krasnodar:addGroups(dispatch.krasnodar)

bc:addZone(anapa)
bc:addZone(alpha)
bc:addZone(bravo)
bc:addZone(charlie)
bc:addZone(convoy)
bc:addZone(krymsk)
bc:addZone(oilfields)
bc:addZone(radio)
bc:addZone(delta)
bc:addZone(factory)
bc:addZone(samsite)
bc:addZone(foxtrot)
bc:addZone(echo)
bc:addZone(krasnodar)

bc:addConnection("Anapa","Alpha")
bc:addConnection("Alpha","Bravo")
bc:addConnection("Bravo","Krymsk")
bc:addConnection("Bravo","Charlie")
bc:addConnection("Bravo","Convoy")
bc:addConnection("Anapa","Charlie")
bc:addConnection("Bravo","Oil Fields")
bc:addConnection("Krymsk","Oil Fields")
bc:addConnection("Krymsk","Radio Tower")
bc:addConnection("Krymsk","Factory")
bc:addConnection("Krymsk","Delta")
bc:addConnection("Factory","Delta")
bc:addConnection("Factory","Foxtrot")
bc:addConnection("Factory","Echo")
bc:addConnection("Delta","Echo")
bc:addConnection("Foxtrot","Krasnodar")
bc:addConnection("Echo","Krasnodar")
bc:addConnection("Echo","SAM Site")
bc:addConnection("Krymsk","SAM Site")


convoy:registerTrigger('lost', function (event, sender)
	local convoyItems = {'convoy1','convoy2','convoy3', 'convoy4'}
	
	local message = "Convoy liberated"
	local totalLost = 0
	for i,v in ipairs(convoyItems) do
		if not StaticObject.getByName(v) then
			totalLost = totalLost+1
		end
	end
	
	if totalLost>0 then
		local percentLost = math.ceil((totalLost/#convoyItems)*100)
		percentLost = math.min(percentLost,100)
		percentLost = math.max(percentLost,1)
		message = message..' but we lost '..percentLost..' of the trucks.'
	else
		message = message..'. We recovered all of the supplies.'
	end
	
	local creditsEarned = (#convoyItems - totalLost) * 250
	message = message..'\n\n+'..creditsEarned..' credits'
	
	bc:addFunds(2, creditsEarned)
	
	trigger.action.outTextForCoalition(2, message, 15)
end, 'convoyLost', 1)

bc:addFunds(1,0)
bc:addFunds(2,0)

Group.getByName('sead1'):destroy()
bc:registerShopItem('sead1', 'F/A-18C SEAD mission', 400, function(sender) 
	local gr = Group.getByName('sead1')
	if gr and gr:getSize()>0 and gr:getController():hasTask() then 
		return 'SEAD mission still in progress'
	end
	mist.respawnGroup('sead1', true)
end)

Group.getByName('sweep1'):destroy()
bc:registerShopItem('sweep1', 'F-14B Fighter Sweep', 250, function(sender) 
	local gr = Group.getByName('sweep1')
	if gr and gr:getSize()>0 and gr:getController():hasTask() then 
		return 'Fighter sweep mission still in progress'
	end
	mist.respawnGroup('sweep1', true)
end)

Group.getByName('cas1'):destroy()
bc:registerShopItem('cas1', 'F-4 Ground Attack', 300, function(sender) 
	local gr = Group.getByName('cas1')
	if gr and gr:getSize()>0 and gr:getController():hasTask() then 
		return 'Ground attack mission still in progress'
	end
	mist.respawnGroup('cas1', true)
end)

bc:addMonitoredROE('cruise1')
local cruiseMissileTargetMenu = nil

bc:registerShopItem('cruiseAttack', 'Cruise Missile Strike', 1500, function(sender)
	if cruiseMissileTargetMenu then
		return 'Choose target zone from F10 menu'
	end
	
	local launchAttack = function(target)
		if cruiseMissileTargetMenu then
			local err = bc:fireAtZone(target, 'cruise1', true, 6)
			if err then
				return err
			end
			
			missionCommands.removeItemForCoalition(2, cruiseMissileTargetMenu)
			cruiseMissileTargetMenu = nil
			trigger.action.outTextForCoalition(2, 'Launching cruise missiles at '..target, 15)
		end
	end
	
	cruiseMissileTargetMenu = missionCommands.addSubMenuForCoalition(2, 'Cruise Missile Target')
	local sub1
	local zones = bc:getZones()
	local count = 0
	for i,v in ipairs(zones) do
		if v.side == 1 then
			count = count + 1
			if count<10 then
				missionCommands.addCommandForCoalition(2, v.zone, cruiseMissileTargetMenu, launchAttack, v.zone)
			elseif count==10 then
				sub1 = missionCommands.addSubMenu("More", cruiseMissileTargetMenu)
				missionCommands.addCommandForCoalition(2, v.zone, sub1, launchAttack, v.zone)
			else
				missionCommands.addCommandForCoalition(2, v.zone, sub1, launchAttack, v.zone)
			end
		end
	end
	
	trigger.action.outTextForCoalition(2, 'Cruise missiles ready. Choose target zone from F10 menu', 15)
end)



bc:addShopItem(2, 'sead1', -1)
bc:addShopItem(2, 'sweep1', -1)
bc:addShopItem(2, 'cas1', -1)
bc:addShopItem(2, 'cruiseAttack', -1)

--red support
Group.getByName('redcas1'):destroy()
bc:registerShopItem('redcas1', 'Red Cas', 300, function(sender) 
	local gr = Group.getByName('redcas1')
	if gr and gr:getSize()>0 and gr:getController():hasTask() then 
		return 'still alive'
	end
	mist.respawnGroup('redcas1', true)
	trigger.action.outTextForCoalition(2,'The enemy has deployed a couple of Su-34 against our ground forces',15)
end)

Group.getByName('redcap1'):destroy()
bc:registerShopItem('redcap1', 'Red Cap', 300, function(sender) 
	local gr = Group.getByName('redcap1')
	if gr and gr:getSize()>0 and gr:getController():hasTask() then 
		return 'still alive'
	end
	mist.respawnGroup('redcap1', true)
	trigger.action.outTextForCoalition(2,'Enemy MiG-31 interceptors, coming in from the South-East',15)
end)

Group.getByName('redsead1'):destroy()
bc:registerShopItem('redsead1', 'Red Sead', 300, function(sender) 
	local gr = Group.getByName('redsead1')
	if gr and gr:getSize()>0 and gr:getController():hasTask() then 
		return 'still alive'
	end
	mist.respawnGroup('redsead1', true)
	trigger.action.outTextForCoalition(2,'The enemy has launched an attack from the North-East on our air defenses',15)
end)

Group.getByName('redmlrs1'):destroy()
bc:registerShopItem('redmlrs1', 'spawn Red mlrs', 500, function(sender) 
	local zn = bc:getZoneByName('Foxtrot')
	if zn.side == 1 and zn.active then
		if Group.getByName('redmlrs1') then
			trigger.action.outTextForCoalition(2,'The enemy has resupplied its artillery near Foxtrot',15)
		else
			trigger.action.outTextForCoalition(2,'The enemy has deployed artillery near Foxtrot',15)
		end
		
		mist.respawnGroup('redmlrs1')
		bc:removeShopItem(1,'redmlrs1fire')
		bc:addShopItem(1, 'redmlrs1fire', 3)
	else
		return 'zone not red'
	end
end)

bc:registerShopItem('redmlrs1fire', 'fire red mlrs', 300, function(sender) 
	local gr = Group.getByName('redmlrs1')
	if gr then
		local targetzones = {'Echo', 'Delta', 'SAM Site', 'Factory', 'Radio Tower', 'Krymsk'}
		local viabletargets = {}
		for i,v in ipairs(targetzones) do
			local z = bc:getZoneByName(v)
			
			if z and z.side == 2 then
				table.insert(viabletargets, v)
			end
		end

		if #viabletargets==0 then
			return 'no targets'
		end
		
		local targetzn = viabletargets[math.random(1,#viabletargets)]
		
		local err = bc:fireAtZone(targetzn, 'redmlrs1', true, 3, 6)
		
		if not err then
			trigger.action.outTextForCoalition(2,'Enemy artillery near Foxtrot has begun preparations to fire on '..targetzn,15)
		else
			return err
		end
	else
		return 'buy first'
	end
end)

bc:addShopItem(1, 'redcas1', -1)
bc:addShopItem(1, 'redcap1', -1)
bc:addShopItem(1, 'redsead1', -1)
bc:addShopItem(1, 'redmlrs1', -1)

bugetAI = BugetCommander:new({ battleCommander = bc, side=1, decissionFrequency=30*60, decissionVariance=10*60, skipChance = 15})
bugetAI:init()
--end red support



bc:loadFromDisk() --will load and overwrite default zone levels, sides, funds and available shop items
bc:init()
bc:startRewardPlayerContribution(15,{infantry = 5, ground = 15, sam = 30, airplane = 30, ship = 200, helicopter=40})

function respawnStatics()
	for i,v in pairs(cargoSpawns) do
		local farp = bc:getZoneByName(i)
		if farp then
			if farp.side==2 then
				for ix,vx in ipairs(v) do
					if not StaticObject.getByName(vx) then
						mist.respawnGroup(vx)
					end
				end
			else
				for ix,vx in ipairs(v) do
					local cr = StaticObject.getByName(vx)
					if cr then
						cr:destroy()
					end
				end
			end
		end
	end
	
	for i,v in pairs(farpSupply) do
		local farp = bc:getZoneByName(i)
		if farp then
			if farp.side==2 then
				for ix,vx in ipairs(v) do
					local gr = Group.getByName(vx)
					if not gr then
						mist.respawnGroup(vx)
					elseif gr:getSize() < gr:getInitialSize() then
						mist.respawnGroup(vx)
					end
				end
			else
				for ix,vx in ipairs(v) do
					local cr = Group.getByName(vx)
					if cr then
						cr:destroy()
					end
				end
			end
		end
	end
end

mist.scheduleFunction(respawnStatics, {}, timer.getTime() + 1, 30)