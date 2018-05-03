package com.firstborn.pepsi.display.gpu.common {
import flash.geom.Matrix;
import flash.geom.Rectangle;
	import starling.textures.Texture;

	import com.firstborn.pepsi.application.FountainFamily;
	import com.zehfernando.display.components.text.RichTextSprite;
	import com.zehfernando.display.components.text.TextSpriteAlign;
	import com.zehfernando.utils.console.log;

	import flash.display.BitmapData;
	import flash.geom.Point;
	/**
	 * @author zeh fernando
	 */
	public class TextBitmap extends BitmapData {

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function TextBitmap(__text:String, __font:String, __fontEM:String, __size:Number, __sizeEM:Number, __color:int, __colorEM:int = -1, __alpha:Number = 1, __alphaEM:Number = 1, __tracking:Number = 0, __trackingEM:Number = 0, __alignment:String = null, __maxWidth:Number = NaN, __leading:Number = 0, __verticalOffset : int = 0) {
			var textSprite:RichTextSprite = createSprite(__text, __font, __fontEM, __size, __sizeEM, __color, __colorEM, __alpha, __alphaEM, __tracking, __trackingEM, __alignment, __maxWidth, __leading);
			var w:int = Math.max(Math.ceil(textSprite.width), 2);
			var h:int = Math.max(Math.ceil(textSprite.height + 2 * __verticalOffset), 2);
			super(w, h, true, 0x00000000);
			draw(textSprite, new Matrix(1,0,0,1,0,__verticalOffset));
		}

		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public static function createTexture(__text:String, __font:String, __fontEM:String, __size:Number, __sizeEM:Number, __color:int, __colorEM:int = -1, __alpha:Number = 1, __alphaEM:Number = 1, __tracking:Number = 0, __trackingEM:Number = 0, __alignment:String = null, __generateMipMaps:Boolean = false, __maxWidth:Number = NaN, __leading:Number = 0, __usedRectangle:Rectangle = null, __verticalOffset : int = 0):Texture {
			var bitmap:TextBitmap = new TextBitmap(__text, __font, __fontEM, __size, __sizeEM, __color, __colorEM, __alpha, __alphaEM, __tracking, __trackingEM, __alignment, __maxWidth, __leading, __verticalOffset);
			var texture:Texture = Texture.fromBitmapData(bitmap, __generateMipMaps, true, 1, FountainFamily.platform.getTextureProfile(TextureLibrary.TEXTURE_ID_GENERIC_TEXT).format, true);
			texture.root.onRestore = function():void {
				texture.root.uploadBitmapData(bitmap);
			};

			if (__usedRectangle !== null) {
				// Fill a rectangle with the area actually used by the image
				var rect:Rectangle = bitmap.getColorBoundsRect(0xff000000, 0x000000, false);
				__usedRectangle.x = rect.x;
				__usedRectangle.y = rect.y;
				__usedRectangle.width = rect.width;
				__usedRectangle.height = rect.height;
			}
			return texture;
		}

		public static function createTextures(__bitmaps:Vector.<TextBitmap>, __lineSpace:Number, __generateMipMaps:Boolean = false, __canDispose:Boolean = true):Texture {
			// Create a texture from several different lines of bitmaps; centered

			// Find dimensions
			var w:Number = 0;
			var h:Number = 0;
			var i:int;
			for (i = 0; i < __bitmaps.length; i++) {
				if (i > 0) h += __lineSpace;
				h += __bitmaps[i].height;
				w = Math.max(w, __bitmaps[i].width);
			}

			w = Math.ceil(w);
			h = Math.ceil(h);

			// Create the new bitmap
			var bitmap:BitmapData = new BitmapData(w, h, true, 0x00000000);
			var posY:Number = 0;
			for (i = 0; i < __bitmaps.length; i++) {
				bitmap.copyPixels(__bitmaps[i], __bitmaps[i].rect, new Point(0, Math.round(posY)), null, null, true);
				posY += __bitmaps[i].height;
				posY += __lineSpace;
			}

			// Dispose of bitmaps if needed
			if (__canDispose) {
				for (i = 0; i < __bitmaps.length; i++) {
					__bitmaps[i].dispose();
				}
			}

			// Finally, create the text
			var texture:Texture = Texture.fromBitmapData(bitmap, __generateMipMaps, true, 1, FountainFamily.platform.getTextureProfile(TextureLibrary.TEXTURE_ID_GENERIC_TEXT).format, true);
			texture.root.onRestore = function():void {
				texture.root.uploadBitmapData(bitmap);
			};
			return texture;
		}

		public static function createSprite(__text:String, __font:String, __fontEM:String, __size:Number, __sizeEM:Number, __color:int, __colorEM:int = -1, __alpha:Number = 1, __alphaEM:Number = 1, __tracking:Number = 0, __trackingEM:Number = 0, __alignment:String = null, __maxWidth:Number = NaN, __leading:Number = 0):RichTextSprite {
			var textSprite:RichTextSprite = new RichTextSprite(__font, __size, __color, __alpha, __tracking);
			textSprite.setStyle("em", __fontEM == null ? __font : __fontEM, __sizeEM, __colorEM >= 0 ? __colorEM : __color, __alphaEM, __trackingEM);
			textSprite.text = __text;
			textSprite.align = __alignment == null ? TextSpriteAlign.LEFT : __alignment;
			textSprite.leading = __leading;
			if (!isNaN(__maxWidth)) textSprite.width = __maxWidth;
			return textSprite;
		}
	}
}
