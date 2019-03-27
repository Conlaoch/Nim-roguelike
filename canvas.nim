import dom
import html5_canvas

type
    Game = ref object
        mx, my: int
        canvas: Canvas
        context: CanvasRenderingContext2D

proc newGame(canvas: Canvas) : Game =
    new result
    result.canvas = canvas
    result.context = canvas.getContext2D()

proc clearGame(game: Game) =
    game.context.fillStyle = rgb(0,0,0);
    game.context.fillRect(0, 0, game.canvas.width.float, game.canvas.height.float)

# setup canvas
dom.window.onload = proc(e: dom.Event) =
  let canvas = dom.document.getElementById("canvas").Canvas
  canvas.width = 800
  canvas.height = 600

  # initial setup
  var game = newGame(canvas);
  game.clearGame();


