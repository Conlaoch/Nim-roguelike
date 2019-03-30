import isometric


type
    # this is Nim's closest class equivalent (a type and associated functions)
    # a type
    Entity* = ref object
        position*: Position
    
    Player* = Entity

# some functions that have our type as the first parameter
proc move*(e: Entity, dx: int, dy: int) =
    e.position = ((e.position.x + dx, e.position.y + dy))
    echo e.position

# how to deal with the fact that canvas ref is stored as part of Game?
#proc draw*(e: Entity) =