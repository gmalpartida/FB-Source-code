package com.firstborn.pepsi.common.display.pad {
	import com.zehfernando.display.abstracts.ResizableSprite;
	import com.zehfernando.display.shapes.Circle;
	import com.zehfernando.display.shapes.RoundedBox;

	import flash.filters.DropShadowFilter;

	/**
	 * @author zeh fernando
	 */
	public class DigitBox extends ResizableSprite {

		// Constants
		private static const CORNER_RADIUS:Number = 6;
		private static const CIRCLE_RADIUS:Number = 8;

		// Properties
		private var _isChecked:Boolean;

		// Instances
		private var circle:Circle;
		private var background:RoundedBox;


		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function DigitBox(__densityScale:Number, __fontScale:Number) {
			super();

			_isChecked = false;

			background = new RoundedBox(_width, _height, 0xffffff, CORNER_RADIUS * __densityScale);
			background.filters = [new DropShadowFilter(2 * __densityScale, 90, 0x000000, 0.25, 2 * __densityScale, 2 * __densityScale, 1, 2, true)];
			addChild(background);

			circle = new Circle(DigitBox.CIRCLE_RADIUS * __fontScale, 0xee1b22);
			addChild(circle);

			redrawChecked();
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		override protected function redrawWidth():void {
			background.width = _width;
			circle.x = _width * 0.5;
		}

		override protected function redrawHeight():void {
			background.height = _height;
			circle.y = _height * 0.5;
		}

		private function redrawChecked():void {
			circle.visible = _isChecked;
		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		public function get isChecked():Boolean {
			return _isChecked;
		}
		public function set isChecked(__value:Boolean):void {
			if (_isChecked != __value) {
				_isChecked = __value;
				redrawChecked();
			}
		}
	}
}
