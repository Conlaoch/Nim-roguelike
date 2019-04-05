import math_helpers, map


type
    # this is Nim's closest class equivalent (a type and associated functions)
    # a type
    Entity* = ref object
        position*: Vector2
        creature*: Creature
    
    Player* = Entity

    Creature* = ref object
        # small caps!
        name*: string

# Nim functions have to be defined before anything that uses them
proc get_creatures_at(entities: seq[Entity], x:int, y:int) : Entity =
    for entity in entities:
        if not isNil(entity.creature) and entity.position.x == x and entity.position.y == y:
            return entity

    return nil


# some functions that have our type as the first parameter
proc move*(e: Entity, dx: int, dy: int, map:Map, entities:seq[Entity]) : bool =
    var tx = e.position.x + dx
    var ty = e.position.y + dy
    
    if tx < 0 or ty < 0:
        return false
    
    if tx > map.tiles.len or ty > map.tiles.len:
        return false

    # if it's a wall
    if map.tiles[ty * map.width + tx] == 0:
        return false

    # check for creatures
    var target:Entity;
    target = get_creatures_at(entities, tx, ty);
    if not isNil(target):
        echo("You kick the " & $target.creature.name & " in the shins!");
        # no need to recalc FOV
        return false

    e.position = ((e.position.x + dx, e.position.y + dy))
    return true
    #echo e.position

# how to deal with the fact that canvas ref is stored as part of Game?
#proc draw*(e: Entity) =