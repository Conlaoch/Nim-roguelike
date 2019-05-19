import dom
import json

import game_class, entity, math_helpers
import table_tools, save
import type_defs

# for next level
import map, arena_map, FOV, camera

# global stuff goes here
# needed because key handlers ref Game
var game*: Game;

# functions to be called from JS by JQuery onclick()
# and by the key input
proc moveNim(x:int, y:int) {.exportc.} =
    if game.game_state == PLAYER_TURN.int and game.player.move(x, y, game, game.level.map, game.level.entities):
        game.camera.move(x,y);
        game.recalc_FOV = true
    game.game_state = ENEMY_TURN.int

proc pickupNim() {.exportc.} =
    if game.game_state == PLAYER_TURN.int:
        var it = get_items_at(game.level.entities, game.player.position.x, game.player.position.y)
        if not isNil(it):
            it.item.pick_up(game.player, game);
        else:
            game.game_messages.add(("No item to pick up here", (255,255,255)));
    # end turn regardless        
    game.game_state = ENEMY_TURN.int


proc showInventoryKeypad() =
    # dom magic
    dom.document.getElementById("keypad").style.display = "none";
    dom.document.getElementById("inventory_keypad").style.display = "block";

    var target = getInventoryKeypad();
    # these need to be created on the fly, depending on how many items we have...
    # Nim ranges are inclusive!
    for i in 0 .. game.player.inventory.items.len-1:
        createButton(target, i);

proc hideInventoryKeypad() = 
    # dom magic
    dom.document.getElementById("keypad").style.display = "block";
    dom.document.getElementById("inventory_keypad").style.display = "none";

    var target = getInventoryKeypad();
    removeAll(target);


proc showInventoryNim() {.exportc.} =
    # remember previous state
    game.previous_state = game.game_state
    # we can't name it inventory because Nim enums do not need to be qualified with their type
    game.game_state = GUI_S_INVENTORY.int

    showInventoryKeypad()

proc showDropNim {.exportc.} =
    game.previous_state = game.game_state
    # see above for why we have the "GUI_S_" prefix
    game.game_state = GUI_S_DROP.int

    showInventoryKeypad()

proc quitInventoryNim() {.exportc.} = 
    if game.game_state == GUI_S_INVENTORY.int or game.game_state == GUI_S_DROP.int:
        # go back to previous state
        game.game_state = game.previous_state

        hideInventoryKeypad();

proc inventorySelectNim(index:int) {.exportc.} =
    #echo $index & " is a valid inventory entry"
    var item = game.player.inventory.items[index]
    #echo "Item is " & $item.owner.name
    if game.game_state == GUI_S_INVENTORY.int:
        if item.use_item(game.player, game):
            game.game_messages.add(($game.player.name & " uses " & $item.owner.name, (255,255,255)));
            # quit inventory menu
            quitInventoryNim();
            # end turn      
            game.game_state = ENEMY_TURN.int
        # handle targeting items
        elif item.targeting:
            # destroy
            game.player.inventory.items.delete(game.player.inventory.items.find(item));
            # standard stuff
            game.game_messages.add(($game.player.name & " uses " & $item.owner.name, (255,255,255)));
            # quit inventory menu
            quitInventoryNim();

            # switch to targeting
            game.game_state = TARGETING.int
            # set initial target to our position
            game.targeting = game.player.position

            # keypad
            # dom magic
            dom.document.getElementById("keypad").style.display = "none";
            dom.document.getElementById("targeting_keypad").style.display = "block";

        else:
            game.game_messages.add(($item.owner.name & " cannot be used!", (255,0,0)));

    if game.game_state == GUI_S_DROP.int:
        item.drop(game.player, game);
        # quit inventory menu
        quitInventoryNim();
        # end turn      
        game.game_state = ENEMY_TURN.int


proc saveGameNim() {.exportc.} = 
    echo "Saving game test..."

    game.game_messages.add(("Saving game...", (255,255,255)))

    # Nim 0.19.4 seems to have a bug in its marshal library, and manually serializing is a PITA, so... 
    # head over to JS side
    saveJS(game);

