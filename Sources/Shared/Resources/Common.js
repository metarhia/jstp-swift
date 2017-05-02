//
//  Common.js
//  JSTP
//
//  Created by Andrew Visotskyy on 9/1/16.
//  Copyright © 2016 Andrew Visotskyy. All rights reserved.
//

var common = {};

common.extend = function(object, extension) {
	for (var property in extension) {
		object[property] = extension[property];
	}
	return object;
};

common.escape = function(string) {
	var escapes = {
		'\\': '\\\\',
		'\'': '\\\'',
		'\n': '\\n',
		'\r': '\\r',
		'\u2028': '\\u2028',
		'\u2029': '\\u2029'
	};
	return string.replace(/['\\\n\r\u2028\u2029]/g, function(character) {
		return escapes[character];
	})
};

common.serializer = function(types) {

	function serialize(object) {
		var type;
		if (object instanceof Array) {
			type = 'array';
		} else if (object instanceof Date) {
			type = 'date';
		} else if (object === null) {
			type = 'null';
		} else {
			type = typeof object;
		}
		return serialize.types[type](object);
	}

	serialize.types = common.extend({
		null: function(arg) {
			return 'null';
		},
		undefined: function(arg) {
			return 'undefined';
		},
		boolean: function(arg) {
			return String(arg);
		},
		number: function(arg) {
			return String(arg);
		},
		string: function(arg) {
			return '\'' + common.escape(arg) + '\'';
		},
		array: function(arg) {
			return '[' + arg.map(serialize).join(',') + ']';
		},
		object: function(arg) {
			var keys = Object.keys(arg);
			var array = [];
			keys.forEach(function(key) {
				var representation = serialize(arg[key]);
				if (representation !== 'undefined') {
					array.push('"' + key + '":' + representation);
				}
			});
			return '{' + array.join(',') + '}';
		}
	}, types);
	
	return serialize;
};

var stringify = common.serializer({
	function: function(arg) {
		return 'undefined';
	},
	date: function(arg) {
		return '\'' + arg.toISOString().split('T')[0] + '\'';
	}
});

function Packet(kind, id, iface, verb, args) {
	this[kind] = iface ? [id, iface] : [id]
	if (verb) {
		this[verb] = args;
	}
}
