package com.firstborn.pepsi.display.gpu.common.blobs {
	import flash.display.BitmapData;
	import flash.display.Shape;
	/**
	 * @author zeh fernando
	 */
	public class PillBitmap extends BitmapData {

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function PillBitmap(__width:int, __height:int, __margin:Number, __strokeWidth:Number = 0, __filters:Array = null) {
			super(__width, __height, true, 0x00000000);

			// Draw everything
			var r:Number = __height / 2;
			var shape:Shape = new Shape();
			shape.graphics.beginFill(0xffffff, 1);
			shape.graphics.drawRoundRectComplex(__margin, __margin, __width - __margin * 2, __height - __margin * 2, r, r, r, r);
			if (__strokeWidth > 0) {
				var rs:Number = r - __strokeWidth / 2;
				shape.graphics.drawRoundRectComplex(__margin + __strokeWidth, __margin + __strokeWidth, __width - __margin * 2 - __strokeWidth * 2, __height - __margin * 2 - __strokeWidth * 2, rs, rs, rs, rs);
			}
			shape.graphics.endFill();

			if (__filters != null) shape.filters = __filters;

			draw(shape);
		}
	}
}
