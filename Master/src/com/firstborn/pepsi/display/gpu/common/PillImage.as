package com.firstborn.pepsi.display.gpu.common {
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.textures.Texture;

	import com.firstborn.pepsi.display.gpu.common.blobs.PillBitmap;
	import com.zehfernando.transitions.Equations;
	import com.zehfernando.utils.MathUtils;

	import flash.display.BitmapData;

	/**
	 * @author zeh fernando
	 */
	public class PillImage extends Sprite {

		// Properties
		private var _visibility:Number;
		private var cutoff:int;
		private var bitmapWidth:int;
		private var _width:Number;
		private var _height:Number;

		// Instances
		private var imageL:Image;
		private var imageR:Image;

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function PillImage(__width:int, __height:int, __margin:Number, __color:uint, __smoothing:String, __textureFormat:String) {
			_visibility = 1;
			_width = __width;
			_height = __height;

			bitmapWidth = __width;
			cutoff = Math.round(__height / 2);

			var bitmap:BitmapData = new PillBitmap(_width, _height, __margin);
			var texture:Texture = Texture.fromBitmapData(bitmap, false, false, 1, __textureFormat);

			imageL = new Image(texture);
			imageL.width = cutoff;
			imageL.color = __color;
			imageL.smoothing = __smoothing;
			addChild(imageL);

			imageR = new Image(texture);
			imageR.x = cutoff;
			imageR.color = __color;
			imageR.smoothing = __smoothing;
			addChild(imageR);

			redrawVisibility();
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private function redrawVisibility():void {
			alpha = Equations.quintOut(_visibility);
			visible = _visibility > 0;

			var lr:Number = cutoff / bitmapWidth;

			imageL.setTexCoordsTo(0, 0, 0);
			imageL.setTexCoordsTo(1, lr, 0);
			imageL.setTexCoordsTo(2, 0, 1);
			imageL.setTexCoordsTo(3, lr, 1);

			var rw:Number = MathUtils.map(_visibility, 0, 1, cutoff, bitmapWidth - cutoff);
			var rl:Number = 1 - rw / bitmapWidth;

			imageR.width = rw;
			imageR.setTexCoordsTo(0, rl, 0);
			imageR.setTexCoordsTo(1, 1, 0);
			imageR.setTexCoordsTo(2, rl, 1);
			imageR.setTexCoordsTo(3, 1, 1);
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		override public function dispose():void {
			removeChild(imageL);
			imageL.texture.dispose();
			imageL.dispose();
			imageL = null;

			super.dispose();
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

		override public function set width(value : Number) : void {
			_width = value;
			bitmapWidth = value;
		}

		override public function get width():Number {
			return _width;
		}

		override public function get height():Number {
			return _height;
		}
	}
}
