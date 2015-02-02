Ant-like methods primary for haxe sys platforms (neko / php / cpp)
==================================================================

Also allow build FlashDevelop haxe projects. For example, to find *.hxproj in current dir and build it run next command:
```shell
haxelib run hant fdbuild 
```
To get help use "--help" switch:
```shell
haxelib run hant fdbuild --help
```

CmdOptions
----------
Helper class to parse command-line arguments.

```haxe
var options = new CmdOptions();
options.add("keyA", "myDefaultValue", [ "-a", "--key-a" ], "Description of keyA param.")
options.add("keyB", 0, [ "-b", "--key-b" ], "Description of keyB param.")
options.addRepeatable("emails", String, [ "--email" ], "This key may be specified several times.");
options.add("file", "", "This is a param with no keys.");

if (Sys.args().length == 0)
{
    Lib.println("Usage: myapp <options> <file>");
    Lib.println("Options:");
    Lib.println(options.getHelpMessage());
    Lib.println("Example: myapp -a=mystr --key-b=123 --email=my1@gmail.com --email=my2@gmail.com readme.txt");
}
else
{
    options.parse(Sys.args());
    var keyA : String = options.get("keyA"); // example: "mystr"
    var keyB : Int = options.get("keyB"); // example: 123
    var emails : Array<String> = options.get("emails"); // example: ["my1@gmail.com", "my2@gmail.com"]
    var file : String = options.get("file"); // example: "readme.txt"
    
    // your code
}
```

Path
----
Extended version of the standard haxe.io.Path class. Additinal methods:
```haxe
Path.normalize("c:\\dir\\file\\") // => "c:/dir/file"
Path.join([ "pathA", "pathB" ]) // => "pathA/pathB"
Path.getRelative("c:/mydirA/mydirB", "c:/mydirA/mydirC") // => "../mydirC"
Path.makeNative("c:/mydir/file/") // => "c:\\mydir\\file\\" for Windows, "c:/mydir/file/" for others

```

Process
-------
```haxe
// Synchronously execute a process & read output (this method is more stable than standard sys.io.Process.run()):
var r = Process.run("haxe", [ "myoption" ]);
r.exitCode // exit code as int
r.output   // stdout as string
r.error    // stderr as string

// Start a process detached, so you can finish parent process and keep child alive:
Process.runDetached("myproc.exe", [ "myoption" ]);
```

Log
---
Helper to print beautiful log messages like Apache Ant produce. Support nesting level limit & detail level specification.
```haxe
Log.instance = new Log(); // init log at the start of your application
...
Log.start("MyProcessStartMessage");
...
Log.echo("myMessage");
...
if (good) Log.finishSuccess(); // finish Process
else      Log.finishFail();

// or

// inside: start(), callback(), and finishSuccess() on return or finishFail() on exception.
Log.process("MyProcessStartMessage", function()
{
	...
});
```

FlashDevelopProject
-------------------
Helper to parse *.hxproj files.
```haxe
var project = FlashDevelopProject.load("myProject.hxproj");
trace(project.libs);
var exitCode = project.build();
```

Haxelib & HaxeCompiler
----------------------
Helpers to get haxe lib paths & detect/call haxe compiler.


Console
----------------------
Helper to get string from user.
```haxe
Sys.print("Enter your name: ");
var name = Console.readLine();
trace(name);

```

NdllTools
---------
A class to find & load *.ndll neko modules. It's like neko.Lib.load(), but with a smart search for module file.
For example, if you want to load function from module "myModule" on Windows platform:
```haxe
var func = NdllTools.load("myModule", "prim", argCount);
```
NdllTool.load() test next paths:

 * %FOLDER_OF_CURRENT_MODULE%/myModule-windows.ndll
 * %FOLDER_OF_CURRENT_MODULE%/ndll/Windows/myModule.ndll
 * %NEKOPATH%/myModule.ndll
 * %HAXELIBS%/myModule/%VERSION%/ndll/Windows/myModule.ndll (useful if installed same-named haxe library)
