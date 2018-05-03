package com.firstborn.pepsi.data.inventory {
	import com.zehfernando.utils.console.error;
	import com.zehfernando.utils.console.warn;
	/**
	 * @author zeh fernando
	 */
	public class Inventory {

		// Instances
		private var beverages:Vector.<Beverage>;
		private var flavors:Vector.<Flavor>;
		private var recipeIdReferences:Vector.<RecipeIdReference>;


		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function Inventory(__beveragesXML:XML, __flavorsXML:XML, __recipesXML:XML, __platformIdMain:String, __platformIdAlternative:String, __flavorIdsAllowed:Vector.<String>):void {
			// Reads everything from a XML List

			// Recipe references need to go first, so that beverages and flavors can get the recipe ids
			recipeIdReferences = RecipeIdReference.fromXMLList(__recipesXML.child("recipe"));

			var platformsIdsAllowed:Vector.<String> = new Vector.<String>();
			platformsIdsAllowed.push(__platformIdMain);
			if (__platformIdMain != __platformIdAlternative) platformsIdsAllowed.push(__platformIdAlternative);

			beverages = Beverage.fromXMLList(__beveragesXML.child("beverage"), this, platformsIdsAllowed);
			flavors = Flavor.fromXMLList(__flavorsXML.child("flavor"), this, platformsIdsAllowed, __flavorIdsAllowed);
		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		public function getBeverageById(__id:String):Beverage {
			for (var i:int = 0; i < beverages.length; i++) {
				if (beverages[i].id == __id) return beverages[i];
			}
			error("Beverage with id [" + __id + "] not found!");
			return null;
		}

		public function getBeverageByRecipeId(__recipeId:String, __ignoreMixes:Boolean = true):Beverage {
			for (var i:int = 0; i < beverages.length; i++) {
				if (beverages[i].recipeId == __recipeId && (!__ignoreMixes || !beverages[i].isMix)) return beverages[i];
			}
			error("Beverage with recipe id [" + __recipeId + "] not found!");
			return null;
		}

		public function getBeverageSparklingWater():Beverage {
			for (var i:int = 0; i < beverages.length; i++) {
				if (beverages[i].isSparklingWater) return beverages[i];
			}
			error("Beverage with sparkling water set to true not found!");
			return null;
		}

		public function getBeverageTapater():Beverage {
			for (var i:int = 0; i < beverages.length; i++) {
				if (beverages[i].isTapWater) return beverages[i];
			}
			error("Beverage with tap water set to true not found!");
			return null;
		}

		public function getBeverages():Vector.<Beverage> {
			return beverages;
		}

		public function getFlavorById(__id:String):Flavor {
			for (var i:int = 0; i < flavors.length; i++) {
				if (flavors[i].id == __id) return flavors[i];
			}
			//warn("Flavor with id [" + __id + "] not found");
			return null;
		}

		public function getFlavorsById(__flavorIds:Vector.<String>):Vector.<Flavor> {
			// Given a list of flavor ids, return a list of valid flavors
			var validFlavors:Vector.<Flavor> = new Vector.<Flavor>();
			var newFlavor:Flavor;
			for (var i:int = 0; i < __flavorIds.length; i++) {
				newFlavor = getFlavorById(__flavorIds[i]);
				if (newFlavor != null) {
					validFlavors.push(newFlavor);
				}
			}
			return validFlavors;
		}

		public function getFlavorRecipeIds(__flavorIds:Vector.<String>):Vector.<String> {
			// Given a list of flavor ids, returns the list of recipe ids

			var flavors:Vector.<Flavor> = getFlavorsById(__flavorIds);
			var recipeIds:Vector.<String> = new Vector.<String>();
			for each (var flavor:Flavor in flavors) {
				recipeIds.push(flavor.recipeId);
			}

			return recipeIds;
		}

		public function getFlavors():Vector.<Flavor> {
			return flavors;
		}

		public function setFlavorsLocalization(names: Vector.<Flavor>):void {
			for(var i : uint = 0; i < names.length; i ++) {
				flavors[i].names.push(names[i].name);
			}
		}

		public function isKnownRecipeId(__recipeId:String):Boolean {
			// Looks for a recipe id in the list of known ids, returning true if found
			for (var i:int = 0; i < recipeIdReferences.length; i++) {
				if (recipeIdReferences[i].recipeId == __recipeId) return true;
			}
			return false;
		}

		public function getRecipeIdFrom(__recipeId:String):String {
			// Try to find a recipe (from recipes.xml) that has its internal id as __recipeId
			// If found, returns the actual recipe id from it; if not, just return the passed __recipeId
			for (var i:int = 0; i < recipeIdReferences.length; i++) {
				if (recipeIdReferences[i].internalId == __recipeId) return recipeIdReferences[i].recipeId;
			}
			if (__recipeId.length > 0 && !isKnownRecipeId(__recipeId)) warn("Could not find recipes.xml recipe for [" + __recipeId + "]: using own id as recipe");
			return __recipeId;
		}

		public function getNumCombinations():int {
			// Return the number of combinations possible with these beverages and flavors
			var total:int = 0;
			for (var i:int = 0; i < beverages.length; i++) {
				total += beverages[i].getNumCombinations(flavors);
			}
			return total;
		}
	}
}