# proc loadGameNim() =
#     echo "Load test"

#     # string obtained from a previous run of saveGameNim()
#     # it's a bit wasteful, especially the "Field0" and the strings being stored as arrays of char codes
#     var test = """{"mx":0,"my":0,"canvas":{},"context":{},"images":[{},{},{},{},{},{},{},{}],
#     "player":{"position":{"Field0":9,"Field1":10},"image":0,"name":[80,108,97,121,101,114],"creature":{"hp":4,"max_hp":20,"attack":40,"defense":30,"dead":false},"ai":null,"item":null,"inventory":{"capacity":26,"owner":null,"items":null}},"map":{"tiles":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"width":20,"height":20},"recalc_FOV":false,
#     "FOV_map":[{"Field0":9,"Field1":10},{"Field0":8,"Field1":9},{"Field0":7,"Field1":8},{"Field0":6,"Field1":7},{"Field0":8,"Field1":11},{"Field0":7,"Field1":12},{"Field0":6,"Field1":13},{"Field0":7,"Field1":7},{"Field0":8,"Field1":12},{"Field0":7,"Field1":13},{"Field0":8,"Field1":8},{"Field0":7,"Field1":6},{"Field0":9,"Field1":11},{"Field0":8,"Field1":13},{"Field0":7,"Field1":14},{"Field0":9,"Field1":9},{"Field0":8,"Field1":7},{"Field0":8,"Field1":6},{"Field0":9,"Field1":12},{"Field0":8,"Field1":14},{"Field0":9,"Field1":8},{"Field0":9,"Field1":7},{"Field0":9,"Field1":6},{"Field0":9,"Field1":13},{"Field0":9,"Field1":14},{"Field0":10,"Field1":8},{"Field0":10,"Field1":7},{"Field0":10,"Field1":6},{"Field0":10,"Field1":13},{"Field0":10,"Field1":14},{"Field0":10,"Field1":9},{"Field0":11,"Field1":7},{"Field0":11,"Field1":6},{"Field0":10,"Field1":12},{"Field0":11,"Field1":14},{"Field0":11,"Field1":8},{"Field0":10,"Field1":11},{"Field0":11,"Field1":13},{"Field0":12,"Field1":7},{"Field0":11,"Field1":12},{"Field0":12,"Field1":13},{"Field0":6,"Field1":8},{"Field0":11,"Field1":9},{"Field0":12,"Field1":8},{"Field0":7,"Field1":9},{"Field0":5,"Field1":8},{"Field0":10,"Field1":10},{"Field0":8,"Field1":10},{"Field0":6,"Field1":9},{"Field0":5,"Field1":9},{"Field0":7,"Field1":10},{"Field0":6,"Field1":10},{"Field0":5,"Field1":10},{"Field0":7,"Field1":11},{"Field0":6,"Field1":11},{"Field0":5,"Field1":11},{"Field0":6,"Field1":12},{"Field0":5,"Field1":12},{"Field0":11,"Field1":11},{"Field0":12,"Field1":12},{"Field0":10,"Field1":10},{"Field0":10,"Field1":10},{"Field0":10,"Field1":10},{"Field0":10,"Field1":10},{"Field0":10,"Field1":10},{"Field0":10,"Field1":10},{"Field0":10,"Field1":10},{"Field0":10,"Field1":10},{"Field0":10,"Field1":10},{"Field0":10,"Field1":10},{"Field0":10,"Field1":10},{"Field0":10,"Field1":10},{"Field0":10,"Field1":10},{"Field0":10,"Field1":10}],"explored":[{"Field0":0,"Field1":0},{"Field0":0,"Field1":1},{"Field0":0,"Field1":2},{"Field0":0,"Field1":3},{"Field0":0,"Field1":4},{"Field0":0,"Field1":5},{"Field0":1,"Field1":0},{"Field0":1,"Field1":1},{"Field0":1,"Field1":2},{"Field0":1,"Field1":3},{"Field0":1,"Field1":4},{"Field0":1,"Field1":5},{"Field0":2,"Field1":0},{"Field0":2,"Field1":1},{"Field0":2,"Field1":2},{"Field0":2,"Field1":3},{"Field0":2,"Field1":4},{"Field0":2,"Field1":5},{"Field0":3,"Field1":0},{"Field0":3,"Field1":1},{"Field0":3,"Field1":2},{"Field0":3,"Field1":3},{"Field0":3,"Field1":4},{"Field0":3,"Field1":5},{"Field0":4,"Field1":0},{"Field0":4,"Field1":1},{"Field0":4,"Field1":2},{"Field0":4,"Field1":3},{"Field0":4,"Field1":4},{"Field0":5,"Field1":0},{"Field0":5,"Field1":1},{"Field0":5,"Field1":2},{"Field0":5,"Field1":3},{"Field0":4,"Field1":5},{"Field0":5,"Field1":4},{"Field0":6,"Field1":0},{"Field0":6,"Field1":1},{"Field0":6,"Field1":2},{"Field0":6,"Field1":3},{"Field0":5,"Field1":5},{"Field0":6,"Field1":4},{"Field0":7,"Field1":0},{"Field0":7,"Field1":1},{"Field0":7,"Field1":2},{"Field0":7,"Field1":3},{"Field0":6,"Field1":5},{"Field0":7,"Field1":4},{"Field0":8,"Field1":0},{"Field0":8,"Field1":1},{"Field0":8,"Field1":2},{"Field0":8,"Field1":3},{"Field0":7,"Field1":5},{"Field0":8,"Field1":4},{"Field0":9,"Field1":0},{"Field0":9,"Field1":1},{"Field0":9,"Field1":2},{"Field0":9,"Field1":3},{"Field0":8,"Field1":5},{"Field0":9,"Field1":4},{"Field0":10,"Field1":0},{"Field0":10,"Field1":1},{"Field0":10,"Field1":2},{"Field0":10,"Field1":3},{"Field0":9,"Field1":5},{"Field0":10,"Field1":4},{"Field0":11,"Field1":0},{"Field0":11,"Field1":1},{"Field0":11,"Field1":2},{"Field0":11,"Field1":3},{"Field0":10,"Field1":5},{"Field0":11,"Field1":4},{"Field0":12,"Field1":0},{"Field0":12,"Field1":1},{"Field0":12,"Field1":2},{"Field0":12,"Field1":3},{"Field0":11,"Field1":5},{"Field0":12,"Field1":4},{"Field0":13,"Field1":0},{"Field0":13,"Field1":1},{"Field0":13,"Field1":2},{"Field0":13,"Field1":3},{"Field0":12,"Field1":5},{"Field0":13,"Field1":4},{"Field0":14,"Field1":0},{"Field0":14,"Field1":1},{"Field0":14,"Field1":2},{"Field0":14,"Field1":3},{"Field0":13,"Field1":5},{"Field0":14,"Field1":4},{"Field0":15,"Field1":0},{"Field0":15,"Field1":1},{"Field0":15,"Field1":2},{"Field0":15,"Field1":3},{"Field0":14,"Field1":5},{"Field0":15,"Field1":4},{"Field0":16,"Field1":0},{"Field0":16,"Field1":1},{"Field0":16,"Field1":2},{"Field0":16,"Field1":3},{"Field0":15,"Field1":5},{"Field0":16,"Field1":4},{"Field0":17,"Field1":0},{"Field0":17,"Field1":1},{"Field0":17,"Field1":2},{"Field0":17,"Field1":3},{"Field0":16,"Field1":5},{"Field0":17,"Field1":4},{"Field0":18,"Field1":0},{"Field0":18,"Field1":1},{"Field0":18,"Field1":2},{"Field0":18,"Field1":3},{"Field0":17,"Field1":5},{"Field0":18,"Field1":4},{"Field0":19,"Field1":0},{"Field0":19,"Field1":1},{"Field0":19,"Field1":2},{"Field0":19,"Field1":3},{"Field0":18,"Field1":5},{"Field0":19,"Field1":4},{"Field0":19,"Field1":5},{"Field0":16,"Field1":6},{"Field0":17,"Field1":6},{"Field0":18,"Field1":6},{"Field0":19,"Field1":6},{"Field0":15,"Field1":6},{"Field0":16,"Field1":7},{"Field0":17,"Field1":7},{"Field0":18,"Field1":7},{"Field0":19,"Field1":7},{"Field0":14,"Field1":6},{"Field0":15,"Field1":7},{"Field0":16,"Field1":8},{"Field0":17,"Field1":8},{"Field0":18,"Field1":8},{"Field0":19,"Field1":8},{"Field0":14,"Field1":7},{"Field0":15,"Field1":8},{"Field0":16,"Field1":9},{"Field0":17,"Field1":9},{"Field0":18,"Field1":9},{"Field0":19,"Field1":9},{"Field0":14,"Field1":8},{"Field0":15,"Field1":9},{"Field0":16,"Field1":10},{"Field0":17,"Field1":10},{"Field0":18,"Field1":10},{"Field0":19,"Field1":10},{"Field0":14,"Field1":9},{"Field0":15,"Field1":10},{"Field0":16,"Field1":11},{"Field0":17,"Field1":11},{"Field0":18,"Field1":11},{"Field0":19,"Field1":11},{"Field0":14,"Field1":10},{"Field0":15,"Field1":11},{"Field0":16,"Field1":12},{"Field0":17,"Field1":12},{"Field0":18,"Field1":12},{"Field0":19,"Field1":12},{"Field0":14,"Field1":11},{"Field0":15,"Field1":12},{"Field0":16,"Field1":13},{"Field0":17,"Field1":13},{"Field0":18,"Field1":13},{"Field0":19,"Field1":13},{"Field0":14,"Field1":12},{"Field0":15,"Field1":13},{"Field0":16,"Field1":14},{"Field0":17,"Field1":14},{"Field0":18,"Field1":14},{"Field0":19,"Field1":14},{"Field0":14,"Field1":13},{"Field0":15,"Field1":14},{"Field0":16,"Field1":15},{"Field0":17,"Field1":15},{"Field0":18,"Field1":15},{"Field0":19,"Field1":15},{"Field0":14,"Field1":14},{"Field0":15,"Field1":15},{"Field0":16,"Field1":16},{"Field0":17,"Field1":16},{"Field0":18,"Field1":16},{"Field0":19,"Field1":16},{"Field0":13,"Field1":10},{"Field0":13,"Field1":11},{"Field0":13,"Field1":12},{"Field0":13,"Field1":13},{"Field0":13,"Field1":14},{"Field0":14,"Field1":15},{"Field0":15,"Field1":16},{"Field0":12,"Field1":10},{"Field0":12,"Field1":11},{"Field0":12,"Field1":12},{"Field0":12,"Field1":13},{"Field0":12,"Field1":14},{"Field0":13,"Field1":9},{"Field0":13,"Field1":15},{"Field0":14,"Field1":16},{"Field0":11,"Field1":10},{"Field0":11,"Field1":11},{"Field0":11,"Field1":12},{"Field0":11,"Field1":13},{"Field0":11,"Field1":14},{"Field0":12,"Field1":9},{"Field0":12,"Field1":15},{"Field0":13,"Field1":8},{"Field0":13,"Field1":16},{"Field0":10,"Field1":10},{"Field0":10,"Field1":11},{"Field0":10,"Field1":12},{"Field0":10,"Field1":13},{"Field0":10,"Field1":14},{"Field0":11,"Field1":9},{"Field0":11,"Field1":15},{"Field0":12,"Field1":8},{"Field0":12,"Field1":16},{"Field0":9,"Field1":11},{"Field0":9,"Field1":12},{"Field0":9,"Field1":13},{"Field0":9,"Field1":14},{"Field0":10,"Field1":9},{"Field0":10,"Field1":15},{"Field0":11,"Field1":8},{"Field0":11,"Field1":16},{"Field0":8,"Field1":10},{"Field0":8,"Field1":11},{"Field0":8,"Field1":12},{"Field0":8,"Field1":13},{"Field0":8,"Field1":14},{"Field0":9,"Field1":10},{"Field0":9,"Field1":15},{"Field0":10,"Field1":8},{"Field0":10,"Field1":16},{"Field0":7,"Field1":10},{"Field0":7,"Field1":11},{"Field0":7,"Field1":12},{"Field0":7,"Field1":13},{"Field0":7,"Field1":14},{"Field0":8,"Field1":9},{"Field0":8,"Field1":15},{"Field0":9,"Field1":9},{"Field0":9,"Field1":16},{"Field0":6,"Field1":10},{"Field0":6,"Field1":11},{"Field0":6,"Field1":12},{"Field0":6,"Field1":13},{"Field0":6,"Field1":14},{"Field0":7,"Field1":9},{"Field0":7,"Field1":15},{"Field0":8,"Field1":8},{"Field0":8,"Field1":16},{"Field0":9,"Field1":8},{"Field0":5,"Field1":10},{"Field0":5,"Field1":11},{"Field0":5,"Field1":12},{"Field0":5,"Field1":13},{"Field0":5,"Field1":14},{"Field0":6,"Field1":9},{"Field0":6,"Field1":15},{"Field0":7,"Field1":8},{"Field0":7,"Field1":16},{"Field0":4,"Field1":10},{"Field0":4,"Field1":11},{"Field0":4,"Field1":12},{"Field0":4,"Field1":13},{"Field0":4,"Field1":14},{"Field0":5,"Field1":9},{"Field0":5,"Field1":15},{"Field0":6,"Field1":8},{"Field0":6,"Field1":16},{"Field0":7,"Field1":7},{"Field0":8,"Field1":7},{"Field0":9,"Field1":7},{"Field0":10,"Field1":7},{"Field0":5,"Field1":8},{"Field0":6,"Field1":7},{"Field0":7,"Field1":6},{"Field0":8,"Field1":6},{"Field0":9,"Field1":6},{"Field0":10,"Field1":6},{"Field0":11,"Field1":6},{"Field0":11,"Field1":7},{"Field0":12,"Field1":7},{"Field0":5,"Field1":7},{"Field0":6,"Field1":6},{"Field0":12,"Field1":6},{"Field0":13,"Field1":7}],"entities":[{"position":{"Field0":11,"Field1":17},"image":3,"name":[107,111,98,111,108,100],"creature":{"hp":5,"max_hp":5,"defense":30,"attack":20,"dead":false},"ai":{},"item":null,"inventory":null},{"position":{"Field0":7,"Field1":16},"image":4,"name":[112,111,116,105,111,110],"creature":null,"ai":null,"item":{"targeting":false},"inventory":null},{"position":{"Field0":4,"Field1":13},"image":5,"name":[108,105,103,104,116,110,105,110,103,32,115,99,114,111,108,108],"creature":null,"ai":null,"item":{"use_func":null,"targeting":false},"inventory":null},{"position":{"Field0":10,"Field1":16},"image":6,"name":[102,105,114,101,32,115,99,114,111,108,108],
#     "creature":null,"ai":null,"item":{"targeting":true,"use_func":null},"inventory":null}],"game_state":0,"previous_state":0,"game_messages":[[107,111,98,111,108,100,32,97,116,116,97,99,107,115,32,80,108,97,121,101,114,32,102,111,114,32,50,32,112,111,105,110,116,115,32,111,102,32,100,97,109,97,103,101,33],[107,111,98,111,108,100,32,97,116,116,97,99,107,115,32,80,108,97,121,101,114,32,98,117,116,32,100,111,101,115,32,110,111,32,100,97,109,97,103,101],[107,111,98,111,108,100,32,97,116,116,97,99,107,115,32,80,108,97,121,101,114,32,98,117,116,32,100,111,101,115,32,110,111,32,100,97,109,97,103,101],[107,111,98,111,108,100,32,97,116,116,97,99,107,115,32,80,108,97,121,101,114,32,102,111,114,32,49,32,112,111,105,110,116,115,32,111,102,32,100,97,109,97,103,101,33],[107,111,98,111,108,100,32,97,116,116,97,99,107,115,32,80,108,97,121,101,114,32,102,111,114,32,49,32,112,111,105,110,116,115,32,111,102,32,100,97,109,97,103,101,33],[80,108,97,121,101,114,32,97,116,116,97,99,107,115,32,107,111,98,111,108,100,32,102,111,114,32,54,32,112,111,105,110,116,115,32,111,102,32,100,97,109,97,103,101,33],[107,111,98,111,108,100,32,97,116,116,97,99,107,115,32,80,108,97,121,101,114,32,98,117,116,32,100,111,101,115,32,110,111,32,100,97,109,97,103,101],[107,111,98,111,108,100,32,105,115,32,100,101,97,100,33],[80,108,97,121,101,114,32,97,116,116,97,99,107,115,32,107,111,98,111,108,100,32,102,111,114,32,49,32,112,111,105,110,116,115,32,111,102,32,100,97,109,97,103,101,33],[107,111,98,111,108,100,32,97,116,116,97,99,107,115,32,80,108,97,121,101,114,32,102,111,114,32,53,32,112,111,105,110,116,115,32,111,102,32,100,97,109,97,103,101,33],[80,108,97,121,101,114,32,97,116,116,97,99,107,115,32,107,111,98,111,108,100,32,98,117,116,32,100,111,101,115,32,110,111,32,100,97,109,97,103,101],[107,111,98,111,108,100,32,97,116,116,97,99,107,115,32,80,108,97,121,101,114,32,102,111,114,32,50,32,112,111,105,110,116,115,32,111,102,32,100,97,109,97,103,101,33],[80,108,97,121,101,114,32,97,116,116,97,99,107,115,32,107,111,98,111,108,100,32,98,117,116,32,100,111,101,115,32,110,111,32,100,97,109,97,103,101],[107,111,98,111,108,100,32,97,116,116,97,99,107,115,32,80,108,97,121,101,114,32,102,111,114,32,53,32,112,111,105,110,116,115,32,111,102,32,100,97,109,97,103,101,33],[80,108,97,121,101,114,32,97,116,116,97,99,107,115,32,107,111,98,111,108,100,32,102,111,114,32,52,32,112,111,105,110,116,115,32,111,102,32,100,97,109,97,103,101,33],[107,111,98,111,108,100,32,105,115,32,100,101,97,100,33]],"to_remove":[],"targeting":{"Field0":0,"Field1":0}}"""

    # let jsonRes = parseJSON(test);
    # echo $jsonRes;

    # JSON module's to() cannot deal with type aliases... :(

    # test loading data
    # var loaded = jsonRes["game_state"].getInt()
    # echo $loaded

    # # test something more involved
    # var msgs = jsonRes["game_messages"]

    # # clear
    # if game.game_messages.len > 0:
    #     game.game_messages.setLen(0);

    # for e in msgs:
    #     # needs to be converted from JsonNode to string 
    #     var st = loadStrBack($e);
    #     # $cstring serves as a nice reverse of cstring(str)
    #     game.game_messages.add($st);

