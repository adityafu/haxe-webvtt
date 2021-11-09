import js.html.CustomElementRegistry;
import js.lib.RegExp;
import node.dns.CaaRecord;
import haxe.Json;
import sys.io.File;
import haxe.io.Path;
import sys.FileSystem;
import level.LevelDB;
import levelup.LevelUp;
import Level;
import jsasync.IJSAsync;
import js.lib.Promise;
import haxe.Timer;
import jsasync.JSAsync;

using jsasync.JSAsyncTools;

class Json2Level implements IJSAsync {
	public static function main() {}

	static var mapDB:Map<String, LevelDB<Dynamic, Dynamic>> = [];

	@:jsasync
	public static function mainAsync(targetPath:String) {
		getAllFilesInForlder('${targetPath}/').jsawait();
	}

	@:jsasync
	public static function mainAsync2(targetPath:String) {
		var db3 = cast Level.call('${targetPath}', {valueEncoding: 'json'});

		//trace('db was create /root/leveldbJson.db');
		//	getAllFilesInForlder('${targetPath}/').jsawait();

		// getAllKeysAndObjects();

		trace('now?!!!');

		var reg:EReg = new EReg("what's ", "");

		var arr:Array<Array<Cue>> = cast collectLast(db3, 5, reg).jsawait();

		for (e in arr) {
			for (f in e) {
				trace(f.text + " " + f.translate);
			}
		}
	}

	@:jsasync
	static function collectLast(db3:LevelDB<Dynamic, Dynamic>, limit:Float, reg:EReg) {
		return new Promise(function(resolve, reject) {
			try {
				var iterator = db3.iterator({reverse: true, limit: limit});

				var results:Array<Array<Cue>> = [];
				function end(err:Dynamic = null) {
					iterator.end(function(err2:Dynamic) {
						// callback(err || err2);

						if (err) {
							reject([]);
						} else {
							resolve(results);
						}
					});
				}

				function loop() {
					iterator.next((err, key, value) -> {
						if (err != null)
							return end(err);

						if (key == null && value == null) {
							// reached the end
							return end();
						}

						var result:CuesResult = cast value;

						// trace(result.cues.length);

						results.push(match(result, reg));

						loop();
					});
				};

				loop();
			} catch (e) {
				reject(e);
			}
		});
	}

	public static function match(target:CuesResult, cues:EReg) {
		var result:Array<Cue> = [];

		for (e in target.cues) {
			var cue:Cue = e;

			if (cues.match(cue.text)) {
				result.push(cue);
			}
		}

		return result;
	}

	static function delay(time:Int) { // 毫秒
		var p = new Promise(function(resole, reject) {
			Timer.delay(() -> {
				resole(1);
			}, time);
		});

		return p;
	}

	@:jsasync
	public static function getAllFilesInForlder(path:String) {
		var putok = false;
		var maps:Map<String, FileMaps> = [];
		var files = FileSystem.readDirectory(path);

		try {
			for (c in files) {
				var tPath1:String = Path.join([path, c]);
				if (FileSystem.isDirectory(tPath1)) {
					
					getAllFilesInForlder(tPath1);
				} else {
					// trace(tPath1);

					// Path.getExtension(tPath1);

					if (Path.extension(tPath1) == "json") {
						// trace('parse json ${tPath1}');

						try {
							var r:CuesResult = cast Json.parse(File.getContent(tPath1));

							//	trace('finish parse json');
							if (r != null && r.id != null) {
								//	trace('ok parse =${tPath1} id=${r.id}');
								// l&&db3.get(r.id) == null
								if (r.upLoader == null) {
									r.upLoader = "youtube";
								}

								// trace('uploader =${r.upLoader}');

								if (!mapDB.exists(r.upLoader)) {
									trace('create levedb now  /root/vttdb/${r.upLoader}.db');
									var dx = cast Level.call('/data/${r.upLoader}.db', {valueEncoding: 'json'});

									mapDB[r.upLoader] = dx;
								}

								var db3:LevelDB<Dynamic, Dynamic> = mapDB.get(r.upLoader);
								//	db.put(r.id,r);

								var gotKey = false;

								var key = r.id + "__" + r.upLoader;

								
								try {
									db3.get(key).jsawait();
									gotKey = true;
								} catch (e) {
									trace('what? got key now?');
									gotKey = false;
								}

								if (!gotKey) {
									
									db3.put(key, r).jsawait();
                                     //这里可以考虑用db3.batch...
								//db3.batch()
									var obj = db3.get(key).jsawait();

									trace('get ok=${obj.cues.length}');
									putok = true;
								} else {
									trace('already got key ,i');
								}
							} else {
								trace("er:" + tPath1);
							}
						} catch (e) {
							trace("error=:" + Std.string(e));
						}
					}
				}
			}
		}
	}
}
// static var db3:LevelDB<String, CuesResult>;
