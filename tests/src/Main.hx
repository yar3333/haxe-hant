package ;

class Main
{
    static function main()
	{
		var r = new haxe.unit.TestRunner();
		r.add(new HantTest());
		r.add(new LogTest());
		r.run();
	}
}
