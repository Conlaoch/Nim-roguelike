import dom
import html5_canvas

import input_handler
import type_defs
import resources, entity, game_class
import map, arena_map, FOV, camera
import death_functions
import menus
import save
import generators

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

    generators.loadfiles()

# called from JS after loading generator data files
proc onReadyNimCallback*() {.exportc.} =
    echo "Callback!"
    var data = generators.getData();

    generators.items_data = data[0];


    # setup cd.
    game.player = Player(position: (1,1), image:0, name:"Player");
    var arr = generate_stats("heroic");
    # procs have a different syntax to type() construction (= instead of :)
    game.player.creature = newCreature(owner=game.player, hp=20, attack=40, defense=30,
    base_str=arr[0], base_dex=arr[1], base_con=arr[2], base_int=arr[3], base_wis=arr[4], base_cha=arr[5]);
    game.player.inventory = Inventory(capacity:26);
    game.camera = Camera(width:7, height:7, position:game.player.position, offset:(360,260));
    game.camera.calculate_extents();
    game.map = arena_map.generateMap(15,15,@[(10,10)])
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
            # piggyback on this for camera recalculations
            game.camera.position = game.player.position
            game.camera.calculate_extents();
            game.FOV_map = calculate_fov(game.map, 0, game.player.position, 4);
            # the loop is called 60x a second, so immediately set the flag to false
            game.recalc_FOV = false;
        # clear
        game.clearGame();
        # render
        game.renderMap(game.map, game.FOV_map, game.explored, game.camera);
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

        # targeting
        if game.game_state == TARGETING.int:
            game.drawTargeting();

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

