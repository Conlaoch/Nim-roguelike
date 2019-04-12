import game_class, entity

proc mark_for_del*(e:Entity, game:Game) =
    game.to_remove.add(e);

proc death_monster*(e:Entity, game:Game) =
    game.game_messages.add(e.creature.name & " is dead!");

    game.entities.delete(game.entities.find(e));
    # delete from the delete list, too
    game.to_remove.delete(game.to_remove.find(e));
    # axe refs
    e.creature = nil
    e.ai = nil

proc death_player*(e:Entity, game: Game) =
    game.game_messages.add("You are dead!");
    # remove the player
    game.player = nil
    # shift to special state (prevents moving, among other things)
    game.game_state = PLAYER_DEAD.int