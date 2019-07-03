import html5_canvas, times

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
        player*: Entity
        level*: Level
        recalc_FOV*: bool
        FOV_map*: seq[Vector2]
        camera*: Camera
        game_state*: int # because enums are ints by default
        previous_state*: int # for GUI windows to know what to go back to
        game_messages*: seq[GameMessage]
        # list of entities to be deleted
        to_remove*: seq[Entity]
        targeting*: Vector2
        factions*: seq[Faction]
        # similar to to_remove above
        rem_eff*: seq[Effect]
        calendar*: Calendar
        labels*: bool
        # UI-specific things because nowhere to put them
        talking_data*: tuple [cr: Creature, chat: string, action: string]
        message_log_index*: tuple [begin: int, ending: int]
        shop_data*: tuple [items: seq[Entity]]
        # this really ought to go somewhere
        multicolumn_col*: int
        multicolumn_total*: int # how many columns in total
        multicolumn_wanted*: int # how many keypresses do we want?
        multicolumn_sels*: seq[MulticolumnSel]

    Level* = ref object
        map*: Map
        explored*: seq[Vector2]
        entities*: seq[Entity]
        # special effects need to be cleared after changing levels, too
        effects*: seq[Effect]

    GameState* = enum
        PLAYER_TURN, ENEMY_TURN, PLAYER_DEAD, 
        GUI_S_INVENTORY, GUI_S_DROP, TARGETING, GUI_S_CHARACTER, LOOK_AROUND, GUI_S_DIALOGUE, GUI_S_MESSAGE_LOG, GUI_S_TEXT, GUI_S_CHARACTER_CREATION, GUI_S_CHARACTER_STATS, GUI_S_SHOP

    GameMessage* = tuple[s:string, c:ColorRGB]    

    Faction* = tuple[f1:string, f2:string, react:int]

    #Effect* = tuple[id:string, start: Time, interval: TimeInterval, x:int, y:int, param:int]
    Effect* = ref object
        id*: string
        start*: Time
        interval*: TimeInterval
        x*: int
        y*: int
        param*: int

    Dialogue* = ref object
        start*: string
        answers*: seq[DialogueReply]
        texts*: seq[DialogueText]

    DialogueReply* = tuple[chat:string, reply:string, action: string]
    DialogueText* = tuple[id:string, text:string]

    Calendar* = ref object
        days*: int
        start_year*: int
        start_day*: int
        start_hour*: int
        turn*: int

    MulticolumnSel* = tuple[id: int, col:int]

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
        player*: Player
    
    Player* = ref object
        # back ref to entity
        owner*: Entity
        resting*: bool
        rest_cnt*: int
        rest_turns*: int
        nutrition*: float
        thirst*: float
        money*: seq[Money]

    # this is an object because tuples are immutable...
    Money* = ref object
        kind*: string
        amount*: int

    Creature* = ref object
        # back ref to entity
        owner*: Entity
        # combat stuff
        hp*: int
        max_hp*: int
        defense*: int
        attack*: int
        # stats 
        base_str*: int
        base_dex*: int
        base_con*: int
        base_int*: int
        base_wis*: int
        base_cha*: int
        # making the world more interesting...
        faction*: string
        text*: string
        chat*: Dialogue
        languages*: seq[string]
        # skills
        dodge*: int
        melee*: int
        # flag
        dead*: bool
        body_parts*: seq[BodyPart]

    BodyPart* = ref object
        part*: string
        hp*: int
        max_hp*: int

    AI* = ref object
        # back reference to entity
        owner*: Entity

    Item* = ref object
        # back reference to entity
        owner*: Entity
        # optional
        use_func*: FuncHandler
        targeting*: bool
        price*: int
    
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