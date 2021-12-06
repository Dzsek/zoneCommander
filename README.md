# WIP

# BattleCommander

The BattleCommander object is the base object that monitors and runs the whole mission. You only need a single instance of this.

`bc = BattleCommander:new()`

# ZoneCommander

## Constructor

Handles everything related to a single Zone. You will need to create one of these for each Zone you want in your mission.

`exampleZone = ZoneCommander:new(parameters)`

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

## Critical objects

`exampleZone:addCriticalObject('staticobjectname')`

Adds the name of a StaticObject to monitor within the mission. If all of these objects get destroyed, the zone will enter a disabled state, meaning it will no longer be capturable or upgradeable, and will not provide any benefits. Any groups that exist at the moment of distruction will remain, but will no longer be repaireable by resupply events.

## Triggers

`exampleZone:registerTrigger('eventname', function(event, sender) trigger.action.outText('event triggered',5) end, 'triggerid', 4)`

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


