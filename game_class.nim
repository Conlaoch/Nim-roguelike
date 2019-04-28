import dom
import html5_canvas

import entity, math_helpers, map, tint_image, seq_tools

import camera

# type definition moved to type_defs
import type_defs

import tables

proc newGame*(canvas: Canvas) : Game =
    new result
    result.canvas = canvas
    result.context = canvas.getContext2D()
    result.explored = @[];
    result.game_state = PLAYER_TURN.int; # trick to use the int

proc gameMessage*(game:Game, msg:string) =
    game.game_messages.add(msg);

proc clearGame*(game: Game) =
    game.context.fillStyle = rgb(0,0,0);
    game.context.fillRect(0, 0, game.canvas.width.float, game.canvas.height.float)

# -----------
# pretty much just drawing functions from here down
proc renderGfxTile*(game: Game, img: Element, x,y: int) =
    game.context.drawImage((ImageElement)img, float(x), float(y));

proc render*(game: Game, player: Player) =
    # do nothing if dead
    if isNil(player):
        return
    let iso = isoPos(player.position.x, player.position.y);
    # entities need a slight offset to be placed more or less centrally
    renderGfxTile(game, game.images[0], iso[0]+8, iso[1]+8);

# Note: currently the player is rendered separately (see above)
proc renderEntities*(game: Game, fov_map:seq[Vector2]) =
    for e in game.entities:
        let iso = isoPos(e.position.x, e.position.y);
        # if we can actually see the NPCs
        if (e.position.x, e.position.y) in fov_map:
            # need a slight offset to be placed more or less centrally
            renderGfxTile(game, game.images[e.image], iso[0]+8, iso[1]+8);


var tile_lookup = {0: 1, 1:2, 2:8}.toTable()

proc drawMapTile(game: Game, point:Vector2, tile: int) =
    renderGfxTile(game, game.images[tile_lookup[tile]], point.x, point.y);

    # if tile == 0:
    #     renderGfxTile(game, game.images[1], point.x, point.y);
    # elif tile == 1:
    #     renderGfxTile(game, game.images[2], point.x, point.y);
    # elif tile == 2:
    #     renderGfxTile(game, game.images[8], point.x, point.y);

proc drawMapTileTint(game:Game, point:Vector2, tile:int, tint:ColorRGB) =
    game.context.drawImage(tintImageNim(game.images[tile_lookup[tile]], tint, 0.5), float(point.x), float(point.y));

    # if tile == 0:
    #     game.context.drawImage(tintImageNim(game.images[1], tint, 0.5), float(point.x), float(point.y));
    # else:
    #     game.context.drawImage(tintImageNim(game.images[2], tint, 0.5), float(point.x), float(point.y));

proc renderMap*(game: Game, map: Map, fov_map: seq[Vector2], explored: var seq[Vector2], cam: Camera) =    
    # isometric camera
    var x:int;
    var y:int;

    for a in cam.startxy..cam.endxy:
        for b in cam.startxminy..cam.endxminy:
            # integer division
            x = (a+b) div 2;
            y = (a-b) div 2;

            # weirdness check
            if x < 0 or y < 0 or x > map.width or y > map.height:
                # skip
                continue
    
    # 0..x is inclusive in Nim
    #for x in 0..<map.width:
    #    for y in 0..<map.height:
            #echo map.tiles[y * map.width + x]
            var cell = (x,y)
            if cell in fov_map:
                drawMapTile(game, isoPos(x,y), map.tiles[y * map.width + x])
                if explored.find(cell) == -1:
                    add(explored, cell);
            elif (x,y) in explored:
                drawMapTileTint(game, isoPos(x,y), map.tiles[y * map.width + x], (127,127,127));

proc drawMessages*(game:Game) = 
    var drawn: seq[string];
    # what do we draw?
    if game.game_messages.len <= 5:
        drawn = game.game_messages
    else:
        # fancy slicing similar to Python's
        var view = SeqView[string](data:game.game_messages, bounds: game.game_messages.len-5..game.game_messages.len-1);
        #echo "seqView: " & $view;

        for el in view:
            drawn.add(el);

    # draw
    var y = 0;
    for i in 0..drawn.len-1:
        var el = drawn[i];
        game.context.font = "12px Arial"
        game.context.fillStyle = rgb(255, 255, 255);
        fillText(game.context, el, 5.0, float(game.canvas.height-50+y));
        y += 10;

proc renderBar*(game:Game, x:int,y:int, total_width:int, value:int, maximum:int, bar_color:ColorRGB, bg_color:ColorRGB) =
    # draw the bg color
    game.context.beginPath();
    game.context.fillStyle = rgb(bg_color.r, bg_color.g, bg_color.b);
    game.context.rect(float(x),float(y), float(total_width), 10.0);
    game.context.fill();
        
    # calculate how big the actual bar is
    var perc = float(value)/float(maximum) * 100;
    #echo "v: " & $value & " perc: " & $perc;
    var bar_width = (perc / 100) * float(total_width);
    if bar_width > 0:
        game.context.beginPath();
        game.context.fillStyle = rgb(bar_color.r, bar_color.g, bar_color.b);
        game.context.rect(float(x), float(y), float(bar_width), 10.0);
        game.context.fill();

proc drawTargeting*(game:Game) =
    let iso = isoPos(game.targeting.x, game.targeting.y);
    renderGfxTile(game, game.images[7], iso[0], iso[1]);