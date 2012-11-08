package hant;

private typedef TAction = 
{
	var name : String;
	var switches : Array<String>;
	var action : ValueType;
	var help : String;
}

/**
 * Usage example:
 * var parser = new CommandLineOptionsParser();
 * parser.addOption('isRecursive', [ '-r', '--recursive'], ValueType.true_, '');
 * parser.addOption([ '-c', '--count'], ValueType.int, '');
 * parser.parse([ 'test', '-c10', '-r' ]);
 * // now: 
 * // parser.options = { 'c' => 10, 'r' => true }
 */
class CommandLineOptionsParser<Options>
{
	public var options(default, null) : Options;
	public var params : Array<String>;
	
	var args : Array<String>;
	
	/**
	 * switch => field
	 * '-r' => 'isRecursive'
	 */
	var switches : Hash<String>;

	public function new()
	{
		actions = new Array();
	}

	public function getHelpMessage() : String
	{
		var s = "";
		for (a in actions)
		{
			s += a.switches.join(", ");
			if (a.switches.length > 1)
			{
				s += "\n";
			}
			if (a.help != null) 
			{
				s += "\t" + a.help;
			}
			s += "\n";
		}
		s += "\n";
		return s;
	}

	public function parse(args:Array<String>) : Void
	{
		if (args.length != null)
		{
			this.args = args.copy();
			
			options = new Options();
			params = new Array<String>();
			
			var meta = haxe.rtti.Meta.getFields(Options);
			switches = new Hash<String>();
			for (f in Reflect.fields(options))
			{
				if (!Reflect.isFunction(Reflect.field(options, f)))
				{
					for (sw in Reflect.field(meta, f)
					switches.set(f, 
				}
			}
			
			while (this.args.length > 0)
			{
				parseElement();
			}
		}
	}

	function parseElement()
	{
		var arg = args.shift();
		
		if (arg.substr(0, 1) == "-")
		{
			~/((?:--*).+)=(.+)/.customReplace(arg, function(r)
			{
				arg = r.matched(1);
				args.unshift(r.matched(2));
				return "";
			});
			
			for (a in actions)
			{
				for (s in a.switches)
				{
					if (s == arg)
					{
						resolveSwitch(arg, a.action);
					}
					else
					{
						if (s == arg.substr(0, s.length))
						{
							args.unshift(arg.substr(s.length));
							resolveSwitch(s, a.action);
						}
					}
				}
			}
		}
		else
		{
			params.push(arg);
		}
	}

	function resolveSwitch(s:String, type:ValueType) : Void
	{
		switch (type)
		{
			case ValueType.true_(name):
				options.set(name, true);
			
			case ValueType.false_(name):
				options.set(name, false);
			
			case ValueType.int(name):
				ensureValueExist(s);
				options.set(name, Std.parseInt(suppressQuotes(args.shift())));
				
			case ValueType.float(name):
				ensureValueExist(s);
				options.set(name, Std.parseFloat(suppressQuotes(args.shift())));
				
			case ValueType.string(name):
				ensureValueExist(s);
				options.set(name, suppressQuotes(args.shift()));
				
			case ValueType.bool(name):
				ensureValueExist(s);
				options.set(name, Std.bool(suppressQuotes(args.shift())));
		}
	}
	
	function ensureValueExist(s:String) : Void
	{
		if (args.length == 0)
		{
			throw "Missing value after '" + s + "' switch.";
		}
	}
	
	function suppressQuotes(s:String) : String
	{
		s = ~/'([^']+)'/g.replace( s, "$1" );
		s = ~/"([^"]+)"/g.replace( s, "$1" );
		return s;
	}
}