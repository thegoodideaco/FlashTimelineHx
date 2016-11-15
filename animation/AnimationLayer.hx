package animation;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import haxe.xml.Fast;
import openfl.geom.ColorTransform;

/**
 * TODO:
 * 1. Add duration scaling
 * 2. Add label name features
 * 3. Filters
 * 3. Rotation (Matrix)
 * 4. Color Transform
 * @author Jonathan Snyder
 */
class AnimationLayer {
	var fast:Fast;
	var _currentKeyFrame:AnimationKeyFrame;
	var _currentFrame:Int = 0;

	public var name(default, null):String;
	public var target:FlxSprite;
	public var timeline(default, null):AnimationTimeline;
	
	public var totalFrames(default, null):Int = 0;
	public var currentFrame(get, set):Int;
	
	public var keyFrames(default, null):Array<AnimationKeyFrame> = [];
	
	public var currentKeyFrame(get, null):AnimationKeyFrame;
	public var currentKeyFrameIndex(get, null):Int;
	public var currentKeyFrameInterpolation(get, null):Float;
	
	
	public var prevKeyFrame(get, null):AnimationKeyFrame;
	public var nextKeyFrame(get, null):AnimationKeyFrame;
	
	public var frameLabels(default, null):Array<FrameLabel> = [];
	
	public var autoKill:Bool;
	
	
	public function new(LayerData:Fast, Target:FlxSprite, ?Timeline:AnimationTimeline, ?AutoKill:Bool = true) {
		
		fast = LayerData;
		target = Target;
		timeline = Timeline;
		autoKill = AutoKill;
		name = DataHelper.getAttribute(fast, "name");
		
		target.origin.set();
		
		
		//create and store all keyframes
		var frameNode:Fast = DataHelper.getNode(fast, "frames");
		if (frameNode != null) {
			for (node in frameNode.nodes.resolve("DOMFrame")) {
				
				//checks if there are elements within the frame
				var isEmpty:Bool = !node.hasNode.resolve("elements") || node.hasNode.resolve("elements") && !node.node.resolve("elements").hasNode.resolve("DOMSymbolInstance");
				//create keyframe if it has elements inside
				if (!isEmpty) {
					var keyframe:AnimationKeyFrame = new AnimationKeyFrame(node, this);
					keyFrames.push(keyframe);
					
					if (keyFrames.length > 1) {
						applyMissingDefaultProperties(keyFrames[keyFrames.length - 2], keyframe);
					}
				}
				
				var _index:Int = !node.has.resolve("index") ? 0 : Std.parseInt(node.att.resolve("index"));
				var _duration:Int = !node.has.resolve("duration") ? 0 : Std.parseInt(node.att.resolve("duration"));
				
				
				totalFrames = FlxMath.maxInt(totalFrames, _index + _duration);
				
				
				if (node.has.resolve("name")) {
					var _index:String = DataHelper.getAttribute(node, "index");
					
					
					frameLabels.push({
										 name: node.att.resolve("name"),
										 index: _index == null ? 0 : Std.parseInt(_index)
									 });
				}
			}
		}
	}
	
	
	function applyMissingDefaultProperties(prevFrame:AnimationKeyFrame, curFrame:AnimationKeyFrame) {
		if (prevFrame.properties.colorTransform != null && curFrame.properties.colorTransform == null) {
			curFrame.properties.colorTransform = new ColorTransform();

		}
		
		if (prevFrame.properties.alpha == null) {
			prevFrame.properties.alpha = 1;
		}
	}
	
