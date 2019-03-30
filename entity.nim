import isometric, map


type
    # this is Nim's closest class equivalent (a type and associated functions)
    # a type
    Entity* = ref object
        position*: Position
    
    Player* = Entity

# some functions that have our type as the first parameter
proc move*(e: Entity, dx: int, dy: int, map:Map) =
    var tx = e.position.x + dx
    var ty = e.position.y + dy
    
    if tx < 0 or ty < 0:
        return
    
    if tx > map.tiles.len or ty > map.tiles.len:
        return

    if map.tiles[ty * map.width + tx] == 0:
        return

    e.position = ((e.position.x + dx, e.position.y + dy))
    #echo e.position

# how to deal with the fact that canvas ref is stored as part of Game?
#proc draw*(e: Entity) =