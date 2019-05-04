# Nim bindings for data loader

proc loadfile*(file: cstring) : cstring {.importc.}