	/**
	 * Find the active keyframe based on the current frame index
	 * @return Keyframe
	 */
	function get_currentKeyFrame():AnimationKeyFrame {
		
		
		//if it's null, or if it exists but doesn't fit within the currentFrame, do a loop
		_currentKeyFrame = null;
		for (keyframe in keyFrames) {
			if (FlxMath.inBounds(currentFrame - 1, keyframe.index, keyframe.index + keyframe.duration)) {
				
				_currentKeyFrame = keyframe;
				break;
			}
		}

		return _currentKeyFrame;
	}
	
	
	/**
	 * checks to see if the current keyframe is valid or within range if the frame value
	 * @return
	 */
	function isCurrentKeyFrameValid(frame:Int):Bool {
		return _currentKeyFrame != null && FlxMath.inBounds(frame - 1, _currentKeyFrame.index, _currentKeyFrame.index + _currentKeyFrame.duration);
	}
	
	
	function get_currentFrame():Int {
		return _currentFrame;
	}

	
	/**
	 * Set the current frame
	 * change target property values if needed
	 * @param	value
	 * @return
	 */
	function set_currentFrame(value:Int):Int {
		if (_currentFrame == value) {
			return _currentFrame;
		}
		
		
		_currentFrame = value;
		if (currentKeyFrame != null) {

			if (!target.alive) {
				target.revive();
			}

			applyProperties();


		} else if (autoKill && target.alive) {
			target.kill();
		}
		//}
		
		
		return _currentFrame;
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
	
	public function applyProperties() {
		if (target == null) {
			return;
		}
		
		
		//if there is no tween, set properties instead of traversing
		if (!currentKeyFrame.hasTween) {


			target.x = currentKeyFrame.properties.x;
			target.y = currentKeyFrame.properties.y;
			
			
			/**
				 * if the container is a FlxSpriteGroup
				 * We need to offset the x and y positions to be relative to the group container
				 */
			if (timeline != null && Std.is(timeline.target, FlxSpriteGroup)) {
				var t:FlxSpriteGroup = cast timeline.target;

				target.x += t.x;
				target.y += t.y;
			}
			
			
			target.scale.x = currentKeyFrame.properties.scaleX;
			target.scale.y = currentKeyFrame.properties.scaleY;
			
			//adjust hitbox
			target.width = Math.abs(target.scale.x) * target.frameWidth;
			target.height = Math.abs(target.scale.y) * target.frameHeight;
			target.alpha = currentKeyFrame.properties.alpha;
			target.drawFrame();
			
			
		} else if (currentKeyFrame.eases == null) {
			//traverse without tweens
			currentKeyFrame.interpolateProperties(currentKeyFrame.properties, nextKeyFrame.properties, currentKeyFrameInterpolation);
			
		} else {
			//if there is all, do for all
			var curve:CustomEaseCurve;
			
			if (currentKeyFrame.eases.all != null) {
				curve = currentKeyFrame.eases.all;
				currentKeyFrame.interpolateProperties(currentKeyFrame.properties, nextKeyFrame.properties, curve.getYForX(currentKeyFrameInterpolation));
			} else {
				
				//do position
				if (currentKeyFrame.eases.position != null) {
					curve = currentKeyFrame.eases.position;
					currentKeyFrame.interpolateProperties({
															  x: currentKeyFrame.properties.x,
															  y: currentKeyFrame.properties.y

														  }, nextKeyFrame.properties, curve.getYForX(currentKeyFrameInterpolation));
				}
				
				
				//do color
				if (currentKeyFrame.eases.color != null) {
					curve = currentKeyFrame.eases.color;
					
					currentKeyFrame.interpolateProperties({
															  alpha: currentKeyFrame.properties.alpha

														  }, nextKeyFrame.properties, curve.getYForX(currentKeyFrameInterpolation));
				}
				
				
			}
			
			
		}

	}
	
	function get_currentKeyFrameInterpolation():Float {
		if (currentKeyFrame == null) {
			return 0;
		}
		
		
		return ((currentFrame - 1) - currentKeyFrame.index) / (currentKeyFrame.duration);
	}
	
	function get_currentKeyFrameIndex():Int {
		return keyFrames.indexOf(currentKeyFrame);
	}
	
	function get_prevKeyFrame():AnimationKeyFrame {
		return currentKeyFrameIndex == 0 ? null : keyFrames[currentKeyFrameIndex - 1];
	}
	
	function get_nextKeyFrame():AnimationKeyFrame {
		return keyFrames[currentKeyFrameIndex + 1];
	}
	
}

typedef FrameLabel = {
name:String,
index:Int
}