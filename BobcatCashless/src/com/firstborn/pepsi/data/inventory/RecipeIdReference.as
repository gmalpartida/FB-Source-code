package com.firstborn.pepsi.data.inventory {
	import com.zehfernando.utils.StringUtils;
	import com.zehfernando.utils.XMLUtils;
	/**
	 * @author zeh fernando
	 */
	public class RecipeIdReference {

		// Properties
		public var internalId:String;
		public var recipeId:String;


		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function RecipeIdReference() {
			internalId = "";
			recipeId = "";
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public static function fromXMLList(__xmlList:XMLList):Vector.<RecipeIdReference> {
			var recipeIdReferences:Vector.<RecipeIdReference> = new Vector.<RecipeIdReference>();

			var recipeIdReferenceXML:XML;
			var newRecipeIdReference:RecipeIdReference;

			var i:int;
			for (i = 0; i < __xmlList.length(); i++) {
				recipeIdReferenceXML = __xmlList[i];

				newRecipeIdReference = new RecipeIdReference();
				newRecipeIdReference.internalId			= XMLUtils.getAttributeAsString(recipeIdReferenceXML, "id");
				newRecipeIdReference.recipeId			= StringUtils.getCleanString(recipeIdReferenceXML);

				recipeIdReferences.push(newRecipeIdReference);
			}

			return recipeIdReferences;
		}
	}
}
