import dom

import game_class, entity
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

proc showInventoryNim() {.exportc.} =
    # remember previous state
    game.previous_state = game.game_state
    # we can't name it inventory because Nim enums do not need to be qualified with their type
    game.game_state = GUI_S_INVENTORY.int

    # dom magic
    dom.document.getElementById("keypad").style.display = "none";
    dom.document.getElementById("inventory_keypad").style.display = "block";

    var target = getInventoryKeypad();
    # these need to be created on the fly, depending on how many items we have...
    # Nim ranges are inclusive!
    for i in 0 .. game.player.inventory.items.len-1:
        createButton(target, i);

proc quitInventoryNim() {.exportc.} = 
    if game.game_state == GUI_S_INVENTORY.int:
        # go back to previous state
        game.game_state = game.previous_state

        # dom magic
        dom.document.getElementById("keypad").style.display = "block";
        dom.document.getElementById("inventory_keypad").style.display = "none";
    
        var target = getInventoryKeypad();
        removeAll(target);

proc inventorySelectNim(index:int) {.exportc.} =
    #echo $index & " is a valid inventory entry"
    var item = game.player.inventory.items[index]
    #echo "Item is " & $item.owner.name
    if item.use_item(game.player):
        game.game_messages.add($game.player.name & " uses " & $item.owner.name);
        # quit inventory menu
        quitInventoryNim();
        # end turn      
        game.game_state = ENEMY_TURN.int
    else:
        game.game_messages.add($item.owner.name & " cannot be used!");




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
        else:
          echo key

proc processInventoryKey(key: int, game:Game) =
    # 65 is the int value returned for 'a' key
    let index = key - 65
    if 0 <= index and index < game.player.inventory.items.len:
        inventorySelectNim(index);
    
    elif key == 27: # escape
        quitInventoryNim()

# main key input handler
proc processKeyDown*(key: int, game:Game) =
      if game.game_state == PLAYER_TURN.int:
        processPlayerTurnKey(key, game)
      elif game.game_state == GUI_S_INVENTORY.int:
        processInventoryKey(key, game)
      else:
        echo "Not player turn"