Ant-like methods primary for haxe sys platforms (neko / php / cpp)
==================================================================

Also allow build FlashDevelop haxe projects:
```shell
# find *.hxproj in current dir & parse it & call haxe compiler
haxelib run hant fdbuild 
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

PathTools
---------
```haxe
PathTools.normalize("c:\\dir\\file\\") // => "c:/dir/file"
PathTools.getRelative("c:/mydirA/mydirB", "c:/mydirA/mydirC") // => "../mydirC"
PathTools.makeNative("c:/mydir/file/") // => "c:\\mydir\\file\\" for Windows, no change on other OS
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
Log.instance = new Log(5); // init log at the start of your application; 5 - nesting level limit (messages with greater nesting level will be ignored)
...
Log.start("MyProcessStartMessage");
...
Log.echo("myMessage");
...
if (good) Log.finishSuccess(); // finish Process
else      Log.finishFail();
```

FlashDevelopProject
-------------------
Helper to parse *.hxproj files.
```haxe
var project = FlashDevelopProject.load("myProject.hxproj");
trace(project.libs);
project.build();
```