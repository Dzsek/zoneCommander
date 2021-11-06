function merge(tbls)
	local res = {}
	for i,v in ipairs(tbls) do
		for i2,v2 in ipairs(v) do
			table.insert(res,v2)
		end
	end
	
	return res
end

blueAirfield = { "bInfantry", "bArmor", "bSam", "bSam2", "bSam3"}
redAirfield = {"rInfantry", "rArmor", "rSam", "rSam2", "rSam3" }
blueFarp = {"bInfantry", "bArmor", "bSam"}
redFarp = {"rInfantry", "rArmor", "rSam" }

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

krymskdp = {
	{ tozone = "Bravo", supplyUnit = "krym1", attackGroup = "krym2", cap="krym3"},
	{ tozone = "Krymsk", cap="krym4"}
}

bravodp = {
	{ tozone = "Alpha", supplyUnit = "bravo1", attackGroup = "bravo2"},
	{ tozone = "Charlie", supplyUnit = "bravo6", attackGroup = "bravo7"},
	{ tozone = "Krymsk", supplyUnit = "bravo4", attackGroup = "bravo5"}
}

anapadp = {
	{ tozone = "Alpha", supplyUnit = "anapa1"},
	{ tozone = "Charlie", supplyUnit = "anapa2"},
	{ tozone = "Bravo", supplyUnit = "anapa3"},
	{ tozone = "Krymsk", supplyUnit = "anapa4"}
}


farpCommander.addFarp("Anapa", 2, 5, {}, blueAirfield, redAirfield, cargoAccepts.anapa, nil, anapadp)
farpCommander.addFarp("Alpha", 0, 0, {"bravo1","anapa1"}, blueFarp, redFarp, cargoAccepts.alpha)
farpCommander.addFarp("Bravo", 1, 3, {"alpha1","krym1","anapa3"}, blueFarp, redFarp, cargoAccepts.bravo, bravodp)
farpCommander.addFarp("Charlie", 0, 0, {"bravo6","anapa2"}, blueFarp, redFarp, cargoAccepts.charlie)
farpCommander.addFarp("Krymsk", 1, 5, {"bravo4","anapa4"}, blueAirfield, redAirfield, cargoAccepts.krymsk, krymskdp)
farpCommander.connections = {
	{ from="Anapa", to="Alpha"},
	{ from="Alpha", to="Bravo"},
	{ from="Bravo", to="Krymsk"},
	{ from="Bravo", to="Charlie"},
	{ from="Anapa", to="Charlie"}
}
farpCommander.init()

function respawnCargo()
	for i,v in pairs(cargoSpawns) do
		local farp = farpCommander.getFarpByName(i)
		if farp then
			if farp.side==2 then
				for ix,vx in ipairs(v) do
					if not StaticObject.getByName(vx) then
						mist.respawnGroup(vx)
					end
				end
			else 
				for ix,vx in ipairs(v) do
					local st = StaticObject.getByName(vx)
					if st then
						st:destroy()
					end
				end
			end
		end
	end
end

mist.scheduleFunction(respawnCargo, {}, timer.getTime() + 1, 30)