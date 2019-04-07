import dom
import html5_canvas

import resources, entity, game_class
import map, arena_map, FOV

# global stuff goes here
# needed because key handler refs Game
var game: Game;

# stubs to be called from JS by JQuery onclick()
# and by the key input
proc moveUpNim() {.exportc.} =
    if game.game_state == PLAYER_TURN.int and game.player.move(0, -1, game.map, game.entities):
        game.recalc_FOV = true
    game.game_state = ENEMY_TURN.int

proc moveDownNim() {.exportc.} =
    if game.game_state == PLAYER_TURN.int and game.player.move(0, 1, game.map, game.entities):
        game.recalc_FOV = true
    game.game_state = ENEMY_TURN.int

proc moveLeftNim() {.exportc.} =
    if game.game_state == PLAYER_TURN.int and game.player.move(-1, 0, game.map, game.entities):
        game.recalc_FOV = true
    game.game_state = ENEMY_TURN.int

proc moveRightNim() {.exportc.} =
    if game.game_state == PLAYER_TURN.int and game.player.move(1, 0, game.map, game.entities):
        game.recalc_FOV = true
    game.game_state = ENEMY_TURN.int

proc moveLeftUpNim() {.exportc.} =
    if game.game_state == PLAYER_TURN.int and game.player.move(-1, -1, game.map, game.entities):
        game.recalc_FOV = true
    game.game_state = ENEMY_TURN.int

proc moveRightUpNim() {.exportc.} =
    if game.game_state == PLAYER_TURN.int and game.player.move(1, -1, game.map, game.entities):
        game.recalc_FOV = true
    game.game_state = ENEMY_TURN.int

proc moveLeftDownNim() {.exportc.} =
    if game.game_state == PLAYER_TURN.int and game.player.move(-1, 1, game.map, game.entities):
        game.recalc_FOV = true
    game.game_state = ENEMY_TURN.int

proc moveRightDownNim() {.exportc.} =
    if game.game_state == PLAYER_TURN.int and game.player.move(1, 1, game.map, game.entities):
        game.recalc_FOV = true
    game.game_state = ENEMY_TURN.int

# main key input handler
proc processKeyDown(key: int, game:Game) =
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

      else: echo key

# we need to specify our own %#^%$@ type so that we can work as a callback 
# in onReady()
proc ready(canvas: Canvas) : proc(canvas:Canvas) =
    echo ("We've done loading, ready");

    # moved from main
    # initial setup
    game = newGame(canvas);
    game.clearGame();
    
    #echo $resources.getURLs();

    for k in resources.getURLs():
        echo $k;
        # for easier retrieval from Nim
        game.images.add(resources.get(k));
    
    #game.images.add(resources.get("gfx/human_m.png"));
    #echo game.images.len

    # test
    #renderGfxTile(game, game.images[0], 0, 0);

    # setup cd.
    game.player = Player(position: (1,1))
    game.player.creature = Creature(name:"Player", owner:game.player, hp: 20, max_hp:20, attack:40, defense:30);
    game.map = arena_map.generateMap(20,20,@[(10,10)])
    arena_map.place_entities(game.map, game.entities, 3)
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
        # AI turn
        if game.game_state == ENEMY_TURN.int:
            for entity in game.entities:
                if not isNil(entity.ai):
                    #echo("The " & entity.creature.name & " ponders the meaning of its existence.");
                    entity.ai.take_turn(game.player, game.FOV_map, game.map, game.entities);
            # trick to use actual enum's int value
            game.game_state = GameState.PLAYER_TURN.int

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
    # we have to force cstring conversion for some reason
    resources.load(@[cstring("gfx/human_m.png"), 
    cstring("gfx/wall_stone.png"),
    cstring("gfx/floor_cave.png"),
    cstring("gfx/kobold.png")]);

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