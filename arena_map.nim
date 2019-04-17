import map, math_helpers
import entity, alea

# https://stackoverflow.com/questions/2151084/map-a-2d-array-onto-a-1d-array
proc setTile*(tiles: var seq[int], x,y: int, width: int, id: int) =
  tiles[y * width + x] = id


proc generateMap*(width: int, height: int, pillars: seq[Vector2]): Map =
  var tiles: seq[int] = @[]
  for i in 0 .. <(width*height):
    tiles.add(1)


  for i in 0 ..< pillars.len:
    setTile(tiles, int(pillars[i].x), int(pillars[i].y), width, 0)

  # walls around
  for x in 0 ..< width:
    setTile(tiles, x, 0, width, 0)
    setTile(tiles, x, height-1, width, 0)

  for y in 0 ..< height:
    setTile(tiles, 0, y, width, 0)
    setTile(tiles, 0, height-1, width, 0)

  Map(
    width: width,
    height: height,
    tiles: tiles)


proc place_entities*(map: Map, entities: var seq[Entity], max: int, max_items: int) =
    var rng = aleaRNG();
    # Get a random number of monsters
    var num = rng.range(1..max);
    # Get a random number of items
    var num_items = rng.range(1..max_items);

    # taking a shortcut here: this map is rectangular so we can just place in rectangle
    for i in (1..num):
      # Choose a random location in the map
      let x = rng.range(1..(map.height - 1))
      let y = rng.range(1..(map.width - 1))

      var mon = Entity(position:(x,y), image:3, name:"kobold");
      echo("Spawned monster at " & $mon.position);
      # creature component
      var creat = Creature(owner:mon, hp:5, max_hp:5, defense:30, attack:20);
      mon.creature = creat;
      # AI component
      var AI_comp = AI(owner:mon);
      mon.ai = AI_comp;
      entities.add(mon);

    for i in (1..num_items):
      # Choose a random location in the map
      let x = rng.range(1..(map.height - 2))
      let y = rng.range(1..(map.width - 2))

      var en_it = Entity(position:(x,y), image:4);
      echo("Spawned item at " & $en_it.position);
      # item component
      var it = Item();
      en_it.item = it;
      entities.add(en_it);