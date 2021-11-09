import node.Cluster;
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
import EMDSearch;

using Lambda;
using haxe.io.Path;
using jsasync.JSAsyncTools;
using String;

class Search implements IJSAsync {
	public var map:Map<String, LevelDB<String, CuesResult>> = [];

	var wasFinish=false;
	public function new() {

		trace("Search.new"+Random.int(0, 1000000));
	}

	public static function createSingleDB(folder:String) {

		
		var files = FileSystem.readDirectory(folder);

		

		return files;
	
	}

	public function createIndexs(folder:String) {

		if(map.count() > 0) {
			throw "already created";
			return;
		}
		var files = FileSystem.readDirectory(folder);

		var num = 0;
		for (f in files) {
			if (f.indexOf(".db") != -1 && num < 1000) {
				var dbName = f.withoutDirectory().withoutExtension();
				var path = Path.join([folder, dbName + ".db"]);
				// trace(f, path);

				map[dbName] = cast Level.call(path, {valueEncoding: 'json'});
				// trace('$dbName was added');
				num++;
			}
		}

		if(wasFinish) {
			throw "already created";
			return;
		}
		trace('finish');
		wasFinish=true;
	}

	@:jsasync
	public function search(expression:String, limit:Int, cn:Bool = false, kind:String = "") {
		expression = expression.toLowerCase();
		var result = [];
		for (key => value in map) {
			var item = toSearch(value, expression, limit, cn, kind).jsawait();

			if (item.length > 0) {
				result.push(item);
			}
			// result.push(item);
		}

		return result;
	}

	public function search2(expression:String, limit:Int, cn:Bool = false, kind:String = "") {
		return new Promise(function(resolve, reject) {
			search3(resolve, reject, expression, limit, cn, kind);
		});
	}

	function search3(resolve:Dynamic->Void, reject:Dynamic->Void, expression:String, limit:Int, cn:Bool = false, kind:String = "") {
		expression = expression.toLowerCase();
		var result = [];
		var total = 0;
		var len = map.count();
		var random = Random.int(0, 10000) + Random.int(1000, 100000);
		var keys = [];
		for (key => value in map) {
			keys.push(key);
		}

		if (Cluster.isMaster) {
			trace("Master");
			Cluster.setupMaster();
			
			for (i in 0...16) {
				var worker = Cluster.fork();
				worker.on('message', function(data:String, f) {
					// var dd=Json.stringify(msg);
					// trace('worker ' + worker.id + ': ' + msg);

					trace(data.length);
					var arr = [1, 2, 3];
					var dd:SearchType = Json.parse(data);

					switch (dd.cmd) {
						case Search(text, index, randomKey):
							var key:String = keys[cast index];

							var db = map[cast key]; // 多线程查找
							JSAsync.jsasync((db, keys, total, result, expression, limit, cn, kind, w, f2) -> {
								var item = toSearch(db, expression, limit, cn, kind).jsawait();
								// timer(1000).jsawait();

								if (item.length > 0) {
									result.push(item);
									trace(item);
								}

								total++;

								if (total == keys.length) {
									resolve(result);
								}
								w.disconnect(); // I want to put work here,but not work.

								return 1;
							})(db, keys, total, result, text, limit, cn, kind, worker, f);
						case Unknow:
							trace('unknow');
						case Initialized(dbName):
							trace("");
					}

					// worker.disconnect();
				});
			}
			Cluster.on('exit', function(worker, code, signal) {
				trace('worker ' + worker.id + ' died');
			});
		} else {
			trace("worker " + Cluster.worker.id + " started");
			var worker = Cluster.worker;

			var random = Random.int(0, 10000) + Random.int(1000, 100000);
			var s:SearchType = {cmd: Search(expression, worker.id, random)};
			worker.send(Json.stringify(s));
		}
	}

	@:jsasync
	public static function toSearch(db3:LevelDB<String, CuesResult>, expression:String, limit:Int = 0, cn:Bool = false, kind:String = "") {
		// trace('express=${expression}');
		var reg:EReg = new EReg(expression, "");

		var arr:Array<Array<Cue>> = cast collectLast(db3, limit, reg).jsawait();

		// trace(arr);
		return arr;
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
							trace('error!now');
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

						var r2 = match(result, reg);
						if (r2.length > 0) {
							for (c in r2) {
								c.id = result.id;
								c.upLoader = result.upLoader;
							}
							results.push(r2);
						}

						loop();
					});
				};

				loop();
			} catch (e) {
				reject(e);
			}
		});
	}

	static public function match(target:CuesResult, cues:EReg) {
		var result:Array<Cue> = [];

		for (e in target.cues) {
			var cue:Cue = e;

			if (cues.match(cue.text)) {
				result.push(cue);
			}
		}

		return result;
	}

	public function timer(msec:Int) {
		return new Promise(function(resolve, reject) {
			// Browser.window.setTimeout(resolve, msec);
			Timer.delay(() -> {
				resolve(1);
			}, msec);
		});
	}
}
