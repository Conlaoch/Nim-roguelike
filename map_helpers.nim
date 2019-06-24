# type definition moved to type_defs
import type_defs
import map, math_helpers

import generators

# alas, placing them directly in map.nim results in recursive imports
proc spawnMonsterbyID*(id:string, map: Map) : Entity =
    var pos = random_free_tile(map);
    return generateMonster(id, pos[0], pos[1]);

proc spawnItembyID*(id:string, map:Map) : Entity =
    var pos = random_free_tile(map);
    return generateItem(id, pos[0], pos[1]);