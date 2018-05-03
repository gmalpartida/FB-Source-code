package com.firstborn.pepsi.data {
	import com.zehfernando.data.types.Color;
	import com.zehfernando.utils.XMLUtils;

	import flash.filters.GlowFilter;
	/**
	 * @author zeh fernando
	 */
	public class ADAInfo {

		// Properties

		// Software
		public var softwareEnabled:Boolean;

		// Hardware
		public var hardwareEnabled:Boolean;

		public var hardwareFocusFillColor:Color;
		public var hardwareFocusShadowColor:Color;
		public var hardwareFocusBorderColor:Color;
		public var hardwareFocusBorderWidth:Number;
		public var hardwareFocusTimeAnimate:Number;
		public var hardwareFocusScaleNoise:Number;
		public var hardwareFocusScaleMenu:Number;
		public var hardwareFocusScaleButton:Number;

		public var hardwareKeys:XML;


		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function ADAInfo(__xml:XML) {
			var hardwareNode:XML				= XMLUtils.getNode(__xml, "hardware");
			var softwareNode:XML				= XMLUtils.getNode(__xml, "software");

			if (softwareNode != null) {
				softwareEnabled					= XMLUtils.getNodeAsBoolean(softwareNode, "enabled");
			}

			if (hardwareNode != null) {
				hardwareEnabled					= XMLUtils.getNodeAsBoolean(hardwareNode, "enabled");

				hardwareFocusFillColor			= Color.fromString(XMLUtils.getNodeAsString(hardwareNode, "focusFillColor", "#ff000000"));
				hardwareFocusShadowColor		= Color.fromString(XMLUtils.getNodeAsString(hardwareNode, "focusShadowColor", "#ff000000"));
				hardwareFocusBorderColor		= Color.fromString(XMLUtils.getNodeAsString(hardwareNode, "focusBorderColor", "#ff000000"));
				hardwareFocusBorderWidth		= XMLUtils.getNodeAsFloat(hardwareNode, "focusBorderWidth");
				hardwareFocusTimeAnimate		= XMLUtils.getNodeAsFloat(hardwareNode, "focusTimeAnimate");
				hardwareFocusScaleNoise			= XMLUtils.getNodeAsFloat(hardwareNode, "focusScaleNoise");
				hardwareFocusScaleMenu			= XMLUtils.getNodeAsFloat(hardwareNode, "focusScaleMenu");
				hardwareFocusScaleButton		= XMLUtils.getNodeAsFloat(hardwareNode, "focusScaleButton");

				hardwareKeys					= XMLUtils.getNode(hardwareNode, "keys");
			}
		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		public function get hardwareFocusFilters():Array {
			// If _delayHomeAfter exists, use it; otherwise, use delayHome
			return [new GlowFilter(hardwareFocusShadowColor.toRRGGBB(), hardwareFocusShadowColor.a, 4, 4, 2, 8)];
		}
	}
}
