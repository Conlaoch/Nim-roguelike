import dom
import html5_canvas

import resources

type
    Game = ref object
        mx, my: int
        canvas: Canvas
        context: CanvasRenderingContext2D
        images: seq[ImageElement]

proc newGame(canvas: Canvas) : Game =
    new result
    result.canvas = canvas
    result.context = canvas.getContext2D()

proc clearGame(game: Game) =
    game.context.fillStyle = rgb(0,0,0);
    game.context.fillRect(0, 0, game.canvas.width.float, game.canvas.height.float)

proc renderGfxTile(game: Game, img: Element, x,y: int) =
    game.context.drawImage((ImageElement)img, float(x*32), float(y*32));


# we need to specify our own %#^%$@ type so that we can work as a callback 
# in onReady()
proc ready(canvas: Canvas) : proc(canvas:Canvas) =
    echo ("We've done loading, ready");

    # moved from main
    # initial setup
    var game = newGame(canvas);
    game.clearGame();

    game.images.add(resources.get("gfx/human_m.png"));
    echo game.images.len

    # test
    renderGfxTile(game, game.images[0], 0, 0);

proc onReadyNim() {.exportc.} =
    echo "Calling Nim from JS";
    let canvas = dom.document.getElementById("canvas").Canvas
    discard ready(canvas);

# setup canvas
dom.window.onload = proc(e: dom.Event) =
  let canvas = dom.document.getElementById("canvas").Canvas
  canvas.width = 800
  canvas.height = 600

  # load assets
  # do we need this?
  var ress = initLoader(dom.window);
  # we have to force cstring conversion for some reason
  resources.load(@[cstring("gfx/human_m.png")]);

#   # initial setup
#   var game = newGame(canvas);
#   game.clearGame();