proc nextLevel() {.exportc.} =
    # are we on stairs?
    if game.level.map.is_stairs(game.player.position.x, game.player.position.y):
        game.game_messages.add(("You descend deeper in the dungeon", (127,0,255)))
        game.level = newLevel()
        # # clear entities list
        # if game.entities.len > 0:
        #     game.entities.setLen(0)
        # # clear explored list
        # if game.explored.len > 0:
        #     game.explored.setLen(0);
        # if game.effects.len > 0:
        #     game.effects.setLen(0);
        # generate new level
        game.level.map = arena_map.generateMap(15,15,@[(6,6)])
        arena_map.place_entities(game.level.map, game.level.entities, 3, 2);
        # set player pos
        game.player.position = (1,1);
        game.camera.center(game.player.position);
        # FOV
        game.recalc_FOV = true;
        game.FOV_map = calculate_fov(game.level.map, 0, game.player.position, 4);
    else:
        game.game_messages.add(("There are no stairs here", (255,255,255)));

proc processPlayerTurnKey(key: int, game:Game) =
    case key:
        of 37: moveNim(-1,0)   #left
        of 39: moveNim(1,0)     #right
        of 38: moveNim(0,-1)      #up
        of 40: moveNim(0,1)   #down
        # vim
        of 72: moveNim(-1,0) # h
        of 76: moveNim(1,0) # l
        of 74: moveNim(0,1) # j
        of 75: moveNim(0,-1) # k
        # diagonals
        of 89: moveNim(-1,-1) # y
        of 85: moveNim(1,-1) # u
        of 66: moveNim(-1,1) # b
        of 78: moveNim(1,1) # n
        # others
        of 71: pickupNim() # g
        of 73: showInventoryNim() # i
        of 68: showDropNim() # d
        of 83: saveGameNim() # s
        # loading handled in main.nim # q
        of 13: nextLevel() # enter
        else:
          echo key

