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