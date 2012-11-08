package;

import neko.HaqNative;

class TestsA extends haxe.unit.TestCase
{
    public function testBasic()
    {
		HaqNative.copyFilePreservingAttributes("Привет.txt", "Привет2.txt");
		this.assertTrue(true);
    }
}
