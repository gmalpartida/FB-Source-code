package com.firstborn.pepsi.data {
	import starling.textures.TextureSmoothing;

	import com.zehfernando.utils.XMLUtils;
	import com.zehfernando.utils.console.error;

	import flash.display3D.Context3DTextureFormat;
	/**
	 * @author zeh fernando
	 */
	public class AnimationDefinition {

		// Properties
		public var id:String;								// E.g. "blob-shape"

		public var image:String;
		public var frameWidth:int;
		public var frameHeight:int;
		public var frames:int;
		public var smoothing:String;
		public var fps:Number;
		public var scale:Number;
		public var format:String;

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function AnimationDefinition() {
		}

		// ================================================================================================================
		// STATIC INTERFACE -----------------------------------------------------------------------------------------------

		public static function fromXMLList(__xmlList:XMLList):Vector.<AnimationDefinition> {
			var animationXML:XML;
			var newAnimation:AnimationDefinition;
			var newAnimations:Vector.<AnimationDefinition> = new Vector.<AnimationDefinition>();

			var i:int;
			for (i = 0; i < __xmlList.length(); i++) {
				animationXML = __xmlList[i];

				newAnimation = new AnimationDefinition();

				newAnimation.id							= XMLUtils.getAttributeAsString(animationXML, "id");
				newAnimation.image						= XMLUtils.getNodeAsString(animationXML, "image");
				newAnimation.frameWidth					= XMLUtils.getNodeAsInt(animationXML, "frameWidth");
				newAnimation.frameHeight				= XMLUtils.getNodeAsInt(animationXML, "frameHeight");
				newAnimation.frames						= XMLUtils.getNodeAsInt(animationXML, "frames");
				//newAnimation.format						= XMLUtils.getNodeAsString(animationXML, "format", Context3DTextureFormat.BGRA);
				newAnimation.smoothing					= XMLUtils.getNodeAsString(animationXML, "smoothing", TextureSmoothing.BILINEAR);
				newAnimation.fps						= XMLUtils.getNodeAsFloat(animationXML, "fps", 30);
				newAnimation.scale						= XMLUtils.getNodeAsFloat(animationXML, "scale", 1);
				newAnimation.format						= XMLUtils.getNodeAsString(animationXML, "format", Context3DTextureFormat.BGRA);

				newAnimations.push(newAnimation);
			}
			return newAnimations;
		}

		public static function getAnimationDefinition(__animationId:String, __animations:Vector.<AnimationDefinition>):AnimationDefinition {
			for (var i:int = 0; i < __animations.length; i++) {
				if (__animations[i].id == __animationId) return __animations[i];
			}
			error("Could not find animation definition with id [" + __animationId + "]!");
			return null;
		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		public function get height():Number {
			return frameHeight * scale;
		}
	}
}
