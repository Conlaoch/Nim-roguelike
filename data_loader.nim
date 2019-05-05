# Nim bindings for data loader

import jsffi


proc loadfile*(file: cstring) {.importc.}

proc get_loaded*() : seq[JsObject] {.importc.}