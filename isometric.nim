type
    Vector2* = tuple[x: int, y: int]

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