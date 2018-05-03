package com.firstborn.pepsi.display.gpu.brand.flavors.vertical {
	import com.firstborn.pepsi.data.inventory.Flavor;
import com.firstborn.pepsi.display.gpu.brand.flavors.FlavorSelector;
import com.firstborn.pepsi.display.gpu.brand.flavors.FlavorSelector;
	import com.firstborn.pepsi.display.gpu.brand.flavors.FlavorSelectorItem;

	/**
	 * @author zeh fernando
	 */
	public class FlavorSelectorVertical extends FlavorSelector {

		// Properties
		private var marginFlavorLeft:Number;
		private var marginFlavorIcon:Number;
		private var marginFlavorRight:Number;
		private var assumedWidthFruit:Number;
		private var width:int;
		private var columns:int;
		private var fontSize:Number;
		private var fontTracking:Number;
		private var fruitScale:Number;
		private var invisibleFruitsRedistributesButtons:Boolean;
		private var itemHeight:Number;
		private var itemMarginVertical:Number;

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function FlavorSelectorVertical(__language : uint, __flavorIds:Vector.<String>, __hiddenFlavorIds:Vector.<String>, __maxFlavorsSelected:uint, __marginFlavorLeft:Number, __assumedWidthFruit:Number, __marginFlavorIcon:Number, __marginFlavorRight:Number, __width:int, __columns:int, __fontSize:Number, __fontTracking:Number, __fruitScale:Number, __invisibleFruitsRedistributesButtons:Boolean, __itemHeight:Number, __itemMarginVertical:Number, __allowKeyboardFocus:Boolean) {

			currentLanguage = __language;
			marginFlavorLeft = __marginFlavorLeft;
			marginFlavorIcon = __marginFlavorIcon;
			marginFlavorRight = __marginFlavorRight;
			assumedWidthFruit = __assumedWidthFruit;
			width = __width;
			columns = __columns;
			fontSize = __fontSize;
			fontTracking = __fontTracking;
			fruitScale = __fruitScale;
			invisibleFruitsRedistributesButtons = __invisibleFruitsRedistributesButtons;
			itemHeight = __itemHeight;
			itemMarginVertical = __itemMarginVertical;
			super(__flavorIds, __hiddenFlavorIds, __maxFlavorsSelected, __allowKeyboardFocus);
		}

		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		override protected function getFlavorSelectorItem(__flavor:Flavor):FlavorSelectorItem {
			return new FlavorSelectorVerticalItem(currentLanguage, __flavor, marginFlavorLeft, assumedWidthFruit, marginFlavorIcon, marginFlavorRight, fontSize, fontTracking, fruitScale, itemHeight, itemMarginVertical, allowKeyboardFocus);
		}

		override protected function redraw():void {
			// Redraw elements

			var i:int, j:int;

//			var itemsToForce:int = 2;
//			// Duplicates beverages so the menu can be testes with 12 brands
//			if (flavorItems.length > itemsToForce) {
//				// Remove items
//				flavorItems.splice(itemsToForce, flavorItems.length - itemsToForce);
//			} else {
//				// Add items
//				i = 0;
//				while (flavorItems.length < itemsToForce) {
//					flavorItems.push(flavorItems[i]);
//					i++;
//				}
//			}

			// First, calculate the width needed by every column
			var columnWidths:Vector.<Number> = new Vector.<Number>();
			var columCroppingLeft:Vector.<Number> = new Vector.<Number>();
			var itemCols:Vector.<int> = new Vector.<int>();
			var c:int = 0;
			var itemsPrevCols:int;
			for (i = 0; i < flavorItems.length; i++) {
				if (columnWidths.length < c + 1) {
					// New col
					columnWidths.push(0);
					columCroppingLeft.push(Number.POSITIVE_INFINITY);
					itemsPrevCols = i;
				}

				// Store the column
				itemCols.push(c);

				// Store the value
				columnWidths[c] = Math.max(columnWidths[c], flavorItems[i].width);
				columCroppingLeft[c] = invisibleFruitsRedistributesButtons ? Math.min(columCroppingLeft[c], (flavorItems[i] as FlavorSelectorVerticalItem).getLeftCrop()) : 0;

				// Decide whether it needs to increase the column count
				if (i - itemsPrevCols + 1 >= Math.ceil((flavorItems.length - itemsPrevCols) / (columns - c))) {
					// Last item in this column
					c++;
				}
			}

			// Resize all columns

			// Calculate how much space is left
			var availableWidth:Number = width - marginFlavorLeft - marginFlavorRight;
			for (i = 0; i < columnWidths.length; i++) {
				columnWidths[i] -= columCroppingLeft[i];
				availableWidth -= columnWidths[i];
			}

			// Calculate the available margin between columns
			var columnGutter:Number = availableWidth / (columns - 1);

			// Special case for 2 items: use a maximum margin
			if (flavorItems.length <= 2) columnGutter = Math.min(columnGutter, marginFlavorLeft);

			// Finally, distribute everything
			var posX:Number = marginFlavorLeft;
			var posY:Number = 0;
			var lastCol:int = 0;
			for (i = 0; i < flavorItems.length; i++) {
				if (itemCols[i] != lastCol) {
					// Column break
					posX += columnWidths[lastCol] + columnGutter;
					posY = 0;
					lastCol++;
				}

				flavorItems[i].x = Math.round(posX - columCroppingLeft[lastCol]);
				flavorItems[i].y = Math.round(posY);

				posY += flavorItems[i].height;
			}
		}
	}
}
