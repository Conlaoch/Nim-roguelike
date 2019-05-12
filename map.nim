type
    Map* = object
        # we use seq because we're not sure how many tiles a map will have
        # and int because it will make it easier to save/load
        # we'll have to do some lookup magic for e.g. blocking, though
        # seq is a 1D collection
        tiles*: seq[int]
        width*, height*: int
  
# trick from https://github.com/zacharycarter/NimRL
proc `[]`*(map: Map, x, y: int): int =
    map.tiles[y * map.width + x]

# https://stackoverflow.com/questions/2151084/map-a-2d-array-onto-a-1d-array
proc setTile*(tiles: var seq[int], x,y: int, width: int, id: int) =
    tiles[y * width + x] = id

# general functions
proc is_blocked*(map: Map, x,y: int) : bool =
    if map.tiles[y * map.width + x] == 0:
        return true
    else:
        return false

proc is_stairs*(map: Map, x,y:int) : bool =
    if map.tiles[y * map.width + x] == 2:
        return true
    else:
        return false