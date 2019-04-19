import dom
import html5_canvas

import input_handler
import resources, entity, game_class
import map, arena_map, FOV
import death_functions
import menus

# global stuff goes here
# needed because key handler refs Game
var game: Game;


# we need to specify our own %#^%$@ type so that we can work as a callback 
# in onReady()
proc ready(canvas: Canvas) : proc(canvas:Canvas) =
    echo ("We've done loading, ready");

    # moved from main
    # initial setup
    game = newGame(canvas);
    game.clearGame();
    input_handler.game = game;
    
    #echo $resources.getURLs();

    for k in resources.getURLs():
        echo $k;
        # for easier retrieval from Nim
        game.images.add(resources.get(k));

    # setup cd.
    game.player = Player(position: (1,1), image:0, name:"Player");
    game.player.creature = Creature(owner:game.player, hp: 20, max_hp:20, attack:40, defense:30);
    game.player.inventory = Inventory(capacity:26);
    game.map = arena_map.generateMap(20,20,@[(10,10)])
    arena_map.place_entities(game.map, game.entities, 3, 2);
    # FOV
    game.recalc_FOV = true;
    game.FOV_map = calculate_fov(game.map, 0, game.player.position, 4);

    # what it says on the tin
    proc mainLoop(time:float) = 
        discard dom.window.requestAnimationFrame(mainLoop)

    # should the main loop get moved to dom.window.onload
    # this if will become necessary
    #    if not isNil(game):

        # recalc fov if needed
        if game.recalc_FOV:
            game.FOV_map = calculate_fov(game.map, 0, game.player.position, 4);
            # the loop is called 60x a second, so immediately set the flag to false
            game.recalc_FOV = false;
        # clear
        game.clearGame();
        # render
        game.renderMap(game.map, game.FOV_map, game.explored);
        game.renderEntities(game.FOV_map);
        game.render(game.player);
        game.renderBar(10, 10, 100, game.player.creature.hp, game.player.creature.max_hp, (255,0,0), (191, 0,0));
        game.drawMessages();

        # inventory
        if game.game_state == GUI_S_INVENTORY.int or game.game_state == GUI_S_DROP.int:
            var inv_title: string;
            if game.game_state == GUI_S_INVENTORY.int:
                inv_title = "INVENTORY. Press key to use item"
            else:
                inv_title = "INVENTORY. Press key to drop item"

            game.inventory_menu(inv_title, game.player.inventory, 50, game.canvas.width, game.canvas.height);

        # AI turn
        if game.game_state == ENEMY_TURN.int:
            for entity in game.entities:
                if not isNil(entity.ai) and not entity.creature.dead:
                    #echo("The " & entity.creature.name & " ponders the meaning of its existence.");
                    entity.ai.take_turn(game.player, game.FOV_map, game.map, game.entities, game.game_messages);
            
                if not isNil(entity.creature) and entity.creature.dead:
                    mark_for_del(entity, game);

                # break if the player's killed!
                if game.player.creature.dead:
                    death_player(game.player, game);
                    break

            # trick to use actual enum's int value
            if game.game_state != GameState.PLAYER_DEAD.int:
                game.game_state = GameState.PLAYER_TURN.int

            # avoid modifying while iterating
            for entity in game.to_remove:
                death_monster(entity, game)
                

    # this indentation is crucially important! It's not part of the main loop!
    discard dom.window.requestAnimationFrame(mainLoop)

# just a stub for JS to be able to call
proc onReadyNim() {.exportc.} =
    echo "Calling Nim from JS";
    let canvas = dom.document.getElementById("canvas-game").Canvas
    discard ready(canvas);

# setup canvas
dom.window.onload = proc(e: dom.Event) =
    let canvas = dom.document.getElementById("canvas-game").Canvas
    canvas.width = 800
    canvas.height = 600

    # load assets
    # do we need this? YES WE DO!
    var ress = initLoader(dom.window);
    # the order here is carried over to game.images, and the indices are used by Entity class
    # we have to force cstring conversion for some reason
    resources.load(@[cstring("gfx/human_m.png"), 
    cstring("gfx/wall_stone.png"),
    cstring("gfx/floor_cave.png"),
    cstring("gfx/kobold.png"),
    cstring("gfx/potion.png"),
    cstring("gfx/scroll_lightning.png")]);

    # keys
    #  proc onKeyUp(event: Event) =
    #    processKeyUp(event.keyCode)

    proc onKeyDown(event: Event) =
        # prevent scrolling on arrow keys
        event.preventDefault();
        processKeyDown(event.keyCode, game);

    #  dom.window.addEventListener("keyup", onKeyUp)
    dom.window.addEventListener("keydown", onKeyDown)

    # place for main loop IF we need e.g. a visual loading bar