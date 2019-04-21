# Bindings for JS save functions
import game_class

# ideally would be generic (object or ref object...)
proc saveJS*(obj: Game) {.importc.}

# has to return cstring otherwise it doesn't print back correctly
proc loadStrBack*(str: cstring) : cstring {.importc.}


proc loadJS*() : Game {.importc.}

# see save above
proc loadJSNim*(s:string) : Game {.importc.}
