import dom
import html5_canvas

type
    ColorRGB* = tuple[r:int, g:int, b:int]


proc tintImage(image:ImageElement, color:cstring, opacity:float) : Canvas {.importc.}

proc tintImageNim*(image:ImageElement, color:ColorRGB, opacity:float) : Canvas =
    # build a JS RGB string from ints
    var col_s = "rgb( " & $color.r & ", " & $color.g & ", " & $color.b&")";
    tintImage(image, col_s, opacity);