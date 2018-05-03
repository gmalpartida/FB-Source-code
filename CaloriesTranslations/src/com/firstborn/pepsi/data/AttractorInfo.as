package com.firstborn.pepsi.data {
	import com.zehfernando.data.types.Color;
	import com.zehfernando.utils.MathUtils;
	import com.zehfernando.utils.XMLUtils;
	/**
	 * @author zeh fernando
	 */
	public class AttractorInfo {

		// Properties
		public var file:String;

		public var loop:Boolean;
		public var delayHome:Number;					// Delay, in seconds, before playing the video when on the home screen (0 = never)
		public var delayBrand:Number;					// Delay, in seconds, before playing the video when on the brand screen (0 = never)

		public var delayHomeADA:Number;
		public var delayBrandADA:Number;

		public var lightColors:Vector.<uint>;			// Specific light colors
		public var lightSeconds:Vector.<Number>;		// Specific seconds for each color

		private var _delayHomeAfter:Number;				// Delay, in seconds, before playing the video when on the home screen AFTER playing the idle state for the first time; only valid when loop is set to false; if the mouse is moved while on the home the delay resets to delayHome time (0 = same as delayHome)


		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function AttractorInfo(__xml:XML) {
			file			= XMLUtils.getNodeAsString(__xml, "file");
			loop			= XMLUtils.getNodeAsBoolean(__xml, "loop");
			delayHome		= XMLUtils.getNodeAsFloat(__xml, "delayHome");
			delayBrand		= XMLUtils.getNodeAsFloat(__xml, "delayBrand");
			delayHomeADA	= XMLUtils.getNodeAsFloat(__xml, "delayHome", delayHome);
			delayBrandADA	= XMLUtils.getNodeAsFloat(__xml, "delayBrand", delayBrand);

			lightSeconds	= new Vector.<Number>();
			lightColors		= new Vector.<uint>();
			var colorLights:String = XMLUtils.getNodeAsString(__xml, "colorLights");
			if (colorLights.length > 0) {
				var colorItems:Array = colorLights.split(",");
				for (var i:int = 0; i < colorItems.length; i += 2) {
					lightSeconds.push(parseFloat(colorItems[i]));
					lightColors.push(Color.fromString(colorItems[i+1]).toAARRGGBB());
				}
			}

			_delayHomeAfter	= XMLUtils.getNodeAsFloat(__xml, "delayHomeAfter");
		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		public function get delayHomeAfter():Number {
			// If _delayHomeAfter exists, use it; otherwise, use delayHome
			return _delayHomeAfter > 0 ? _delayHomeAfter : delayHome;
		}

		public function getColorAt(__timeSeconds:Number):uint {
			// Get the color at a specific time
			if (lightSeconds.length == 0) return 0x00000000;
			if (lightSeconds.length == 1) return lightColors[0];
			if (__timeSeconds < lightSeconds[0]) return lightColors[0];
			if (__timeSeconds > lightSeconds[lightSeconds.length - 1]) return lightColors[lightSeconds.length - 1];

			for (var i:int = 0; i < lightSeconds.length - 1; i++) {
				if (lightSeconds[i] <= __timeSeconds && lightSeconds[i+1] > __timeSeconds) {
					// Found the time
					return Color.interpolateAARRGGBB(lightColors[i], lightColors[i+1], MathUtils.map(__timeSeconds, lightSeconds[i], lightSeconds[i+1], 1, 0));
				}
			}

			// Should never happen
			return 0x00000000;
		}
	}
}
