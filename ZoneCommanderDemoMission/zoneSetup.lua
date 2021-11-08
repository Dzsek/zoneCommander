function merge(tbls)
	local res = {}
	for i,v in ipairs(tbls) do
		for i2,v2 in ipairs(v) do
			table.insert(res,v2)
		end
	end
	
	return res
end

airfield = {
	blue = { "bInfantry", "bArmor", "bSam", "bSam2", "bSam3"},
	red = {"rInfantry", "rArmor", "rSam", "rSam2", "rSam3" }
}

farp = {
	blue = {"bInfantry", "bArmor", "bSam"},
	red = {"rInfantry", "rArmor", "rSam" }
}

cargoSpawns = {
	["Anapa"] = {"c1","c2","c3"},
	["Bravo"] = {"c6","c7"},
	["Krymsk"] = {"c8","c9","c10"}
}

cargoAccepts = {
	anapa = merge({cargoSpawns.Bravo}),
	alpha =  merge({cargoSpawns.Bravo,cargoSpawns.Anapa}),
	bravo =  merge({cargoSpawns.Anapa}),
	charlie =  merge({cargoSpawns.Anapa, cargoSpawns.Bravo}),
	krymsk =  merge({cargoSpawns.Bravo, cargoSpawns.Anapa})
}

bc = BattleCommander:new()
anapa = ZoneCommander:new({zone='Anapa', side=2, level=5, upgrades=airfield, crates=cargoAccepts.anapa})
alpha = ZoneCommander:new({zone='Alpha', side=0, level=0, upgrades=farp, crates=cargoAccepts.alpha})
bravo = ZoneCommander:new({zone='Bravo', side=1, level=3, upgrades=farp, crates=cargoAccepts.bravo})
charlie = ZoneCommander:new({zone='Charlie', side=0, level=0, upgrades=farp, crates=cargoAccepts.charlie})
krymsk = ZoneCommander:new({zone='Krymsk', side=1, level=5, upgrades=airfield, crates=cargoAccepts.krymsk})

bravo:addRestrictedPlayerGroup({name='Bravo KA50', side=2})
bravo:addRestrictedPlayerGroup({name='Bravo MI8', side=2})
bravo:addRestrictedPlayerGroup({name='Bravo Gazelle Gun', side=2})
bravo:addRestrictedPlayerGroup({name='Bravo Gazelle ATGM', side=2})
bravo:addRestrictedPlayerGroup({name='Bravo Gazelle AA', side=2})
bravo:addRestrictedPlayerGroup({name='Bravo MI24P', side=2})
bravo:addRestrictedPlayerGroup({name='Bravo Huey', side=2})

dispatch = {
	krymsk = {
		GroupCommander:new({name='krym1', mission='supply', targetzone='Bravo'}),
		GroupCommander:new({name='krym2', mission='attack', targetzone='Bravo'}),
		GroupCommander:new({name='krym3', mission='patrol', targetzone='Bravo'}),
		GroupCommander:new({name='krym4', mission='patrol', targetzone='Krymsk'})
	},
	bravo = {
		GroupCommander:new({name='bravo1', mission='supply', targetzone='Alpha'}),
		GroupCommander:new({name='bravo2', mission='attack', targetzone='Alpha'}),
		GroupCommander:new({name='bravo6', mission='supply', targetzone='Charlie'}),
		GroupCommander:new({name='bravo7', mission='attack', targetzone='Charlie'}),
		GroupCommander:new({name='bravo4', mission='supply', targetzone='Krymsk'}),
		GroupCommander:new({name='bravo5', mission='attack', targetzone='Krymsk'})
	},
	anapa = {
		GroupCommander:new({name='anapa1', mission='supply', targetzone='Alpha'}),
		GroupCommander:new({name='anapa3', mission='supply', targetzone='Bravo'}),
		GroupCommander:new({name='anapa2', mission='supply', targetzone='Charlie'}),
		GroupCommander:new({name='anapa4', mission='supply', targetzone='Krymsk'})
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

bc:addConnection("Anapa","Alpha")
bc:addConnection("Alpha","Bravo")
bc:addConnection("Bravo","Krymsk")
bc:addConnection("Bravo","Charlie")
bc:addConnection("Anapa","Charlie")

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