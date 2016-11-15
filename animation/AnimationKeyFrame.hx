package animation;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.util.FlxColorTransformUtil;
import haxe.xml.Fast;
import openfl.geom.ColorTransform;

/**
 * ...
 * @author Jonathan Snyder
 */
class AnimationKeyFrame {

	var fast:Fast;
	var layer:AnimationLayer;
	
	public var target(get, null):FlxSprite;
	
	public var index(default, null):Int = 0;
	public var duration(default, null):Int = 0;
	public var name(default, null):String;
	public var hasTween(default, null):Bool;
	
	public var properties(default, null):KeyFrameProperties = {};
	public var eases(default, null):KeyFrameEases;
	
	public function new(data:Fast, Layer:AnimationLayer) {
		this.fast = data;
		this.layer = Layer;
		var _index:String = DataHelper.getAttribute(data, "index");
		var _duration:String = DataHelper.getAttribute(data, "duration");
		
		index = _index == null ? 0 : Std.parseInt(_index);
		duration = _duration == null ? 0 : Std.parseInt(_duration);
		name = DataHelper.getAttribute(data, "name");
		
		//the frame might not have eases even when there is a tween involved
		hasTween = data.has.resolve("tweenType");
		
		if (data.hasNode.resolve("tweens")) {
			parseCustomEases();
		}
		
		parseProperties();
	}
	
	function parseCustomEases() {
		
		eases = {};
		for (ease in fast.node.resolve("tweens").nodes.resolve("CustomEase")) {
			var targetStr:String = DataHelper.getAttribute(ease, "target");
			
			var curve:CustomEaseCurve = new CustomEaseCurve(DataHelper.getPointsFromEaseData(ease));
			Reflect.setField(this.eases, targetStr, curve);

			
		}
	}
	
	/**
	 * retrieve all property values
	 */
	function parseProperties() {
		var matrix:FlxMatrix = null;
		var transformationPoint:FlxPoint = null;
		var colorTransform:ColorTransform = null;
		
		var propertyNode:Fast = fast.node.resolve("elements").node.resolve("DOMSymbolInstance");
		
		var matrixData:Fast = DataHelper.getNode(propertyNode, "matrix");
		var transformData:Fast = DataHelper.getNode(propertyNode, "transformationPoint");
		var colorData:Fast = DataHelper.getNode(propertyNode, "color");
		var filterData:Fast = DataHelper.getNode(propertyNode, "filters");
		
		/**
		 * Setup Matrix Data
		 */
		properties.x = properties.y = 0;
		if (matrixData != null) {
			matrix = new FlxMatrix();
			
			matrixData = matrixData.node.resolve("Matrix");
			
			matrix.a = !matrixData.has.resolve("a") ? matrix.a : Std.parseFloat(matrixData.att.resolve("a"));
			matrix.b = !matrixData.has.resolve("b") ? matrix.b : Std.parseFloat(matrixData.att.resolve("b"));
			matrix.c = !matrixData.has.resolve("c") ? matrix.c : Std.parseFloat(matrixData.att.resolve("c"));
			matrix.d = !matrixData.has.resolve("d") ? matrix.d : Std.parseFloat(matrixData.att.resolve("d"));
			matrix.tx = !matrixData.has.resolve("tx") ? matrix.tx : Std.parseFloat(matrixData.att.resolve("tx"));
			matrix.ty = !matrixData.has.resolve("ty") ? matrix.ty : Std.parseFloat(matrixData.att.resolve("ty"));
			
			properties.x = matrix.tx;
			properties.y = matrix.ty;
			//properties.scaleX = matrix.a;
			//properties.scaleY = matrix.d;
			//properties.angle = Math.asin(matrix.b / Math.sqrt(matrix.a * matrix.a + matrix.b * matrix.b)) * FlxAngle.TO_DEG;
			properties.angle = matrix.b;

			var a = matrix.a;
			var b = matrix.b;
			var c = matrix.c;
			var d = matrix.d;
			var rotation:Float = 0;

			var scaleX = Math.sqrt((a * a) + (c * c));
			var scaleY = Math.sqrt((b * b) + (d * d));

			var sign = Math.atan(-c / a);
			var rad = Math.acos(a / scaleX);
			var deg = rad * FlxAngle.TO_DEG;

			if (deg > 90 && sign > 0) {
				rotation = (360 - deg) * FlxAngle.TO_RAD;
			}
			else if (deg < 90 && sign < 0) {
				rotation = (360 - deg) * FlxAngle.TO_RAD;
			}
			else {
				rotation = rad;
			}
			properties.angle = -deg;
			properties.scaleX = scaleX;
			properties.scaleY = scaleY;
		}
		
		/**
		 * Setup transformation data
		 */
		if (transformData != null) {
			transformationPoint = FlxPoint.get();
			
			
			transformData = transformData.node.resolve("Point");
			
			if (transformData.has.resolve("x")) {
				transformationPoint.x = Std.parseFloat(transformData.att.resolve("x"));
			}
			
			if (transformData.has.resolve("y")) {
				transformationPoint.y = Std.parseFloat(transformData.att.resolve("y"));
			}
		}
		
		
		/**
		 * Setup Color data
		 */
		properties.alpha = 1;
		if (colorData != null) {
			colorData = colorData.node.resolve("Color");
			colorTransform = new ColorTransform();
			for (att in colorData.x.attributes()) {
				var targetProp:Dynamic = Reflect.getProperty(colorTransform, att);
				
				var isFloat:Bool = Type.typeof(targetProp) == Type.ValueType.TFloat;
				var hasProp:Bool = Reflect.hasField(colorTransform, att);
				
				if (hasProp) {
					Reflect.setProperty(colorTransform, att, isFloat ? Std.parseFloat(colorData.att.resolve(att)) : Std.parseInt(colorData.att.resolve(att)));
				}
				
			}
			
			properties.alpha = !colorData.has.resolve("alphaMultiplier") ? 1 : Std.parseFloat(colorData.att.resolve("alphaMultiplier"));
			
			/**
			 * BUG WORKAROUND
			 * if a FlxSpriteGroup is within another group 3 levels down
			 * The alpha will never go back if it gets set to 0
			 */
			if (Std.is(target, FlxSpriteGroup) && properties.alpha == 0) {
				properties.alpha = .01;
			}
			
			
			properties.colorTransform = colorTransform;
		}
		
	}
	
