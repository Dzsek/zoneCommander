# WIP

# BattleCommander

## Constructor

### BattleCommander:new()

The BattleCommander object is the base object that monitors and runs the whole mission. You only need a single instance of this.

Example:
`bc = BattleCommander:new()`

## Add Zone

### BattleCommander:addZone(zone)
Registers a ZoneCommander object, and enables state tracking and updates for said zone.

Example:
`bc:addZone(exampleZone)`

## Connections

### BattleCommander:addConnection(from, to)

Draws a line between two zones. Does not have any functional value, only visual. Use to help players see where supplies and attacks might be coming from, and to guide player progression.

Example:
`bc:addConnection('zonename1', 'zonename2')`

## Credits and Support items

### BattleCommander:addFunds(coalition, ammount)

Adds the specified ammount of credits to the specified coalition. 

Coalition parameters must be set to 1 for Red coalition and 2 for Blue coalition.

Ammount can be any number. If negative, it will substract the credits from the account.

Example:
`bc:addFunds(coalition, ammount)`

### BattleCommander:registerShopItem(id, displayname, cost, action)

Defines an item for the support shop. Note this does not make it available yet only defines the properties of the support item.

First parameter should be a unique string id that identifies the item within the system.

Second parameter should be a string that is displayed in the Support shop menu to players.

Third parameter should be a number specifying the price of the item. When bought this price will be substracted from the coalition account. Will prevent buying if not enough funds.

Fourth parameter is a function to execute whenever the item is succesfully bought. First parameter of the function will always be an object describing the shop item in the format { name='examplename', cost=100, action = functionobject }. You can return a string specifying an error, or just *true* in order to prevent item from being bought in case some conditions are required. This will prevent the cost and stock being deducted.

Example:
```
bc:registerShopItem('exampleid', 'display name', cost, function(sender) 
  --your code here 
end)
```

### BattleCommander:addShopItem(coalition, id, ammount)

Will make an item available for the specified coalition.

First parameter is coalition to add item to. 1 for Red, 2 for Blue.

Second parameter is the string that identifies a previously registered item.

Third parameter is a number specifying the available stock for this item. Once the item has been bought the specified ammount of times it will be removed from the shop menu. A value of -1 will make this available indefinitely.

Example:
`bc:addShopItem(coalition, 'exampleitemid', ammount)`

### BattleCommander:removeShopItem(coalition, id)

Removes an item from the specified coalition shop menu, regardless of remaining stock.

First parameter is coalition to remove from. 1 for Red, 2 for Blue.

Second parameter is the string that identified a previously registered item.

Example:
`bc:removeShopItem(coalition, 'exampleitemid)`

# ZoneCommander

## Constructor

### ZoneCommander:new(parameters)

Handles everything related to a single Zone. You will need to create one of these for each Zone you want in your mission.

The parameters table should have the following format:

```
  {
    zone = 'ZoneName', --string, name of the trigger zone in the mission editor(only circular zones work currently)
    side = 1, -- number, 0 for neutral, 1 for red and 2 for blue
    level = 1, -- number, number of upgrades to be spawned from the upgrade list
    upgrades = {'group1','group2','group3'}, -- table, contains strings, names of groups to spawn for each upgrade, they will be spawned in the specified order
    crates = {'c1','c2','c3'}, -- table, constains strings, names of cargo staticobjects, zone will check if any of this is within its borders, triggering a capture/upgrade event if it is, do not add cargo names to the same zone that spawns them as it will trigger instant upgrades
    flavorText = 'description', -- string to display in the F10 radio menu when viewing zone status
    income = 2 --number, credits per tick that the zone will add to the controling coalitions accounts (1 tick = 10 seconds)
  }
```

Example:
`exampleZone = ZoneCommander:new(parameters)`

## Critical objects

### ZoneCommander:addCriticalObject(staticobjectname)

Adds the name of a StaticObject to monitor within the mission. If all of these objects get destroyed, the zone will enter a disabled state, meaning it will no longer be capturable or upgradeable, and will not provide any benefits. Any groups that exist at the moment of distruction will remain, but will no longer be repaireable by resupply events.

Example:
`exampleZone:addCriticalObject('staticobjectname')`

## Triggers

### ZoneCommander:registerTrigger(eventtype, action, id, *runcount*)

Registers a function to run when a zone changes state.

First parameter specifies the event. It should be set to one of the following string values:
- 'captured' - occurs when any side captures the zone, also triggers an upgrade immediatly after the capture
- 'upgraded' - occurs whenever a friendly zone is upgraded, and spawns its next group, 1st upgrade is triggered immediatly after capture
- 'repaired' - occurs whenever a resuply event happens at a zone and there is any group alive with missing members, this group will be restored instead of the next group being spawned
- 'lost' - occurs whenever a zone goes back to neutral state, when all groups are destroyed
- 'destroyed' - occurs when all of the critical objects of a zone have been destroyed, zone will turn black and be effectively useless for the remainder of the campaign

Second parameter is a function that will be called whenever the event is triggered. It will provide the string eventname in the first parameter, and the ZoneCommander object in the second parameter

Third parameter is a string id that is used to keep track of how many times the trigger has run. Used by the persistance code to keep track even after restarts.

Fourth parameter is a number that specifies how many times this trigger can run. Once it has run the specified number of times, the trigger will stop executing. Leave out this parameter to let the event run unlimited number of times.

Example:

`exampleZone:registerTrigger('eventname', function(event, sender) trigger.action.outText('event triggered',5) end, 'triggerid', 4)`
