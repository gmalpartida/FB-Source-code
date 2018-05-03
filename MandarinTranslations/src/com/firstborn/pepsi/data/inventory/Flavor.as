package com.firstborn.pepsi.data.inventory {
	import com.firstborn.pepsi.application.FountainFamily;
	import com.zehfernando.utils.XMLUtils;
	import com.zehfernando.utils.console.error;
	/**
	 * @author zeh fernando
	 */
	public class Flavor {

		// Constants
		public static const ID_ALL:String = "*";

		// Properties
		public var id:String;
		public var name:String;
		public var recipeId:String;

		public var design:FlavorDesign;

		public var names : Vector.<String>;

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function Flavor() {
			id = "";
			name = "";
			recipeId = "";
			names = new Vector.<String>();
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public static function fromXMLList(__xmlList:XMLList, __inventory:Inventory, __platformsIdsAllowed:Vector.<String>, __flavorIdsAllowed:Vector.<String>):Vector.<Flavor> {

			var flavors:Vector.<Flavor> = new Vector.<Flavor>();

			var flavorXML:XML;
			var newFlavor:Flavor;

			var filterNames:Array = [FountainFamily.FILTER_ATTRIBUTE_XML_PLATFORMS];
			var filterValues:Array = [__platformsIdsAllowed];

			var i:int;
			var newFlavorId:String;
			var list:Vector.<XML> = XMLUtils.getFilteredNodeList(__xmlList, filterNames, filterValues, true, true, true);

			for (i = 0; i < list.length; i++) {
				flavorXML = list[i];
				newFlavorId = XMLUtils.getAttributeAsString(flavorXML, "id");

				if (__flavorIdsAllowed.length == 0 || __flavorIdsAllowed.indexOf(newFlavorId) > -1) {

					newFlavor = new Flavor();

					newFlavor.id				= newFlavorId;
					newFlavor.name				= XMLUtils.getNodeAsString(flavorXML, "name");
					newFlavor.recipeId			= __inventory.getRecipeIdFrom(XMLUtils.getNodeAsString(flavorXML, "recipeId"));
					newFlavor.design			= FlavorDesign.fromXML(XMLUtils.getFirstNode(flavorXML.child("design")));

					if (!Boolean(newFlavor.recipeId) || newFlavor.recipeId.length < 2) error("Recipe id for flavor [" + newFlavor.id + "] is [" + newFlavor.recipeId + "]!");

					flavors.push(newFlavor);
				}
			}
			return flavors;
		}
	}
}
