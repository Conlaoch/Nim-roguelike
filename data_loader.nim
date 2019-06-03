# Nim bindings for data loader

import jsffi

proc loadfile*(file: cstring) {.importc.}

proc load_files*(files:seq[cstring]) {.importc.}

proc get_loaded*() : JsObject {.importc.} #seq[JsObject] {.importc.}