Ant-like methods on haxe platform (neko / php)
==============================================

Synopsys
--------

####CmdOptions
Helper class to parse command-line arguments.

```haxe
var options = new CmdOptions();
options.add("keyA", "myDefaultValue", [ "-a", "--key-a" ], "Description of keyA param.")
options.add("keyB", 0, [ "-b", "--key-b" ], "Description of keyA param.")
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
    
    // TODO: useful code
}
```

####PathTools
```haxe
PathTools.normalize("c:\\dir\\file\\") // => "c:/dir/file"
PathTools.getRelative("c:\\mydirA\\mydirB", "c:\\mydirA\\mydirC") // => "../mydirC"
PathTools.makeNative("c:/mydir/file/") // => "c:\\mydir\\file\\" for Windows, no change on other OS
```

####Process
Safety run process & read output.
```haxe
var r = Process.run("haxe", [ "myoption" ]);
r.exitCode // int
r.output // written to stdout
r.error // written to stderr
```
