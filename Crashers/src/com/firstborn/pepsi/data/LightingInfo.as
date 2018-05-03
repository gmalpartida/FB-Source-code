package com.firstborn.pepsi.data {
	import com.zehfernando.data.types.Color;
	import com.zehfernando.utils.XMLUtils;
	/**
	 * @author zeh fernando
	 */
	public class LightingInfo {

		// Properties
		public var brightnessScale:Number;
		public var brightnessPrePour:Number;
		public var brightnessPour:Number;
		public var colorStandby:uint;
		public var timePourBrightnessChange:Number;
		public var timeColorChange:Number;

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function LightingInfo(__xml:XML) {
			brightnessScale				= XMLUtils.getNodeAsFloat(__xml, "brightnessScale");
			brightnessPrePour			= XMLUtils.getNodeAsFloat(__xml, "brightnessPrePour");
			brightnessPour				= XMLUtils.getNodeAsFloat(__xml, "brightnessPour");
			colorStandby				= Color.fromString(XMLUtils.getNodeAsString(__xml, "colorStandby", "#00000000")).toAARRGGBB();
			timePourBrightnessChange	= XMLUtils.getNodeAsFloat(__xml, "timePourBrightnessChange");
			timeColorChange				= XMLUtils.getNodeAsFloat(__xml, "timeColorChange");
		}
	}
}
