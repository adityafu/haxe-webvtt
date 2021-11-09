using StringTools;

class RegexTools {
	public static inline function replace2(s:String, sub:EReg, by:String):String {
		return sub.replace(s, by);
	}

	public static inline function includes(s:String, by:String):Bool {
		return s.contains(by);
	}

	public static  function match2(message:String, ereg:EReg):Array<String> {

		trace('fuck');
		var arr = [];
		while (ereg.match(message)) {
			// trace(ereg.matched(1));
			arr.push(ereg.matched(1));
			message = ereg.matchedRight();
		}

		return arr;
	}
}
