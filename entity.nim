import math_helpers, map


type
    # this is Nim's closest class equivalent (a type and associated functions)
    # a type
    Entity* = ref object
        position*: Vector2
    
    Player* = Entity

# some functions that have our type as the first parameter
proc move*(e: Entity, dx: int, dy: int, map:Map) : bool =
    var tx = e.position.x + dx
    var ty = e.position.y + dy
    
    if tx < 0 or ty < 0:
        return false
    
    if tx > map.tiles.len or ty > map.tiles.len:
        return false

    if map.tiles[ty * map.width + tx] == 0:
        return false

    e.position = ((e.position.x + dx, e.position.y + dy))
    return true
    #echo e.position

# how to deal with the fact that canvas ref is stored as part of Game?
#proc draw*(e: Entity) =