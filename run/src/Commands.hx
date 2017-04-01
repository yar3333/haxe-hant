import hant.CmdOptions;
import hant.FlashDevelopProject;
import hant.Haxelib;
import sys.FileSystem;
using stdlib.StringTools;
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
		
		options.addRepeatable("opts", String, "Library name or *.hxproj file name. You may specify several libraries/projects files.");
		
		if (args.length == 0 || args[0] != "--help")
		{
			options.parse(args);
			var opts : Array<String> = options.get("opts");
			
			if (opts.length == 0) return pathsFromFlashDevelopFile("");
			
			for (opt in opts)
			{
				if (opt.endsWith(".hxproj"))
				{
					var r = pathsFromFlashDevelopFile(opt);
					if (r != 0) return r;
				}
				else
				{
					var path = Haxelib.getPath(opt);
					if (path == null)
					{
						Sys.stderr().writeString("Error detection path for the library '" + opt + "'.\n");
						return 1;
					}
					Sys.println(path);
				}
			}
			
			return 0;
		}
		else
		{
			Sys.println("Get class paths for the specified haxe libraries or FlashDevelop files.");
			Sys.println("Use 'std' as library name to get path to standard library.");
			Sys.println("If no arguments specifed, then *.hxproj file from the current directory is used.");
			Sys.println("Usage: haxelib run hant path [ <library_or_project_file1> [ ... <library_or_project_fileN>] ]");
		}
		
		return 1;
	}
	
	function pathsFromFlashDevelopFile(fdProjectFile:String) : Int
	{
		if (fdProjectFile != "" && !FileSystem.exists(fdProjectFile))
		{
			Sys.stderr().writeString(fdProjectFile != null ? "Project file '" + fdProjectFile + "' is not found.\n" : "Current found don't contains *.hxproj file.\n");
			return 3;
		}
		
		var project = FlashDevelopProject.load(fdProjectFile);
		if (project == null) return 2;
		
		for (lib in project.libs)
		{
			var path = Haxelib.getPath(lib);
			if (path == null)
			{
				Sys.stderr().writeString("Error detection path for the library '" + lib + "'.\n");
				return 1;
			}
			Sys.println(path);
		}
		
		for (path in project.classPaths)
		{
			Sys.println(path);
		}
		
		return 0;
	}
	
	public function compilerOptions(args:Array<String>) : Int
	{
		var options = new CmdOptions();
		
		options.add("project", "", "FlashDevelop *.hxproj file name.");
		
		if (args.length == 0 || args[0] != "--help")
		{
			options.parse(args);
			
			var project = FlashDevelopProject.load(options.get("project"));
			if (project == null)
			{
				Sys.stderr().writeString("Project file is not found.\n");
				return 2;
			}
			
			var params = new Array<String>();
			
			for (name in project.libs) { params.push("-lib"); params.push(name); }
			for (path in project.classPaths) { params.push("-cp"); params.push(path.rtrim("/")); }
			
			for (d in project.directives)
			{
				if (d != null && d != "")
				{
					params.push("-D"); params.push(d);
				}
			}
			
			params = params.concat(project.additionalCompilerOptions);
			
			Sys.println(params.join("\n"));
			
			return 0;
		}
		else
		{
			Sys.println("Get -lib, -cp, -D and additional haxe compiler options from FlashDevelop file.");
			Sys.println("If no arguments specifed, then *.hxproj file from the current directory is used.");
			Sys.println("Usage: haxelib run compiler-options [ <project_file> ]");
		}
		
		return 1;
	}
	
}