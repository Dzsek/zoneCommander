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
	krymsk='Airbase next to the city of Krymsk.\nCapturing it will provide us with valuable aircraft to use for our cause.',
	radio='Radio atenna on the outskirts of Krymsk.\nIf we capture it, we can launch AWACS from the nearby airport\nto get some much needed intel on the enemy.',
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
krymsk = ZoneCommander:new({zone='Krymsk', side=1, level=5, upgrades=airfield, crates=cargoAccepts.krymsk, flavorText=flavor.krymsk})
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
		GroupCommander:new({name='krym21', mission='patrol', targetzone='Delta'})
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
		GroupCommander:new({name='bravo9', mission='supply', targetzone='Alpha'})
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
bc:addZone(krymsk)
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
bc:addConnection("Anapa","Charlie")
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


--alpha:registerTrigger('captured', function (event, sender) trigger.action.outText(sender.zone..' '..event,5) end)

bc:addFunds(1,0)
bc:addFunds(2,1000)

Group.getByName('sead1'):destroy()
bc:registerShopItem('sead1', 'F/A-18C SEAD mission', 200, function(sender) 
	local gr = Group.getByName('sead1')
	if gr and gr:getSize()>0 then 
		return 'SEAD mission still in progress'
	end
	mist.respawnGroup('sead1', true)
end)
bc:addShopItem(2, 'sead1', -1)

bc:loadFromDisk() --will load and overwrite default zone levels, sides, funds and available shop items
bc:init()

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