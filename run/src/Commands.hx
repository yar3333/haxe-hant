import hant.CmdOptions;
import hant.FlashDevelopProject;
import neko.Lib;
using StringTools;
using Lambda;

class Commands
{
	var verbose : Bool;
	var exeDir : String;
	
	public function new(exeDir:String, verbose:Bool)
	{
		this.exeDir = exeDir;
		this.verbose = verbose;
	}
	
	public function fdbuild(args:Array<String>)
	{
		var options = new CmdOptions();
		
		options.add("--port", 0, "Haxe compiler server port (speedup recompiling). Server will start if not running.");
		options.add("path", "", "Path to dir or *.hxproj file. If path is dir, then first found *.hxproj file in that dir will be used.");
		
		if (args.length != 1 || args[0] != "--help")
		{
			var addParams = [];
			
			var sep = args.indexOf("--");
			if (sep >= 0)
			{
				addParams = args.splice(sep + 1, args.length - sep - 1);
				args.pop(); // remove "--"
			}
			
			options.parse(args);
			
			var project = FlashDevelopProject.load(options.get("path"));
			if (project != null)
			{
				project.build(addParams, options.get("port"));
			}
			else
			{
				Lib.println("ERROR: FlashDevelop haxe project not found by path '" + options.get("path") + "'.");
				Sys.exit(1);
			}
		}
		else
		{
			Lib.println("Build using FlashDevelop project (*.hxproj).");
			Lib.println("Usage: haxelib run hant [-v] fdbuild [ --port <PORT> ] [<path>] [ -- <additional_haxe_compiler_options>]");
			Lib.println("where '-v' is the verbose key. Command args description:");
			Lib.println("");
			Lib.print(options.getHelpMessage());
			Lib.println("");
			Lib.println("Examples:");
			Lib.println("");
			Lib.println("    haxelib run hant fdbuild .");
			Lib.println("        Build project using *.fdproj file from the current directory.");
			
		}
	}
}