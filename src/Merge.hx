class Merge {
	public static function MergeTwoVTT(en:String, cn:String, id:String,upLoader:String):CuesResult {
		var parse = new Parse();

		if(upLoader == ""){
			trace(id);
			throw "upLoader is null";
		}
		var d = parse.parse(en, {strict: true, meta: true});
		d.id = id;
		d.upLoader = upLoader;
		var parse2 = new Parse();

		var d2 = parse2.parse(cn, {strict: true, meta: true});

		//trace(d.cues.length);

		//trace(d2.cues.length);

		if (d.cues.length != d2.cues.length) {
			for (index => e in d.cues) {
				var cue:Cue = d.cues[index];

				for (index2 => e2 in d2.cues) {
					var cue2:Cue = d2.cues[index2];

					if ((cue2.start >= cue.start && cue.translate == null) || (cue.end <= cue2.end && cue.translate == null)) {
						cue.translate = cue2.text;
					}
				}
			}
		} else {
			for (index => e in d.cues) {
				var cue:Cue = d.cues[index];
				var cue2:Cue = d2.cues[index];
				cue.translate = cue2.text;
			}
		}

		return d;
	}
}
