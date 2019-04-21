//https://stackoverflow.com/questions/11616630/json-stringify-avoid-typeerror-converting-circular-structure-to-json
const getCircularReplacer = () => {
    const seen = new WeakSet();
    return (key, value) => {
      if (typeof value === "object" && value !== null) {
        if (seen.has(value)) {
          //get name of the object being referenced so that we can visually identify it in the dump
          return "@" + loadStrBack(value.name, false);
        }
        seen.add(value);
      }
      return value;
    };
  };


function saveJS(object) {
    var json = JSON.stringify(object, getCircularReplacer());
    console.log(json);
    //save to local storage
    localStorage.setItem("save", json);
}

// the strings coming from Nim are arrays of char codes under the hood
function loadStrBack(chars, js) {
  if (js){
    chars = JSON.parse(chars);
  }
  else{
    var str = String.fromCharCode.apply(null, chars);
    return str;
  }
}

function loadJS() {
    var save = localStorage.getItem('save');
    var obj = JSON.parse(save);
    console.log(obj);
    return obj;
}


function loadJSNim(json) {
    //unf&^k the json if coming from Nim
    var json = String.fromCharCode.apply(null, json);
    var obj = JSON.parse(json);
    console.log(obj);
    return obj;
}