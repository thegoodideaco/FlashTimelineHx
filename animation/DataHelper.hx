package animation;
import flixel.math.FlxPoint;
import haxe.xml.Fast;

/**
 * ...
 * @author Jonathan Snyder
 */
class DataHelper {

	public static function getAttribute(xml:Fast, att:String):String {
		var str:String = null;
		
		if (xml.has.resolve(att)) {
			str = xml.att.resolve(att);
		}
		
		return str;
	}
	
	
	public static function getNode(xml:Fast, nodeName:String):Fast {
		var node:Fast = null;
		
		if (xml.hasNode.resolve(nodeName)) {
			node = xml.node.resolve(nodeName);
		}
		
		return node;
	}
	
	/**
	 * Creates an array of FlxPoints based on customEase xml data
	 * @param	data
	 * @return an array of points
	 */
	public static function getPointsFromEaseData(data:Fast):Array<FlxPoint> {
		var points:Array<FlxPoint> = [];
		
		for (pNode in data.nodes.resolve("Point")) {
			var point:FlxPoint = FlxPoint.get();
			
			if (pNode.has.resolve("x")) {
				point.x = Std.parseFloat(pNode.att.resolve("x"));
			}
			
			if (pNode.has.resolve("y")) {
				point.y = Std.parseFloat(pNode.att.resolve("y"));
			}
			
			points.push(point);
			
		}
		
		
		return points;
	}
	
}