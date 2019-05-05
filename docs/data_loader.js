var loaded = []
var promise;


//https://stackoverflow.com/questions/19706046/how-to-read-an-external-local-json-file-in-javascript?noredirect=1&lq=1
function readTextFile(file, callback) {
    var rawFile = new XMLHttpRequest();
    rawFile.overrideMimeType("application/json");
    rawFile.open("GET", file, true);
    rawFile.onreadystatechange = function() {
        if (rawFile.readyState === 4 && rawFile.status == "200") {
            callback(rawFile.responseText);
        }
    }
    rawFile.send(null);
}

function loadfile(file){
    var data = "";
    promise = new Promise (function(resolve, reject){
        readTextFile(file+".json", function(text){
             data = JSON.parse(text);
             loaded.push(data);
             //console.log(data);
             console.log(loaded);
             resolve("file loaded OK!");
        });
    });

    promise.then(
        function(result) {
            console.log(result); // "Stuff worked!"
            //call Nim
            onReadyNimCallback();
          }, 
          function(err) {
            console.log(err); // Error: "It broke"
          }
    )
}


function get_loaded(){
    return loaded;
}