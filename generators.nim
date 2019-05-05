import data_loader
import jsffi # to be able to do stuff with the data we loaded from JS side
import type_defs


# globals
var items_data: JsObject;

proc load_files*() =
    # test
    data_loader.loadfile("/data/items");

proc generateItem(id:string) =
    echo "Generate item with id: " & $id

    if not isNil(items_data[id]):
        var item_name = to(items_data[id]["name"], cstring);
        echo $item_name;

        var num_dice = to(items_data[id]["damage_number"], int);
        var damage_dice = to(items_data[id]["damage_dice"], int)
        
        # test
        var x = 1
        var y = 1

        var en_it = Entity(position:(x,y), image:9, name: $item_name);
        # item component
        var it = Item(owner:en_it);
        en_it.item = it;
        # equipment component
        var eq = Equipment(owner:en_it, num_dice: num_dice, damage_dice:damage_dice);
        en_it.equipment = eq;

        echo("Created item: " & $en_it.name & " " & $en_it.equipment.num_dice & " " & $en_it.equipment.damage_dice);

        #entities.add(en_it);
    else:
        echo("No item with id " & $id);



proc onReadyNimCallback*() {.exportc.} = 
    echo "Callback!"
    var data = data_loader.get_loaded();
    
    items_data = data[0];

    #  debugging    
    # for k, v in data[0]:
    #     echo $k
    #     for i in v.keys:
    #         echo $i 

    #for k in data[0].keys:
    #    echo $k

    # test
    generateItem("longsword");


