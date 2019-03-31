import dom
import html5_canvas

import entity, math_helpers, map


# this is Nim's class equivalent (a type and methods which have it as a parameter)
type
    Game* = ref object
        mx, my: int
        canvas*: Canvas
        context*: CanvasRenderingContext2D
        images*: seq[ImageElement]
        player*: Player
        map*: Map

proc newGame*(canvas: Canvas) : Game =
    new result
    result.canvas = canvas
    result.context = canvas.getContext2D()

proc clearGame*(game: Game) =
    game.context.fillStyle = rgb(0,0,0);
    game.context.fillRect(0, 0, game.canvas.width.float, game.canvas.height.float)


# -----------
# pretty much just drawing functions from here down
proc renderGfxTile*(game: Game, img: Element, x,y: int) =
    game.context.drawImage((ImageElement)img, float(x), float(y));

proc render*(game: Game, player: Player) =
    let iso = isoPos(player.position.x, player.position.y);
    # entities need a slight offset to be placed more or less centrally
    renderGfxTile(game, game.images[0], iso[0]+8, iso[1]+8);

proc drawMapTile(game: Game, point:Vector2, tile: int) =
    if tile == 0:
        renderGfxTile(game, game.images[1], point.x, point.y);
    else:
        renderGfxTile(game, game.images[2], point.x, point.y)

proc renderMap*(game: Game, map: Map) =
    # 0..x is inclusive in Nim
    for x in 0..<map.width:
        for y in 0..<map.height:
            #echo map.tiles[y * map.width + x]
            drawMapTile(game, isoPos(x,y), map.tiles[y * map.width + x])