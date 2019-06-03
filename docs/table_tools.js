

function createButton(target, i, fct){
    if (target.rows.length < 2){
        console.log("Inserting a second row");
        target = target.insertRow(1)
    }
    else{
        target = target.rows[1];
    }

    //yet another thing that Nim can't do itself
    var cell = target.insertCell();
    //iterate over char codes to get the letters
    var val = String.fromCharCode(97 + i);
    var btn = document.createElement("input");
    btn.type = "button";
    btn.value = val;
    btn.setAttribute('onclick', fct+"(this.value.charCodeAt(0)-97)");
    cell.appendChild(btn);
}

function getInventoryKeypad(){
    keypad = document.getElementById("inventory_keypad")
    //Nim cannot use rows or other special table props which make working with them easier
    target = keypad.childNodes[1];
    return target;
}

// target here refers to the table itself!
function removeAll(target) {
    target.deleteRow(1);
    console.log("deleted second row");
    // for (n =0;n < target.cells.length; n++){
    //     console.log(n);
    //     target.deleteCell(-1);
    // }

}