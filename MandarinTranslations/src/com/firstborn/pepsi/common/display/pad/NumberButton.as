package com.firstborn.pepsi.common.display.pad {
	import com.zehfernando.display.abstracts.ResizableSprite;
	import com.zehfernando.display.components.text.TextSprite;
	import com.zehfernando.display.components.text.TextSpriteAlign;
	import com.zehfernando.display.shapes.RoundedGradientBox;

	import flash.display.Sprite;
	import flash.filters.DropShadowFilter;
	/**
	 * @author zeh fernando
	 */
	public class NumberButton extends ResizableSprite {

		// Special ids
		public static const CHARACTER_BACKSPACE:String = "backspace";

		// Constants
		private static const CORNER_RADIUS:Number = 6;

		// Properties
		private var _character:String;
		private var densityScale:Number;
		private var fontScale:Number;

		// Instances
		private var caption:TextSprite;
		private var backgroundMask:Sprite;
		private var background:RoundedGradientBox;


		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function NumberButton(__character:String, __densityScale:Number, __fontScale:Number, __fontName:String) {
			super();

			_character = __character;
			densityScale = __densityScale;
			fontScale = __fontScale;

			background = new RoundedGradientBox(_width, _height, 90, [0xf2f2f2, 0xe6e6e6], CORNER_RADIUS * densityScale, [1, 1], [119, 135]);
			addChild(background);

			caption = new TextSprite(__fontName, 24 * __fontScale * getDisplayCharacterScale(), 0x333333);
			caption.text = getDisplayCharacter();
			caption.blockAlignHorizontal = TextSpriteAlign.CENTER;
			caption.blockAlignVertical = TextSpriteAlign.MIDDLE;
			caption.filters = [new DropShadowFilter(2 * __densityScale, 45, 0x000000, 0.9, 2 * __densityScale, 2 * __densityScale, 1, 2, true), new DropShadowFilter(2 * __densityScale, 45, 0xffffff, 0.9, 2 * __densityScale, 2 * __densityScale, 1, 2, false)];
			addChild(caption);

			// Special drawing for backspace
			if (_character == CHARACTER_BACKSPACE) redrawBackgroundMask();
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		override protected function redrawWidth():void {
			background.width = _width;
			caption.x = _width * 0.5;
			if (backgroundMask != null) redrawBackgroundMask();
		}

		override protected function redrawHeight():void {
			background.height = _height;
			caption.y = _height * 0.5;
			if (backgroundMask != null) redrawBackgroundMask();
		}

		private function getDisplayCharacter():String {
			if (_character == CHARACTER_BACKSPACE) return "×"; // ☓ ╳ ⨯  /  × ✖ ✕  /  or \u2716
			return _character;
		}

		private function getDisplayCharacterScale():Number {
			if (_character == CHARACTER_BACKSPACE) return 1.4;
			return 1;
		}

		private function redrawBackgroundMask():void {
			if (backgroundMask == null) {
				backgroundMask = new Sprite();
				background.mask = backgroundMask;
				addChild(backgroundMask);
			}

			var wr:Number = 0.75;
			var bh:Number = _height / 2;
			var bw:Number = bh * wr;
			var cr:Number = CORNER_RADIUS * densityScale;
			var cwr:Number = cr * wr;

			backgroundMask.graphics.clear();
			backgroundMask.graphics.beginFill(0xff0000);
			backgroundMask.graphics.moveTo(0, bh);
			backgroundMask.graphics.curveTo(0, bh - cwr, cwr, bh - cr - cwr);
			backgroundMask.graphics.lineTo(bw - cr - cwr, cr / wr);
			backgroundMask.graphics.curveTo(bw - cwr, 0, bw, 0);
			backgroundMask.graphics.lineTo(_width, 0);
			backgroundMask.graphics.lineTo(_width, _height);
			backgroundMask.graphics.lineTo(bw, _height);
			backgroundMask.graphics.curveTo(bw - cwr, _height, bw - cr - cwr, _height - cr / wr);
			backgroundMask.graphics.lineTo(cwr, bh + cr + cwr);
			backgroundMask.graphics.curveTo(0, bh + cwr, 0, bh);
			backgroundMask.graphics.endFill();
		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		public function get character():String {
			return _character;
		}
	}
}
