import dom
import html5_canvas

import entity


# this is Nim's class equivalent (a type and methods which have it as a parameter)
type
    Game* = ref object
        mx, my: int
        canvas*: Canvas
        context*: CanvasRenderingContext2D
        images*: seq[ImageElement]
        player*: Player

proc newGame*(canvas: Canvas) : Game =
    new result
    result.canvas = canvas
    result.context = canvas.getContext2D()

proc clearGame*(game: Game) =
    game.context.fillStyle = rgb(0,0,0);
    game.context.fillRect(0, 0, game.canvas.width.float, game.canvas.height.float)

proc renderGfxTile*(game: Game, img: Element, x,y: int) =
    game.context.drawImage((ImageElement)img, float(x*32), float(y*32));

proc render*(game: Game, player: Player) =
    renderGfxTile(game, game.images[0], player.position.x, player.position.y);
    