proc processInventoryKey(key: int, game:Game) =
    # 65 is the int value returned for 'a' key
    let index = key - 65
    if 0 <= index and index < game.player.inventory.items.len:
        inventorySelectNim(index);
    
    elif key == 27: # escape
        quitInventoryNim()

# targeting mode keys
proc moveTargetNim(x:int, y:int) {.exportc.} =
    echo "Move target " & $x & " " & $y;
    game.targeting = game.targeting+(x,y)

proc confirmTargetNim() {.exportc.} =
    # damage the target
    var tg = get_creatures_at(game.level.entities, game.targeting.x, game.targeting.y);
    if not isNil(tg):
        tg.creature.take_damage(6);

    # keypad
    # dom magic
    dom.document.getElementById("keypad").style.display = "block";
    dom.document.getElementById("targeting_keypad").style.display = "none";

    # switch turn
    game.game_state = ENEMY_TURN.int

proc quitTargetingNim() {.exportc.} =
    # reset target
    game.targeting = game.player.position;
    # switch back to player turn
    game.game_state = PLAYER_TURN.int

    # keypad
    # dom magic
    dom.document.getElementById("keypad").style.display = "block";
    dom.document.getElementById("targeting_keypad").style.display = "none";

# the Python 3 tutorial uses mouse for targeting, but that is obviously desktop-only
# so we'll use keys (think of it as a look-mode)
proc processTargetingKey(key:int, game:Game) =
    case key:
        of 37: moveTargetNim(-1,0)   #left
        of 39: moveTargetNim(1,0)     #right
        of 38: moveTargetNim(0,-1)      #up
        of 40: moveTargetNim(0,1)   #down
        # vim
        of 72: moveTargetNim(-1,0) # h
        of 76: moveTargetNim(1,0) # l
        of 74: moveTargetNim(0,1) # j
        of 75: moveTargetNim(0,-1) # k
        # diagonals
        of 89: moveTargetNim(-1,-1) # y
        of 85: moveTargetNim(1,-1) # u
        of 66: moveTargetNim(-1,1) # b
        of 78: moveTargetNim(1,1) # n
        # confirm/quit
        of 27: quitTargetingNim() # escape
        of 13: confirmTargetNim() # enter
        else:
            echo key

# main key input handler
proc processKeyDown*(key: int, game:Game) =
      if game.game_state == PLAYER_TURN.int:
        processPlayerTurnKey(key, game)
      elif game.game_state == GUI_S_INVENTORY.int or game.game_state == GUI_S_DROP.int:
        processInventoryKey(key, game)
      elif game.game_state == TARGETING.int:
        processTargetingKey(key, game)
      else:
        echo "Not player turn"