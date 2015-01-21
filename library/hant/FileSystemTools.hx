package hant;

import haxe.io.Path;
import stdlib.Exception;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
using StringTools;

class FileSystemTools
{
    public static function findFiles(path:String, ?onFile:String->Void, ?onDir:String->Bool, verbose=true) : Void
    {
		if (FileSystem.exists(path))
		{
			if (FileSystem.isDirectory(path))
			{
				for (file in FileSystem.readDirectory(path))
				{
					var isDir : Bool = null;
					try
					{
						isDir = FileSystem.isDirectory(path + "/" + file);
					}
					catch (e:Dynamic)
					{
						if (verbose) Log.echo("ERROR: FileSystem.isDirectory('" + path + "/" + file + "')");
					}
					
					if (isDir == true)
					{
						if (file != ".svn" && file != ".hg" && file != ".git")
						{
							if (onDir == null || onDir(path + "/" + file))
							{
								findFiles(path + "/" + file, onFile, onDir, verbose);
							}
						}
					}
					else
					if (isDir == false)
					{
						if (onFile != null) onFile(path + "/" + file);
					}
				}
			}
			else
			{
				if (onFile != null) onFile(path);
			}
		}
    }
    
    public static function createDirectory(path:String, verbose=true)
    {
		path = PathTools.normalize(path);
		
        if (path != "" && !FileSystem.exists(path))
		{
			if (verbose) Log.start("Create directory '" + path + "'");
			try
			{
				FileSystem.createDirectory(path);
				if (verbose) Log.finishSuccess();
			}
			catch (message:String)
			{
				if (verbose) Log.finishFail(message);
				Exception.rethrow(message);
			}
		}
    }
    
    public static function copyFolderContent(src:String, dest:String, verbose=true)
    {
		src = PathTools.normalize(src);
        dest = PathTools.normalize(dest);
		
		if (verbose) Log.start("Copy directory '" + src + "' => '" + dest + "'");
        
		findFiles(src, function(path)
		{
			copyFile(path, dest + path.substr(src.length), verbose);
		});
		
		if (verbose) Log.finishSuccess();
    }
	
	public static function rename(path:String, newpath:String, verbose=true)
    {
        if (verbose) Log.start("Rename '" + path + "' => '" + newpath + "'");
        try
        {
            if (FileSystem.exists(path))
            {
				createDirectory(Path.directory(newpath), false);
				
                if (!FileSystem.isDirectory(path))
				{
					if (FileSystem.exists(newpath) && !isSamePaths(path, newpath))
					{
						FileSystem.deleteFile(newpath);
					}
					FileSystem.rename(path, newpath);
				}
				else
				{
					if (FileSystem.exists(newpath) && !isSamePaths(path, newpath))
					{
						FileSystem.deleteDirectory(newpath);
					}
					FileSystem.rename(path, newpath);
				}
            }
            else
            {
                throw "File '" + path + "' not found.";
            }
            if (verbose) Log.finishSuccess();
        }
        catch (message:String)
        {
			if (verbose) Log.finishFail(message);
			Exception.rethrow(message);
        }
    }
    
    public static function deleteDirectory(path:String, verbose=true)
    {
        if (FileSystem.exists(path))
		{
			if (verbose) Log.start("Delete directory '" + path + "'");
			try
			{
				for (file in FileSystem.readDirectory(path))
				{
					if (FileSystem.isDirectory(path + "/" + file))
					{
						deleteDirectory(path + "/" + file);
					}
					else
					{
						deleteFile(path + "/" + file);
					}
				}

				FileSystem.deleteDirectory(path);
				if (verbose) Log.finishSuccess();
			}
			catch (message:String)
			{
				if (verbose) Log.finishFail(message);
				Exception.rethrow(message);
			}
		}
    }
	
    public static function deleteFile(path:String, verbose=true)
    {
        if (FileSystem.exists(path))
		{
			if (verbose) Log.start("Delete file '" + path + "'");
			try
			{
				FileSystem.deleteFile(path);
				if (verbose) Log.finishSuccess();
			}
			catch (message:String)
			{
				if (verbose) Log.finishFail(message);
				Exception.rethrow(message);
			}
		}
    }
	
	public static function deleteAny(path:String, verbose=true)
	{
		if (FileSystem.exists(path))
		{
			if (FileSystem.isDirectory(path))
			{
				deleteDirectory(path, verbose);
			}
			else
			{
				deleteFile(path, verbose);
			}
		}
	}
	
	public static function restoreFileTimes(src:String, dest:String, ?filter:EReg, verbose=true)
	{
		findFiles(src, function(srcFile)
		{
			if (filter == null || filter.match(srcFile))
			{
				var destFile = dest + srcFile.substr(src.length);
				if (FileSystem.exists(destFile) && File.getContent(srcFile) == File.getContent(destFile))
				{
					rename(srcFile, destFile, verbose);
				}
			}
		}, verbose);
	}
    
	public static function getHiddenFileAttribute(path:String) : Bool
	{
		if (Sys.systemName() == "Windows")
		{
			var p = new Process("attrib", [ path ]);
			var s = p.stdout.readAll().toString();
			if (s.length > 12)
			{
				s = s.substr(0, 12);
				return s.indexOf("H") >= 0;
			}
		}
		return false;
	}
	
	public static function setHiddenFileAttribute(path:String, hidden:Bool) : Void
	{
		if (Sys.systemName() == "Windows")
		{
			Sys.command("attrib", [ (hidden ? "+" : "-") + "H", path ]);
		}
	}
	
	#if neko
	static var copy_file_preserving_attributes : Dynamic->Dynamic->Dynamic;
	public static function copyFile(src:String, dest:String, verbose:Bool)
	{
		createDirectory(Path.directory(dest), false);
		
		if (Sys.systemName() == "Windows" && NdllTools.getPath("hant") != null)
		{
			if (copy_file_preserving_attributes == null)
			{
				copy_file_preserving_attributes = NdllTools.load("hant", "copy_file_preserving_attributes", 2);
			}
			
			var r : Int = neko.Lib.nekoToHaxe(copy_file_preserving_attributes(neko.Lib.haxeToNeko(PathTools.makeNative(src)), neko.Lib.haxeToNeko(PathTools.makeNative(dest))));
			
			if (r != 0)
			{
				if (r == 1)
				{
					throw "Error open source file ('" + src + "').";
				}
				else
				if (r == 2)
				{
					throw "Error open dest file ('" + dest + "').";
				}
				else
				if (r == 3)
				{
					throw "Error get attributes from source file ('" + src + "').";
				}
				else
				if (r == 4)
				{
					throw "Error set attributes to dest file ('" + dest + "').";
				}
				else
				{
					throw "Error code is " + r + ".";
				}
			}
		}
		else
		{
			File.copy(src, dest);
		}
	}
	#else
	public static inline function copyFile(src:String, dest:String) : Void
	{
		File.copy(src, dest);
	}
	#end
	
	static function isSamePaths(pathA:String, pathB:String)
	{
		pathA = FileSystem.fullPath(pathA);
		pathB = FileSystem.fullPath(pathB);
		return pathA == pathB || pathA.toLowerCase() == pathB.toLowerCase() && Sys.systemName() == "Windows";
	}
}