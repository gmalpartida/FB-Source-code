package com.firstborn.pepsi.data.inventory {
	import com.firstborn.pepsi.application.FountainFamily;
	import com.zehfernando.utils.VectorUtils;
	import com.zehfernando.utils.XMLUtils;
	import com.zehfernando.utils.console.error;
	/**
	 * @author zeh fernando
	 */
	public class Beverage {

		// Properties
		public var id:String;
		public var name:String;
		public var recipeId:String;
		public var mixBeverageId:String;
		public var flavorIds:Vector.<String>;
		public var preselectedFlavorIds:Vector.<String>;
		public var lockedFlavorIds:Vector.<String>;
		public var hiddenFlavorIds:Vector.<String>;
		public var mixFlavorIds:Vector.<String>;
		public var maxFlavors:int;
		public var parentIds:Vector.<String>;
		public var groupId:String;
		public var isSparklingWater:Boolean;
		public var isTapWater:Boolean;
		public var isMix:Boolean;

        //Calories per oz defined in the beverages XML
        public var calories: Number;

		private var _design:BeverageDesign;
		private var _designADA:BeverageDesign;

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function Beverage() {
			// Set defaults
			id = "";
			name = "";
			recipeId = "";
			mixBeverageId = "";
			flavorIds = new Vector.<String>();
			preselectedFlavorIds = new Vector.<String>();
			lockedFlavorIds = new Vector.<String>();
			hiddenFlavorIds = new Vector.<String>();
			mixFlavorIds = new Vector.<String>();
			maxFlavors = 0;
			parentIds = new Vector.<String>();
			groupId = "";
			isSparklingWater = false;
			isTapWater = false;
			isMix = false;
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function getDesign(__isADA:Boolean = false):BeverageDesign {
			return __isADA ? _designADA : _design;
		}

		public static function fromXMLList(__xmlList:XMLList, __inventory:Inventory, __platformsIdsAllowed:Vector.<String>):Vector.<Beverage> {
			var beverages:Vector.<Beverage> = new Vector.<Beverage>();

			var newBeverage:Beverage;

			var i:int;

			for (i = 0; i < __xmlList.length(); i++) {
				newBeverage = fromXMLListItem(__xmlList, __inventory, __platformsIdsAllowed, XMLUtils.getAttributeAsString(__xmlList[i], "id"));
				beverages.push(newBeverage);

				if (FountainFamily.DEBUG_BEVERAGES_IGNORE_GROUPS) newBeverage.groupId = "";
				if (FountainFamily.DEBUG_BEVERAGES_IGNORE_PARENT) newBeverage.parentIds = new Vector.<String>();

				if (FountainFamily.DEBUG_BEVERAGES_USE_EVEN_ODD_GROUPS) {
					// Injects fake group data
					newBeverage.groupId = (i % 2 == 0 ? "even" : "odd");
				}

				if (FountainFamily.DEBUG_BEVERAGES_USE_XYZW_GROUPS) {
					// Injects fake group data
					if (i < 11) {
						newBeverage.groupId = "";
					} else if (i < 14) {
						newBeverage.groupId = "x";
					} else {
						newBeverage.groupId = "";
					}
				}

				if (FountainFamily.DEBUG_BEVERAGES_USE_FAKE_PARENTS) {
					if (i < 6 && i % 2 == 1) {
						newBeverage.parentIds = new Vector.<String>();
						newBeverage.parentIds.push(beverages[i-1].id);
					} else {
						newBeverage.parentIds = new Vector.<String>();
					}
				}

			}

			return beverages;
		}

		public static function fromXMLListItem(__xmlList:XMLList, __inventory:Inventory, __platformsIdsAllowed:Vector.<String>, __id:String):Beverage {
			var beverageXML:XML;
			var newBeverage:Beverage;

			var filterNames:Array = [FountainFamily.FILTER_ATTRIBUTE_XML_PLATFORMS];
			var filterValues:Array = [__platformsIdsAllowed];

			var i:int;

			var baseId:String;

			for (i = 0; i < __xmlList.length(); i++) {
				beverageXML = __xmlList[i];
				if (XMLUtils.getAttributeAsString(beverageXML, "id") == __id) {

					baseId = XMLUtils.getAttributeAsString(beverageXML, "base");
					if (baseId != "") {
						// Use other as a base
						newBeverage = fromXMLListItem(__xmlList, __inventory, __platformsIdsAllowed, baseId);
					} else {
						// New beverage
						newBeverage = new Beverage();
					}

					newBeverage.id						= XMLUtils.getAttributeAsString(beverageXML, "id",														newBeverage.id);

					var isTemplate:Boolean = newBeverage.id.substr(0, 9) == "template-";

					newBeverage.name					= XMLUtils.getFilteredNodeAsString(beverageXML, "name",													filterNames, filterValues, true, true, newBeverage.name);
					newBeverage.recipeId				= __inventory.getRecipeIdFrom(XMLUtils.getFilteredNodeAsString(beverageXML, "recipeId",					filterNames, filterValues, true, true, newBeverage.recipeId));
					newBeverage.mixBeverageId			= XMLUtils.getFilteredNodeAsString(beverageXML, "mixBeverage",											filterNames, filterValues, true, true, newBeverage.mixBeverageId);
					newBeverage.maxFlavors				= XMLUtils.getFilteredNodeAsInt(beverageXML, "maxFlavors",												filterNames, filterValues, true, true, newBeverage.maxFlavors);
					newBeverage.parentIds				= VectorUtils.stringToStringVector(XMLUtils.getFilteredNodeAsString(beverageXML, "parent",				filterNames, filterValues, true, true, newBeverage.parentIds.join(",")), ",", true);
					newBeverage.groupId					= XMLUtils.getFilteredNodeAsString(beverageXML, "group",												filterNames, filterValues, true, true, newBeverage.groupId);
					newBeverage.isSparklingWater		= XMLUtils.getFilteredNodeAsBoolean(beverageXML, "isSparklingWater",									filterNames, filterValues, true, true, newBeverage.isSparklingWater);
					newBeverage.isTapWater				= XMLUtils.getFilteredNodeAsBoolean(beverageXML, "isTapWater",											filterNames, filterValues, true, true, newBeverage.isTapWater);
					newBeverage.isMix					= XMLUtils.getFilteredNodeAsBoolean(beverageXML, "isMix",												filterNames, filterValues, true, true, newBeverage.isMix);


                    //Save the current calories count per oz in the beverate object
                    newBeverage.calories				= XMLUtils.getFilteredNodeAsFloat(beverageXML, "calories_per_oz",										filterNames, filterValues, true, true, newBeverage.calories);


                    newBeverage.flavorIds				= VectorUtils.stringToStringVector(XMLUtils.getFilteredNodeAsString(beverageXML, "flavors",				filterNames, filterValues, true, true, newBeverage.flavorIds.join(",")), ",", true);
					newBeverage.preselectedFlavorIds	= VectorUtils.stringToStringVector(XMLUtils.getFilteredNodeAsString(beverageXML, "preselectedFlavors",	filterNames, filterValues, true, true, newBeverage.preselectedFlavorIds.join(",")), ",", true);
					newBeverage.lockedFlavorIds			= VectorUtils.stringToStringVector(XMLUtils.getFilteredNodeAsString(beverageXML, "lockedFlavors",		filterNames, filterValues, true, true, newBeverage.lockedFlavorIds.join(",")), ",", true);
					newBeverage.hiddenFlavorIds			= VectorUtils.stringToStringVector(XMLUtils.getFilteredNodeAsString(beverageXML, "hiddenFlavors",		filterNames, filterValues, true, true, newBeverage.hiddenFlavorIds.join(",")), ",", true);
					newBeverage.mixFlavorIds			= VectorUtils.stringToStringVector(XMLUtils.getFilteredNodeAsString(beverageXML, "mixFlavors",			filterNames, filterValues, true, true, newBeverage.mixFlavorIds.join(",")), ",", true);

					newBeverage._design					= BeverageDesign.fromXML(XMLUtils.getFilteredFirstNode(beverageXML.child("design"),						filterNames, filterValues), __platformsIdsAllowed, false, isTemplate, newBeverage._design);
					newBeverage._designADA				= BeverageDesign.fromXML(XMLUtils.getFilteredFirstNode(beverageXML.child("design"),						filterNames, filterValues), __platformsIdsAllowed, true, isTemplate, newBeverage._designADA);

					if ((!Boolean(newBeverage.recipeId) || newBeverage.recipeId.length < 2) && !isTemplate) error("Recipe id for recipe [" + newBeverage.id + "] is [" + newBeverage.recipeId + "]!");

					return newBeverage;
				}
			}

			return null;
		}

		public function getValidPreselectedFlavorIds():Vector.<String> {
			// Returns the preselected flavor ids, but filtering by flavor ids that are actually allowed
			var validPreselectedFlavors:Vector.<String> = new Vector.<String>();
			for each (var preselectedFlavorId:String in preselectedFlavorIds) {
				if (flavorIds.indexOf(preselectedFlavorId) >= 0 && FountainFamily.inventory.getFlavorById(preselectedFlavorId) != null) validPreselectedFlavors.push(preselectedFlavorId);
			}
			return validPreselectedFlavors;
		}

		public function getNumCombinations(__flavors:Vector.<Flavor> = null):int {
			// Return the number of combinations possible for this brand
			var i:int;
			var j:int;

			var validFlavors:int = 0;
			if (__flavors == null) {
				// All potential flavors
				validFlavors = flavorIds.length;
			} else {
				// Find the number of flavors that actually exist
				for (i = 0; i < flavorIds.length; i++) {
					for (j = 0; j < __flavors.length; j++) {
						if (__flavors[j].id == flavorIds[i]) {
							// Valid id
							validFlavors++;
							break;
						}
					}
				}
			}

			// Calculate the combinations
			// http://stackoverflow.com/questions/25329814/finding-number-of-combinations-possible/25330045#25329980
			var sum:int = 0;
			var nci:int = 1;

			// Optimized binomial coefficient
			for (i = 0; i <= maxFlavors; i++) {
				sum += nci;
				nci *= validFlavors - i;
				nci /= i + 1;
			}

			return sum;
		}

		public function getRelatedBeverage():Beverage {
			// Finds the "related" beverage (for mixes, the main beverage)
			var relatedBeverage:Beverage = FountainFamily.inventory.getBeverageById(mixBeverageId);
			if (relatedBeverage == null) {
				error("Error: could not find related beverage with id [" + mixBeverageId + "] for mix beverage!");
			} else {
				return relatedBeverage;
			}
			return null;
		}

		public function getRelatedBrandImageLogoIsBig(__isADA:Boolean = false):Boolean {
			// For mixes, find whether the related brand (the brand this mix's recipe id come from) logo is big or not
			if (getDesign(__isADA).imageLogoRecipe.length > 0) {
				// The mix has a beverage logo of its own, so use it instead of the recipe id's beverage's actual logo
				return getDesign(__isADA).imageLogoRecipeIsBig;
			} else {
				// Use the actual related beverage
				var relatedBeverage:Beverage = getRelatedBeverage();
				if (relatedBeverage != null) return relatedBeverage.getDesign(__isADA).imageLogoBrandIsBig;
			}
			return false;
		}

		public function getRelatedBrandImageLogo(__isADA:Boolean = false):String {
			// For mixes, find whether the related brand (the brand this mix's recipe id come from) logo is big or not
			if (getDesign(__isADA).imageLogoRecipe.length > 0) {
				// The mix has a beverage logo of its own, so use it instead of the recipe id's beverage's actual logo
				return getDesign(__isADA).imageLogoRecipe;
			} else {
				// Use the actual related beverage
				var relatedBeverage:Beverage = getRelatedBeverage();
				if (relatedBeverage != null) return relatedBeverage.getDesign(__isADA).imageLogoBrand;
			}
			return null;
		}

		public function getRelatedBrandImageLogoScale(__isADA:Boolean = false):Number {
			// For mixes, find whether the related brand (the brand this mix's recipe id come from) logo is big or not
			if (getDesign(__isADA).imageLogoRecipe.length > 0) {
				// The mix has a beverage logo of its own, so use it instead of the recipe id's beverage's actual logo
				return getDesign(__isADA).scaleLogoRecipe;
			} else {
				// Use the actual related beverage
				var relatedBeverage:Beverage = getRelatedBeverage();
				if (relatedBeverage != null) return relatedBeverage.getDesign(__isADA).scaleLogo;
			}
			return null;
		}
	}
}
