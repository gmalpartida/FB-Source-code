package com.firstborn.pepsi.display.flash {
	import com.firstborn.pepsi.application.FountainFamily;
	import com.firstborn.pepsi.assets.FontLibrary;
	import com.zehfernando.display.components.text.TextSprite;
	import com.zehfernando.display.components.text.TextSpriteAlign;
	import com.zehfernando.display.shapes.Box;
	import com.zehfernando.localization.StringList;
	import com.zehfernando.transitions.Equations;
	import com.zehfernando.transitions.ZTween;
	import com.zehfernando.utils.RandomGenerator;
	import com.zehfernando.utils.StringUtils;
	import com.zehfernando.utils.getTimerUInt;

	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.filters.DropShadowFilter;
	/**
	 * @author zeh fernando
	 */
	public class TestingOverlay extends Sprite {

		// Assets
		[Embed(source="/../embed/instructions/hand.png")]
		public static const INSTRUCTIONS_HAND:Class;

		// Constants
		private static const HAND_SCALE:Number = 1.5;
		private static const TIME_SHOW:Number = 0.3;
		private static const TIME_HIDE:Number = 0.3;

		// Properties
		private var _visibility:Number;
		private var _offsetX:Number;
		private var _offsetY:Number;
		private var isLeftHanded:Boolean;

		// Instances
		private var cover:Box;
		private var spriteHand:Sprite;
		private var bitmapHand:Bitmap;
		private var textMessage:TextSprite;

		private var textTime:TextSprite;

		private var lastTimeInvisible:uint;


		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function TestingOverlay(__offsetX:Number, __offsetY:Number) {
			super();

			_visibility = 0;
			_offsetX = __offsetX;
			_offsetY = __offsetY;
			isLeftHanded = Math.random() < 0.1;

			var w:int = FountainFamily.platform.width;
			var h:int = FountainFamily.platform.height;

			// Hand for auto testing
			spriteHand = new Sprite();
			spriteHand.x = FountainFamily.platform.width * 0.5;
			spriteHand.y = FountainFamily.platform.height * 0.5;
			spriteHand.scaleX = HAND_SCALE * (isLeftHanded ? -1 : 1);
			spriteHand.scaleY = HAND_SCALE;
			spriteHand.rotation = getTypicalHandRotation();
			addChild(spriteHand);

			bitmapHand = new INSTRUCTIONS_HAND();
			bitmapHand.x = -bitmapHand.bitmapData.width * 0.4;
			bitmapHand.y = -bitmapHand.bitmapData.height * 0.1;
			bitmapHand.smoothing = true;
			spriteHand.addChild(bitmapHand);

			cover = new Box(w, h, 0x777777);
			cover.alpha = 0.8;
			addChild(cover);

			textMessage = new TextSprite(FontLibrary.BOOSTER_FY_REGULAR, 120, 0xffffff, 1);
			textMessage.text = StringList.getList(FountainFamily.current_language).getString("generic/testing/body");
			textMessage.align = TextSpriteAlign.CENTER;
			textMessage.blockAlignHorizontal = TextSpriteAlign.CENTER;
			textMessage.blockAlignVertical = TextSpriteAlign.MIDDLE;
			textMessage.width = w * 0.7;
			textMessage.x = w * 0.5;
			textMessage.y = h * 0.5;
			textMessage.filters = [new DropShadowFilter(3, 45, 0x000000, 0.5, 4, 4, 1, 2)];
			addChild(textMessage);

			textTime = new TextSprite(FontLibrary.BOOSTER_FY_REGULAR, 40, 0xffffff, 1);
			textTime.text = "";
			textTime.align = TextSpriteAlign.CENTER;
			textTime.blockAlignHorizontal = TextSpriteAlign.CENTER;
			textTime.blockAlignVertical = TextSpriteAlign.MIDDLE;
			textTime.width = w * 0.7;
			textTime.x = w * 0.5;
			textTime.y = textMessage.y + textMessage.height * 0.5 + 50;
			textTime.filters = [new DropShadowFilter(2, 45, 0x000000, 0.5, 4, 4, 1, 2)];
			addChild(textTime);

			redrawVisibility();

			lastTimeInvisible = getTimerUInt();
			updateTime(true);
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private function redrawVisibility():void {
			var wasVisible:Boolean = visible;

			alpha = _visibility;
			visible = _visibility > 0;

			if (!wasVisible && visible) {
				lastTimeInvisible = getTimerUInt();
				addEventListener(Event.ENTER_FRAME, onEnterFrame);
			} else if (!visible && wasVisible) {
				removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			}
		}

		private function getTypicalHandRotation():Number {
			return (RandomGenerator.getInRange(-15, 15) - 24) * (isLeftHanded ? -1 : 1);
		}

		private function formatTime(__timeMS:Number):String {
			var s:Number = __timeMS / 1000;

			var ts:Number = Math.floor(s) % 60;
			var tm:Number = Math.floor((s / 60) % 60);
			var th:Number = Math.floor(s / 60 / 60);

			return StringUtils.getCleanString(th + "h" + ("00" + tm).substr(-2, 2) + "m" + ("00" + ts).substr(-2, 2) + "s");
		}

		private function updateTime(__forced:Boolean = false):void {
			// Update the visible text with the current test time

			var newTime:String = formatTime((getTimerUInt() - lastTimeInvisible) * FountainFamily.timeScale);
			if (textTime.text != newTime || __forced) {
				textTime.text = newTime;
			}

		}


		// ================================================================================================================
		// EVENT INTERFACE ------------------------------------------------------------------------------------------------

		private function onEnterFrame(__e:Event):void {
			updateTime();
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function show():void {
			ZTween.remove(this, "visibility");
			ZTween.add(this, {visibility:1}, {time:TIME_SHOW});
			textMessage.text = StringList.getList(FountainFamily.current_language).getString("generic/testing/body");
		}

		public function hide():void {
			ZTween.remove(this, "visibility");
			ZTween.add(this, {visibility:0}, {time:TIME_HIDE});
		}

		public function animateHandDynamic(__press:Boolean, __functionX:Function, __functionY:Function, __x:Number = 0, __y:Number = 0):void {
			animateHand(__press, __functionX() + __x, __functionY() + __y);
		}

		public function animateHand(__press:Boolean, __x:Number = NaN, __y:Number = NaN):void {
			__x += _offsetX;
			__y += _offsetY;
			if (!isNaN(__x) && !isNaN(__y)) {
				ZTween.add(spriteHand, {x:__x, y:__y}, {time:0.4, transition:Equations.quadInOut});
				ZTween.add(spriteHand, {rotation:getTypicalHandRotation()}, {time:0.4, transition:Equations.quadInOut});
			}

			var scale:Number = (__press ? 0.8 : 1) * TestingOverlay.HAND_SCALE;
			ZTween.add(spriteHand, {scaleX:scale * (isLeftHanded ? -1 : 1), scaleY:scale}, {time:0.15, delay:0.25, transition:Equations.quadOut});
		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		public function get visibility():Number {
			return _visibility;
		}
		public function set visibility(__value:Number):void {
			if (_visibility != __value) {
				_visibility = __value;
				redrawVisibility();
			}
		}
	}
}
