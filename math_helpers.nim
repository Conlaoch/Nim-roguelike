import math

type
    Vector2* = tuple[x: int, y: int]

    # based on Godot's, so x,y,w,h
    Rect2* = ref object
        x*: int
        y*: int
        w*: int
        h*: int

# return the distance to another object
proc distance_to*(start:Vector2, to:Vector2) : int =
    let dx = to.x - start.x;
    let dy = to.y - start.y;
    return int(math.sqrt(float(dx ^ 2 + dy ^ 2)));

proc `+`*(a:Vector2, b:Vector2) : Vector2 =
    (a.x + b.x, a.y + b.y)

# x,y are positions in map coordinates
proc isoPos*(x,y:int): (int, int)  =
    # isometric
    # those values work for Gervais isometric tiles
    let HALF_TILE_HEIGHT = 16
    let HALF_TILE_WIDTH = 32
    let offset_x = 80
    let tile_x = (x - y) * HALF_TILE_WIDTH + offset_x
    let tile_y = (x + y) * HALF_TILE_HEIGHT
  
    return (int(tile_x),
      int(tile_y))