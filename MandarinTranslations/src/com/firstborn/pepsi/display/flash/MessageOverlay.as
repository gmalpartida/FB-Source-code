package com.firstborn.pepsi.display.flash {
	import com.firstborn.pepsi.application.FountainFamily;
	import com.firstborn.pepsi.assets.FontLibrary;
	import com.zehfernando.display.components.text.TextSprite;
	import com.zehfernando.display.components.text.TextSpriteAlign;
	import com.zehfernando.display.shapes.Box;

	import flash.display.Sprite;
	/**
	 * @author zeh fernando
	 */
	public class MessageOverlay extends Sprite {

		// Properties
		private var _visibility:Number;

		// Instances
		private var cover:Box;
		private var textMessage:TextSprite;

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function MessageOverlay() {
			super();

			_visibility = 1;

			var w:int = FountainFamily.platform.width;
			var h:int = FountainFamily.platform.height;

			cover = new Box(w, h, 0x000000);
			cover.alpha = 0.9;
			addChild(cover);

			textMessage = new TextSprite(FontLibrary.BOOSTER_FY_REGULAR, 10, 0xffffff);
			textMessage.align = TextSpriteAlign.CENTER;
			textMessage.blockAlignHorizontal = TextSpriteAlign.CENTER;
			textMessage.blockAlignVertical = TextSpriteAlign.MIDDLE;
			textMessage.width = w * 0.7;
			textMessage.x = w * 0.5;
			textMessage.y = h * 0.5;
			addChild(textMessage);

			redrawVisibility();
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private function redrawVisibility():void {
			alpha = _visibility;
			visible = _visibility > 0;
		}



		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function setText(__text:String, __fontSizeScale:Number = 1):void {
			textMessage.fontSize = 100 * __fontSizeScale;
			textMessage.text = __text;
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
