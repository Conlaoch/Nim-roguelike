import dom
import json

import game_class, entity, math_helpers, map_common
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
    
    # honor dialogue state
    if game.game_state == GUI_S_DIALOGUE.int:
        return
    else:
        # advance time
        game.calendar.turn += 1;

        game.game_state = ENEMY_TURN.int

proc pickupNim() {.exportc.} =
    if game.game_state == PLAYER_TURN.int:
        var it = get_items_at(game.level.entities, game.player.position.x, game.player.position.y)
        if not isNil(it):
            it.item.pick_up(game.player, game);
        else:
            game.game_messages.add(("No item to pick up here", (255,255,255)));
    # end turn regardless
    # advance time
    game.calendar.turn += 1;        
    game.game_state = ENEMY_TURN.int


proc showInventoryKeypad() =
    # dom magic
    dom.document.getElementById("keypad").style.display = "none";
    dom.document.getElementById("inventory_keypad").style.display = "block";

    var target = getInventoryKeypad();
    # these need to be created on the fly, depending on how many items we have...
    # Nim ranges are inclusive!
    for i in 0 .. game.player.inventory.items.len-1:
        createButton(target, i, cstring("inventorySelectNim"));

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
            # advance time
            game.calendar.turn += 1;
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
        # advance time
        game.calendar.turn += 1;
        game.game_state = ENEMY_TURN.int

proc showCharacterSheetNim() {.exportc.} =
    # remember previous state
    game.previous_state = game.game_state
    # we can't name it inventory because Nim enums do not need to be qualified with their type
    game.game_state = GUI_S_CHARACTER.int

proc quitCharacterSheet() =
    # switch back to player turn
    game.game_state = game.previous_state

proc quitTextMenu() =
    # switch back to player turn
    #game.game_state = PLAYER_TURN.int
    game.game_state = GUI_S_CHARACTER_CREATION.int

proc quitDialogue() =
    # hide keypad
    hideInventoryKeypad();

    # switch back to player turn
    game.game_state = game.previous_state

    if game.talking_data.action != "":
        echo "Action: " & $game.talking_data.action

    if game.talking_data.action == "shop":
        if game.shop_data.items.len > 0:
            # go to shop gui
            game.game_state = GUI_S_SHOP.int

proc showDialogueKeypad() =
    # dom magic
    dom.document.getElementById("keypad").style.display = "none";
    dom.document.getElementById("inventory_keypad").style.display = "block";

    var target = getInventoryKeypad();
    # these need to be created on the fly, depending on how many items we have...
    # Nim ranges are inclusive!
    for i in 0 .. game.talking_data.cr.chat.answers.len-1:
        createButton(target, i, cstring("dialogueSelectNim"));

# helper
proc findDialogueText(id: string) : string =
    for t in game.talking_data.cr.chat.texts:
        if t.id == id:
            return t.text

    return ""

proc dialogueSelectNim(index:int) {.exportc.} =
    # initial
    if game.talking_data.chat == game.talking_data.cr.chat.start:
        var sel = game.talking_data.cr.chat.answers[index]
        #echo $sel

        # dialogue actions
        game.talking_data.action = $sel.action

        # display new text if any
        echo $sel.reply
        var text = findDialogueText($sel.reply);
        if text != "":
            game.talking_data.chat = text #sel.reply
            # refresh keys
            hideInventoryKeypad();
            showDialogueKeypad();
        else:
            echo "Reply not found"
            # quit
            quitDialogue();

    else:
        #quit 
        quitDialogue();

# for JS
proc quitButtonNim() {.exportc.} =
    # contextual
    if game.game_state == GUI_S_INVENTORY.int or game.game_state == GUI_S_DROP.int:
        quitInventoryNim();
    elif game.game_state == GUI_S_CHARACTER.int:
        quitCharacterSheet();
    elif game.game_state == GUI_S_DIALOGUE.int:
        quitDialogue();
    elif game.game_state == GUI_S_TEXT.int:
        quitTextMenu();


proc saveGameNim() {.exportc.} = 
    echo "Saving game test..."

    game.game_messages.add(("Saving game...", (255,255,255)))

    # Nim 0.19.4 seems to have a bug in its marshal library, and manually serializing is a PITA, so... 
    # head over to JS side
    saveJS(game);


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

proc restNim {.exportc.} =
    game.player.player.rest_start(30, game);


proc showLookAroundNim() {.exportc.} =
    # remember previous state
    game.previous_state = game.game_state

    # set initial target to our position
    game.targeting = game.player.position

    game.game_state = LOOK_AROUND.int

    # keypad
    # dom magic
    dom.document.getElementById("keypad").style.display = "none";
    dom.document.getElementById("targeting_keypad").style.display = "block";

