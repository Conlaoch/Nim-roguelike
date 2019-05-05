import data_loader
import jsffi # to be able to do stuff with the data we loaded from JS side
import type_defs


# globals
var items_data*: JsObject;

proc load_files*() =
    # test
    data_loader.loadfile("/data/items");

proc generateItem*(id:string, x: int, y:int) : Entity =
    echo "Generate item with id: " & $id

    if isNil(items_data[id]):
        echo("No item with id " & $id);
        return nil

    else:
        var item_name = to(items_data[id]["name"], cstring);
        echo $item_name;

        var num_dice = to(items_data[id]["damage_number"], int);
        var damage_dice = to(items_data[id]["damage_dice"], int);

        var en_it = Entity(position:(x,y), image:9, name: $item_name);
        # item component
        var it = Item(owner:en_it);
        en_it.item = it;
        # equipment component
        var eq = Equipment(owner:en_it, num_dice: num_dice, damage_dice:damage_dice);
        en_it.equipment = eq;

        echo("Created item: " & $en_it.name & " " & $en_it.equipment.num_dice & " " & $en_it.equipment.damage_dice);

        return en_it;

proc getData*() : seq[JsObject] =
    var data = data_loader.get_loaded();

    return data

# the callback on loading all data files was moved to main.nim


