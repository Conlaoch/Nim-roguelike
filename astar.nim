# A* bindings
import map, math_helpers
import type_defs

proc findPath(map:Map, start:Vector2, end_point:Vector2, entities: seq[Entity]) : seq[array[2, int]] {.importc.}

# to make things easier to use on the Nim side
proc findPathNim*(map:Map, start:Vector2, end_point:Vector2, entities:seq[Entity]) : seq[Vector2] =
    var res = findPath(map, start, end_point, entities);
    var ret: seq[Vector2]

    # Nim arrays are inclusive
    for i in 0 .. res.len-1:
        #echo $res[i]
        #echo $res[i][0] & " " & $res[i][1]
        ret.add((res[i][0], res[i][1]));

    return ret;