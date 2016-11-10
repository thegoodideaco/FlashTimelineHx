package animation;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import haxe.xml.Fast;


/**
 * ...
 * @author Jonathan Snyder
 */
class AnimationTimeline {
	
	var xml:Xml;
	var fast:Fast;
	
	public var target(default, null):FlxGroup;
	public var targetFields(default, null):Array<String>;
	public var currentFrame(default, set):Int = 0;
	public var totalFrames(default, null):Int = 0;
	public var layers:Array<AnimationLayer>;

	public function new(XmlString:String, Target:FlxGroup) {
		
		
		target = Target;
		targetFields = Type.getInstanceFields(Type.getClass(Target));
		
		xml = Xml.parse(XmlString);
		fast = new Fast(xml.firstElement());
		
		
		//populate layers
		layers = [];
		var _layers:List<Fast> = fast.node.resolve("timeline").node.resolve("DOMTimeline").node.resolve("layers").nodes.resolve("DOMLayer");
		for (layer in _layers) {
			var layerTarget:FlxSprite = null;
			var layerName:String = DataHelper.getAttribute(layer, "name");
			
			
			//if the layer has a name and that name refers to an object in the target
			if (layerName != null && targetFields.indexOf(layerName) != 1) {
				var obj = Reflect.getProperty(Target, layerName);
				
				
				//map target to layer if it's a FlxObject
				if (Std.is(obj, FlxSprite)) {
					layerTarget = cast obj;
				}
			}
			
			
			if (layerTarget != null) {
				var animLayer:AnimationLayer = new AnimationLayer(layer, layerTarget, this);
				layers.push(animLayer);
				
				
				//update total amount of frames
				totalFrames = FlxMath.maxInt(totalFrames, animLayer.totalFrames);
				
			}
			
			
		}
	}
	
	public function applyProperties() {
		for (layer in layers) {
			layer.applyProperties();
		}
	}
	
	public function getLayerByName(Name:String):AnimationLayer {
		var layer:AnimationLayer = null;
		var matches:Array<AnimationLayer> = layers.filter(function(f:AnimationLayer) {
			return f.name == Name;
		});
		
		if (matches.length > 0) {
			layer = matches[0];
		}
		
		return layer;
	}
	
	public function play(?OnComplete:TweenCallback) {
		FlxTween.tween(this, {currentFrame: this.totalFrames}, this.totalFrames / 60, {
			onComplete: OnComplete
		});
	}
	
	
	function set_currentFrame(value:Int):Int {
		if (Math.isNaN(value)) {
			value = 1;
		}
		
		value = Std.int(FlxMath.bound(value, 1, totalFrames));
		currentFrame = value;
		
		for (layer in layers) {
			layer.currentFrame = value;
		}
		
		
		return currentFrame;
	}
	
	
}