# here because, again, we run into recursive module problem (can't reach into main.nim from input_handler.nim)
proc loadGameNim() {.exportc.} =
    echo "Load test"

    # string obtained from a previous run of saveGameNim()
    # it's a bit wasteful, especially the "Field0" and the strings being stored as arrays of char codes
    # var test = """{"mx":0,"my":0,"canvas":{},"context":{},"images":[{},{},{},{},{},{},{},{}],
    # "player":{"position":{"Field0":9,"Field1":10},"image":0,"name":[80,108,97,121,101,114],"creature":{"hp":4,"max_hp":20,"attack":40,"defense":30,"dead":false},"ai":null,"item":null,"inventory":{"capacity":26,"owner":null,"items":null}},"map":{"tiles":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"width":20,"height":20},"recalc_FOV":false,
    # "FOV_map":[{"Field0":9,"Field1":10},{"Field0":8,"Field1":9},{"Field0":7,"Field1":8},{"Field0":6,"Field1":7},{"Field0":8,"Field1":11},{"Field0":7,"Field1":12},{"Field0":6,"Field1":13},{"Field0":7,"Field1":7},{"Field0":8,"Field1":12},{"Field0":7,"Field1":13},{"Field0":8,"Field1":8},{"Field0":7,"Field1":6},{"Field0":9,"Field1":11},{"Field0":8,"Field1":13},{"Field0":7,"Field1":14},{"Field0":9,"Field1":9},{"Field0":8,"Field1":7},{"Field0":8,"Field1":6},{"Field0":9,"Field1":12},{"Field0":8,"Field1":14},{"Field0":9,"Field1":8},{"Field0":9,"Field1":7},{"Field0":9,"Field1":6},{"Field0":9,"Field1":13},{"Field0":9,"Field1":14},{"Field0":10,"Field1":8},{"Field0":10,"Field1":7},{"Field0":10,"Field1":6},{"Field0":10,"Field1":13},{"Field0":10,"Field1":14},{"Field0":10,"Field1":9},{"Field0":11,"Field1":7},{"Field0":11,"Field1":6},{"Field0":10,"Field1":12},{"Field0":11,"Field1":14},{"Field0":11,"Field1":8},{"Field0":10,"Field1":11},{"Field0":11,"Field1":13},{"Field0":12,"Field1":7},{"Field0":11,"Field1":12},{"Field0":12,"Field1":13},{"Field0":6,"Field1":8},{"Field0":11,"Field1":9},{"Field0":12,"Field1":8},{"Field0":7,"Field1":9},{"Field0":5,"Field1":8},{"Field0":10,"Field1":10},{"Field0":8,"Field1":10},{"Field0":6,"Field1":9},{"Field0":5,"Field1":9},{"Field0":7,"Field1":10},{"Field0":6,"Field1":10},{"Field0":5,"Field1":10},{"Field0":7,"Field1":11},{"Field0":6,"Field1":11},{"Field0":5,"Field1":11},{"Field0":6,"Field1":12},{"Field0":5,"Field1":12},{"Field0":11,"Field1":11},{"Field0":12,"Field1":12},{"Field0":10,"Field1":10},{"Field0":10,"Field1":10},{"Field0":10,"Field1":10},{"Field0":10,"Field1":10},{"Field0":10,"Field1":10},{"Field0":10,"Field1":10},{"Field0":10,"Field1":10},{"Field0":10,"Field1":10},{"Field0":10,"Field1":10},{"Field0":10,"Field1":10},{"Field0":10,"Field1":10},{"Field0":10,"Field1":10},{"Field0":10,"Field1":10},{"Field0":10,"Field1":10}],"explored":[{"Field0":0,"Field1":0},{"Field0":0,"Field1":1},{"Field0":0,"Field1":2},{"Field0":0,"Field1":3},{"Field0":0,"Field1":4},{"Field0":0,"Field1":5},{"Field0":1,"Field1":0},{"Field0":1,"Field1":1},{"Field0":1,"Field1":2},{"Field0":1,"Field1":3},{"Field0":1,"Field1":4},{"Field0":1,"Field1":5},{"Field0":2,"Field1":0},{"Field0":2,"Field1":1},{"Field0":2,"Field1":2},{"Field0":2,"Field1":3},{"Field0":2,"Field1":4},{"Field0":2,"Field1":5},{"Field0":3,"Field1":0},{"Field0":3,"Field1":1},{"Field0":3,"Field1":2},{"Field0":3,"Field1":3},{"Field0":3,"Field1":4},{"Field0":3,"Field1":5},{"Field0":4,"Field1":0},{"Field0":4,"Field1":1},{"Field0":4,"Field1":2},{"Field0":4,"Field1":3},{"Field0":4,"Field1":4},{"Field0":5,"Field1":0},{"Field0":5,"Field1":1},{"Field0":5,"Field1":2},{"Field0":5,"Field1":3},{"Field0":4,"Field1":5},{"Field0":5,"Field1":4},{"Field0":6,"Field1":0},{"Field0":6,"Field1":1},{"Field0":6,"Field1":2},{"Field0":6,"Field1":3},{"Field0":5,"Field1":5},{"Field0":6,"Field1":4},{"Field0":7,"Field1":0},{"Field0":7,"Field1":1},{"Field0":7,"Field1":2},{"Field0":7,"Field1":3},{"Field0":6,"Field1":5},{"Field0":7,"Field1":4},{"Field0":8,"Field1":0},{"Field0":8,"Field1":1},{"Field0":8,"Field1":2},{"Field0":8,"Field1":3},{"Field0":7,"Field1":5},{"Field0":8,"Field1":4},{"Field0":9,"Field1":0},{"Field0":9,"Field1":1},{"Field0":9,"Field1":2},{"Field0":9,"Field1":3},{"Field0":8,"Field1":5},{"Field0":9,"Field1":4},{"Field0":10,"Field1":0},{"Field0":10,"Field1":1},{"Field0":10,"Field1":2},{"Field0":10,"Field1":3},{"Field0":9,"Field1":5},{"Field0":10,"Field1":4},{"Field0":11,"Field1":0},{"Field0":11,"Field1":1},{"Field0":11,"Field1":2},{"Field0":11,"Field1":3},{"Field0":10,"Field1":5},{"Field0":11,"Field1":4},{"Field0":12,"Field1":0},{"Field0":12,"Field1":1},{"Field0":12,"Field1":2},{"Field0":12,"Field1":3},{"Field0":11,"Field1":5},{"Field0":12,"Field1":4},{"Field0":13,"Field1":0},{"Field0":13,"Field1":1},{"Field0":13,"Field1":2},{"Field0":13,"Field1":3},{"Field0":12,"Field1":5},{"Field0":13,"Field1":4},{"Field0":14,"Field1":0},{"Field0":14,"Field1":1},{"Field0":14,"Field1":2},{"Field0":14,"Field1":3},{"Field0":13,"Field1":5},{"Field0":14,"Field1":4},{"Field0":15,"Field1":0},{"Field0":15,"Field1":1},{"Field0":15,"Field1":2},{"Field0":15,"Field1":3},{"Field0":14,"Field1":5},{"Field0":15,"Field1":4},{"Field0":16,"Field1":0},{"Field0":16,"Field1":1},{"Field0":16,"Field1":2},{"Field0":16,"Field1":3},{"Field0":15,"Field1":5},{"Field0":16,"Field1":4},{"Field0":17,"Field1":0},{"Field0":17,"Field1":1},{"Field0":17,"Field1":2},{"Field0":17,"Field1":3},{"Field0":16,"Field1":5},{"Field0":17,"Field1":4},{"Field0":18,"Field1":0},{"Field0":18,"Field1":1},{"Field0":18,"Field1":2},{"Field0":18,"Field1":3},{"Field0":17,"Field1":5},{"Field0":18,"Field1":4},{"Field0":19,"Field1":0},{"Field0":19,"Field1":1},{"Field0":19,"Field1":2},{"Field0":19,"Field1":3},{"Field0":18,"Field1":5},{"Field0":19,"Field1":4},{"Field0":19,"Field1":5},{"Field0":16,"Field1":6},{"Field0":17,"Field1":6},{"Field0":18,"Field1":6},{"Field0":19,"Field1":6},{"Field0":15,"Field1":6},{"Field0":16,"Field1":7},{"Field0":17,"Field1":7},{"Field0":18,"Field1":7},{"Field0":19,"Field1":7},{"Field0":14,"Field1":6},{"Field0":15,"Field1":7},{"Field0":16,"Field1":8},{"Field0":17,"Field1":8},{"Field0":18,"Field1":8},{"Field0":19,"Field1":8},{"Field0":14,"Field1":7},{"Field0":15,"Field1":8},{"Field0":16,"Field1":9},{"Field0":17,"Field1":9},{"Field0":18,"Field1":9},{"Field0":19,"Field1":9},{"Field0":14,"Field1":8},{"Field0":15,"Field1":9},{"Field0":16,"Field1":10},{"Field0":17,"Field1":10},{"Field0":18,"Field1":10},{"Field0":19,"Field1":10},{"Field0":14,"Field1":9},{"Field0":15,"Field1":10},{"Field0":16,"Field1":11},{"Field0":17,"Field1":11},{"Field0":18,"Field1":11},{"Field0":19,"Field1":11},{"Field0":14,"Field1":10},{"Field0":15,"Field1":11},{"Field0":16,"Field1":12},{"Field0":17,"Field1":12},{"Field0":18,"Field1":12},{"Field0":19,"Field1":12},{"Field0":14,"Field1":11},{"Field0":15,"Field1":12},{"Field0":16,"Field1":13},{"Field0":17,"Field1":13},{"Field0":18,"Field1":13},{"Field0":19,"Field1":13},{"Field0":14,"Field1":12},{"Field0":15,"Field1":13},{"Field0":16,"Field1":14},{"Field0":17,"Field1":14},{"Field0":18,"Field1":14},{"Field0":19,"Field1":14},{"Field0":14,"Field1":13},{"Field0":15,"Field1":14},{"Field0":16,"Field1":15},{"Field0":17,"Field1":15},{"Field0":18,"Field1":15},{"Field0":19,"Field1":15},{"Field0":14,"Field1":14},{"Field0":15,"Field1":15},{"Field0":16,"Field1":16},{"Field0":17,"Field1":16},{"Field0":18,"Field1":16},{"Field0":19,"Field1":16},{"Field0":13,"Field1":10},{"Field0":13,"Field1":11},{"Field0":13,"Field1":12},{"Field0":13,"Field1":13},{"Field0":13,"Field1":14},{"Field0":14,"Field1":15},{"Field0":15,"Field1":16},{"Field0":12,"Field1":10},{"Field0":12,"Field1":11},{"Field0":12,"Field1":12},{"Field0":12,"Field1":13},{"Field0":12,"Field1":14},{"Field0":13,"Field1":9},{"Field0":13,"Field1":15},{"Field0":14,"Field1":16},{"Field0":11,"Field1":10},{"Field0":11,"Field1":11},{"Field0":11,"Field1":12},{"Field0":11,"Field1":13},{"Field0":11,"Field1":14},{"Field0":12,"Field1":9},{"Field0":12,"Field1":15},{"Field0":13,"Field1":8},{"Field0":13,"Field1":16},{"Field0":10,"Field1":10},{"Field0":10,"Field1":11},{"Field0":10,"Field1":12},{"Field0":10,"Field1":13},{"Field0":10,"Field1":14},{"Field0":11,"Field1":9},{"Field0":11,"Field1":15},{"Field0":12,"Field1":8},{"Field0":12,"Field1":16},{"Field0":9,"Field1":11},{"Field0":9,"Field1":12},{"Field0":9,"Field1":13},{"Field0":9,"Field1":14},{"Field0":10,"Field1":9},{"Field0":10,"Field1":15},{"Field0":11,"Field1":8},{"Field0":11,"Field1":16},{"Field0":8,"Field1":10},{"Field0":8,"Field1":11},{"Field0":8,"Field1":12},{"Field0":8,"Field1":13},{"Field0":8,"Field1":14},{"Field0":9,"Field1":10},{"Field0":9,"Field1":15},{"Field0":10,"Field1":8},{"Field0":10,"Field1":16},{"Field0":7,"Field1":10},{"Field0":7,"Field1":11},{"Field0":7,"Field1":12},{"Field0":7,"Field1":13},{"Field0":7,"Field1":14},{"Field0":8,"Field1":9},{"Field0":8,"Field1":15},{"Field0":9,"Field1":9},{"Field0":9,"Field1":16},{"Field0":6,"Field1":10},{"Field0":6,"Field1":11},{"Field0":6,"Field1":12},{"Field0":6,"Field1":13},{"Field0":6,"Field1":14},{"Field0":7,"Field1":9},{"Field0":7,"Field1":15},{"Field0":8,"Field1":8},{"Field0":8,"Field1":16},{"Field0":9,"Field1":8},{"Field0":5,"Field1":10},{"Field0":5,"Field1":11},{"Field0":5,"Field1":12},{"Field0":5,"Field1":13},{"Field0":5,"Field1":14},{"Field0":6,"Field1":9},{"Field0":6,"Field1":15},{"Field0":7,"Field1":8},{"Field0":7,"Field1":16},{"Field0":4,"Field1":10},{"Field0":4,"Field1":11},{"Field0":4,"Field1":12},{"Field0":4,"Field1":13},{"Field0":4,"Field1":14},{"Field0":5,"Field1":9},{"Field0":5,"Field1":15},{"Field0":6,"Field1":8},{"Field0":6,"Field1":16},{"Field0":7,"Field1":7},{"Field0":8,"Field1":7},{"Field0":9,"Field1":7},{"Field0":10,"Field1":7},{"Field0":5,"Field1":8},{"Field0":6,"Field1":7},{"Field0":7,"Field1":6},{"Field0":8,"Field1":6},{"Field0":9,"Field1":6},{"Field0":10,"Field1":6},{"Field0":11,"Field1":6},{"Field0":11,"Field1":7},{"Field0":12,"Field1":7},{"Field0":5,"Field1":7},{"Field0":6,"Field1":6},{"Field0":12,"Field1":6},{"Field0":13,"Field1":7}],"entities":[{"position":{"Field0":11,"Field1":17},"image":3,"name":[107,111,98,111,108,100],"creature":{"hp":5,"max_hp":5,"defense":30,"attack":20,"dead":false},"ai":{},"item":null,"inventory":null},{"position":{"Field0":7,"Field1":16},"image":4,"name":[112,111,116,105,111,110],"creature":null,"ai":null,"item":{"targeting":false},"inventory":null},{"position":{"Field0":4,"Field1":13},"image":5,"name":[108,105,103,104,116,110,105,110,103,32,115,99,114,111,108,108],"creature":null,"ai":null,"item":{"use_func":null,"targeting":false},"inventory":null},{"position":{"Field0":10,"Field1":16},"image":6,"name":[102,105,114,101,32,115,99,114,111,108,108],
    # "creature":null,"ai":null,"item":{"targeting":true,"use_func":null},"inventory":null}],"game_state":0,"previous_state":0,"game_messages":[[107,111,98,111,108,100,32,97,116,116,97,99,107,115,32,80,108,97,121,101,114,32,102,111,114,32,50,32,112,111,105,110,116,115,32,111,102,32,100,97,109,97,103,101,33],[107,111,98,111,108,100,32,97,116,116,97,99,107,115,32,80,108,97,121,101,114,32,98,117,116,32,100,111,101,115,32,110,111,32,100,97,109,97,103,101],[107,111,98,111,108,100,32,97,116,116,97,99,107,115,32,80,108,97,121,101,114,32,98,117,116,32,100,111,101,115,32,110,111,32,100,97,109,97,103,101],[107,111,98,111,108,100,32,97,116,116,97,99,107,115,32,80,108,97,121,101,114,32,102,111,114,32,49,32,112,111,105,110,116,115,32,111,102,32,100,97,109,97,103,101,33],[107,111,98,111,108,100,32,97,116,116,97,99,107,115,32,80,108,97,121,101,114,32,102,111,114,32,49,32,112,111,105,110,116,115,32,111,102,32,100,97,109,97,103,101,33],[80,108,97,121,101,114,32,97,116,116,97,99,107,115,32,107,111,98,111,108,100,32,102,111,114,32,54,32,112,111,105,110,116,115,32,111,102,32,100,97,109,97,103,101,33],[107,111,98,111,108,100,32,97,116,116,97,99,107,115,32,80,108,97,121,101,114,32,98,117,116,32,100,111,101,115,32,110,111,32,100,97,109,97,103,101],[107,111,98,111,108,100,32,105,115,32,100,101,97,100,33],[80,108,97,121,101,114,32,97,116,116,97,99,107,115,32,107,111,98,111,108,100,32,102,111,114,32,49,32,112,111,105,110,116,115,32,111,102,32,100,97,109,97,103,101,33],[107,111,98,111,108,100,32,97,116,116,97,99,107,115,32,80,108,97,121,101,114,32,102,111,114,32,53,32,112,111,105,110,116,115,32,111,102,32,100,97,109,97,103,101,33],[80,108,97,121,101,114,32,97,116,116,97,99,107,115,32,107,111,98,111,108,100,32,98,117,116,32,100,111,101,115,32,110,111,32,100,97,109,97,103,101],[107,111,98,111,108,100,32,97,116,116,97,99,107,115,32,80,108,97,121,101,114,32,102,111,114,32,50,32,112,111,105,110,116,115,32,111,102,32,100,97,109,97,103,101,33],[80,108,97,121,101,114,32,97,116,116,97,99,107,115,32,107,111,98,111,108,100,32,98,117,116,32,100,111,101,115,32,110,111,32,100,97,109,97,103,101],[107,111,98,111,108,100,32,97,116,116,97,99,107,115,32,80,108,97,121,101,114,32,102,111,114,32,53,32,112,111,105,110,116,115,32,111,102,32,100,97,109,97,103,101,33],[80,108,97,121,101,114,32,97,116,116,97,99,107,115,32,107,111,98,111,108,100,32,102,111,114,32,52,32,112,111,105,110,116,115,32,111,102,32,100,97,109,97,103,101,33],[107,111,98,111,108,100,32,105,115,32,100,101,97,100,33]],"to_remove":[],"targeting":{"Field0":0,"Field1":0}}"""


    # store the unsaved refs (canvas, context, images)
    var cnv = game.canvas
    var cnt = game.context
    var imgs = game.images


    game = loadJS();
    # restore the refs
    game.canvas = cnv;
    game.context = cnt;
    game.images = imgs;
    input_handler.game = game;

    # fix references
    # naive way (a proper one would probably involve a e id => Entity ref lookup table)
    for e in game.entities:
        if not isNil(e.item):
            e.item.owner = e
        if not isNil(e.ai):
            e.ai.owner = e
        if not isNil(e.creature):
            e.creature.owner = e
        if not isNil(e.equipment):
            e.equipment.owner = e

    # fix player's ref, too
    game.player.creature.owner = game.player


    game.game_messages.add("Loaded game...");

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
    cstring("gfx/scroll_lightning.png"), #5
    cstring("gfx/scroll_fire.png"),
    cstring("gfx/mouseover.png"),
    cstring("gfx/stairs_down.png"),
    cstring("gfx/longsword.png"),
    cstring("gfx/chain_armor.png")]); #10

    # keys
    #  proc onKeyUp(event: Event) =
    #    processKeyUp(event.keyCode)

    proc onKeyDown(event: Event) =
        # prevent scrolling on arrow keys
        event.preventDefault();

        # avoids main loop desync between us and input handler when loading
        if event.keyCode == 81: # q
            loadGameNim();

        processKeyDown(event.keyCode, game);

    #  dom.window.addEventListener("keyup", onKeyUp)
    dom.window.addEventListener("keydown", onKeyDown)

    # place for main loop IF we need e.g. a visual loading bar