proc showMessageHistoryNim() {.exportc.} =
    # set scroll values
    var begin = 0
    if game.game_messages.len > 26:
        begin = game.game_messages.len - 25;
    game.message_log_index = (begin, game.game_messages.len);
    # remember previous state
    game.previous_state = game.game_state
    # we can't name it inventory because Nim enums do not need to be qualified with their type
    game.game_state = GUI_S_MESSAGE_LOG.int

proc quitMessageHistory() =
    # switch back to player turn
    game.game_state = game.previous_state

proc scrollMessageHistory(diff: int) =
    # do nothing if we'd scroll past 0 or past the end
    if game.message_log_index[0] + diff > 0 and game.message_log_index[1] + diff < game.game_messages.len:
        game.message_log_index[0] += diff
        game.message_log_index[1] += diff

proc toggleLabelsNim() {.exportc.} =
    # toggle
    game.labels = not game.labels

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
        of 82: restNim() # r
        of 73: showInventoryNim() # i
        of 68: showDropNim() # d
        of 67: showCharacterSheetNim() # c
        of 88: showLookAroundNim() # x
        of 83: saveGameNim() # s
        # loading handled in main.nim # q
        of 13: nextLevel() # enter
        of 9: toggleLabelsNim() # tab
        of 77: showMessageHistoryNim() # m
        else:
          echo key

proc processInventoryKey(key: int, game:Game) =
    # 65 is the int value returned for 'a' key
    let index = key - 65
    if 0 <= index and index < game.player.inventory.items.len:
        inventorySelectNim(index);
    
    elif key == 27: # escape
        quitInventoryNim()

proc processDialogueKey(key: int, game:Game) =
    # 65 is the int value returned for 'a' key
    let index = key - 65
    if 0 <= index and index < game.talking_data.cr.chat.answers.len:
        dialogueSelectNim(index);

    elif key == 27: # escape
        var act = game.talking_data.cr.chat.answers
        quitDialogue()

proc multiColumnSelectNim(index:int, col:int) {.exportc.} =
    if len(game.multicolumn_sels) < game.multicolumn_total:
        var id = index
        if game.multicolumn_col > 0:
            # 2 is hardcoded for now - we need a way to know how many entries per column
            id = id - 2;

        game.multicolumn_sels.add((id, col));

proc toggleColumnNim(game: Game) =
    echo $game.multicolumn_col & " " & $game.multicolumn_total
    if game.multicolumn_col < game.multicolumn_total-1:
        game.multicolumn_col += 1
    else:
        game.multicolumn_col = 0

proc processCharacterCreationKey(key: int, game:Game) =
    # 65 is the int value returned for 'a' key
    let index = key - 65

    var start = 0;
    # 2 is hardcoded for now - we need a way to know how many entries per column
    if game.multicolumn_col > 0:
        start = 2

    if start <= index and index < start + 2: 
        multiColumnSelectNim(index, game.multicolumn_col);

    if key == 9: #tab
        toggleColumnNim(game);
    
    # debug purposes
    if key == 27: #esc
        game.game_state = PLAYER_TURN.int

# targeting mode keys
proc moveTargetNim(x:int, y:int) {.exportc.} =
    echo "Move target " & $x & " " & $y;
    game.targeting = game.targeting+(x,y)

proc confirmTargetNim() {.exportc.} =
    if game.game_state == TARGETING.int:
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
        # do nothing if sleeping
        if not game.player.player.resting:
            processPlayerTurnKey(key, game)
      elif game.game_state == GUI_S_INVENTORY.int or game.game_state == GUI_S_DROP.int:
        processInventoryKey(key, game)
      elif game.game_state == TARGETING.int or game.game_state == LOOK_AROUND.int:
        processTargetingKey(key, game)
      elif game.game_state == GUI_S_CHARACTER.int:
        if key == 27 or key == 67:
            quitCharacterSheet();
      elif game.game_state == GUI_S_DIALOGUE.int:
            processDialogueKey(key, game);
      elif game.game_state == GUI_S_MESSAGE_LOG.int:
        if key == 27 or key == 77:
            quitMessageHistory();
        if key == 40: # down
            scrollMessageHistory(1);
        if key == 38: # up
            scrollMessageHistory(-1);
      elif game.game_state == GUI_S_TEXT.int:
        if key == 27:
            quitTextMenu();
      elif game.game_state == GUI_S_CHARACTER_CREATION.int or game.game_state == GUI_S_SHOP.int:
        processCharacterCreationKey(key, game);
      else:
        echo "Not player turn"