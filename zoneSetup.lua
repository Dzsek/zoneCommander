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

ensureExists = { 'bravoFarpAmmo', 'bravoFarpFuel' }

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

cargoSpawns = {
	["Anapa"] = {"c1","c2","c3"},
	["Bravo"] = {"c6","c7"},
	["Krymsk"] = {"c8","c9","c10"},
	["Factory"] = {"c4","c5","c11"}
}

cargoAccepts = {
	anapa = allExcept(cargoSpawns, 'Anapa'),
	bravo =  allExcept(cargoSpawns, 'Bravo'),
	krymsk =  allExcept(cargoSpawns, 'Krymsk'),
	factory =  allExcept(cargoSpawns, 'Factory'),
	general = allExcept(cargoSpawns)
}

bc = BattleCommander:new()
anapa = ZoneCommander:new({zone='Anapa', side=2, level=5, upgrades=airfield, crates=cargoAccepts.anapa})
alpha = ZoneCommander:new({zone='Alpha', side=0, level=0, upgrades=farp, crates=cargoAccepts.general})
bravo = ZoneCommander:new({zone='Bravo', side=1, level=3, upgrades=farp, crates=cargoAccepts.bravo})
charlie = ZoneCommander:new({zone='Charlie', side=0, level=0, upgrades=farp, crates=cargoAccepts.general})
krymsk = ZoneCommander:new({zone='Krymsk', side=1, level=5, upgrades=airfield, crates=cargoAccepts.krymsk})
radio = ZoneCommander:new({zone='Radio Tower', side=1, level=1, upgrades=special, crates=cargoAccepts.general})
delta = ZoneCommander:new({zone='Delta', side=1, level=1, upgrades=farp, crates=cargoAccepts.general})
factory = ZoneCommander:new({zone='Factory', side=1, level=1, upgrades=special, crates=cargoAccepts.factory})
samsite = ZoneCommander:new({zone='SAM Site', side=0, level=0, upgrades=specialSAM, crates=cargoAccepts.general})
foxtrot = ZoneCommander:new({zone='Foxtrot', side=1, level=3, upgrades=farp, crates=cargoAccepts.general})

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
		GroupCommander:new({name='anapa4', mission='supply', targetzone='Krymsk'}),
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
		GroupCommander:new({name='factory6', mission='supply', targetzone='Foxtrot'})
	}
}


anapa:addGroups(dispatch.anapa)
bravo:addGroups(dispatch.bravo)
krymsk:addGroups(dispatch.krymsk)
charlie:addGroups(dispatch.charlie)
factory:addGroups(dispatch.factory)

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

bc:addConnection("Anapa","Alpha")
bc:addConnection("Alpha","Bravo")
bc:addConnection("Bravo","Krymsk")
bc:addConnection("Bravo","Charlie")
bc:addConnection("Anapa","Charlie")
bc:addConnection("Krymsk","Radio Tower")
bc:addConnection("Krymsk","Factory")
bc:addConnection("Krymsk","Delta")
-- bc:addConnection("SAM Site","Farm")
bc:addConnection("Factory","Delta")
bc:addConnection("Factory","Foxtrot")
-- bc:addConnection("Factory","Echo")
-- bc:addConnection("Delta","Echo")
-- bc:addConnection("Foxtrot","Krasnodar")
-- bc:addConnection("Echo","Krasnodar")
bc:addConnection("Krymsk","SAM Site")

bc:loadFromDisk()
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
	
	for i,v in pairs(ensureExists) do
		if not StaticObject.getByName(v) then
			mist.respawnGroup(v)
		end
	end
end

mist.scheduleFunction(respawnStatics, {}, timer.getTime() + 1, 30)