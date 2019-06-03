//it's 2019, use a proper map! (ES 6 feature [!])
var loaded = new Map();
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
    return new Promise (function(resolve, reject){
        readTextFile(file+".json", function(text){
             data = JSON.parse(text);
             loaded.set(file, data);
             //loaded.push(data);
             //console.log(data);
             console.log(loaded);
             resolve("file loaded OK!");
        });
    });

    // promise.then(
    //     function(result) {
    //         console.log(result); // "Stuff worked!"
    //         //call Nim
    //         onReadyNimCallback();
    //       }, 
    //       function(err) {
    //         console.log(err); // Error: "It broke"
    //       }
    // )
}

//wrapper for Nim to call
function load_files(files_array){
    //https://stackoverflow.com/questions/49744707/how-to-use-promise-all-on-array-of-promises-which-take-parameters
    Promise.all(
        files_array.map(  //map location to promise
            file => loadfile(file))) // promises
            .then(results => { 
                // executed when all promises resolved, 
                // results is the array of results resolved by the promises
                console.log(results);
                //call Nim
                onReadyNimCallback();
            })
            .catch(err => {  
            // catch if single promise fails to resolve
            console.log(err);
            });
};


function get_loaded(){
    //console.log(Array.from(loaded));
    //Nim doesn't understand the Map type, so convert...
    return Array.from(loaded);
    //return loaded;
}