import map, math_helpers
import type_defs, entity, alea
import use_functions
import generators

# Find the global center of a Rect2
proc center(rect : Rect2) : Vector2 =
    var x = int(rect.w / 2)
    var y = int(rect.h / 2)
    return (rect.x, rect.y) + (x,y)
    
    
# Get Vector2's along x1 - x2, y
proc hline(x1, x2, y:int) : seq[Vector2] =
    var line : seq[Vector2]
    for x in (min(x1,x2) .. max(x1,x2)):
        line.add((x,y))
    return line

# Get Vector2's along x, y1 - y2
proc vline(y1, y2, x:int) : seq[Vector2] =
    var line : seq[Vector2]
    for y in (min(y1,y2) .. max(y1,y2)):
        line.add((x,y))
    return line


proc generateMap*(width=20, height=20, room_size: Vector2=(3,5)): (Map, Vector2) =

    var start_pos: Vector2
    var rooms: seq[Rect2]

    var tiles: seq[int] = @[]
    # fill with walls
    for i in 0 ..< (width*height):
        tiles.add(0)

    var rng = aleaRNG();
    for r in 0 .. 30:
        # Roll Random Room Rect
        # Width & Height
        # No overlapping rooms
        var w = rng.range((room_size.x+1)..room_size.y+1)
        var h = rng.range((room_size.x+1)..room_size.y+1)
        # Origin (top-left corner)
        var x = rng.range(0..width - w - 1)
        var y = rng.range(0..height - h - 1)
        
        # Construct Rect2
        var new_room = Rect2(x:x, y:y, w:w, h:h)
        #echo("room: x " & $x & " y:" & $y & " w: " & $w & " h: " & $h);
        
        # Check against existing rooms for intersection
        if rooms.len > 0:
            var passed = true
            for other_room in rooms:
                # If we intersect any other rooms..
                if new_room.intersects( other_room ):
                    echo "Intersects"
                    # don't add to rooms list
                    passed = false
            if passed: 
                rooms.add(new_room)
        # Add the first room
        else:   
            rooms.add(new_room)
        
    # Process generated rooms
    for i in 0 .. rooms.len-1:
        var room = rooms[i]
        echo("room: " & $room.x & " y: " & $room.y & " w " & $room.w & " h: " & $room.h)
        # Carve room
        for x in 0 .. (room.w - 2):
            for y in 0 .. (room.h - 2):
                setTile(tiles, room.x+x+1, room.y+y+1, width, 1) # floor
                
    # Tunnels
        if i == 0:
            # First room
            # Define the start_pos in the first room
            start_pos = center(room)
            echo "Start pos: " & $start_pos
        else:
            # Carve a hall between this room and the last room
            var prev_room = rooms[i-1]
            var A = center(room)
            var B = center(prev_room)

            # Flip a coin..
            if rng.randint32() mod 2 == 0:
                # carve vertical -> horizontal hall
                for cell in hline( A.x, B.x, A.y ):
                    setTile(tiles, cell.x,cell.y, width, 1) # floor
                for cell in vline( A.y, B.y, B.x ):
                    setTile(tiles, cell.x, cell.y, width, 1) # floor
            else:
                # carve horizontal -> vertical hall
                for cell in vline( A.y, B.y, A.x ):
                    setTile(tiles, cell.x, cell.y, width, 1) # floor
                for cell in hline( A.x, B.x, B.y ):
                    setTile(tiles, cell.x, cell.y, width, 1) #floor_id

            # Spawning
            #place_monsters(room)
        
            if i == rooms.len-1:
                echo("Last room")
                # place stairs
                var cent = center(room)
                setTile(tiles, cent.x,cent.y, width, 2) #stairs
            
        # items
        #place_items(room)

    (Map(
        width: width,
        height: height,
        tiles: tiles),
    start_pos)



