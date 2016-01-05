// Generated by CoffeeScript 1.9.1
(function() {
  var D, Derives, U, Utils, _, concat, invoke, isAfter, isAlpha, isArguments, isArray, isAscii, isBefore, isCreditCard, isDate, isEmail, isEmpty, isFunction, isMongoId, isObject, isString, isUndefined, mapObj, slice, spreadOnlyArg, v, validator, xss;

  _ = require('lodash');

  v = validator = require('validator');

  xss = require('xss');

  isArray = _.isArray, isObject = _.isObject, isString = _.isString, isUndefined = _.isUndefined, isFunction = _.isFunction, isEmpty = _.isEmpty, isArguments = _.isArguments;

  isMongoId = v.isMongoId, isDate = v.isDate, isEmail = v.isEmail, isAlpha = v.isAlpha, isAscii = v.isAscii, isAfter = v.isAfter, isBefore = v.isBefore, isCreditCard = v.isCreditCard;

  slice = function(arr) {
    var args;
    args = [].slice.call(arguments, 1);
    return [].slice.apply(arr, args);
  };

  concat = function(args) {
    var i, j, len, ref, res;
    if (arguments.length === 1) {
      if (isArray(args)) {
        return concat.apply(null, args);
      } else if (isArguments(args)) {
        return slice(args);
      }
    } else {
      args = slice(arguments);
      res = [];
      len = args.length;
      i = 0;
      for (i = j = 0, ref = len - 1; 0 <= ref ? j <= ref : j >= ref; i = 0 <= ref ? ++j : --j) {
        res = res.concat(args[i]);
      }
      return res;
    }
  };

  mapObj = function(obj, fn, context) {
    var keys;
    keys = _.keys(obj);
    return _.map(keys, function(key) {
      return fn.call(context, obj[key], key);
    });
  };

  spreadOnlyArg = function(args) {
    if (args.length === 1 && isArray(args[0])) {
      return args[0];
    } else {
      return slice(args);
    }
  };

  invoke = function(fn) {
    var args, callArgs, context, ref;
    args = slice(arguments, 1);
    callArgs = concat(args);
    context = null;
    if (isArray(fn)) {
      ref = fn, fn = ref[0], context = ref[1];
    }
    return fn.apply(context, callArgs);
  };

  D = Derives = {
    oppoWrap: function(fn) {
      return function() {
        var res;
        res = invoke(fn, arguments);
        if (isFunction(res)) {
          return D.oppoWrap(res);
        } else {
          return !res;
        }
      };
    },
    mapWrap: function(arr, func) {
      return function() {
        var args;
        args = slice(arguments);
        return arr.map(function(item) {
          var _args;
          _args = [item].concat(args);
          return func.apply(null, _args);
        });
      };
    },
    invokeWith: function(fn) {
      var argsWith;
      argsWith = slice(arguments, 1);
      return function() {
        var args, argsIn;
        argsIn = slice(arguments);
        args = argsIn.concat(argsWith);
        return apply(fn, args);
      };
    },
    spreadOnlyArgWrap: function(fn) {
      return function() {
        if (arguments.length === 1 && isArray(arguments[0])) {
          return invoke(fn, arguments[0]);
        } else {
          return invoke(fn, arguments);
        }
      };
    }
  };

  U = Utils = {
    clearSpace: function(str) {
      return str.replace(/\s+/g, '');
    },
    is: function(obj1, obj2) {
      var len;
      len = arguments.length;
      if (len === 1) {
        return _.curry(_.isEqual)(obj1);
      } else {
        return invoke([_.isEqual, _], arguments);
      }
    },
    isType: function(obj, type) {
      if (isString(type)) {
        type = type.toLowerCase();
      }
      switch (type) {
        case 'array' || Array:
          return isArray(obj);
        case 'string' || String:
          return isString(obj);
        case 'object' || Object:
          return isObject(obj);
        case 'objectid' || 'id':
          return isMongoId(obj);
        case 'date' || Date:
          return isDate(obj);
        case 'function' || Function:
          return isFunction(obj);
        default:
          return _.equal(obj, type);
      }
    },
    result: function(fn) {
      var args;
      if (isFunction(fn)) {
        args = slice(arguments, 1);
        return invoke(fn, args);
      } else {
        return fn;
      }
    },
    map: function(obj) {
      var handler;
      if (isArray(obj)) {
        handler = [_.map, _];
      } else if (isObject(obj)) {
        handler = mapObj;
      } else {
        return [];
      }
      return invoke(handler, arguments);
    },
    mapAny: function() {
      var args, arrs, fn, j, maxLen, ref, results;
      args = slice(arguments);
      fn = args.pop();
      arrs = _.filter(args, isArray);
      maxLen = Math.max.apply(Math, _.map(arrs, U.length));
      if (!maxLen) {
        return [];
      }
      return (function() {
        results = [];
        for (var j = 0, ref = maxLen - 1; 0 <= ref ? j <= ref : j >= ref; 0 <= ref ? j++ : j--){ results.push(j); }
        return results;
      }).apply(this).map(function(i) {
        var _args;
        _args = U.callOrApply(U.getByIndex, arrs, i);
        return fn.apply(null, _args);
      });
    },
    until: function(arr, fn, judge) {
      var breaked, item, j, len1, res;
      breaked = null;
      if (!isFunction(judge)) {
        judge = U.is(judge);
      }
      for (j = 0, len1 = arr.length; j < len1; j++) {
        item = arr[j];
        res = invoke(judge, invoke(fn, item));
        if (!res) {
          breaked = true;
          break;
        }
      }
      return breaked && item;
    },
    jsonify: function(fields, objs) {
      var needPick;
      needPick = function(val, key) {
        return ~_.indexOf(fields, key);
      };
      if (isArray(objs)) {
        return objs.map(function(obj) {
          return _.pick(obj, needPick);
        });
      } else {
        return _.pick(objs, needPick);
      }
    },
    required: function(fields, obj) {
      var field, j, len1;
      for (j = 0, len1 = fields.length; j < len1; j++) {
        field = fields[j];
        if (!obj[field]) {
          return false;
        }
      }
      return true;
    },
    leastOne: function(fields, obj) {
      var field, j, len1;
      for (j = 0, len1 = fields.length; j < len1; j++) {
        field = fields[j];
        if (obj[field]) {
          return true;
        }
      }
      return false;
    },
    xss: function(str) {
      return xss(str || '');
    },
    and: function() {
      var _and, args, len;
      args = spreadOnlyArg(arguments);
      len = args.length;
      if (len === 1) {
        return !!args[0];
      } else {
        return _.reduce(args, _and);
      }
      return _and = function(a, b) {
        return a && b;
      };
    },
    contain: function(source, target) {
      if (isArray(source) && !isArray(target)) {
        return !!~_.indexOf(source, target);
      }
      if (isArray(source) && isArray(target)) {
        return U.andArr(target.map(function(item) {
          return U.contain(source, item);
        }));
      }
      if (isString(source) && isString(target)) {
        return !!~source.indexOf(target);
      }
      if (isObject(source) && isString(target)) {
        return _.has(source, target);
      }
      if (isObject(source) && isArray(target)) {
        return U.and(target.map(function(item) {
          return U.contain(source, item);
        }));
      }
      return false;
    },
    length: function(obj) {
      return obj.length;
    },
    getByIndex: function() {
      var args, ind;
      args = slice(arguments);
      ind = args.pop();
      return args.map(function(arg) {
        return arg[ind];
      });
    },
    mapAny: function() {
      var args, arrs, fn, j, maxLen, ref, results;
      args = slice(arguments);
      fn = args.pop();
      arrs = _.filter(args, isArray);
      maxLen = Math.max.apply(Math, _.map(arrs, U.length));
      return (function() {
        results = [];
        for (var j = 0, ref = maxLen - 1; 0 <= ref ? j <= ref : j >= ref; 0 <= ref ? j++ : j--){ results.push(j); }
        return results;
      }).apply(this).map(function(i) {
        var _args;
        _args = invoke(U.getByIndex, arrs, i);
        return fn.apply(null, _args);
      });
    }
  };

  U.isnt = D.oppoWrap(U.is);

  module.exports = [_, _.assign({}, U, D)];

}).call(this);