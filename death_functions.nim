import game_class, type_defs

proc mark_for_del*(e:Entity, game:Game) =
    game.to_remove.add(e);

proc death_monster*(e:Entity, game:Game) =
    game.game_messages.add((e.name & " is dead!", (127,127,127)));

    if not isNil(e.inventory):
        echo("Monster had inventory")
        for item in e.inventory.items:
            echo("Spawning an item from inventory")
            item.owner.position = e.position
            game.level.entities.add(item.owner)


    if game.level.entities.find(e) > -1:
        game.level.entities.delete(game.level.entities.find(e));

    # axe refs
    e.creature = nil
    e.ai = nil

proc death_player*(e:Entity, game: Game) =
    game.game_messages.add(("You are dead!", (255,0,0)));
    # remove the player
    game.player = nil
    # shift to special state (prevents moving, among other things)
    game.game_state = PLAYER_DEAD.int