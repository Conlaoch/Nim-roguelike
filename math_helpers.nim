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

proc intersects*(r: Rect2, p_rect: Rect2) : bool =
    if (r.x >= (p_rect.x + p_rect.w)):
        return false;
    if ((r.x + r.w) <= p_rect.x):
        return false;
    if (r.y >= (p_rect.y + p_rect.h)):
        return false;
    if ((r.y + r.h) <= p_rect.y):
        return false;

    return true;


# x,y are positions in map coordinates
proc isoPos*(x:int,y:int, offset:Vector2): (int, int)  =
    # isometric
    # those values work for Gervais isometric tiles
    let HALF_TILE_HEIGHT = 16
    let HALF_TILE_WIDTH = 32
    # lets us see the whole 15x15 map 
    # which is, incidentally, the biggest map that we can fit on 800x600 canvas
    #let offset_x = 360 
    let tile_x = offset.x + (x - y) * HALF_TILE_WIDTH
    let tile_y = offset.y + (x + y) * HALF_TILE_HEIGHT
  
    return (int(tile_x),
      int(tile_y))