	/**
	 * Adjust the targets propeties to be between frames
	 * @param	props properties to change
	 * @param	toFrame keyframe next
	 * @param	t time between 0 and 1
	 */
	public function interpolateProperties(props:Dynamic, toProps:Dynamic, t:Float) {
		for (prop in Reflect.fields(props)) {
			if (Reflect.hasField(toProps, prop)) {
				var targetProp:Dynamic = Reflect.getProperty(target, prop);
				var beginProp:Dynamic = Reflect.getProperty(properties, prop);
				var endProp:Dynamic = Reflect.getProperty(toProps, prop);
				
				//target.
				//if float or int
				if (targetProp != null && !(prop == "x" || prop == "y") && !Math.isNaN(targetProp)) {
					Reflect.setProperty(target, prop, beginProp + ((endProp - beginProp) * t));
				}
				
				var xpos = properties.x + ((toProps.x - properties.x) * t);
				var ypos = properties.y + ((toProps.y - properties.y) * t);
				
				
				/**
				 * if the container is a FlxSpriteGroup
				 * We need to offset the x and y positions to be relative to the group container
				 */
				if (layer.timeline != null && Std.is(layer.timeline.target, FlxSpriteGroup)) {
					
					xpos += Std.parseFloat(Std.string(Reflect.getProperty(layer.timeline.target, 'x')));
					ypos += Std.parseFloat(Std.string(Reflect.getProperty(layer.timeline.target, 'y')));
					
					
					//trace(Reflect.getProperty(layer.timeline.target, 'x'));
				}
				
				target.setPosition(xpos, ypos);


				switch (prop){
					case "scaleX":
						target.scale.x = beginProp + ((endProp - beginProp) * t);
					case "scaleY":
						target.scale.y = beginProp + ((endProp - beginProp) * t);
					case "angle":
						target.angle = beginProp + ((endProp - beginProp) * t);
					//trace(target.angle + "!");
				}
				
				
			}
		}
	}
	
	function get_target():FlxSprite {
		if (layer != null) {
			return layer.target;
		}
		
		return null;
	}
	
	
}


typedef KeyFrameProperties = {
?x:Float,
?y:Float,
?scaleX:Float,
?scaleY:Float,
?angle:Float,
?transformationPoint:FlxPoint,
?colorTransform:ColorTransform,
?alpha:Float
}

typedef KeyFrameEases = {
?all:CustomEaseCurve,
?position:CustomEaseCurve,
?rotation:CustomEaseCurve,
?scale:CustomEaseCurve,
?color:CustomEaseCurve,
?filters:CustomEaseCurve
}