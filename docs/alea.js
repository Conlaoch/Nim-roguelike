// Original from http://baagoe.com/en/RandomMusings/javascript/
function aleaRNG() {
    return (function(args) {
      // Johannes Baagøe <baagoe@baagoe.com>, 2010
      var s0 = 0;
      var s1 = 0;
      var s2 = 0;
      var c = 1;
  
      if (args.length == 0) {
        args = [+new Date];
      }
  
      /* private: initializes generator with specified seed */
      function _initState( _internalSeed ) {
        var mash = Mash();
        
        s0 = mash( ' ' );
        s1 = mash( ' ' );
        s2 = mash( ' ' );

        c = 1;

        for( var i = 0; i < _internalSeed.length; i++ ) {
            s0 -= mash( _internalSeed[ i ] );
            if( s0 < 0 ) { s0 += 1; }

            s1 -= mash( _internalSeed[ i ] );
            if( s1 < 0 ) { s1 += 1; }
            
            s2 -= mash( _internalSeed[ i ] );
            if( s2 < 0 ) { s2 += 1; }
        }

        mash = null;
      };

      var random = function() {
        var t = 2091639 * s0 + c * 2.3283064365386963e-10; // 2^-32
        s0 = s1;
        s1 = s2;
        var ret = s2 = t - (c = t | 0) 
        //console.log("Random() " + ret);
        return ret;
      };


      random.version = 'Alea 0.9';
      random.args = args;
      //actually init the bloody RNG
      _initState(args);

      //console.log("RNG: " + random);
      return random;
  
    } (Array.prototype.slice.call(arguments)));
  };

//moved to be top_level functions so that Nim bindings can work
uint32 = function(random) {
  return random() * 0x100000000; // 2^32
};
fract53 = function(random) {
  return random() + 
    (random() * 0x200000 | 0) * 1.1102230246251565e-16; // 2^-53
};

/* private: check if number is integer */
function _isInteger( _int ) { 
  return parseInt( _int ) === _int; 
};

/* public: return inclusive range */
range = function(random, nums) { 
  //console.log("Random range " + nums.a + " " + nums.b);
  var loBound
      , hiBound
  ;
  
  //bit of a rework since nums is now explicitly a parameter
  //more generic (doesn't work in <IE8)
  if( Object.keys(nums).length === 1 ) {
      loBound = 0;
      hiBound = nums.a;

  } else {
      loBound = nums.a;
      hiBound = nums.b;
  }

  if( nums.a > nums.b ) { 
      loBound = nums.a;
      hiBound = nums.b;
  }
  //console.log(loBound + " " + hiBound);
  // return integer
  if( _isInteger( loBound ) && _isInteger( hiBound ) ) {
      var ret = Math.floor( random() * ( hiBound - loBound + 1 ) ) + loBound
      console.log("Returning int " + ret);
      return ret;

  // return float
  } else {
      return random() * ( hiBound - loBound ) + loBound; 
  }
};

//Based on https://github.com/skeeto/rng-js/blob/master/rng.js
roller = function(random, expr) {
  var parts = expr.split(/(\d+)?d(\d+)([+-]\d+)?/).slice(1);
  var dice = parseFloat(parts[0]) || 1;
  var sides = parseFloat(parts[1]);
  var mod = parseFloat(parts[2]) || 0;
  console.log("dice: " + dice + " d " + sides + " sides");
  var total = mod;
  for (var i = 0; i < dice; i++) {
      var num = range(random, {a:sides});
      //console.log("num:" + num);
      total += num;
  };
  console.log("Roller returns: " + total);
  return total;
};

//private - moved for readability
function Mash() {
    var n = 0xefc8249d;

    var mash = function( data ) {
        data = data.toString();
        for( var i = 0, l = data.length; i < l; i++ ) {
            n += data.charCodeAt( i );
            var h = 0.02519603282416938 * n;
            n = h >>> 0;
            h -= n;
            h *= n;
            n = h >>> 0;
            h -= n;
            n += h * 0x100000000; // 2^32
        }
        return ( n >>> 0 ) * 2.3283064365386963e-10; // 2^-32
    };

    return mash;
};