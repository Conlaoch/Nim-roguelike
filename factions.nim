import tint_image

# type definition moved to type_defs
import type_defs


# taken from Python version, originally adapted from ToME4
proc add_faction*(game:Game, faction_data:Faction) =
    game.factions.add(faction_data)
    echo ("Added faction " & $faction_data);
    # add the reverse mapping, too
    game.factions.add((faction_data[1], faction_data[0], faction_data[2]))
    echo ("Added reverse faction " & $(faction_data[1], faction_data[0], faction_data[2]));

proc get_faction_reaction*(game:Game, faction:string, target_faction:string, log=false) : int =
    if faction == target_faction:
        return 100

    for fact in game.factions:
        if fact[0] == faction and fact[1] == target_faction:
            if log:
                echo ("Faction reaction of " & $fact[0] & " to " & $fact[1] & " is " & $fact[2]);
            return fact[2]

    return 0

# should be in entity, but it leads to recursive imports...
proc get_marker_color*(cr:Creature, game:Game) : ColorRGB =
    let react = game.get_faction_reaction(cr.faction, "player");
    if react < -50:
        return (r:255, g:0, b:0) #"red"
    elif react < 0:
        return (r:255, g:165, b:0) #"orange"
    elif react == 0:
        return (r:255, g:255, b:0) #"yellow"
    elif react > 50:
        return (r:0, g:255, b:255) #"cyan"
    elif react > 0:
        return (r:0, g:0, b:255) #"blue"