package com.firstborn.pepsi.display.gpu.common.blobs {
	import com.zehfernando.utils.MathUtils;
	import com.zehfernando.utils.console.warn;

	import flash.display.BitmapData;
	import flash.geom.Rectangle;

	/**
	 * @author zeh fernando
	 */
	public class TiledBitmapData extends BitmapData {

		// Properties
		protected var _tileDimensions:int;							// Resolution to use (dimensions for each tile)
		protected var _numTiles:int;								// Num of tiles used
		protected var _maxTiles:int;								// Max tiles allowed

		protected var _cols:int;									// Cols possible
		protected var _rows:int;									// Rows possible

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function TiledBitmapData(__maxTextureDimensions:int, __tileDimensions:int, __maxTiles:int) {
			_tileDimensions = __tileDimensions;
			_numTiles = 0;
			_maxTiles = __maxTiles;

			var maxCols:int = Math.floor(__maxTextureDimensions / __tileDimensions);
			var maxRows:int = Math.floor(__maxTextureDimensions / __tileDimensions);

			_cols = Math.min(maxCols, __maxTiles);
			_rows = Math.min(maxRows, Math.ceil(__maxTiles / _cols));

			var w:int = __tileDimensions * _cols;
			var h:int = __tileDimensions * _rows;

			var totalGPUPixels:int = MathUtils.getHighestPowerOfTwo(w) * MathUtils.getHighestPowerOfTwo(h);
			//debug("Pixels used for " + __maxTiles + " tiles: " + w + "x" + h + " = " + (w * h) + " pixels / power of 2 simulation = " + MathUtils.getHighestPowerOfTwo(w) + "x" + MathUtils.getHighestPowerOfTwo(h) + " = " + totalGPUPixels + " pixels");

			// Find the size that uses the less amount of pixels; if size is small, try to get the most square one (just to limit dimensions; but only if the actual area used is smaller)
			var bestCols:int = _cols;
			var bestPixelAreaGPU:int = totalGPUPixels;
			var bestPixelAreaSoftware:int = w * h;
			var bestPixelPerimeter:int = MathUtils.getHighestPowerOfTwo(w) * 2 + MathUtils.getHighestPowerOfTwo(h) * 2;
			var tCols:int = _cols;
			var tRows:int = Math.floor(_maxTiles / tCols);
			var tPixelAreaGPU:int;
			var tPixelAreaSoftware:int;
			var tPixelPerimeter:int;
			while (tCols > 0 && tRows <= maxRows) {
				tPixelAreaGPU = MathUtils.getHighestPowerOfTwo(tCols * __tileDimensions) * MathUtils.getHighestPowerOfTwo(tRows * __tileDimensions);
				tPixelAreaSoftware = tCols * __tileDimensions * tRows * __tileDimensions;
				tPixelPerimeter = MathUtils.getHighestPowerOfTwo(tCols * __tileDimensions) * 2 + MathUtils.getHighestPowerOfTwo(tRows * __tileDimensions) * 2;
				if (tPixelAreaGPU < bestPixelAreaGPU || (tPixelAreaGPU == bestPixelAreaGPU && tPixelPerimeter < bestPixelPerimeter && tPixelAreaSoftware <= bestPixelAreaSoftware)) {
					bestPixelAreaGPU = tPixelAreaGPU;
					bestPixelAreaSoftware = tPixelAreaSoftware;
					bestPixelPerimeter = tPixelPerimeter;
					bestCols = tCols;
				}
				tCols--;
				tRows = Math.ceil(_maxTiles / tCols);
			};

			if (_cols != bestCols) {
				_cols = bestCols;
				_rows = Math.ceil(_maxTiles / _cols);
				w = __tileDimensions * _cols;
				h = __tileDimensions * _rows;
				//var newGPUPixels:int = MathUtils.getHighestPowerOfTwo(w) * MathUtils.getHighestPowerOfTwo(h);
				//debug("==> Optimized texture area pixels: " + w + "x" + h + " = " + (w * h) + " pixels / power of 2 simulation = " + MathUtils.getHighestPowerOfTwo(w) + "x" + MathUtils.getHighestPowerOfTwo(h) + " = " + newGPUPixels + " pixels (saved " + (((totalGPUPixels - newGPUPixels) / totalGPUPixels) * 100).toFixed(2) + "%)");
			}

			if (_cols * _rows < __maxTiles) warn("Warning: tried creating a tile texture with " + __maxTiles + " tiles of dimensions " + __tileDimensions + ", but only " + (_cols * _rows) + " are allowed due to a max texture dimension of " + __maxTextureDimensions + ".");

			super(w, h, true, 0x00000000);
		}


		// ================================================================================================================
		// STATIC INTERFACE -----------------------------------------------------------------------------------------------

		public static function getTileRectangle(__width:int, __height:int, __dimensions:int, __tileIndex:int):Rectangle {
			// Helper function to generate a texture rectangle for a tile
			var cols:int = Math.floor(__width / __dimensions);
			var rows:int = Math.floor(__height / __dimensions);

			var col:int = __tileIndex % cols;
			var row:int = Math.floor(__tileIndex / cols) % rows;

			return new Rectangle(col * __dimensions, row * __dimensions, __dimensions, __dimensions);
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function getTileRect(__index:int):Rectangle {
			// Return a given tile's rectangle
			return getTileRectangle(width, height, _tileDimensions, __index);
		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		public function get numTiles():int {
			return _numTiles;
		}

//		public function get cols():int {
//			return _cols;
//		}
//
//		public function get rows():int {
//			return _rows;
//		}
	}
}
