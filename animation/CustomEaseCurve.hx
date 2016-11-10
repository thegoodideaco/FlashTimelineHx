package animation;
import flixel.input.FlxPointer;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import haxe.xml.Fast;

/**
 * The container of multiple cubic bezier segments
 * @author Jonathan Snyder
 */
class CustomEaseCurve {

	public var segments(default, null):Array<BezierSegment> = [];
	
	
	public function new(points:Array<FlxPoint>) {
		var totalSegments:Int = Math.ceil(points.length / 4);
		
		
		var index:Int = 0;
		for (i in 0...totalSegments) {
			var a:FlxPoint = points[index];
			var b:FlxPoint = points[index + 1];
			var c:FlxPoint = points[index + 2];
			var d:FlxPoint = points[index + 3];
			
			var segment:BezierSegment = new BezierSegment(a, b, c, d);
			add(segment);
			
			index += 3;
		}
	}

	public function add(s:BezierSegment) {
		segments.push(s);
	}
	
	
	public function getValue(t:Float, ?point:FlxPoint):FlxPoint {
		var s = getSegmentFromTime(t);
		return s.getValue(t - s.a.x, point);
	}
	
	
	/**
	 * This can (probably) be used as an ease function
	 * @param	x
	 * @param	coefficients
	 * @return
	 */
	public function getYForX(x:Float, coefficients:Array<Float> = null):Float {
		var s = getSegmentFromTime(x);
		return s.getYForX(x, coefficients);
	}
	
	
	public function getSegmentFromTime(t:Float):BezierSegment {
		var s:BezierSegment = segments[0];
		
		
		if (t == 0) {
			return segments[0];
		} else if (t == 1) {
			return segments[segments.length - 1];
		} else {
			for (seg in segments) {
				if (seg.a.x <= t && seg.d.x > t) {
					s = seg;
					break;
					
				}
			}
		}
		
		return s;
	}
	
}