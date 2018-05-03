package com.firstborn.pepsi.display.gpu.common.blobs {
	import com.zehfernando.data.BitmapDataPool;
	import com.zehfernando.data.types.Color;
	import com.zehfernando.display.BitmapFillBox;
	import com.zehfernando.display.shapes.GradientBox;
	import com.zehfernando.transitions.Equations;

	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.display.BlendMode;
	import flash.display.GradientType;
	import flash.display.Shape;
	import flash.display.StageQuality;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	/**
	 * @author zeh fernando
	 */
	public class MultiGradientBlobBitmap extends TiledBitmapData {

		// A BitmapData with several gradient blobs drawn on it, tiled

		// Properties
		private var margin:Number;

		private var regions:Object;

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function MultiGradientBlobBitmap(__maxTextureDimensions:int, __tileDimensions:int, __maxTiles:int, __margin:Number) {
			super(__maxTextureDimensions, __tileDimensions, __maxTiles);

			margin = __margin;
			regions = {};
		}

		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private function drawGradientBlob(__bitmapData:BitmapData, __colorInside:uint, __colorOutside:uint):void {
			// Generate smooth gradient (curved instead of linear)
			var gradientColors:Array = [];
			var gradientRatios:Array = [];
			var desiredStops:int = 8; // Minimum 2 (start and end); the more, the smoother
			var f:Number;
			for (var i:int = 0; i < desiredStops; i++) {
				f = i / (desiredStops-1);
				gradientColors.push(Color.interpolateRRGGBB(__colorOutside, __colorInside, f));
				gradientRatios.push(Equations.quadOut(f) * 255);
				//gradientRatios.push(Equations.quadOut(f) * 255);
			}

			var box:GradientBox = new GradientBox(__bitmapData.width, __bitmapData.height, 0, gradientColors, null, gradientRatios, GradientType.RADIAL);
			//box.gradientScaleY = 2;

			var radius:Number = (_tileDimensions / 2) - margin;

			// Draw gradient
			__bitmapData.draw(box, null, null, null, null);
			//__bitmapData.drawWithQuality(box, null, null, null, null, true, StageQuality.HIGH_16X16);

			// Draw noise
			var noise:BitmapData = BitmapDataPool.getPool().get(__bitmapData.width, __bitmapData.height, false, 0xffffff);
			var noisePattern:BitmapData = BitmapFillBox.getPatternNoise(128, 128);
			for (var row:int = 0; row < noise.height; row += noisePattern.height) {
				for (var col:int = 0; col < noise.width; col += noisePattern.width) {
					noise.copyPixels(noisePattern, noisePattern.rect, new Point(col, row));
				}
			}
			__bitmapData.draw(noise, null, new ColorTransform(1, 1, 1, 0.06), BlendMode.OVERLAY);
			//__bitmapData.drawWithQuality(noise, null, new ColorTransform(1, 1, 1, 0.06), BlendMode.OVERLAY, null, true, StageQuality.HIGH_16X16);
			BitmapDataPool.getPool().put(noise);
			noise = null;
			noisePattern.dispose();
			noisePattern = null;

			// Clip to blob mask
			var bmpMask:BitmapData = BitmapDataPool.getPool().get(_tileDimensions, _tileDimensions, true, 0xffffff);
			var mtx:Matrix = new Matrix();
			mtx.translate(_tileDimensions * 0.5, _tileDimensions * 0.5);
			var shape:Shape = new BlobShape(radius, 0x000000, 1, 0x000000, 0, 0);
			bmpMask.drawWithQuality(shape, mtx, null, null, null, true, StageQuality.HIGH_16X16);
			__bitmapData.copyChannel(bmpMask, bmpMask.rect, new Point(0, 0), BitmapDataChannel.ALPHA, BitmapDataChannel.ALPHA);
			BitmapDataPool.getPool().put(bmpMask);
			bmpMask = null;
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function addShape(__id:String, __colorInside:uint, __colorOutside:uint):void {
			var col:int = _numTiles % _cols;
			var row:int = Math.floor(_numTiles / _cols);

			var bmp:BitmapData = BitmapDataPool.getPool().get(_tileDimensions, _tileDimensions, true, 0x00000000);
			drawGradientBlob(bmp, __colorInside, __colorOutside);
			copyPixels(bmp, bmp.rect, new Point(col * _tileDimensions, row * _tileDimensions));

			BitmapDataPool.getPool().put(bmp);

			regions[__id] = _numTiles;

			_numTiles++;
		}

		public function getTileIndex(__id:String):int {
			return regions[__id];
		}

		public function reset():void {
			fillRect(rect, 0x00000000);
			_numTiles = 0;
		}
	}
}
