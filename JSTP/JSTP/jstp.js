var api = {};

api.common = {};

api.common.extend = function(obj, ext) {
   if (obj === undefined) obj = null;
   for (var property in ext) obj[property] = ext[property];
   return obj;
};

api.common.keys = function(object) {
   return Object.keys(object);
};

api.createSerializer = function(additionalTypes) {
   function serialize(obj, i, arr) {
      var type;
      if (obj instanceof Array) type = 'array';
      else if (obj instanceof Date) type = 'date';
      else if (obj === null) type = 'undefined';
      else type = typeof(obj);
      var fn = serialize.types[type];
      return fn(obj, arr);
   };
   
   serialize.types = api.common.extend({
      number: function(n) { return n + ''; },
      string: function(s) { return '\'' + s.replace(/'/g, '\\\'') + '\''; },
      boolean: function(b) { return b ? 'true' : 'false'; },
      undefined: function(u, arr) { return !!arr ? '' : 'undefined'; },
      array: function(a) {
         return '[' + a.map(serialize).join(',') + ']';
      },
      object: function(obj) {
      var a = [], s, key;
      for (key in obj) {
      s = serialize(obj[key]);
      if (s !== 'undefined') {
      a.push(key + ':' + s);
      }
      }
      return '{' + a.join(',') + '}';
      }
      }, additionalTypes);
   
   return serialize;
};

api.stringify = api.createSerializer({
    function: function() { return 'undefined'; },
      date: function(d) {
      return '\'' + d.toISOString().split('T')[0] + '\'';
    }
});

var Packet = function(kind, id, iface, verb, args) {
   
   this[kind] = [id];
   this[verb] = args;
   
   if (iface) {
      this[kind].push(iface);
   }
    
   console.log(stringify(this));
}

function serialize(kind, packet, interface, verb, args) {
   return api.stringify(new Packet(kind, packet, interface, verb, args));
}

function stringify(object) {
   return api.stringify(object);
}