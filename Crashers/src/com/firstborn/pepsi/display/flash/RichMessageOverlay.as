package com.firstborn.pepsi.display.flash {
	import com.firstborn.pepsi.application.FountainFamily;
	import com.firstborn.pepsi.assets.FontLibrary;
	import com.firstborn.pepsi.display.gpu.common.TextBitmap;
	import com.zehfernando.display.components.text.TextSprite;
	import com.zehfernando.display.components.text.TextSpriteAlign;
	import com.zehfernando.localization.StringList;

	import flash.display.Bitmap;
	import flash.display.BlendMode;
	import flash.display.Sprite;
	/**
	 * @author zeh fernando
	 */
	public class RichMessageOverlay extends Sprite {

		// Assets
		[Embed(source="/../embed/out-of-service/background.png")]
		public static const IMAGE_BACKGROUND:Class;

		[Embed(source="/../embed/out-of-service/bubbles.png")]
		public static const IMAGE_BUBBLES:Class;

		[Embed(source="/../embed/out-of-service/icon.png")]
		public static const IMAGE_ICON:Class;

		// Properties
		private var _visibility:Number;

		// Instances
		private var bitmapBackground:Bitmap;
		private var bitmapBubbles:Bitmap;
		private var bitmapIcon:Bitmap;
		private var textTitle:TextSprite;
		private var textBody:TextSprite;
		private var textMessage:TextSprite;

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function RichMessageOverlay() {
			super();

			_visibility = 1;
			blendMode = BlendMode.LAYER;

			var w:int = FountainFamily.platform.width;
			var h:int = FountainFamily.platform.height;

			bitmapBackground = new IMAGE_BACKGROUND();
			bitmapBackground.width = w;
			bitmapBackground.height = h;
			bitmapBackground.smoothing = true;
			addChild(bitmapBackground);

			bitmapBubbles = new IMAGE_BUBBLES();
			bitmapBubbles.width = w;
			bitmapBubbles.height = (w / bitmapBubbles.bitmapData.width) * bitmapBubbles.bitmapData.height;
			bitmapBubbles.y = h - bitmapBubbles.height;
			bitmapBubbles.smoothing = true;
			addChild(bitmapBubbles);

			bitmapIcon = new IMAGE_ICON();
			bitmapIcon.x = w * 0.5 - bitmapIcon.width * 0.5;
			bitmapIcon.y = h * 0.3 - bitmapIcon.height * 0.5;
			bitmapIcon.smoothing = true;
			addChild(bitmapIcon);

			textTitle = TextBitmap.createSprite(StringList.getList(FountainFamily.current_language).getString("generic/out-of-service/title"), FontLibrary.BOOSTER_FY_REGULAR, null, 76, NaN, 0x7e878c, -1, 1, 1, 60, 60, TextSpriteAlign.CENTER, w * 0.8);
			textTitle.x = w * 0.5 - textTitle.width * 0.5;
			textTitle.y = bitmapIcon.y - 35 - textTitle.height;
			addChild(textTitle);

			textBody = TextBitmap.createSprite(StringList.getList(FountainFamily.current_language).getString("generic/out-of-service/body"), FontLibrary.BOOSTER_FY_REGULAR, null, 30, NaN, 0x7e878c, 0x33a2d1, 1, 1, 55, 55, TextSpriteAlign.CENTER, w * 0.8, 8);
			textBody.x = w * 0.5 - textBody.width * 0.5;
			textBody.y = bitmapIcon.y + bitmapIcon.height + 35;
			addChild(textBody);

			textMessage = TextBitmap.createSprite("", FontLibrary.BOOSTER_FY_REGULAR, null, 20, NaN, 0xbec7cc, -1, 1, 1, 75, 75, TextSpriteAlign.RIGHT);
			textMessage.blockAlignHorizontal = TextSpriteAlign.RIGHT;
			textMessage.x = w - 43;
			textMessage.y = 63;
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

		public function setText(__text:String):void {
			textMessage.text = __text;
		}

		public function updateLanguage() : void {
			//textTitle.text = StringList.getList(FountainFamily.current_language).getString("generic/out-of-service/title");
			//textBody.text = StringList.getList(FountainFamily.current_language).getString("generic/out-of-service/body");
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
