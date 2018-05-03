package com.firstborn.pepsi.data.home {
	import com.firstborn.pepsi.application.FountainFamily;
	import com.firstborn.pepsi.data.inventory.Inventory;
	import com.zehfernando.utils.XMLUtils;
	/**
	 * @author zeh fernando
	 */
	public class MenuItemDefinition {

		// Properties
		public var beverageId:String;

		// Static
		private static var _menuItems:Vector.<MenuItemDefinition>;

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function MenuItemDefinition() {
			beverageId = "";
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function clone():MenuItemDefinition {
			var menuItem:MenuItemDefinition = new MenuItemDefinition();
			menuItem.beverageId = beverageId;
			return menuItem;
		}

		public static function fromXMLList(__xmlList:XMLList):Vector.<MenuItemDefinition> {
			var menuItems:Vector.<MenuItemDefinition> = new Vector.<MenuItemDefinition>();

			var menuItemXML:XML;
			var newMenuItem:MenuItemDefinition;

			var i:int;

			for (i = 0; i < __xmlList.length(); i++) {
				menuItemXML = __xmlList[i];

				newMenuItem = new MenuItemDefinition();

				// Common
				newMenuItem.beverageId					= XMLUtils.getNodeAsString(menuItemXML, "beverageId");

				menuItems.push(newMenuItem);
			}

			return menuItems;
		}

		public static function getMenuItemIndexByBeverageId(__id:String):int {
			var menuItems:Vector.<MenuItemDefinition> = getMenuItems();
			for (var i:int = 0; i < menuItems.length; i++) {
				if (menuItems[i].beverageId == __id) return i;
			}
			return -1;
		}

		public static function getMenuItems():Vector.<MenuItemDefinition> {
			if (_menuItems == null) {
				// Need to load menu items first
				_menuItems = fromXMLList((FountainFamily.homeXML.child("menu")[0] as XML).children());

				if (FountainFamily.DEBUG_FORCE_MENU_BEVERAGES_COUNT) {
					var itemsToForce:int = FountainFamily.DEBUG_FORCE_MENU_BEVERAGES_COUNT_VALUE;
					var newMenuItem:MenuItemDefinition;

					// Use original items in their beverages sequence
					_menuItems.length = 0;

					var c:int = 0;
					while (c < itemsToForce) {
						if (!FountainFamily.inventory.getBeverages()[c].isMix) {
							newMenuItem = new MenuItemDefinition();
							newMenuItem.beverageId = FountainFamily.inventory.getBeverages()[c].id;
							_menuItems.push(newMenuItem);
						}
						c++;
					}

//					// Duplicates beverages so the menu can be tested with a given number of items
//					if (_menuItems.length > itemsToForce) {
//						// Remove items
//						_menuItems.splice(itemsToForce, _menuItems.length - itemsToForce);
//					} else {
//						// Add items
//						i = 0;
//						while (_menuItems.length < itemsToForce) {
//							_menuItems.push(_menuItems[i].clone());
//							i++;
//						}
//					}
				}
			}
			return _menuItems;
		}

		public static function getNumCombinations(__inventory:Inventory):int {
			// Return the number of combinations possible with these beverages and flavors (similar to Inventory.getNumCombinations)
			var items:Vector.<MenuItemDefinition> = getMenuItems();
			var total:int = 0;
			for (var i:int = 0; i < items.length; i++) {
				total += __inventory.getBeverageById(items[i].beverageId).getNumCombinations(__inventory.getFlavors());
			}
			return total;
		}
	}
}
