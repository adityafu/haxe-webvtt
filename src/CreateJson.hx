import haxe.ds.Map;
import haxe.io.Path;
import sys.FileSystem;
import haxe.Json;
import sys.io.File;
import Parse;

using Lambda;



class CreateJson {
	public static function main(path:String,override2:Bool = false):Void {
		// trace("Hello, world!");

		getAllFilesInForlder(path,override2);


	}

	public static function getAllFilesInForlder(path:String,override2:Bool):Void {
		var maps:Map<String, FileMaps> = [];
		var files = FileSystem.readDirectory(path);
		for (c in files) {
			var tPath1:String = Path.join([path, c]);
			if (FileSystem.isDirectory(tPath1)) {
				getAllFilesInForlder(tPath1,override2);
			} else {


				if (Path.extension(tPath1) == "vtt") {
					var arr = tPath1.split("/");

					var fileName = arr[arr.length - 1].split(".")[0]; // filename

					var forlder = Path.directory(tPath1);

					var id = arr[arr.length - 2];

					var fileNamePath = Path.join([forlder, fileName]);

					var upLoader=arr[arr.length - 4];

					if(upLoader==""){

						trace(arr);
						throw "upLoader is null";
					}
				//	trace(fileNamePath + "\n");

					if (id != null && !maps.exists(id))
						maps[id] = {
							cn: fileNamePath + ".zh-Hans.vtt",
							en: fileNamePath + ".en.vtt",
							id: id,
							json:fileNamePath + ".en.json",
							upLoader:upLoader
						}
				}
			}
		}

		//trace(maps.count());

		for (key => value in maps) {
			if (FileSystem.exists(value.cn) && FileSystem.exists(value.en)) {
				var s = File.getContent(value.cn);

				var s2 = File.getContent(value.en);
				var s = File.getContent(value.en);
				var s2 = File.getContent(value.cn);

				trace('merge ${value.en}');



				if(value.upLoader==""){
					trace(value);
					throw "upLoader is null";
				}
				try{


					var result = Merge.MergeTwoVTT(s, s2,value.id,value.upLoader);

					var f = Path.withoutExtension(value.en);
					File.saveContent(f + ".json", Json.stringify(result));
					trace('**** ${value.json}');
				}catch(e){

					trace(Std.string(e));
				}
				
			}else{

				trace('error');
			}
		}
	}
}
