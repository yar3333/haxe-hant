package hant;

/**
 * Improved version of haxe.io.Path.
 */
class Path extends haxe.io.Path
{
	public static inline function withoutExtension(path:String) : String return haxe.io.Path.withoutExtension(path);
	public static inline function withoutDirectory(path:String) : String return haxe.io.Path.withoutDirectory(path);
	public static inline function directory(path:String) : String return haxe.io.Path.directory(path);
	public static inline function extension(path:String) : String return haxe.io.Path.extension(path);
	public static inline function withExtension(path:String, ext:String) : String return haxe.io.Path.withExtension(path, ext);
	public static inline function addTrailingSlash(path:String) : String return haxe.io.Path.addTrailingSlash(path);
	public static inline function removeTrailingSlashes(path:String) : String return haxe.io.Path.removeTrailingSlashes(path);
	
	/**
	 * Replace `\` to '/' and remove slashes at the end.
	 */
	public static function normalize(path:String) : String
	{
		path = StringTools.replace(path, "\\", "/");
		while (path.length > 1 && path.charAt(path.length - 1) == "/") path = path.substr(0, -1);
		return path;
	}
	
	public static function join(paths:Array<String>) : String
	{
		paths = paths.map(removeTrailingSlashes);
		if (paths.length == 1 && paths[0] == ".") return ".";
		paths = paths.filter(function(s) return s != "" && s != ".");
		return paths.join("/");
	}
	
	public static function getRelative(basePath:String, absolutePath:String) : String
	{
		#if sys
        if (basePath == "" || removeTrailingSlashes(basePath) == ".") basePath = sys.FileSystem.fullPath(".");
		#end
        
		basePath = StringTools.replace(basePath, "\\", "/");
        absolutePath = StringTools.replace(absolutePath, "\\", "/");
		
        var r = "";
        var commonPart = "";
        var basePathFolders = basePath.split("/");
        var absolutePathFolders = absolutePath.split("/");
        var i = 0;
        while (i < basePathFolders.length && i < absolutePathFolders.length)
        {
            if (basePathFolders[i].toLowerCase() == absolutePathFolders[i].toLowerCase())
            {
                commonPart += basePathFolders[i] + "/";
            }
            else
            {
                break;
            }
            i++;
        }
        if (commonPart.length > 0)
        {
            for (dir in basePath.substr(commonPart.length - 1).split("/"))
            {
                if (dir != "") r += "../";
            }
        }
        r += absolutePath.substr(commonPart.length);
        return r;
    }
	
	#if sys
	static var isWindows : Null<Bool>;
	public static function makeNative(path:String) : String
	{
		if (isWindows == null) isWindows = Sys.systemName() == "Windows";
		return isWindows ? StringTools.replace(path, "/", "\\") : StringTools.replace(path, "\\", "/");
	}
	#end
}