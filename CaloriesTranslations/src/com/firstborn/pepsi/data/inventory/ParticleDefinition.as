package com.firstborn.pepsi.data.inventory {
	import com.firstborn.pepsi.application.FountainFamily;
	import com.zehfernando.data.types.Color;
	import com.zehfernando.utils.RandomGenerator;
	import com.zehfernando.utils.XMLUtils;
	/**
	 * @author zeh fernando
	 */
	public class ParticleDefinition {

		// Properties
		public var color:uint;
		public var opacityMin:Number;
		public var opacityMax:Number;
		public var frequency:Number;
		public var colorVariation:Number;


		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function ParticleDefinition() {
			// Set defaults
			color = 0x000000;
			opacityMin = 0;
			opacityMax = 1;
			frequency = 1;
			colorVariation = 0;
		}

		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private static function getUintFromColorString(__color:String, __default:uint):uint {
			// Converts a "#aarrggbb" color string to an uint, with uint defaults
			if (__color == null || __color.length == 0) return __default;
			return Color.fromString(__color).toAARRGGBB();
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function get fullColor():Color {
			var clr:Color = Color.fromRRGGBB(color);
			clr.r += RandomGenerator.getInRange(-colorVariation, colorVariation) / 255;
			clr.g += RandomGenerator.getInRange(-colorVariation, colorVariation) / 255;
			clr.b += RandomGenerator.getInRange(-colorVariation, colorVariation) / 255;
			clr.a = RandomGenerator.getInRange(opacityMin, opacityMax);
			return clr;
		}

		// ================================================================================================================
		// STATIC INTERFACE -----------------------------------------------------------------------------------------------

		public static function fromXMLList(__xmlList:XMLList, __platformsIdsAllowed:Vector.<String>):Vector.<ParticleDefinition> {
			var particleXML:XML;
			var particle:ParticleDefinition;
			var particles:Vector.<ParticleDefinition> = new Vector.<ParticleDefinition>();

			var filterNames:Array = [FountainFamily.FILTER_ATTRIBUTE_XML_PLATFORMS];
			var filterValues:Array = [__platformsIdsAllowed];

			var i:int;
			var list:Vector.<XML> = XMLUtils.getFilteredNodeList(__xmlList, filterNames, filterValues);

			for (i = 0; i < list.length; i++) {
				particleXML = list[i];

				particle = new ParticleDefinition();

				particle.color						= getUintFromColorString(XMLUtils.getFilteredNodeAsString(particleXML, "color", filterNames, filterValues), particle.color);
				particle.opacityMin					= XMLUtils.getFilteredNodeAsFloat(particleXML, "opacityMin",				filterNames, filterValues, true, true, particle.opacityMin);
				particle.opacityMax					= XMLUtils.getFilteredNodeAsFloat(particleXML, "opacityMax",				filterNames, filterValues, true, true, particle.opacityMax);
				particle.frequency					= XMLUtils.getFilteredNodeAsFloat(particleXML, "frequency",					filterNames, filterValues, true, true, particle.frequency);
				particle.colorVariation				= XMLUtils.getFilteredNodeAsFloat(particleXML, "colorVariation",			filterNames, filterValues, true, true, particle.colorVariation);

				particles.push(particle);
			}

			return particles;
		}
	}
}