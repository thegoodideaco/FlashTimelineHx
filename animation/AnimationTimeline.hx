package animation;

import animation.AnimationLayer.FrameLabel;
import flash.errors.Error;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import haxe.xml.Fast;


/**
 * TODO:
 * 1. Add duration scaling
 * 2. Add label name features
 * @author Jonathan Snyder
 */
class AnimationTimeline implements IFlxDestroyable {
	
	var xml:Xml;
	var fast:Fast;
	
	public var target(default, null):Dynamic;
	public var targetFields(default, null):Array<String>;
	public var currentFrame(default, set):Int = 0;
	public var totalFrames(default, null):Int = 0;
	public var layers:Array<AnimationLayer>;
	public var frameLabels(default, null):Array<FrameLabel> = [];
	private var tween:FlxTween;

	public function new(XmlString:String, Target:Dynamic) {
		
		
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
			
			
			//find any frames with labels on them, and store them
			for (frame in layer.node.resolve("frames").nodes.resolve("DOMFrame")) {
				if (frame.has.resolve("name")) {
					var label:FrameLabel = {
						name: frame.att.resolve("name"),
						index: Std.parseInt(frame.att.resolve("index"))
					}
					
					frameLabels.push(label);
				}
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
	
	
	/**
	 * Finds a frame number based off of a label string
	 * @param	LabelStr
	 * @return
	 */
	public function getFrameIndexByLabel(LabelStr:String):FrameLabel {
		var label:FrameLabel = null;
		
		for (frame in frameLabels) {
			if (frame.name == LabelStr) {
				label = frame;
				break;
			}
		}
		
		
		return label;
	}
	
	public function play(?OnComplete:TweenCallback):FlxTween {
		if (tween != null) {
			tween.destroy();
		}
		
		return tween = FlxTween.tween(this, {currentFrame: this.totalFrames}, this.totalFrames / FlxG.drawFramerate, {
			onComplete: OnComplete
		});

	}
	
	
	public function playToLabel(LabelStr:String, ?OnComplete:TweenCallback):FlxTween {
		var frame:FrameLabel = getFrameIndexByLabel(LabelStr);
		
		if (frame == null) {
			throw new Error("this frame " + LabelStr + " does not exist");
		} else {
			if (tween != null && tween.active) {
				tween.cancel();
			}
			
			
		}
		
		return tween = FlxTween.tween(this, {
			currentFrame: (frame.index + 1)
		}, (frame.index - (currentFrame - 1)) / FlxG.updateFramerate, {
										  onComplete: OnComplete
									  });
	}
	
	
	public function stop() {
		tween.cancel();
	}
	
	
	/* INTERFACE flixel.util.FlxDestroyUtil.IFlxDestroyable */
	public function destroy():Void {
		tween.cancel();
		
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