package com.firstborn.pepsi.data.home {
	import com.firstborn.pepsi.application.FountainFamily;
	import com.firstborn.pepsi.data.AnimationDefinition;
	import com.zehfernando.net.assets.AssetLibrary;
	import com.zehfernando.utils.XMLUtils;
	/**
	 * @author zeh fernando
	 */
	public class MetaballItemDefinition {

		// Properties
		public var animationId:String;
		private var _animation:AnimationDefinition;

		public var centerX:Number;
		public var centerY:Number;
		public var frequency:Number;
		public var angle:Number;
		public var scale:Number;

		// Static
		private static var _metaballItems:Vector.<MetaballItemDefinition>;

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function MetaballItemDefinition() {
			animationId = "";
			centerX = 0;
			centerY = 0;
			frequency = 1;
			angle = 0;
			scale = 1;
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public static function fromXMLList(__xmlList:XMLList):Vector.<MetaballItemDefinition> {
			var metaballItems:Vector.<MetaballItemDefinition> = new Vector.<MetaballItemDefinition>();

			var metaballItemXML:XML;
			var newMetaballItem:MetaballItemDefinition;

			var i:int;
			for (i = 0; i < __xmlList.length(); i++) {
				metaballItemXML = __xmlList[i];

				newMetaballItem = new MetaballItemDefinition();

				// Common
				newMetaballItem.animationId					= XMLUtils.getNodeAsString(metaballItemXML, "animation");
				newMetaballItem.centerX						= XMLUtils.getNodeAsFloat(metaballItemXML, "centerX", 0);
				newMetaballItem.centerY						= XMLUtils.getNodeAsFloat(metaballItemXML, "centerY", 0);
				newMetaballItem.frequency					= XMLUtils.getNodeAsFloat(metaballItemXML, "frequency", 1);
				newMetaballItem.angle						= XMLUtils.getNodeAsFloat(metaballItemXML, "angle", 0);
				newMetaballItem.scale						= XMLUtils.getNodeAsFloat(metaballItemXML, "scale", 1);

				metaballItems.push(newMetaballItem);
			}
			return metaballItems;
		}

		public static function getMetaballItems():Vector.<MetaballItemDefinition> {
			if (_metaballItems == null) {
				// Need to load menu items first
				_metaballItems = fromXMLList((FountainFamily.homeXML.child("metaballs")[0] as XML).children());
			}
			return _metaballItems;
		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		public function get animation():AnimationDefinition{
			if (_animation == null) {
				// Animation is unknown, tries to find it first
				_animation = AnimationDefinition.getAnimationDefinition(animationId, FountainFamily.animationDefinitions);
			}
			return _animation;
		}
	}
}
