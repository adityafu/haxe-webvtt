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

class Main implements IJSAsync {
	public static function main() {


        var regexp:EReg = ~/world/;

trace(regexp.match("hello world"));
// true : 'world' was found in the string

trace(regexp.match("hello")); 

        var parse=new ParseSRT();


       
        parse.parse( File.getContent("bin/test.srt"));

    }
}
