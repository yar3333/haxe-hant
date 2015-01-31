import hant.CmdOptions;
import hant.FileSystemTools;
import hant.FlashDevelopProject;
import hant.Ftp;
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
					Lib.println("ERROR: FlashDevelop haxe project not found by path '" + options.get("path") + "'.");
				}
			}
			catch (e:AmbiguousProjectFilesException)
			{
				Lib.println("ERROR: " + e.message);
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
			Lib.println("    haxelib run hant fdbuild");
			Lib.println("        Build project using *.fdproj file from the current directory.");
		}
		
		return 1;
	}
	
	public function ftp(args:Array<String>) : Int
	{
		var options = new CmdOptions();
		
		options.add("sourcePath", "", "Source path.");
		options.add("destPath", "", "Destination path.");
		
		if (args.length != 1 || args[0] != "--help")
		{
			options.parse(args);
			
			var sourcePath = options.get("sourcePath");
			var destPath = options.get("destPath");
			if (sourcePath != "") fail("Source path must be specified.");
			if (destPath != "") fail("Destination path must be specified.");
			
			var re = ~/^([_a-zA-Z0-9]+):(.+?)@([-_.a-zA-Z0-9]+)(?:[:](\d+))?\/([-_a-zA-Z0-9]+)$/;
			
			if (sourcePath.startsWith("ftp://"))
			{
				if (!re.match(sourcePath.substring("ftp://".length))) fail("Incorrect ftp path format (" + sourcePath + ").");
				return ftpDownload(re.matched(1), re.matched(2), re.matched(3), re.matched(4) != null && re.matched(4) != "" ? Std.parseInt(re.matched(4)) : 21, re.matched(5), destPath);
			}
			else
			if (destPath.startsWith("ftp://"))
			{
				if (!re.match(destPath.substring("ftp://".length))) fail("Incorrect ftp path format (" + destPath + ").");
				return ftpUpload(sourcePath, re.matched(1), re.matched(2), re.matched(3), re.matched(4) != null && re.matched(4) != "" ? Std.parseInt(re.matched(4)) : 21, re.matched(5));
			}
		}
		else
		{
			Lib.println("Working with FTP server.");
			Lib.println("Usage: haxelib run hant [-v] ftp <sourcePath> <destPath>");
			Lib.println("where '-v' is the verbose key. Command args description:");
			Lib.println("");
			Lib.print(options.getHelpMessage());
			Lib.println("");
			Lib.println("Path to ftp server must be specified in the  form 'ftp://USER:PASSWORD@HOST/DIRECTORY'.");
			Lib.println("If path not starts with 'ftp://' then it treated as regular local path.");
		}
	}
	
	function ftpDownload(user, pass, host, port:Int, dir, dest) : Int
	{
		if (dest.startsWith("ftp://")) fail("Copying from FTP to FTP is not supported.");
		
		var ftp = new Ftp(host, port);
		ftp.login(user, pass);
		if (dir != null && dir != "") ftp.cwd(dir);
		ftpDownloadInner(ftp, dest);
		
		return 1;
	}
	
	function ftpDownloadInner(ftp:Ftp, dest:String)
	{
		FileSystemTools.createDirectory(dest);
		
	}
	
	function ftpUpload(src, user, pass, host, port:Int, dir) : Int
	{
		if (src.startsWith("ftp://")) fail("Copying from FTP to FTP is not supported.");
		return 1;
	}
	
	static function fail(message:String)
	{
		Sys.println("ERROR: " + message);
		Sys.exit(1);
	}
}