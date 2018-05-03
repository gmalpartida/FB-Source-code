package com.firstborn.pepsi.data {
	import starling.textures.TextureSmoothing;

	import com.zehfernando.utils.XMLUtils;

	import flash.display3D.Context3DTextureFormat;
	/**
	 * @author zeh fernando
	 */
	public class TextureProfile {

		// Properties
		public var id:String;								// E.g. "blob-shape"

		public var resolution:int;							// Dimensions, in pixels
		public var format:String;							// Texture format ("bgra" (default), "compressed", "compressedAlpha", "bgrPacked565", "bgraPacked4444")
		public var smoothing:String;						// Texture smoothing ("none", "bilinear", "trilinear")

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function TextureProfile() {
		}

		// ================================================================================================================
		// STATIC INTERFACE -----------------------------------------------------------------------------------------------

		public static function fromXMLList(__xmlList:XMLList):Vector.<TextureProfile> {
			var textureXML:XML;
			var newTexture:TextureProfile;
			var newTextures:Vector.<TextureProfile> = new Vector.<TextureProfile>();

			var i:int;
			for (i = 0; i < __xmlList.length(); i++) {
				textureXML = __xmlList[i];

				newTexture = new TextureProfile();

				newTexture.id							= XMLUtils.getAttributeAsString(textureXML, "id");
				newTexture.resolution					= XMLUtils.getNodeAsInt(textureXML, "resolution");
				newTexture.format						= XMLUtils.getNodeAsString(textureXML, "format", Context3DTextureFormat.BGRA);
				newTexture.smoothing					= XMLUtils.getNodeAsString(textureXML, "smoothing", TextureSmoothing.BILINEAR);

				newTextures.push(newTexture);
			}
			return newTextures;
		}
	}
}
