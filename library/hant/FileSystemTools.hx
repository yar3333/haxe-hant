package hant;

import stdlib.Exception;
#if unicode
import unicode.FileSystem;
import unicode.File;
#else
import sys.FileSystem;
import sys.io.File;
#end
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
		path = Path.normalize(path);
		
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
		src = Path.normalize(src);
        dest = Path.normalize(dest);
		
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
						deleteDirectory(path + "/" + file, verbose);
					}
					else
					{
						deleteFile(path + "/" + file, verbose);
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
	
	public static function copyFile(src:String, dest:String, verbose=true)
	{
		if (verbose) Log.start("Copy " + src + " => " + dest);
		try
		{
			createDirectory(Path.directory(dest), false);
			nativeCopyFile(src, dest);
		}
		catch (e:Dynamic)
		{
			if (verbose) Log.finishFail();
			Exception.rethrow(e);
		}
		if (verbose) Log.finishSuccess();
	}
	
	/**
	 * Find and remove empty directories. Return true if specified base directory was removed.
	 */
	public static function removeEmptyDirectories(baseDir:String, removeSelf=false) : Bool
	{
		var childCount = 0;
		
		for (file in FileSystem.readDirectory(baseDir))
		{
			childCount++;
			
			var isDir = false;
			try isDir = FileSystem.isDirectory(baseDir + "/" + file)
			catch (e:Dynamic) {}
			
			if (isDir)
			{
				if (removeEmptyDirectories(baseDir + "/" + file, true)) childCount--;
			}
		}
		
		if (removeSelf && childCount == 0)
		{
			FileSystem.deleteDirectory(baseDir);
			return true;
		}
		
		return false;
	}
	
	#if (neko && !hant_no_ndll)
	static var copy_file_preserving_attributes : Dynamic->Dynamic->Dynamic;
	static function nativeCopyFile(src:String, dest:String)
	{
		if (Sys.systemName() == "Windows")
		{
			if (copy_file_preserving_attributes == null)
			{
				try copy_file_preserving_attributes = neko.Lib.load("hant", "copy_file_preserving_attributes", 2)
				catch (_:Dynamic) {}
			}
			
			if (copy_file_preserving_attributes != null)
			{
				var r = copy_file_preserving_attributes(neko.Lib.haxeToNeko(Path.makeNative(src)), neko.Lib.haxeToNeko(Path.makeNative(dest)));
				switch (r)
				{
					case 0: // nothing to do
					case 1: throw "Error open source file ('" + src + "').";
					case 2: throw "Error open dest file ('" + dest + "').";
					case 3: throw "Error get attributes from source file ('" + src + "').";
					case 4: throw "Error set attributes to dest file ('" + dest + "').";
					case _: throw "Error code is " + r + ".";
					
				}
			}
			else
			{
				File.copy(src, dest);
			}
		}
		else
		{
			File.copy(src, dest);
		}
	}
	#else
	static inline function nativeCopyFile(src:String, dest:String)
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