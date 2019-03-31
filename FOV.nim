import map, math_helpers

# Helpers

# Construct a rectangle around origin with radius distance to an edge
proc get_fov_rect(origin:Vector2, radius:int) : Rect2 =
    var x = origin.x - radius
    var y = origin.y - radius
    var s = 1+(radius*2)
    return Rect2(x:x,y:y,w:s,h:s)

# Check for wall index in datamap cell
proc is_wall(map:Map, wall_index:int, cell:Vector2) : bool =
    return map.tiles[cell.y * map.width + cell.x] == wall_index


# Returns an array of cells that lie
# under the from map cell to map cell
proc get_line(from_cell:Vector2,to:Vector2) : seq[Vector2] =
    # setup
    var x1 = from_cell.x
    var y1 = from_cell.y
    var x2 = to.x
    var y2 = to.y
    var dx = x2 - x1
    var dy = y2 - y1

    
    # determine steepness of line
    var is_steep = abs(dy) > abs(dx)
    # rotate line if steep
    if is_steep:
        # swap x1/y1
        var ox = x1
        x1 = y1
        y1 = ox 
        # swap x2/y2
        ox = x2
        x2 = y2
        y2 = ox

    # swap start points if needed
    var swapped = false
    if x1 > x2:
        # swap x1/x2
        var ox = x1
        x1 = x2
        x2 = ox
        # swap y1/y2
        var oy = y1
        y1 = y2
        y2 = oy
        swapped = true
    
    # recalculate differentials
    dx = x2-x1
    dy = y2-y1
    
    # calculate error
    var error = int(float(dx) / float(2.0))
    var ystep = -1 
    if y1 < y2:
        ystep = 1
    
    # iterate over bounding box generating points between
    var y = y1
    var points: seq[Vector2];
    for x in x1..x2:
        var coord = (x,y) 
        if is_steep:
            coord = (y,x)
        points.add(coord)
        error -= abs(dy)
        if error < 0:
            y += ystep
            error += dx
    
    var ret = points
    # reverse list if coordinates were swapped
    if swapped:
        # alas, my reverse implementation is not in-place
        ret = points.reverse()

    return ret

# Cast a fov line, stopping at first blocking cell
proc cast_fov_ray(map:Map,wall_index:int,from_cell:Vector2,to:Vector2) : seq[Vector2] =
    var cells: seq[Vector2];
    var line = get_line(from_cell,to);
    for cell in line:
        var m_height = map.tiles.len div map.width;
        if -1 < cell.x and cell.x <= map.width and -1 < cell.y and cell.y <= m_height:
            # Check for blocking cell
            if not is_wall(map, wall_index, cell):
                cells.add(cell)
            else:
                # include the blocking cell in the list
                cells.add(cell)
                return cells
    return cells

# Main function!!!
# Calculates an array of cells within the FOV of the origin within radius range
#  wall_index= int which represents a sight-blocker
#  origin= origin cell to cast FOV from
#  radius= distance in cells to cast to (only cells within radius are considered)

# returns a seq of Vector2
proc calculate_fov*(map:Map, wall_index:int, origin:Vector2, radius:int) : seq[Vector2] =
    echo("Calculating fov for : " & $origin & " r: " & $radius & " " & $wall_index);
    var rect = get_fov_rect(origin, radius)
    var cells: seq[Vector2];
    #var data = map.tiles
    # scan top edge
    for x in rect.x..rect.x+rect.w-1:
        var V = (x,rect.y)
        var line = cast_fov_ray(map,wall_index,origin,V)
        for cell in line:
            #if not cell in cells:
            if cells.find(cell) == -1:
                if cell.distance_to(origin) <= radius:
                    cells.add(cell)
    # scan bottom edge
        V = (x,rect.y+rect.h-1)
        line = cast_fov_ray(map,wall_index,origin,V)
        for cell in line:
            #if not cell in cells:
            if cells.find(cell) == -1:
                if cell.distance_to(origin) <= radius:
                    cells.add(cell)
    # scan left edge
    for y in rect.y..rect.h+rect.y:
        var V = (rect.x, y)
        var line = cast_fov_ray(map,wall_index,origin,V)
        for cell in line:
            #if not cell in cells:
            if cells.find(cell) == -1:
                if cell.distance_to(origin) <= radius:
                    cells.add(cell)
    #scan right edge
        V = (rect.w+rect.x-1, y)
        line = cast_fov_ray(map,wall_index,origin,V)
        for cell in line:
            #if not cell in cells:
            if cells.find(cell) == -1:
                if cell.distance_to(origin) <= radius:
                    cells.add(cell)
    
    # to avoid modifying while iterating
    var res = cells;
    for cell in res:
        if not is_wall(map, wall_index, cell):
            for x in -1..2:
                for y in -1..2:
                    var ncell = cell+(x,y)
                    echo ncell
                    var m_height = map.height
                    #var m_height = map.tiles.len div map.width;
                    if -1 < ncell.x and ncell.x <= map.width and -1 < ncell.y and ncell.y <= m_height:
                        if is_wall(map, wall_index, ncell) and int(ncell.distance_to(origin)) <= radius:
                            cells.add(ncell)

    return cells