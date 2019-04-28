import math_helpers

type
    Camera* = ref object
        position*: Vector2
        # this is for actually drawing on screen
        offset*: Vector2
        width*: int
        height*: int
        # these are for determining which tiles are in view
        start_xy*: int # X+Y
        end_xy*: int
        start_xminy*: int #X-Y for lack of a better name
        end_xminy*: int


proc calculate_extents*(cam:Camera) =
    # for a map centered at 15,15 with width, height of 4
    # X+Y is constant for all tiles in a row, and X-Y is constant for all tiles in a column
    # given the above, the top is at 11,11 (center-height) => X-Y is still 0
    # in other case, e.g. (14,16), if we go up, we decrease both by the same number, or increase if we go down
    # left hand side is at 11,19 (increase x by 4, decrease y by the same) => X+Y is still 30
    # right hand side is the opposite, (19,11) (increase y, decrease x)
    # do the same to the top: (11-4, 11+4) = 7,15 for left hand, (11+4,11-4) = 15,7 for right

    #var position_xminy = cam.position.x - cam.position.y;
    var top_position : Vector2 = (cam.position.x - cam.height, cam.position.y - cam.height);
    # decrease x, increase y to go left
    var top_left : Vector2 = (top_position.x - cam.width, top_position.y + cam.width);
    var bottom_pos : Vector2 = (cam.position.x + cam.height, cam.position.y + cam.height);
    #var bottom_left: Vector2 = (bottom_pos.x + cam.width, bottom_pos.y - cam.width);
    # increase x, decrease y to go to the right hand side
    var bottom_right : Vector2 = (bottom_pos.x + cam.width, bottom_pos.y - cam.width);

    cam.start_xy = top_position.x + top_position.y;
    cam.end_xy = bottom_pos.x + bottom_pos.y;

    cam.start_xminy = top_left.x - top_left.y;
    cam.end_xminy = bottom_right.x - bottom_right.y; 

    #echo("Start xy: " & $cam.start_xy & " end xy: " & $cam.end_xy & " s x-y: " & $cam.start_xminy & " end: " & $cam.end_xminy);


# Based on Python implementation
proc move(cam: Camera, dx:int, dy:int) =
    # those values work for Gervais isometric tiles
    let HALF_TILE_HEIGHT = 16
    let HALF_TILE_WIDTH = 32

    # if we increase map x by 1, draw coordinates increase by 1/2 tile width, 1/2 tile height
    # reverse that since we want the camera to stay in same place
    let x_change = (-HALF_TILE_WIDTH, -HALF_TILE_HEIGHT)
    # if we increase map y by 1, draw coordinates change by -1/2 tile_width, 1/2 tile height
    # reverse that since we want the camera to stay in one place
    let y_change = (HALF_TILE_WIDTH, -HALF_TILE_HEIGHT)

    var new_x = cam.offset[0] + x_change[0] * dx + y_change[0] * dy
    var new_y = cam.offset[1] + x_change[1] * dx + y_change[1] * dy

    cam.offset = (new_x, new_y) 