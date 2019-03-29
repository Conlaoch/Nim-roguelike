proc isoPos*(x,y:int): (int, int)  =
    # isometric
    let offset_x = 80
    let tile_x = (x - y) * 4 + offset_x
    let tile_y = (x + y) * 1
  
    return (int(tile_x),
      int(tile_y))