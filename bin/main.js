(function ($global) { "use strict";
class EReg {
	constructor(r,opt) {
		this.r = new RegExp(r,opt.split("u").join(""));
	}
	match(s) {
		if(this.r.global) {
			this.r.lastIndex = 0;
		}
		this.r.m = this.r.exec(s);
		this.r.s = s;
		return this.r.m != null;
	}
	matched(n) {
		if(this.r.m != null && n >= 0 && n < this.r.m.length) {
			return this.r.m[n];
		} else {
			throw haxe_Exception.thrown("EReg::matched");
		}
	}
}
EReg.__name__ = true;
class HxOverrides {
	static cca(s,index) {
		let x = s.charCodeAt(index);
		if(x != x) {
			return undefined;
		}
		return x;
	}
	static substr(s,pos,len) {
		if(len == null) {
			len = s.length;
		} else if(len < 0) {
			if(pos == 0) {
				len = s.length + len;
			} else {
				return "";
			}
		}
		return s.substr(pos,len);
	}
	static now() {
		return Date.now();
	}
}
HxOverrides.__name__ = true;
class Main {
	static main() {
		let regexp = new EReg("world","");
		console.log("src/Main.hx:29:",regexp.match("hello world"));
		console.log("src/Main.hx:32:",regexp.match("hello"));
		let parse = new ParseSRT();
		parse.parse(js_node_Fs.readFileSync("bin/test.srt",{ encoding : "utf8"}));
	}
}
Main.__name__ = true;
Math.__name__ = true;
class ParseSRT {
	constructor() {
		this.TIMESTAMP_REGEXP = new EReg("([0-9]{1,2})?:?([0-9]{2}):([0-9]{2}\\.[0-9]{2,3})","i");
	}
	parse(input,options) {
		if(options == null) {
			options = { meta : false, strict : true};
		}
		input = StringTools.trim(input);
		let sub_r = new RegExp("\r\n","g".split("u").join(""));
		input = input.replace(sub_r,"\n");
		let sub_r1 = new RegExp("\r","g".split("u").join(""));
		input = input.replace(sub_r1,"\n");
		let parts = input.split("\n\n");
		let result = this.parseCues(parts,options.strict);
		return { valid : true, strict : true, cues : result, errors : [], meta : { Kind : "captions", Language : "en"}};
	}
	parseCues(cues,strict) {
		let arrs = [];
		let _g = 0;
		let _g1 = cues.length;
		while(_g < _g1) {
			let i = _g++;
			let cuess = cues[i];
			try {
				let cue = this.parseCue(cuess,i,strict);
				if(cue != null) {
					arrs.push(cue);
				}
			} catch( _g ) {
				console.log("src/ParseSRT.hx:92:",Std.string(haxe_Exception.caught(_g)));
			}
		}
		return arrs;
	}
	parseCue(cue,i,strict) {
		let start = 0;
		let end = 0.01;
		let text = "";
		let _this = cue.split("\n");
		let _g = [];
		let _g1 = 0;
		while(_g1 < _this.length) {
			let v = _this[_g1];
			++_g1;
			if(v != null) {
				_g.push(v);
			}
		}
		_g.shift();
		if(_g.length > 0 && StringTools.trim(_g[0]).startsWith("NOTE")) {
			return null;
		}
		if(_g.length == 1 && !_g[0].includes("-->")) {
			throw new ParserError("Cue identifier cannot be standalone (cue #${i})");
		}
		if(_g.length > 1 && !(_g[0].includes("-->") || _g[1].includes("-->"))) {
			throw new ParserError("Cue identifier needs to be followed by timestamp (cue #${i})");
		}
		if(_g.length > 1 && _g[1].includes("-->")) {
			_g.shift();
		}
		let times = [];
		if(typeof(_g[0]) == "string") {
			times = _g[0].split(" --> ");
		}
		if(times.length != 2 || !this.validTimestamp(times[0]) || !this.validTimestamp(times[1])) {
			throw new ParserError("Invalid cue timestamp (cue #" + i + ")");
		}
		start = this.parseTimestamp(times[0]);
		end = this.parseTimestamp(times[1]);
		if(strict) {
			if(start > end) {
				throw new ParserError("Start timestamp greater than end (cue #${i})");
			}
			if(end <= start) {
				throw new ParserError("End must be greater than start (cue #${i})");
			}
		}
		if(!strict && end < start) {
			throw new ParserError("End must be greater or equal to start when not strict (cue #${i})");
		}
		times[1].replace(this.TIMESTAMP_REGEXP.r,"");
		_g.shift();
		text = _g.join("");
		if(text == null || text.includes("<c>") && text.includes("</c>") || text.includes("[Music]") || text.includes("[音乐]")) {
			return null;
		}
		let result = { start : start, end : end, text : text};
		return result;
	}
	validTimestamp(timestamp) {
		return this.TIMESTAMP_REGEXP.match(timestamp);
	}
	parseTimestamp(timestamp) {
		this.TIMESTAMP_REGEXP.match(timestamp);
		let secs = parseFloat(this.TIMESTAMP_REGEXP.matched(1)) * 60 * 60;
		secs += parseFloat(this.TIMESTAMP_REGEXP.matched(2)) * 60;
		secs += parseFloat(this.TIMESTAMP_REGEXP.matched(3));
		return secs;
	}
}
ParseSRT.__name__ = true;
class haxe_Exception extends Error {
	constructor(message,previous,native) {
		super(message);
		this.message = message;
		this.__previousException = previous;
		this.__nativeException = native != null ? native : this;
	}
	toString() {
		return this.get_message();
	}
	get_message() {
		return this.message;
	}
	get_native() {
		return this.__nativeException;
	}
	static caught(value) {
		if(((value) instanceof haxe_Exception)) {
			return value;
		} else if(((value) instanceof Error)) {
			return new haxe_Exception(value.message,null,value);
		} else {
			return new haxe_ValueException(value,null,value);
		}
	}
	static thrown(value) {
		if(((value) instanceof haxe_Exception)) {
			return value.get_native();
		} else if(((value) instanceof Error)) {
			return value;
		} else {
			let e = new haxe_ValueException(value);
			return e;
		}
	}
}
haxe_Exception.__name__ = true;
class ParserError extends haxe_Exception {
	constructor(message,previous,native) {
		super(message,previous,native);
	}
}
ParserError.__name__ = true;
class Std {
	static string(s) {
		return js_Boot.__string_rec(s,"");
	}
}
Std.__name__ = true;
class StringTools {
	static isSpace(s,pos) {
		let c = HxOverrides.cca(s,pos);
		if(!(c > 8 && c < 14)) {
			return c == 32;
		} else {
			return true;
		}
	}
	static ltrim(s) {
		let l = s.length;
		let r = 0;
		while(r < l && StringTools.isSpace(s,r)) ++r;
		if(r > 0) {
			return HxOverrides.substr(s,r,l - r);
		} else {
			return s;
		}
	}
	static rtrim(s) {
		let l = s.length;
		let r = 0;
		while(r < l && StringTools.isSpace(s,l - r - 1)) ++r;
		if(r > 0) {
			return HxOverrides.substr(s,0,l - r);
		} else {
			return s;
		}
	}
	static trim(s) {
		return StringTools.ltrim(StringTools.rtrim(s));
	}
}
StringTools.__name__ = true;
class haxe_ValueException extends haxe_Exception {
	constructor(value,previous,native) {
		super(String(value),previous,native);
		this.value = value;
	}
}
haxe_ValueException.__name__ = true;
class haxe_iterators_ArrayIterator {
	constructor(array) {
		this.current = 0;
		this.array = array;
	}
	hasNext() {
		return this.current < this.array.length;
	}
	next() {
		return this.array[this.current++];
	}
}
haxe_iterators_ArrayIterator.__name__ = true;
class js_Boot {
	static __string_rec(o,s) {
		if(o == null) {
			return "null";
		}
		if(s.length >= 5) {
			return "<...>";
		}
		let t = typeof(o);
		if(t == "function" && (o.__name__ || o.__ename__)) {
			t = "object";
		}
		switch(t) {
		case "function":
			return "<function>";
		case "object":
			if(((o) instanceof Array)) {
				let str = "[";
				s += "\t";
				let _g = 0;
				let _g1 = o.length;
				while(_g < _g1) {
					let i = _g++;
					str += (i > 0 ? "," : "") + js_Boot.__string_rec(o[i],s);
				}
				str += "]";
				return str;
			}
			let tostr;
			try {
				tostr = o.toString;
			} catch( _g ) {
				return "???";
			}
			if(tostr != null && tostr != Object.toString && typeof(tostr) == "function") {
				let s2 = o.toString();
				if(s2 != "[object Object]") {
					return s2;
				}
			}
			let str = "{\n";
			s += "\t";
			let hasp = o.hasOwnProperty != null;
			let k = null;
			for( k in o ) {
			if(hasp && !o.hasOwnProperty(k)) {
				continue;
			}
			if(k == "prototype" || k == "__class__" || k == "__super__" || k == "__interfaces__" || k == "__properties__") {
				continue;
			}
			if(str.length != 2) {
				str += ", \n";
			}
			str += s + k + " : " + js_Boot.__string_rec(o[k],s);
			}
			s = s.substring(1);
			str += "\n" + s + "}";
			return str;
		case "string":
			return o;
		default:
			return String(o);
		}
	}
}
js_Boot.__name__ = true;
var js_node_Fs = require("fs");
if(typeof(performance) != "undefined" ? typeof(performance.now) == "function" : false) {
	HxOverrides.now = performance.now.bind(performance);
}
{
	String.__name__ = true;
	Array.__name__ = true;
}
js_Boot.__toStr = ({ }).toString;
Main.main();
})({});

//# sourceMappingURL=main.js.map