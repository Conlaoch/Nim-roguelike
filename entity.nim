import math_helpers, map, math, alea


type
    # this is Nim's closest class equivalent (a type and associated functions)
    # a type
    Entity* = ref object
        position*: Vector2
        # optional components
        creature*: Creature
        ai*: AI
    
    Player* = Entity

    Creature* = ref object
        # small caps!
        name*: string
        # back ref to entity
        owner*: Entity
        # combat stuff
        hp*: int
        max_hp*: int
        defense*: int
        attack*: int

    AI* = ref object
        # back reference to entity
        owner*: Entity

# Nim functions have to be defined before anything that uses them
proc get_creatures_at(entities: seq[Entity], x:int, y:int) : Entity =
    for entity in entities:
        if not isNil(entity.creature) and entity.position.x == x and entity.position.y == y:
            return entity

    return nil

# basic combat system
proc take_damage*(cr:Creature, amount:int) =
    cr.hp -= amount;

proc attack*(cr:Creature, target:Entity) =
    var rng = aleaRNG();
    var damage = rng.roller("1d6");

    if damage > 0:
        target.creature.take_damage(damage);
        echo(cr.name & " attacks " & target.creature.name & " for " & $damage & " points of damage!");
    else:
        echo(cr.name & " attacks " & target.creature.name & " but does no damage");


# some functions that have our Entity type as the first parameter
proc move*(e: Entity, dx: int, dy: int, map:Map, entities:seq[Entity]) : bool =
    ##echo("Move: " & $dx & " " & $dy);
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
        #echo("You kick the " & $target.creature.name & " in the shins!");
        attack(e.creature, target);
        # no need to recalc FOV
        return false

    e.position = ((e.position.x + dx, e.position.y + dy))
    return true
    #echo e.position

proc move_towards(e:Entity, target:Vector2, game_map:Map, entities:seq[Entity]) : bool =
    var dx = target.x - e.position.x
    var dy = target.y - e.position.y
    #var distance = math.sqrt(dx ** 2 + dy ** 2)
    var distance = distance_to(e.position, target);

    dx = int(round(dx / distance))
    dy = int(round(dy / distance))
    #echo ("dx " & $dx & " dy: " & $dy);

    if not game_map.is_blocked(e.position.x + dx, e.position.y + dy) or isNil(get_creatures_at(entities, e.position.x + dx, e.position.y + dy)):
        echo("We can move to " & $(e.position.x + dx) & " " & $(e.position.y + dy));
        return e.move(dx, dy, game_map, entities);

# how to deal with the fact that canvas ref is stored as part of Game?
#proc draw*(e: Entity) =

proc take_turn*(ai:AI, target:Entity, fov_map:seq[Vector2], game_map:Map, entities:seq[Entity]) = 
    #echo ("The " & ai.owner.creature.name & "wonders when it will get to move");
    var monster = ai.owner
    # assume if we can see it, it can see us too
    if monster.position in fov_map:
        if monster.position.distance_to(target.position) >= 2:
            # discard means we're not using the return value
            discard monster.move_towards(target.position, game_map, entities);
        elif target.creature.hp > 0:
            #echo ai.owner.creature.name & " insults you!";
            attack(ai.owner.creature, target);