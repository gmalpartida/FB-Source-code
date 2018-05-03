package com.firstborn.pepsi.data.inventory {
	import com.firstborn.pepsi.application.FountainFamily;
	import com.zehfernando.data.types.Color;
	import com.zehfernando.utils.XMLUtils;
	/**
	 * @author zeh fernando
	 */
	public class FlavorDesign {

		// Properties
		public var colorText:uint;
		public var colorTextSelected:uint;
		public var colorBackground:uint;
		public var opacityDisabled:Number;
		public var animationIntro:String;
		public var animationSelect:String;
		public var animationDeselect:String;

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function FlavorDesign() {
			colorText = 0x000000;
			colorTextSelected = 0xffffff;
			colorBackground = 0x000000;
			opacityDisabled = 1;
			animationIntro = "";
			animationSelect = "";
			animationDeselect = "";
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public static function fromXML(__xmlData:XML):FlavorDesign {
			var flavorDesign:FlavorDesign = new FlavorDesign();

			// Common
			flavorDesign.colorText			= Color.fromString(XMLUtils.getNodeAsString(__xmlData, "colorText", "#000000")).toRRGGBB();
			flavorDesign.colorTextSelected	= Color.fromString(XMLUtils.getNodeAsString(__xmlData, "colorTextSelected", "#000000")).toRRGGBB();
			flavorDesign.colorBackground	= Color.fromString(XMLUtils.getNodeAsString(__xmlData, "colorBackground", "#000000")).toRRGGBB();
			flavorDesign.opacityDisabled	= XMLUtils.getNodeAsFloat(__xmlData, "opacityDisabled");

			if (!FountainFamily.DEBUG_FLAVORS_IGNORE_ANIMATIONS) {
				flavorDesign.animationIntro		= XMLUtils.getNodeAsString(__xmlData, "animationIntro");
				flavorDesign.animationSelect	= XMLUtils.getNodeAsString(__xmlData, "animationSelect");
				flavorDesign.animationDeselect	= XMLUtils.getNodeAsString(__xmlData, "animationDeselect");
			}

			return flavorDesign;
		}
	}
}
