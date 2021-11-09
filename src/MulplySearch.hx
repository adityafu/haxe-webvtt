import js.html.Worker;
import level.LevelDB;
import node.Os;
import node.os.CpuInfo;
import jsasync.IJSAsync;
import jsasync.JSAsyncTools;
import jsasync.JSAsync;
import haxe.ds.Map;
import haxe.io.Path;
import sys.FileSystem;
import haxe.Json;
import sys.io.File;
import Parse;
import Level;
import node.Cluster;
import js.lib.Promise;
import haxe.Timer;

using haxe.io.Path;
using Lambda;
using jsasync.JSAsyncTools;

class MulplySearch implements IJSAsync {
	static var wasInit = false;

	static function main22222() {
		// main2();

		trace('why?sdfsdfdf' + Random.int(0, 100));
		//	main2();
	}

	public static var wasSet = false;

	public static var mapDB:Map<String, LevelDB<String, CuesResult>> = [];
	public static var mapResult:Map<String, Array<Array<Array<CuesResult>>>> = [];
	public static var mapResultKey:Map<String, Int> = [];
	static var allDB:LevelDB<String, Array<Array<Array<CuesResult>>>>;
	public static var lastFindNum = 2;
	static var arr46:Array<String>;

	@:jsasync
	static function toSearchAll(allWorks:Array<node.cluster.Worker>, word:String = null, value:Array<Array<Array<CuesResult>>> = null) {
		if (allDB == null) {
			allDB = cast Level.call("./all.db", {valueEncoding: 'json'});

			arr46 = File.getContent("./CET46.txt").split("\n");
		}

		var searchNum=1;
		if (word != null && value != null) {

			trace('完成 ${word} len=${value.length}');
			if(value.length>0&&value[0].length>0){
				lastFindNum=1;

				allDB.put(word, value).jsawait();
			}else{
				trace('0个查找.');
				mapResult[word]=[];
				lastFindNum++;

				if(lastFindNum<100){
					toSearch(word, allWorks,lastFindNum);
					return;
				}else{
					lastFindNum=1;
				}
				
			}
			
		}
		if (arr46.length > 0) {
			var word = arr46.shift();

			while(word.length<3&&arr46.length>0){
				word = arr46.shift();
			}

			
			trace('查找 ${word}');
			toSearch(word, allWorks,searchNum);
		}
	}

	static function toSearch(word:String, allWorks:Array<node.cluster.Worker>,searchNum:Int=1) {

		if(searchNum>1){
			trace('查找 ${word} ${searchNum}');
		}
		mapResult[word] = [];
		mapResultKey[word] = 0;
		for (w in allWorks) {
			var initData:EMDSearch = EMDSearch.Search(word, searchNum, 0);
			w.send(Json.stringify(initData));
		}
	}

