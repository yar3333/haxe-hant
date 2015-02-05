import hant.CmdOptions;
import hant.FlashDevelopProject;
import hant.Haxelib;
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
	
	public function fdbuild(args:Array<String>) : Int
	{
		var options = new CmdOptions();
		
		options.add("outputPath", "", [ "--output-path", "-o" ], "Override output path.");
		options.add("outputType", "", [ "--output-type", "-t" ], "Override output type ('Application' or 'CustomBuild').");
		options.add("platform", "", [ "--platform", "-p" ], "Override target platform.");
		options.add("mainClass", "", [ "--main-class", "-main" ], "Override main class.");
		options.add("noPreBuild", false, [ "--no-prebuild", "-nopre" ], "Do not do pre-build step.");
		options.add("noPostBuild", false, [ "--no-postbuild", "-nopost" ], "Do not do post-build step.");
		options.add("port", 0, [ "--port" ], "Haxe compiler server port (speedup recompiling). Server will start if not running.");
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
			
			try
			{
				var project = FlashDevelopProject.load(options.get("path"));
				if (project != null)
				{
					if (options.get("outputPath") != "") project.outputPath = options.get("outputPath");
					if (options.get("outputType") != "") project.outputType = options.get("outputType");
					if (options.get("platform") != "") project.platform = options.get("platform");
					if (options.get("mainClass") != "") project.mainClass = options.get("mainClass");
					if (options.get("noPreBuild")) project.preBuildCommand = "";
					if (options.get("noPostBuild")) project.postBuildCommand = "";
					
					return project.build(addParams, options.get("port"));
				}
				else
				{
					Sys.println("ERROR: FlashDevelop haxe project not found by path '" + options.get("path") + "'.");
				}
			}
			catch (e:AmbiguousProjectFilesException)
			{
				Sys.println("ERROR: " + e.message);
			}
		}
		else
		{
			Sys.println("Build using FlashDevelop project (*.hxproj).");
			Sys.println("Usage: haxelib run hant [-v] fdbuild [ --port <PORT> ] [<path>] [ -- <additional_haxe_compiler_options>]");
			Sys.println("where '-v' is the verbose key. Command args description:");
			Sys.println("");
			Sys.print(options.getHelpMessage());
			Sys.println("");
			Sys.println("Examples:");
			Sys.println("");
			Sys.println("    haxelib run hant fdbuild");
			Sys.println("        Build project using *.fdproj file from the current directory.");
		}
		
		return 1;
	}
	
	public function path(args:Array<String>) : Int
	{
		var options = new CmdOptions();
		
		options.addRepeatable("libs", String, "Library name. You may specify several libraries.");
		
		if (args.length > 0 && args[0] != "--help")
		{
			options.parse(args);
			var libs : Array<String> = options.get("libs");
			for (lib in libs)
			{
				var path = Haxelib.getPath(lib);
				if (path == null) return 1;
				Sys.println(path);
			}
			return 0;
		}
		else
		{
			Sys.println("Get class paths of the specified haxe libraries.");
			Sys.println("Use 'std' as library name to get path to standard library.");
			Sys.println("Usage: haxelib run hant path <library1> [ ... <libraryN>]");
		}
		
		return 1;
	}
}