import math_helpers, map, math, alea, astar


type
    # this is Nim's closest class equivalent (a type and associated functions)
    # a type
    Entity* = ref object
        position*: Vector2
        image*: int # the index of the tile in game.images
        # small caps for type string!
        name*: string
        # optional components
        creature*: Creature
        ai*: AI
        item*: Item
        inventory*:Inventory
    
    Player* = Entity

    Creature* = ref object
        # back ref to entity
        owner*: Entity
        # combat stuff
        hp*: int
        max_hp*: int
        defense*: int
        attack*: int
        # flag
        dead*: bool

    AI* = ref object
        # back reference to entity
        owner*: Entity

    Item* = ref object
        # back reference to entity
        owner*: Entity
        # optional
        use_func*: FuncHandler
    
    Inventory* = ref object
        # back reference to entity
        owner*: Entity
        capacity*: int
        items*: seq[Item]

    # in Nim, the easiest way to call a function is to assign a dummy type
    FuncHandler* = proc(i:Item, e:Entity)

# Nim functions have to be defined before anything that uses them
proc get_creatures_at(entities: seq[Entity], x:int, y:int) : Entity =
    for entity in entities:
        if not isNil(entity.creature) and entity.position.x == x and entity.position.y == y:
            return entity

    return nil

proc get_items_at*(entities: seq[Entity], x:int, y:int) : Entity =
    for entity in entities:
        if not isNil(entity.item) and entity.position.x == x and entity.position.y == y:
            return entity
    
    return nil

# find closest enemy, up to a maximum range, and in the player's FOV
proc closest_monster*(player: Entity, entities: seq[Entity], fov_map:seq[Vector2], max_range:int) : Entity =
    var target: Entity;
    var closest_dist: int;
    closest_dist = max_range+1; # start with slightly more than maximum range
    for entity in entities:
        if not isNil(entity.creature) and entity != player and entity.position in fov_map:
            # calculate distance between this entity and the player
            var dist = player.position.distance_to(entity.position);
            if dist < closest_dist: # it's closer, so remember it
                target = entity
                closest_dist = dist

    return target

proc pick_up*(item: Item, e: Entity) =
    if not isNil(e.inventory):
        e.inventory.items.add(item)
        # the rest is handled elsewhere because we can't use anything from Game here

proc drop*(item: Item, e: Entity) =
    e.inventory.items.delete(e.inventory.items.find(item));
    # set position
    item.owner.position = e.position
    # can't put it back in entities list here due to it being in game... see input handler for now

proc use_item*(item:Item, user:Entity) : bool =
    # call proc?
    if not isNil(item.use_func):
        echo "Calling use function"
        item.use_func(item, user);
        return true
    else:
        return false

# basic combat system
proc take_damage*(cr:Creature, amount:int) =
    cr.hp -= amount;

    # kill!
    if cr.hp <= 0:
        cr.dead = true;

proc attack*(cr:Creature, target:Entity, messages: var seq[string]) =
    var rng = aleaRNG();
    var damage = rng.roller("1d6");

    if damage > 0:
        target.creature.take_damage(damage);
        messages.add(cr.owner.name & " attacks " & target.name & " for " & $damage & " points of damage!");
    else:
        messages.add(cr.owner.name & " attacks " & target.name & " but does no damage");


# some functions that have our Entity type as the first parameter
proc move*(e: Entity, dx: int, dy: int, map:Map, entities:seq[Entity], messages: var seq[string]) : bool =
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
        attack(e.creature, target, messages);
        # no need to recalc FOV
        return false

    e.position = ((e.position.x + dx, e.position.y + dy))
    return true
    #echo e.position

proc move_towards(e:Entity, target:Vector2, game_map:Map, entities:seq[Entity], messages:var seq[string]) : bool =
    var dx = target.x - e.position.x
    var dy = target.y - e.position.y
    #var distance = math.sqrt(dx ** 2 + dy ** 2)
    var distance = distance_to(e.position, target);

    dx = int(round(dx / distance))
    dy = int(round(dy / distance))
    #echo ("dx " & $dx & " dy: " & $dy);

    if not game_map.is_blocked(e.position.x + dx, e.position.y + dy) or isNil(get_creatures_at(entities, e.position.x + dx, e.position.y + dy)):
        echo("We can move to " & $(e.position.x + dx) & " " & $(e.position.y + dy));
        return e.move(dx, dy, game_map, entities, messages);

proc move_astar(e:Entity, target:Vector2, game_map:Map, entities:seq[Entity], messages:var seq[string]) =
    echo "Calling astar..."
    var astar = findPathNim(game_map, e.position, target);
    # for e in astar:
    #     echo e
    if not astar.len < 1:
        # get the next point along the path (because #0 is our current position)
        # it was already checked for walkability by astar so we don't need to do it again
        e.position = astar[1]
    else:
        # backup in case no path found
        discard e.move_towards(target, game_map, entities, messages);

# how to deal with the fact that canvas ref is stored as part of Game?
#proc draw*(e: Entity) =

proc take_turn*(ai:AI, target:Entity, fov_map:seq[Vector2], game_map:Map, entities:seq[Entity], messages:var seq[string]) = 
    #echo ("The " & ai.owner.creature.name & "wonders when it will get to move");
    var monster = ai.owner
    # assume if we can see it, it can see us too
    if monster.position in fov_map:
        if monster.position.distance_to(target.position) >= 2:
            # discard means we're not using the return value
            #discard monster.move_towards(target.position, game_map, entities);
            monster.move_astar(target.position, game_map, entities, messages);
        elif target.creature.hp > 0:
            #echo ai.owner.creature.name & " insults you!";
            attack(ai.owner.creature, target, messages);