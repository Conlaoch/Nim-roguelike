import map, isometric

# https://stackoverflow.com/questions/2151084/map-a-2d-array-onto-a-1d-array
proc setTile*(tiles: var seq[int], x,y: int, width: int, id: int) =
  tiles[y * width + x] = id


proc generateMap*(width: int, height: int, pillars: seq[Vector2]): Map =
  var tiles: seq[int] = @[]
  for i in 0 .. <(width*height):
    tiles.add(1)


  for i in 0 ..< pillars.len:
    setTile(tiles, int(pillars[i].x), int(pillars[i].y), width, 0)

  # walls around
  for x in 0 ..< width:
    setTile(tiles, x, 0, width, 0)
    setTile(tiles, x, width-1, width, 0)

  for y in 0 ..< height:
    setTile(tiles, 0, y, width, 0)
    setTile(tiles, 0, height-1, width, 0)

  Map(
    width: width,
    height: height,
    tiles: tiles)

