# type definition moved to type_defs
import type_defs

import math_helpers, map

# this is used by A*, too
proc get_creatures_at*(entities: seq[Entity], x:int, y:int) : Entity {.exportc.}  =
    for entity in entities:
        if not isNil(entity.creature) and entity.position.x == x and entity.position.y == y:
            return entity

    return nil

proc get_items_at*(entities: seq[Entity], x:int, y:int) : Entity =
    for entity in entities:
        if not isNil(entity.item) and entity.position.x == x and entity.position.y == y:
            return entity
    
    return nil

proc find_free_grid_in_range*(map: Map, dist: int, x: int, y:int, entities: seq[Entity]) : seq[Vector2] =
    var coords = find_grid_in_range(map, dist, x,y)
    var free = get_free_tiles(map)
    var res : seq[Vector2]

    echo("Finding free grid in range...");

    for c in coords:
        if (c[0], c[1]) in free:
            if isNil(get_creatures_at(entities, c[0],c[1])):
                res.add((c[0], c[1]))

    echo $res;
    return res