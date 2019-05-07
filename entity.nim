import math_helpers, map, math, alea, astar

# type definition moved to type_defs
import type_defs

# constructor so that we can provide default values
proc newCreature*(owner: Entity, hp: int, defense:int, attack:int, base_str=8, base_dex=8, base_con=8, base_int=8, base_wis=8, base_cha=8) : Creature =

    Creature(owner:owner, hp:hp, max_hp:hp, defense:defense, attack:attack, 
    base_str:base_str, base_dex:base_dex, base_con:base_con, base_int:base_int, base_wis:base_wis, base_cha:base_cha);    

proc generate_stats*(typ="standard", kind="melee") : array[6,int] = 
    var arr : array[6, int]
    if typ == "heroic":
        arr = [ 15, 14, 13, 12, 10, 8]
    else:
        arr = [ 13, 12, 11, 10, 9, 8]

    var temp: array[6, int]
    if kind == "ranged":
        # STR DEX CON INT WIS CHA
        temp[0] = arr[2]
        temp[1] = arr[0]
        temp[2] = arr[1]
        temp[3] = arr[3]
        temp[4] = arr[4]
        temp[5] = arr[5]
    else:
        echo "Using default array"
        # STR DEX CON INT WIS CHA
        temp[0] = arr[0]
        temp[1] = arr[2]
        temp[2] = arr[1]
        temp[3] = arr[4]
        temp[4] = arr[3]
        temp[5] = arr[5]


    return temp
    


# Nim functions have to be defined before anything that uses them
proc get_creatures_at*(entities: seq[Entity], x:int, y:int) : Entity =
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

proc pick_up*(item: Item, e: Entity, game:Game) =
    if not isNil(e.inventory):
        e.inventory.items.add(item)
        game.game_messages.add("Picked up item " & item.owner.name);
        # because it's no longer on map
        game.entities.delete(game.entities.find(item.owner));

proc drop*(item: Item, e: Entity, game:Game) =
    e.inventory.items.delete(e.inventory.items.find(item));
    # set position
    item.owner.position = e.position
    game.entities.add(item.owner);
    game.game_messages.add("You dropped the " & $item.owner.name);

# Equipment system
proc display_name*(e: Entity) : string = 
    if not isNil(e.item):
        if not isNil(e.equipment) and e.equipment.equipped:
            return e.name & " (equipped)"
        else:
            return e.name
    else:
        return e.name


proc equip(eq: Equipment, game: Game) =
    eq.equipped = true;

    game.game_messages.add("Item equipped");

proc unequip(eq: Equipment, game: Game) =
    eq.equipped = false;
    game.game_messages.add("Took off item");


proc toggle_equip(eq: Equipment, game: Game) = 
    if eq.equipped:
        eq.unequip(game)
    else:
        eq.equip(game)

proc equipped_items(inv: Inventory) : seq[Item] =
    var list_equipped: seq[Item];
    
    for it in inv.items:
        if not isNil(it.owner.equipment) and it.owner.equipment.equipped:
            list_equipped.add(it);

    return list_equipped

proc get_weapon(e:Entity) : Item =
    if not isNil(e.inventory):
        for i in e.inventory.equipped_items:
            if not isNil(i.owner.equipment) and i.owner.equipment.num_dice > 0:
                #echo("We have a weapon " & $i.owner.name);
                return i

        # in case there is none
        return nil
    else:
        return nil

proc use_item*(item:Item, user:Entity, game:Game) : bool =
    # equippable items
    if not isNil(item.owner.equipment):
        item.owner.equipment.toggle_equip(game);
        return true

    # call proc?
    elif not isNil(item.use_func):
        echo "Calling use function"
        item.use_func(item, user, game);
        return true
    else:
        return false

# Nim property
# Unfortunately we can't name it the same as the variable itself,
# the manual indicates we should be able to, but there's a name collision...
proc get_defense*(cr:Creature): int {.inline.} =
    var ret = cr.defense

    if not isNil(cr.owner.inventory):
        # check for items
        for i in cr.owner.inventory.equipped_items:
            if i.owner.equipment.defense_bonus > 0:
                ret += i.owner.equipment.defense_bonus
                #echo("Added def bonus of " & $i.owner.equipment.defense_bonus);
    
    echo("Def: " & $ret)
    return ret



proc heal_damage*(cr:Creature, amount: int) =
    var amount = amount;
    # prevent overhealing
    if cr.hp + amount > cr.max_hp:
        amount = cr.max_hp - cr.hp

    cr.hp += amount


# basic combat system
proc take_damage*(cr:Creature, amount:int) =
    cr.hp -= amount;

    # kill!
    if cr.hp <= 0:
        cr.dead = true;

proc attack*(cr:Creature, target:Entity, messages: var seq[string]) =
    var rng = aleaRNG();
    var damage = rng.roller("1d6");

    var weapon = cr.owner.get_weapon()
    if not isNil(weapon):
        #echo("We have a weapon, dmg " & $weapon.owner.equipment.num_dice & "d" & $weapon.owner.equipment.damage_dice);
        damage = rng.roller($weapon.owner.equipment.num_dice & "d" & $weapon.owner.equipment.damage_dice);

    var attack_roll = rng.roller("1d100");

    if attack_roll < target.creature.get_defense:
        if damage > 0:
            target.creature.take_damage(damage);
            messages.add(cr.owner.name & " attacks " & target.name & " for " & $damage & " points of damage!");
        else:
            messages.add(cr.owner.name & " attacks " & target.name & " but does no damage");
    else:
        messages.add(cr.owner.name & " misses " & target.name & "!");


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
    if astar.len > 1:
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