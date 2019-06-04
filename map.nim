import algorithm # for sorting

import math_helpers, alea

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

proc get_free_tiles*(inc_map: Map) : seq[Vector2] =
    var free_tiles: seq[Vector2]
    for t in 0..inc_map.tiles.len-1:
        if inc_map.tiles[t] != 0:
            # inversion from # https://stackoverflow.com/questions/2151084/map-a-2d-array-onto-a-1d-array
            var x = t mod inc_map.width
            var y = (t - t mod inc_map.width) div inc_map.width;
            free_tiles.add((x,y))
    return free_tiles

proc random_free_tile*(inc_map:Map) : Vector2 =
    var free_tiles = get_free_tiles(inc_map)
    var rng = aleaRNG();
    var index = rng.range(0..len(free_tiles)-1)
    #print("Index is " + str(index))
    var x = free_tiles[index][0]
    var y = free_tiles[index][1]
    echo("Coordinates are " & $x & " " & $y)
    return (x, y)

proc find_grid_in_range*(map: Map, dist: int, x: int, y: int) : seq[Vector2] =
    echo("Looking for grids in range " & $dist & " of " & $x & " " & $y);
    var coord_in_range : seq[Vector2]
    var tmp: seq[tuple[x: int, y: int, dist: int]]

    for i in (x-dist..x+dist):
        for j in (y-dist..y+dist):
            if i > 0 and i < map.width and j > 0 and j < map.height:
                var dist = distance_to((x,y), (i,j));
                tmp.add((i, j, dist))
                
    # sort
    tmp.sort do (x,y: tuple[x:int, y:int, dist:int]) -> int:
        result = cmp(x.dist, y.dist);
    
    for e in tmp:
        coord_in_range.add((e.x, e.y));
    
    return coord_in_range