//
//  Common.js
//  JSTP
//
//  Created by Andrew Visotskyy on 9/1/16.
//  Copyright © 2016 Andrew Visotskyy. All rights reserved.
//

var common = {};

common.extend = function (object, extension) {

   for (var property in extension) {
      object[property] = extension[property];
   }

   return object;
};

common.serializer = function (types) {

   function serialize(object) {

      var type;

           if (object instanceof Array) type = 'array';
      else if (object instanceof Date ) type = 'date';
      else if (object === null        ) type = 'undefined';
      else                              type = typeof object;

      return serialize.types[type](object);
   }

   serialize.types = common.extend ({

      undefined: function (arg) { return 'undefined'; },
      boolean:   function (arg) { return String(arg); },
      number:    function (arg) { return String(arg); },
      string:    function (arg) { return '\'' + arg.replace(/'/g, '\\\'') + '\''; },
      array:     function (arg) { return '[' + arg.map(serialize).join(',') + ']'; },
      
      object: function(arg) {
            
         var keys = Object.keys(arg);
         var array = [];

         keys.forEach(function(key, index) {
            
            var representation = serialize(arg[key]);

            if (representation !== 'undefined') {
                array.push(key + ':' + representation);
            }
         });

         return '{' + array.join(',') + '}';	
      }

   }, types);

   return serialize;
};

var stringify = common.serializer ({
   function: function(arg) { return 'undefined'; },
   date:     function(arg) { return '\'' + arg.toISOString().split('T')[0] + '\''; }
});

function Packet(kind, id, iface, verb, args) {

   this[kind] = [id];
   this[verb] = args;

   if (iface) {
      this[kind].push(iface);
   }
}

