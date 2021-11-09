using StringTools;
using Lambda;
using RegexTools;

// 00:00:00.123
class Parse {
	var TIMESTAMP_REGEXP = ~/([0-9]{1,2})?:?([0-9]{2}):([0-9]{2}\.[0-9]{2,3})/i;

	public function new() {}

	public function parse(input:String, options:Options):CuesResult {
		if (options == null) {
			options = {meta: false, strict: true};
		}

		input = input.trim();

		input = input.replace2(~/\r\n/g, '\n');
		input = input.replace2(~/\r/g, '\n');

		var parts = input.split('\n\n');
		var header = parts.shift();

		if (!header.startsWith('WEBVTT')) {
			throw new ParserError('Must start with "WEBVTT"');
		}

		var headerParts = header.split('\n');

		var headerComments = headerParts[0].replace('WEBVTT', '');

		if (headerComments.length > 0 && (headerComments.charAt(0) != ' ' && headerComments.charAt(0) != '\t')) {
			throw new ParserError('Header comment must start with space or tab');
		}

		// nothing of interests, return early
		if (parts.length == 0 && headerParts.length == 1) {
			return {
				valid: true,
				strict: true,
				cues: [],
				errors: []
			};
		}

		if (!options.meta && headerParts.length > 1 && headerParts[1] != '') {
			throw new ParserError('Missing blank line after signature');
		}

		var result:Array<Cue> = parseCues(parts, options.strict);

		// if (options.strict && result.errors.length > 0) {
		// 	throw result.errors[0];
		// }

		// var headerMeta = options.meta ? parseMeta(headerParts) : null;

		// // var  result =ob //{ valid: errors.length == 0, strict:options.strict:options.strict, cues, errors };

		// result.strict = options.strict;
		// result.valid = result.errors.length == 0;

		// if (options.meta) {
		// 	result.meta = headerMeta;
		// }

		// return result;

		return {
			valid: true,
			strict: true,
			cues: result,
			errors: [],
			meta: {
				Kind: 'captions',
				Language: 'en'
			}
		};
	}

	// function parseMeta(headerParts:Array<String>) {
	// 	var meta = new Map<String, String>();
	// 	headerParts.slice(1).foreach((header:String) -> {
	// 		var splitIdx = header.indexOf(':');
	// 		var key = header.substr(0, splitIdx).trim();
	// 		var value = header.substr(splitIdx + 1).trim();
	// 		meta[key] = value;
	// 	});
	// 	return meta.keys.count() > 0 ? meta : null;
	// }
	function parseCues(cues:Array<String>, strict:Bool):Array<Cue> {
		var errors = [];
		// var parsedCues = cues.map((cue, i) -> {
		// 	try {
		// 		return parseCue(cue, i, strict);
		// 	} catch (e) {
		// 		errors.push(e);
		// 		return null;
		// 	}
		// }).filter(Boolean);
		// return {
		// 	cues:parsedCues,
		// 	errors:errors
		// };

		var arrs:Array<Cue> = [];
		for (i in 0...cues.length) {
			var cuess = cues[i];

			try {
				var cue = parseCue(cuess, i, strict);
				if (cue != null) {
					arrs.push(cue);
				}
			} catch (e) {
				trace(Std.string(e));
			}
		}

		return arrs;
	}

	// /**
	//  * Parse a single cue block.
	//  *
	//  * @param {array} cue Array of content for the cue
	//  * @param {number} i Index of cue in array
	//  *
	//  * @returns {object} cue Cue object with start, end, text and styles.
	//  *                       Null if it's a note
	//  */
	function parseCue(cue:String, i:Int, strict:Bool):Cue {
		var identifier = '';
		var start:Float = 0;
		var end:Float = 0.01;
		var text = '';
		var styles = '';
		// split and remove empty lines
		var lines = cue.split('\n').filter(item -> item != null);
		if (lines.length > 0 && lines[0].trim().startsWith('NOTE')) {
			return null;
		}
		if (lines.length == 1 && !lines[0].includes('-->')) {
			throw new ParserError("Cue identifier cannot be standalone (cue #${i})");
		}
		if (lines.length > 1 && !(lines[0].includes('-->') || lines[1].includes('-->'))) {
			var msg = "Cue identifier needs to be followed by timestamp (cue #${i})";
			throw new ParserError(msg);
		}
		if (lines.length > 1 && lines[1].includes('-->')) {
			identifier = lines.shift();
		}

		var times:Array<String> = [];
		// var  times = Std.isOfType(lines[0],String) && lines[0].split(' --> ');

		if (Std.isOfType(lines[0], String)) {
			times = lines[0].split(' --> ');
		}

		if (times.length != 2 || !validTimestamp(times[0]) || !validTimestamp(times[1])) {
			throw new ParserError('Invalid cue timestamp (cue #${i})');
		}

		start = parseTimestamp(times[0]);
		end = parseTimestamp(times[1]);
		if (strict) {
			if (start > end) {
				throw new ParserError("Start timestamp greater than end (cue #${i})");
			}
			if (end <= start) {
				throw new ParserError("End must be greater than start (cue #${i})");
			}
		}
		if (!strict && end < start) {
			throw new ParserError("End must be greater or equal to start when not strict (cue #${i})");
		}
		// TODO better style validation
		styles = times[1].replace2(TIMESTAMP_REGEXP, '').trim();
		lines.shift();
		text = lines.join('');
		if (text == null || text.contains("<c>") && text.contains("</c>") || text.contains('[Music]') || text.contains("[音乐]")) {
			return null;
		}

		var result:Cue = {
			//identifier: identifier,
			start: start,
			end: end,
			text: text,
		//	styles: styles
		};
		return result;
	}

	function validTimestamp(timestamp:String):Bool {
		return TIMESTAMP_REGEXP.match(timestamp);
	}

	function parseTimestamp(timestamp:String):Float {
		TIMESTAMP_REGEXP.match(timestamp); // timestamp.match2(TIMESTAMP_REGEXP);
		var secs = Std.parseFloat(TIMESTAMP_REGEXP.matched(1)) * 60 * 60; // hours
		secs += Std.parseFloat(TIMESTAMP_REGEXP.matched(2)) * 60; // mins
		secs += Std.parseFloat(TIMESTAMP_REGEXP.matched(3));
		// secs += parseFloat(matches[4]);
		return secs;
	}
}
