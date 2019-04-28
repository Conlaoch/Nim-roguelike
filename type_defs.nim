import html5_canvas

import math_helpers, map, FOV, tint_image

import camera

# Solution to Game <-> Entity dependency that plagued the tutorial
# In Nim mutually recursive types can only be declared within a single type section
type
    # From game_class
    Game* = ref object
        mx, my: int
        canvas*: Canvas
        context*: CanvasRenderingContext2D
        images*: seq[ImageElement]
        player*: Player
        map*: Map
        recalc_FOV*: bool
        FOV_map*: seq[Vector2]
        explored*: seq[Vector2]
        camera*: Camera
        entities*: seq[Entity]
        game_state*: int # because enums are ints by default
        previous_state*: int # for GUI windows to know what to go back to
        game_messages*: seq[string]
        # list of entities to be deleted
        to_remove*: seq[Entity]
        targeting*: Vector2

    GameState* = enum
        PLAYER_TURN, ENEMY_TURN, PLAYER_DEAD, GUI_S_INVENTORY, GUI_S_DROP, TARGETING

    GameMessage* = tuple[s:string, c:ColorRGB]    

    # From entity.nim
    Entity* = ref object
        position*: Vector2
        image*: int # the index of the tile in game.images
        # small caps for type string!
        name*: string
        # optional components
        creature*: Creature
        ai*: AI
        item*: Item
        equipment*: Equipment
        inventory*:Inventory
    
    Player* = Entity

    Creature* = ref object
        # back ref to entity
        owner*: Entity
        # combat stuff
        hp*: int
        max_hp*: int
        defense*: int
        attack*: int
        # flag
        dead*: bool

    AI* = ref object
        # back reference to entity
        owner*: Entity

    Item* = ref object
        # back reference to entity
        owner*: Entity
        # optional
        use_func*: FuncHandler
        targeting*: bool
    
    Equipment* = ref object
        # back reference to entity
        owner*: Entity
        slot*: string
        equipped*: bool
        num_dice*: int
        damage_dice*: int
        attack_bonus*: int
        defense_bonus*: int

    Inventory* = ref object
        # back reference to entity
        owner*: Entity
        capacity*: int
        items*: seq[Item]

    # in Nim, the easiest way to call a function is to assign a dummy type
    FuncHandler* = proc(i:Item, e:Entity, g:Game)