	static function main() {
		if (Cluster.isMaster) {
			trace("************************************************Master");
			wasSet = true;
			Cluster.setupMaster();

			var folder = "/data/";

			var _drs = FileSystem.readDirectory(folder);

			var drs = [];

			for (f in _drs) {
				if (f.indexOf(".db") != -1) {
					drs.push(f);
				}
			}

			var totalDBNum = drs.length;
			var cpus = 8;

			var arrs = [];

			var toLen = Math.floor(drs.length / cpus);
			while (drs.length > 0) {
				// arrs.push(drs.splice(0, Math.min(drs.length, cpus)));
				var childArr = [];
				arrs.push(childArr);

				while (childArr.length < toLen && drs.length > 0) {
					var f = drs.shift();
					var dbName = f.withoutDirectory().withoutExtension();
					var path = Path.join([folder, dbName + ".db"]);
					childArr.push(path);
				}
			}

			var totalNum = arrs.length;

			var currentInit = 0;

			// File.saveContent("d:/data.json",Json.stringify(arrs));

			var allWorks = [];

			for (arr in arrs) {
				var worker = Cluster.fork();
				allWorks.push(worker);

				worker.on('message', function(data:String, f) {
					if (data == null || data.length < 5) {
						return;
					}

						//trace("data--------------="+data);
					var initData:EMDSearch = Json.parse(data);

					switch (initData) {
						case EMDSearch.Initialized(db, workerID):
							// trace('from child to main initialized workID=  $workerID');
							currentInit++;

							if (currentInit == totalNum) {
								trace('all initialized---');
								// main22222();
								// currentInit = 0;

								//toSearch("what", allWorks);
								toSearchAll(allWorks);
							}
						case EMDSearch.Search(value, id, workID, result):

						//trace(result);
								mapResultKey[value]++;


							if(result.length>0&&result[0].length>0){
								
								mapResult[value].push(result);
							}
							
							// trace('workID=${workID} len =${totalDBNum} from child to main search ${mapResult[value].count()}');
							if (mapResultKey[value] == totalDBNum) {
								trace('查找完成--------------');

								// trace(mapResult[value]);

								// File.saveContent("/all2.json",Json.stringify(mapResult));

								toSearchAll(allWorks,value,mapResult[value]);

								//mapResult.remove(value);
							}

						case Unknow:
							trace('from child to main unknow');
					}
				});

				if (currentInit != totalNum) {
					var initData:EMDSearch = EMDSearch.Initialized(arr);
					worker.send(Json.stringify(initData));
				}
			}
			Cluster.on('exit', function(worker, code, signal) {
				trace('worker ' + worker.id + ' died');
			});
		} else {
			trace("worker " + Cluster.worker.id + " started");

			trace(wasSet);
			var worker = Cluster.worker;

			worker.on('message', function(data:String, f) {
				var initData:EMDSearch = Json.parse(data);

				switch (initData) {
					case EMDSearch.Initialized(dbs):
						for (db in dbs) {
							var folder = Path.directory(db);
							if (db.indexOf(".db") != -1) {
								var dbName = db.withoutDirectory().withoutExtension();
								var path = Path.join([folder, dbName + ".db"]);
								// trace("打开---"+ path);

								if (mapDB.exists(db)) {
									trace('db 又打开了 $db');
									return;
								}
								mapDB[db] = cast Level.call(path, {valueEncoding: 'json'});
								// trace('child $dbName was added');
							}
						}
						var callBack:EMDSearch = EMDSearch.Initialized(dbs, worker.id);
						worker.send(Json.stringify(callBack));

					case EMDSearch.Search(value, total, current):
						// trace('收到查找key =$value');
						for (keys => db in mapDB) {
							// trace('遍历查找' + worker.id);
							JSAsync.jsasync((db, value) -> {
								// trace('入内了' + value);
								var item = Search.toSearch(db, value,cast total).jsawait();

								if (item.length > 0) {
									// trace(item.length);
								} else {
									// trace('没有数据');
								}

								var initData:EMDSearch = EMDSearch.Search(value, total, worker.id, cast item);
								worker.send(Json.stringify(initData));

								return 1;
							})(db, value);
						}

					case Unknow:
						trace('unknow');
				}
			});
			// worker.send("hello");
		}
	}

	@:jsasync
	static function mainAsyncLocal(text:String) {
		trace('why?' + Random.int(0, 100));
		var search = new Search();
		// search.createIndexs2("bin/data");
		trace('create database ok');
		var allData = Level.call("bin/all2.db", {valueEncoding: 'json'});
		trace('createdatabaseok?');
		var texts = ["what"]; // File.getContent("/data/CET46.txt").split("\n");
		trace('what?');
		var output = "";
		var text = "what";
		// for (text in texts) {

		var arr = search.search2(text, 1).jsawait();
		if (arr.length == 0) {
			trace('$text ************没收录');
			output += text + "\n";
		} else {
			trace('$text 收录了 ${arr.length}');
			allData.put(text, arr).jsawait();
		}
		// }
		File.saveContent("bin/output.txt", output);
	}

	@:jsasync
	static function mainAsync3333(text:String) {
		var search = new Search();

		// search.createIndexs3("/data");

		trace('create database ok');
		var allData = Level.call("/all/all.db", {valueEncoding: 'json'});

		trace('createdatabaseok?');

		var texts = File.getContent("/data/CET46.txt").split("\n");

		trace('what?');
		var output = "";
		for (text in texts) {
			if (text.length < 3)
				continue;

			var arr = search.search(text, 1000).jsawait();

			if (arr.length == 0) {
				trace('$text ************没收录');
				output += text + "\n";
			} else {
				trace('$text 收录了 ${arr.length}');

				allData.put(text, arr).jsawait();
			}
		}

		File.saveContent("/data/output.txt", output);
	}

	static function create() {}
}
