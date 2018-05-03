package com.firstborn.pepsi.display.gpu.common.components {
	import com.zehfernando.data.types.Color;
	import com.zehfernando.utils.VectorUtils;
	/**
	 * @author zeh fernando
	 */
	public class BlobButtonLayer {

		// Just a class to help on building blob buttons

		// Properties
		public var colorStroke:uint;
		public var alphaStroke:Number;
		public var widthStroke:Number;
		public var colorSolid:uint;
		public var alphaSolid:Number;
		public var scale:Number;

		public var blendMode:String;


		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function BlobButtonLayer() {
			colorStroke = 0x000000;
			alphaStroke = 0;
			widthStroke = 2;

			colorSolid = 0x000000;
			alphaSolid = 0;

			scale = 1;

			blendMode = null;
		}


		// ================================================================================================================
		// STATIC INTERFACE -----------------------------------------------------------------------------------------------

		public static function getSolidBlob(__color:uint, __alpha:Number):BlobButtonLayer {
			var blob:BlobButtonLayer = new BlobButtonLayer();
			blob.colorSolid = __color | 0xff000000;
			blob.alphaSolid = __alpha;

			return blob;
		}

		public static function getStrokeBlob(__color:uint, __alpha:Number, __widthStroke:Number):BlobButtonLayer {
			var blob:BlobButtonLayer = new BlobButtonLayer();
			blob.colorStroke = __color | 0xff000000;
			blob.alphaStroke = __alpha;
			blob.widthStroke = __widthStroke;

			return blob;
		}

		public static function getSolidStrokeBlob(__colorSolid:uint, __alphaSolid:Number, __colorStroke:uint, __alphaStroke:Number, __widthStroke:Number, __scale:Number = 1):BlobButtonLayer {
			var blob:BlobButtonLayer = new BlobButtonLayer();
			blob.colorSolid = __colorSolid | 0xff000000;
			blob.alphaSolid = __alphaSolid;

			blob.colorStroke = __colorStroke | 0xff000000;
			blob.alphaStroke = __alphaStroke;
			blob.widthStroke = __widthStroke;

			blob.scale = __scale;

			return blob;
		}

		public static function getSolidStrokeBlobsFromColors(__colorSolids:Vector.<uint>, __colorStrokes:Vector.<uint>, __strokeWidths:Vector.<Number>, __scales:Vector.<Number>):Array {
			// Based on a list of colors, create corresponding layers
			// __colorSolids and __colorStrokes must have the same length; __strokeWidths wraps around
			//var blobs:Vector.<BlobButtonLayer> = new Vector.<BlobButtonLayer>();
			var blobs:Array = [];
			var scale:Number;
			for (var i:int = 0; i < __colorSolids.length; i++) {
				scale = VectorUtils.getEquivalentItemFromNumberVector(i, __colorSolids.length - 1, __scales);
				blobs.push(getSolidStrokeBlob(__colorSolids[i], Color.fromAARRGGBB(__colorSolids[i]).a, __colorStrokes[i], Color.fromAARRGGBB(__colorStrokes[i]).a,__strokeWidths[i % __strokeWidths.length], scale));
			}
			return blobs;
		}
	}
}
