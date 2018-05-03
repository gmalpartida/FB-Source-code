package com.firstborn.pepsi.display.gpu.common.blobs {
	import com.zehfernando.data.BitmapDataPool;
	import com.zehfernando.utils.RandomGenerator;

	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.display.StageQuality;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	/**
	 * @author zeh fernando
	 */
	public class MultiBlobBitmap extends TiledBitmapData {

		// A BitmapData with several blobs drawn on it, tiled

		// Private
		private var margin:Number;

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function MultiBlobBitmap(__maxTextureDimensions:int, __tileDimensions:int, __maxTiles:int, __margin:Number) {
			super(__maxTextureDimensions, __tileDimensions, __maxTiles);

			margin = __margin;
			_numTiles = 0;
		}

		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function fillWithBlobs(__colorSolid:uint, __alphaSolid:Number, __colorStroke:uint, __alphaStroke:Number, __strokeWidth:Number = 2, __noiseRadiusScale:Number = 1, __isInverse:Boolean = false, __filters:Array = null, __repeatable:Boolean = false):void {
			// Fill with shapes
			for (var i:int = _numTiles; i < _maxTiles; i++) {
				addBlob(__colorSolid, __alphaSolid, __colorStroke, __alphaStroke, __strokeWidth, __noiseRadiusScale, __isInverse, __filters, false, false, __repeatable ? i : -1);
			}
		}

		public function addBlob(__colorSolid:uint, __alphaSolid:Number, __colorStroke:uint, __alphaStroke:Number, __strokeWidth:Number = 2, __noiseRadiusScale:Number = 1, __isInverse:Boolean = false, __filters:Array = null, __variableOctables:Boolean = false, __normalizeRadius:Boolean = false, __randomSeed:int = -1, __totalDegrees : Number = 360, __useSegments : Boolean = false):void {
			var r:Number = (_tileDimensions / 2) - margin;
			var col:int, row:int;
			col = _numTiles % _cols;
			row = Math.floor(_numTiles / _cols);
			var octavesA:int = __variableOctables ? RandomGenerator.getInIntegerRange(1, 2) : 2;
			var octavesB:int = __variableOctables ? RandomGenerator.getInIntegerRange(1, 2) : 1;
			var shape:BlobShape = new BlobShape(r, __colorSolid, __alphaSolid, __colorStroke, __alphaStroke, __strokeWidth, BlobShape.NOISE_RADIUS_SCALE_STANDARD * __noiseRadiusScale, octavesA, octavesB, __normalizeRadius, __randomSeed, __totalDegrees, __useSegments);
			if (__filters != null) shape.filters = __filters;

			var mtx:Matrix = new Matrix();

			if (!__isInverse) {
				// Normal draw
				mtx.translate(_tileDimensions * 0.5 + col * _tileDimensions, _tileDimensions * 0.5 + row * _tileDimensions);
				//draw(shape, mtx, null, null, null, true);
				drawWithQuality(shape, mtx, null, null, null, true, StageQuality.HIGH_16X16);
			} else {
				// Inverse draw
				var bmp:BitmapData = BitmapDataPool.getPool().get(_tileDimensions, _tileDimensions, true, 0xffffffff);
				mtx.translate(_tileDimensions * 0.5, _tileDimensions * 0.5);
				//bmp.draw(shape, mtx, new ColorTransform(0, 0, 0, 1, 0, 0, 0), null, null, true);
				bmp.drawWithQuality(shape, mtx, new ColorTransform(0, 0, 0, 1, 0, 0, 0), null, null, true, StageQuality.HIGH_16X16);
				fillRect(new Rectangle(col * _tileDimensions, row * _tileDimensions, _tileDimensions, _tileDimensions), 0xffffffff);
				copyChannel(bmp, bmp.rect, new Point(col * _tileDimensions, row * _tileDimensions), BitmapDataChannel.RED, BitmapDataChannel.ALPHA);
				BitmapDataPool.getPool().put(bmp);
				bmp = null;
			}
			_numTiles++;
		}
	}
}
