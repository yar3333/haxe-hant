package hant;

import haxe.io.Bytes;
import neko.Lib;
import neko.vm.Thread;
using StringTools;

private class Stdin extends haxe.io.Output
{
	var p : Dynamic;
	var buf : haxe.io.Bytes;

	public function new(p)
	{
		this.p = p;
		buf = haxe.io.Bytes.alloc(1);
	}

	override public function close()
	{
		super.close();
		_stdin_close(p);
	}

	override public function writeByte(c)
	{
		buf.set(0, c);
		writeBytes(buf, 0, 1);
	}

	override public function writeBytes(buf:haxe.io.Bytes, pos:Int, len:Int) : Int
	{
		try 
		{
			return _stdin_write(p, buf.getData(), pos, len);
		}
		catch (e:Dynamic)
		{
			throw new haxe.io.Eof();
		}
	}

	static var _stdin_write = NdllTools.loadLazy("hant","process_stdin_write", 4);
	static var _stdin_close = NdllTools.loadLazy("hant","process_stdin_close", 1);
}

private class Stdout extends haxe.io.Input
{
	var p : Dynamic;
	var out : Bool;
	var buf : haxe.io.Bytes;

	public function new(p, out)
	{
		this.p = p;
		this.out = out;
		buf = haxe.io.Bytes.alloc(1);
	}

	public override function readByte()
	{
		if (readBytes(buf,0,1) == 0) throw haxe.io.Error.Blocked;
		return buf.get(0);
	}

	public override function readBytes(str:haxe.io.Bytes, pos:Int, len:Int) : Int
	{
		try
		{
			return (out ? _stdout_read : _stderr_read)(p, str.getData(), pos, len);
		}
		catch (e:Dynamic)
		{
			throw new haxe.io.Eof();
		}
	}

	static var _stdout_read = NdllTools.loadLazy("hant","process_stdout_read", 4);
	static var _stderr_read = NdllTools.loadLazy("hant","process_stderr_read", 4);
}

/**
 * Exception with type Int may be thown by runDetached.
 */
class ProceessErrorCode
{
	public static inline var UNKNOW = 0;
	public static inline var ARG_LIST_TOO_LONG = 1;
	public static inline var INVALID_ARGUMENT = 2;
	public static inline var FILE_NOT_FOUND = 3;
	public static inline var FORMAT_ERROR = 4;
	public static inline var NOT_ENOUGH_MEMORY = 5;
}

class Process
{
	/**
	 * Minimizes a window, even if the thread that owns the window is not responding. This flag should only be used when minimizing windows from a different thread.
	 */
	public static inline var SW_FORCEMINIMIZE = 11;

	/**
	 * Hides the window and activates another window.
	 */
	public static inline var SW_HIDE = 0;
		
	/**
	 * Maximizes the specified window.
	 */
	public static inline var SW_MAXIMIZE = 3;

	/**
	 * Minimizes the specified window and activates the next top-level window in the Z order.
	 */
	public static inline var SW_MINIMIZE = 6;

	/**
	 * Activates and displays the window. If the window is minimized or maximized, the system restores it to its original size and position. An application should specify this flag when restoring a minimized window.
	 */
	public static inline var SW_RESTORE = 9;

	/**
	 * Activates the window and displays it in its current size and position.
	 */
	public static inline var SW_SHOW = 5;

	/**
	 * Sets the show state based on the SW_ value specified in the STARTUPINFO structure passed to the CreateProcess function by the program that started the application.
	 */
	public static inline var SW_SHOWDEFAULT = 10;

	/**
	 * Activates the window and displays it as a maximized window.
	 */
	public static inline var SW_SHOWMAXIMIZED = 3;

	/**
	 * Activates the window and displays it as a minimized window.
	 */
	public static inline var SW_SHOWMINIMIZED = 2;
	
	/**
	 * Displays the window as a minimized window. This value is similar to SW_SHOWMINIMIZED, except the window is not activated.
	 */
	public static inline var SW_SHOWMINNOACTIVE = 7;
	
