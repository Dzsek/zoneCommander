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

cargoSpawns = {
	["Anapa"] = {"c1","c2","c3"},
	["Bravo"] = {"c6","c7"},
	["Krymsk"] = {"c8","c9","c10"},
	["Echo"] = {"c11","c12"}
}

cargoAccepts = {
	anapa = allExcept(cargoSpawns, 'Anapa'),
	bravo =  allExcept(cargoSpawns, 'Bravo'),
	krymsk =  allExcept(cargoSpawns, 'Krymsk'),
	general = allExcept(cargoSpawns)
}

bc = BattleCommander:new()
anapa = ZoneCommander:new({zone='Anapa', side=2, level=5, upgrades=airfield, crates=cargoAccepts.anapa})
alpha = ZoneCommander:new({zone='Alpha', side=0, level=0, upgrades=farp, crates=cargoAccepts.general})
bravo = ZoneCommander:new({zone='Bravo', side=1, level=3, upgrades=farp, crates=cargoAccepts.bravo})
charlie = ZoneCommander:new({zone='Charlie', side=0, level=0, upgrades=farp, crates=cargoAccepts.general})
krymsk = ZoneCommander:new({zone='Krymsk', side=1, level=5, upgrades=airfield, crates=cargoAccepts.krymsk})
radio = ZoneCommander:new({zone='Radio Tower', side=0, level=0, upgrades=special, crates=cargoAccepts.general})

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
		GroupCommander:new({name='krym11', mission='supply', targetzone='Radio Tower'})
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
	}
}


anapa:addGroups(dispatch.anapa)
bravo:addGroups(dispatch.bravo)
krymsk:addGroups(dispatch.krymsk)

bc:addZone(anapa)
bc:addZone(alpha)
bc:addZone(bravo)
bc:addZone(charlie)
bc:addZone(krymsk)
bc:addZone(radio)

bc:addConnection("Anapa","Alpha")
bc:addConnection("Alpha","Bravo")
bc:addConnection("Bravo","Krymsk")
bc:addConnection("Bravo","Charlie")
bc:addConnection("Anapa","Charlie")
bc:addConnection("Krymsk","Radio Tower")
-- bc:addConnection("Krymsk","Factory")
-- bc:addConnection("Krymsk","Delta")
-- bc:addConnection("Delta","SAM Site")
-- bc:addConnection("SAM Site","Farm")
-- bc:addConnection("Factory","Delta")
-- bc:addConnection("Factory","Foxtrot")
-- bc:addConnection("Factory","Echo")
-- bc:addConnection("Delta","Echo")
-- bc:addConnection("Foxtrot","Krasnodar")
-- bc:addConnection("Echo","Krasnodar")
-- bc:addConnection("Krymsk","SAM Site")

bc:init()

function respawnCargo()
	for i,v in pairs(cargoSpawns) do
		local farp = bc:getZoneByName(i)
		if farp then
			if farp.side==2 then
				for ix,vx in ipairs(v) do
					if not StaticObject.getByName(vx) then
						mist.respawnGroup(vx)
					end
				end
			end
		end
	end
end

mist.scheduleFunction(respawnCargo, {}, timer.getTime() + 1, 30)