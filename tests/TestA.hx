package;

import hant.Hant;

class TestA extends haxe.unit.TestCase
{
    public function testSimple()
    {
		var hant = new Hant(new hant.Log(5), "../hant-windows");
    }
}
