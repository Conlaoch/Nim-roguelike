import dom

import game_class, entity, math_helpers
import table_tools

# global stuff goes here
# needed because key handlers ref Game
var game*: Game;

# stubs to be called from JS by JQuery onclick()
# and by the key input
proc moveUpNim() {.exportc.} =
    if game.game_state == PLAYER_TURN.int and game.player.move(0, -1, game.map, game.entities, game.game_messages):
        game.recalc_FOV = true
    game.game_state = ENEMY_TURN.int

proc moveDownNim() {.exportc.} =
    if game.game_state == PLAYER_TURN.int and game.player.move(0, 1, game.map, game.entities, game.game_messages):
        game.recalc_FOV = true
    game.game_state = ENEMY_TURN.int

proc moveLeftNim() {.exportc.} =
    if game.game_state == PLAYER_TURN.int and game.player.move(-1, 0, game.map, game.entities, game.game_messages):
        game.recalc_FOV = true
    game.game_state = ENEMY_TURN.int

proc moveRightNim() {.exportc.} =
    if game.game_state == PLAYER_TURN.int and game.player.move(1, 0, game.map, game.entities, game.game_messages):
        game.recalc_FOV = true
    game.game_state = ENEMY_TURN.int

proc moveLeftUpNim() {.exportc.} =
    if game.game_state == PLAYER_TURN.int and game.player.move(-1, -1, game.map, game.entities, game.game_messages):
        game.recalc_FOV = true
    game.game_state = ENEMY_TURN.int

proc moveRightUpNim() {.exportc.} =
    if game.game_state == PLAYER_TURN.int and game.player.move(1, -1, game.map, game.entities, game.game_messages):
        game.recalc_FOV = true
    game.game_state = ENEMY_TURN.int

proc moveLeftDownNim() {.exportc.} =
    if game.game_state == PLAYER_TURN.int and game.player.move(-1, 1, game.map, game.entities, game.game_messages):
        game.recalc_FOV = true
    game.game_state = ENEMY_TURN.int

proc moveRightDownNim() {.exportc.} =
    if game.game_state == PLAYER_TURN.int and game.player.move(1, 1, game.map, game.entities, game.game_messages):
        game.recalc_FOV = true
    game.game_state = ENEMY_TURN.int

proc pickupNim() {.exportc.} =
    if game.game_state == PLAYER_TURN.int:
        var it = get_items_at(game.entities, game.player.position.x, game.player.position.y)
        if not isNil(it):
            it.item.pick_up(game.player);
            game.game_messages.add("Picked up item " & it.name);
            # because it's no longer on map
            game.entities.delete(game.entities.find(it));
        else:
            game.game_messages.add("No item to pick up here");
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
        if item.use_item(game.player):
            game.game_messages.add($game.player.name & " uses " & $item.owner.name);
            # quit inventory menu
            quitInventoryNim();
            # end turn      
            game.game_state = ENEMY_TURN.int
        # ugly hack because we can't use game stuff in entity.nim...
        elif item.owner.name == "lightning scroll":
            # cast lighting
            var tg = closest_monster(game.player, game.entities, game.FOV_map, 4);
            if isNil(tg):
                game.game_messages.add("No enemy is close enough to strike");
            else:
                tg.creature.take_damage(8);
                game.game_messages.add("A lightning bolt strikes " & $tg.name & " and deals 8 damage!");
            # destroy
            game.player.inventory.items.delete(game.player.inventory.items.find(item));
            # standard stuff
            game.game_messages.add($game.player.name & " uses " & $item.owner.name);
            # quit inventory menu
            quitInventoryNim();
            # end turn      
            game.game_state = ENEMY_TURN.int
        # handle targeting items
        elif item.targeting:
            # destroy
            game.player.inventory.items.delete(game.player.inventory.items.find(item));
            # standard stuff
            game.game_messages.add($game.player.name & " uses " & $item.owner.name);
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
            game.game_messages.add($item.owner.name & " cannot be used!");

    if game.game_state == GUI_S_DROP.int:
        item.drop(game.player);
        game.entities.add(item.owner);
        game.game_messages.add("You dropped the " & $item.owner.name);
        # quit inventory menu
        quitInventoryNim();
        # end turn      
        game.game_state = ENEMY_TURN.int


proc processPlayerTurnKey(key: int, game:Game) =
    case key:
        of 37: moveLeftNim()   #left
        of 39: moveRightNim()     #right
        of 38: moveUpNim()      #up
        of 40: moveDownNim()   #down
        # vim
        of 72: moveLeftNim() # h
        of 76: moveRightNim() # l
        of 74: moveDownNim() # j
        of 75: moveUpNim() # k
        # diagonals
        of 89: moveLeftUpNim() # y
        of 85: moveRightUpNim() # u
        of 66: moveLeftDownNim() # b
        of 78: moveRightDownNim() # n
        # others
        of 71: pickupNim() # g
        of 73: showInventoryNim() # i
        of 68: showDropNim() # d
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
    var tg = get_creatures_at(game.entities, game.targeting.x, game.targeting.y);
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