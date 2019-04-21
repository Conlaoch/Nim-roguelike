//https://stackoverflow.com/questions/11616630/json-stringify-avoid-typeerror-converting-circular-structure-to-json
const getCircularReplacer = () => {
    const seen = new WeakSet();
    return (key, value) => {
      if (typeof value === "object" && value !== null) {
        if (seen.has(value)) {
          return;
        }
        seen.add(value);
      }
      return value;
    };
  };


function saveJS(object) {
    var json = JSON.stringify(object, getCircularReplacer());
    console.log(json);
}

// the strings coming from Nim are arrays of char codes under the hood
function loadStrBack(chars) {
    chars = JSON.parse(chars);
    var str = String.fromCharCode.apply(null, chars);
    return str;
}


function loadJS(json) {
    //unf&^k the json
    var json = String.fromCharCode.apply(null, json);
    var obj = JSON.parse(json);
    console.log(obj);
    return obj;
}