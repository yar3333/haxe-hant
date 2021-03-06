Tools primary for console applications (sys platforms: neko/php/cpp)
====================================================================

Note for `neko` platform
------------------------

Some classes load `hant.ndll`.
If you want to be sure about no dependency on `hant.ndll`,
use `-D hant-no-ndll` in haxe options to skip these classes/methods.

Embedded Commands
-----------------

Use `haxelib run hant` to get list of commands and `haxelib run hant <command> --help` to get help about command.

`fdbuild`

Allow build FlashDevelop haxe projects.
```shell
# Take *.hxproj from the current dir and build it:
haxelib run hant fdbuild
```

`path`

Return class paths for the specified haxe libraries. Use `std` as a name of the standard haxe library.

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

```haxe
// fast library path detect (run haxelib only once to detect a root path)
Haxelib.getPath("myLib")

// in regular case return value of the HAXE_STD_PATH
Haxelib.getStdPath()

// path to compiler executable file
HaxeCompiler.getPath()

// run compiler with a server support (if port specified)
HaxeCompiler.run(params, ?port, ?curDir, ?isEcho, ?isVerbose)
```

Console
----------------------
Helper to get string from user.
```haxe
Sys.print("Enter your name: ");
var name = Console.readLine();
trace(name);

```
