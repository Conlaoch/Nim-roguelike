# Nim bindings for Alea

type
    AleaRNG* = ref object

# init
proc aleaRNG*(): AleaRNG {.importc.}


proc seed*(random: AleaRNG, seed:int) {.importc.}

proc range*(random: AleaRNG, interval: Slice[int]) : int {.importc.}

#proc rangeNim*(random:AleaRNG, interval: Slice[int]) : int =
#    return range(random, interval);