	/**
	 * Displays the window in its current size and position. This value is similar to SW_SHOW, except that the window is not activated.
	 */
	public static inline var SW_SHOWNA = 8;
	
	/**
	 * Displays a window in its most recent size and position. This value is similar to SW_SHOWNORMAL, except that the window is not activated.
	 */
	public static inline var SW_SHOWNOACTIVATE = 4;
	
	/**
	 * Activates and displays a window. If the window is minimized or maximized, the system restores it to its original size and position. An application should specify this flag when displaying the window for the first time.	
	 */
	public static inline var SW_SHOWNORMAL = 1;
	
	var p : Dynamic;
	public var stdout(default,null) : haxe.io.Input;
	public var stderr(default,null) : haxe.io.Input;
	public var stdin(default,null) : haxe.io.Output;

	public function new(cmd:String, args:Array<String>, showWindowFlag=SW_HIDE, useStdHandles=true) : Void
	{
		p = try _run(untyped cmd.__s, neko.Lib.haxeToNeko(args), showWindowFlag, useStdHandles) catch( e : Dynamic ) throw "Process creation failure : "+cmd;
		if (useStdHandles)
		{
			stdin = new Stdin(p);
			stdout = new Stdout(p,true);
			stderr = new Stdout(p, false);
		}
	}

	public function getPid() : Int return _pid(p);

	public function exitCode() : Int return _exit(p);

	public function close() : Void _close(p);

	public function kill() : Void _kill(p);

	public static function run(fileName:String, args:Array<String>, ?input:String, verbose=false, ?log:Log) : { exitCode:Int, output:String, error:String }
	{
		if (log != null)
		{
			log.trace(fileName.replace("/", "\\") + " " + args.join(" "));
		}		
		
		var p = new Process(fileName, args);
		
		if (input != null)
		{
			p.stdin.writeString(input);
			p.stdin.close();
		}
		
		var output : String = null;
		Thread.create(function()
		{
			var buffer = new StringBuf();
			try
			{
				while (true)
				{
					var s = p.stdout.readString(1);
					for (i in 0...s.length)
					{
						var c = s.charAt(i);
						if (verbose && c == "\n")
						{
							var bufStr = buffer.toString();
							var n = bufStr.lastIndexOf("\n");
							Lib.println(n < 0 ? bufStr : bufStr.substr(n + 1));
						}
						buffer.add(c);
					}
				}
			}
			catch (e:haxe.io.Eof) { }
			output = buffer.toString();
		});
		
		var error : String = null;
		Thread.create(function()
		{
			var buffer = new StringBuf();
			try
			{
				while (true)
				{
					var s = p.stderr.readString(1);
					for (i in 0...s.length)
					{
						var c = s.charAt(i);
						if (verbose && c == "\n")
						{
							var bufStr = buffer.toString();
							var n = bufStr.lastIndexOf("\n");
							Lib.println(n < 0 ? bufStr : bufStr.substr(n + 1));
						}
						buffer.add(c);
					}
				}
			}
			catch (e:haxe.io.Eof) { }
			error = buffer.toString();
		});
		
		var exitCode = p.exitCode();
		
		while (output == null || error == null) Sys.sleep(0.01);
		
		p.close();
		
		if (exitCode != 0)
		{
			if (log != null)
			{
				log.trace("Run error: " + exitCode);
			}
		}
		
		return { exitCode:exitCode, output:output.replace("\r", ""), error:error };
	}
	
	/**
	 * Run child process detached and return PID.
	 */
	public static function runDetached(fileName:String, args:Array<String>) : Int
	{
		return Lib.nekoToHaxe(_run_detached(Lib.haxeToNeko(fileName), Lib.haxeToNeko(args)));
	}
	
	static var _run = NdllTools.loadLazy("hant","process_run", 4);
	static var _exit = NdllTools.loadLazy("hant","process_exit", 1);
	static var _pid = NdllTools.loadLazy("hant","process_pid", 1);
	static var _close = NdllTools.loadLazy("hant","process_close", 1);
	static var _kill = NdllTools.loadLazy("hant","process_kill", 1);
	static var _run_detached = NdllTools.loadLazy("hant", "process_run_detached", 2);
}
