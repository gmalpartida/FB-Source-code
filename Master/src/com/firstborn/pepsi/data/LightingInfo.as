package com.firstborn.pepsi.data {
	import com.zehfernando.data.types.Color;
	import com.zehfernando.utils.XMLUtils;
    import com.firstborn.pepsi.common.backend.BackendModel;
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

        //Brightness Modifier for the idle state and attractor
        public var brightnessAttractorMenu: Number;

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function LightingInfo(__xml:XML) {
			brightnessScale				= XMLUtils.getNodeAsFloat(__xml, "brightnessScale");
			brightnessPrePour			= XMLUtils.getNodeAsFloat(__xml, "brightnessPrePour");
			brightnessPour				= XMLUtils.getNodeAsFloat(__xml, "brightnessPour");
			colorStandby				= Color.fromString(XMLUtils.getNodeAsString(__xml, "colorStandby", "#00000000")).toAARRGGBB();
			timePourBrightnessChange	= XMLUtils.getNodeAsFloat(__xml, "timePourBrightnessChange");
			timeColorChange				= XMLUtils.getNodeAsFloat(__xml, "timeColorChange");


            var data :XML = XML(XMLUtils.getNodeAsString(__xml, "brightnessAttractorMenu"));
            brightnessAttractorMenu = Number(data.brightnessShade.(@id == BackendModel.lightihgHardware)) || (data.brightnessShade[0]);

            //To work with previous versions of the XMLs
            if(data == "undefined" || data == "") brightnessAttractorMenu = 0.7;

		}
	}
}
