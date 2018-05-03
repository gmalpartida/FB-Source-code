package com.firstborn.pepsi.display.gpu.home.menu.mesh {
	import com.zehfernando.utils.MathUtils;
	import com.zehfernando.utils.console.log;

	import flash.geom.Point;
	/**
	 * @author zeh fernando
	 */
	public class MeshInfoGrid extends MeshInfo {

		// Constants
		public static var MAX_NODES:int = 16; // Absolute maximum number of items to guarantee a good design
		public static var LINK_ROTATION_ANGLE:Number = 45 * MathUtils.DEG2RAD; // Normally should be 30 because it's half of 60, the right angle for a equilateral triangle
		public static var TIMES_TO_SMOOTH_DISTANCE:int = 30; // Times to re-adjust distance... since it's an approximation

		// Properties
		private var _cols:int;							// Cols on the node grid
		private var _rows:int;							// Rows on the node grid
		private var startCol:int;						// Position of the first node ("start")
		private var startRow:int;
		private var nodeParentIds:Vector.<int>;			// List a node's parent id: follows the grid id but contains the original list id
		private var nodeGroupIds:Vector.<String>;		// List a node's group id (a string): follows the grid id

		private var numNodesAssigned:int;				// Number of nodes with an id already assigned

		private var numDesiredCols:int;


		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function MeshInfoGrid(__numNodes:int, __parentIds:Vector.<int>, __groupIds:Vector.<String>, __customParameters:String, __numDesiredCols:int = 4) {
			numDesiredCols = __numDesiredCols;
			// Special case because of bridge: bridge was built for 12-16 items, 5 columns default, but then changed to suppport 8-12 items too.
			// So if the ADA had 8 items with 5 columns, it'd show a row of 5 columns, and a row of 3. So it tries to even it out
			var numRows:int = Math.ceil(__numNodes / numDesiredCols);
			var numNeededCols:int = Math.ceil(__numNodes / numRows)
			if (numNeededCols < numDesiredCols) numDesiredCols = numNeededCols;

			super(__numNodes, __parentIds, __groupIds, __customParameters);
		}


		// ================================================================================================================
		// EXTENDED INTERFACE ---------------------------------------------------------------------------------------------

		override protected function setDefaultValues():void {
			super.setDefaultValues();

			minimumNodeDistance = MathUtils.map(_numNodes, 8, 12, NODE_DISTANCE_MINIMUM, 0, true);
			numNodesAssigned = 0;
			paddingTop = 0;
			paddingBottom = MathUtils.map(_numNodes, 12, 16, 10, -15, true);
			paddingLeft = MathUtils.map(_numNodes, 8, 12, 0, -15, true);
			paddingRight = 0;
		}

		override protected function createNodes():void {
			createNodeList();
			assignStartId();
			assignSecondaryIds();
			reshuffleNodes();
			assignNodePositions();
		}

		override protected function createOrderedLists():void {
			var r:int, c:int;
			var i:int;

			// Grid: runs the row, then goes to the next row

			// Create a list of the nodeinfos ordered by the suggested order for hardware ADA
			orderedNodesByFocus = new Vector.<MeshNodeInfo>();

			i = 0;
			for (r = 0; r < _rows; r++) {
				for (c = 0; c < _cols; c++) {
					if (getNodeAt(c, r) != null) {
						orderedNodesByFocus[i] = getNodeAt(c, r);
						i++;
					}
				}
			}

			// Create a list of nodeinfos ordered for animation
			orderedNodesByAppearance = new Vector.<MeshNodeInfo>();

			i = 0;
			for (r = 0; r < _rows; r++) {
				for (c = 0; c < _cols; c++) {
					if (getNodeAt(c, r) != null) {
						orderedNodesByAppearance[i] = getNodeAt(c, r);
						i++;
					}
				}
			}
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private function createNodeList():void {
			// Calculate the number of grid cols (not cell cols) depending on the number of items
			// Grid-like distribution
			_cols = numDesiredCols;
			_rows = Math.ceil(_numNodes / _cols);

			// Now that we know the number of columns and rows, we can distribute the items

			// Create a grid of nodes
			// Each item will contain the index of the menuItem that goes there
			nodes = new Vector.<MeshNodeInfo>(_cols * _rows, true);
			nodeParentIds = new Vector.<int>(nodes.length, true);
			nodeGroupIds = new Vector.<String>(nodes.length, true);
		}

		private function assignStartId():void {
			// Marks one node as being the "start" node
			// Start from center, but aligned left/top
			startCol = Math.floor((_cols+1)/2) - 1;
			startRow = Math.floor((_rows+1)/2) - 1;

			// Assign it
			assignNode(startCol, startRow);
		}

		private function assignSecondaryIds():void {
			// Marks the nodes around the "start" node with their respective ids

			var i:int;
			var row:int, col:int;

			// Simply assign all ids in a grid manner

			// Assign all nodes by proximity to the center
			var closestDistance:Number;
			var distance:Number;
			var closestIndex:int;
			var distanceScaleX:Number = 0.9; // Bias so it assigns to the sides before assigning above and below
			var center:Point = new Point(startCol * distanceScaleX, startRow);
			//var center:Point = new Point(_cols / 2 * distanceScaleX, _rows / 2);

			while (numNodesAssigned < _numNodes) {
				// Search all positions to find the one that's closest to the center
				// This is a bit brute-force but it's more flexible

				closestIndex = -1;
				closestDistance = NaN;

				for (i = 0; i < nodes.length; i++) {
					if (nodes[i] == null) {
						// Can be used for new nodes, calculate distance

						col = i % _cols;
						row = Math.floor(i / _cols);
						distance = Point.distance(center, new Point(col * distanceScaleX, row));

						if (isNaN(closestDistance) || distance < closestDistance) {
							closestDistance = distance;
							closestIndex = i;
						}
					}
				}

				// Assign node
				col = closestIndex % _cols;
				row = Math.floor(closestIndex / _cols);
				assignNode(col, row);
			}
		}

		private function reshuffleNodes():void {
			// Tries to shuffle nodes around, to maintain the relationships between nodes as accurately as possible

			var i:int, j:int;
			var row:int, col:int;

			// Now, shuffle nodes around by finding better positions
			var allNodes:Vector.<MeshNodeInfo> = nodes.concat();
			var isNextToParentItem:Boolean;
			var groupSiblingsItem:int;
			var distanceFromCenterItem:Number;
			var isNextToParentItemNew:Boolean;
			var groupSiblingsItemNew:int;
			var distanceFromCenterItemNew:Number;
			var selectedPos:int;
			var selectedScore:Number;
			var currentScore:Number;

			var isNextToParentUnderItem:Boolean;
			var groupSiblingsUnderItem:int;
			var isNextToParentUnderItemNew:Boolean;
			var groupSiblingsUnderItemNew:int;

			var oldPos:int;
			var oldCol:int;
			var oldRow:int;
			var timesToShuffle:int = 10;
			var minScore:Number = 0;

			var centerNodePosition:Point = getNodePosition(startCol, startRow);

			while (timesToShuffle > 0) {

				for (i = 0; i < allNodes.length; i++) {
					if (allNodes[i] != null && allNodes[i].id != 0) {
						// Find a better position for this node
						oldPos = nodes.indexOf(allNodes[i]);
						oldCol = oldPos % _cols;
						oldRow = Math.floor(oldPos / _cols);
						isNextToParentItem = isNodeNextToParent(oldCol, oldRow, allNodes[oldPos]);
						groupSiblingsItem = getNodeGroupSiblings(oldCol, oldRow, allNodes[oldPos]);
						distanceFromCenterItem = Point.distance(getNodePosition(oldCol, oldRow), centerNodePosition);
						selectedPos = -1;
						selectedScore = 0;

						for (j = 0; j < nodes.length; j++) {

							if (nodes[j] != null && nodes[j].id != 0 && nodes[j] != allNodes[i]) {
								col = j % _cols;
								row = Math.floor(j / _cols);
								isNextToParentItemNew = isNodeNextToParent(col, row, allNodes[i]);
								groupSiblingsItemNew = getNodeGroupSiblings(col, row, allNodes[i]);
								distanceFromCenterItemNew = Point.distance(getNodePosition(col, row), centerNodePosition);

								if (isNextToParentItemNew && !isNextToParentItem || (groupSiblingsItemNew > groupSiblingsItem && isNextToParentItemNew == isNextToParentItem) || distanceFromCenterItem != distanceFromCenterItemNew) {
									// This new one is a better position
									// Calculate a score
									currentScore = 0;
									// Next to parent (new): 5 points
									if (isNextToParentItemNew && !isNextToParentItem) currentScore += 5;
									// Moving close to/away from siblings: +-1 point per sibling
									currentScore += groupSiblingsItemNew - groupSiblingsItem;

									// Also check the negative score by moving the item under it
									isNextToParentUnderItem = isNodeNextToParent(col, row, nodes[j]);
									groupSiblingsUnderItem = getNodeGroupSiblings(col, row, nodes[j]);
									isNextToParentUnderItemNew = isNodeNextToParent(oldCol, oldRow, nodes[j]);
									groupSiblingsUnderItemNew = getNodeGroupSiblings(oldCol, oldRow, nodes[j]);

									// Away from parent: -5 points
									if (isNextToParentUnderItem && !isNextToParentUnderItemNew) currentScore -= 5;
									// Next to parent: +5 points
									if (!isNextToParentUnderItem && isNextToParentUnderItemNew) currentScore += 5;
									// Moving close to/away from siblings: +-1 point per sibling
									currentScore += groupSiblingsUnderItemNew - groupSiblingsUnderItem;

									// If closer to center and a lower id, +1 point
									if (distanceFromCenterItemNew < distanceFromCenterItem) {
										// New position is closer to center
										if (allNodes[i].id < nodes[j].id) currentScore += 1;
										if (allNodes[i].id > nodes[j].id) currentScore -= 1;
									} else if (distanceFromCenterItemNew > distanceFromCenterItem) {
										// New position is further away from center
										if (allNodes[i].id > nodes[j].id) currentScore += 1;
										if (allNodes[i].id < nodes[j].id) currentScore -= 1;
									}

									if (currentScore > selectedScore && currentScore > minScore) {
										// Best so far!
										selectedScore = currentScore;
										selectedPos = j;

//										log("Found a best pos: item at " + oldPos + " should switch with " + j + ", score = " + currentScore);
//										log("    siblings original => new = [" + col + "," + row + "] " + groupSiblingsItemNew + " prev = [" + oldCol + "," + oldRow + "] " + groupSiblingsItem);
//										log("    siblings under => new = [" + oldCol + "," + oldRow + "] " + groupSiblingsUnderItemNew + " prev = [" + col + "," + row + "] " + groupSiblingsUnderItem);
									}
								} else {
									// Not a better position
								}
							}
						}

						if (selectedPos > -1) {
							//log("=====> Best position: item at " + oldPos + " should swap with item at " + selectedPos + ", score is " + selectedScore);
							swapNodes(oldPos, selectedPos);
						}
					}
				}

				minScore += 0.2;
				timesToShuffle--;
			}
		}

		private function getNodePosition(__col:int, __row:int):Point {
			var distance:Number = NODE_RADIUS_STANDARD * 2 + minimumNodeDistance;
			var rowHeightHexagon:Number = Math.sqrt(Math.pow(distance, 2) - Math.pow(distance * 0.5, 2));

			var p:Point = new Point();

			if (isHexagon()) {
				p.x = __col * distance - (isRowOffsetToTheLeft(__row) ? distance * 0.5 : 0);
				p.y = __row * rowHeightHexagon;
			} else {
				p.x = __col * distance;
				p.y = __row * distance;
			}

			return p;
		}

		private function assignNodePositions():void {
			// Set the position of every node in the form of a square grid

			var i:int;
			var row:int, col:int;
			var p:Point;

			// Grid distribution, optionally in hexagon formation

			for (i = 0; i < nodes.length; i++) {
				if (nodes[i] != null) {
					col = i % _cols;
					row = Math.floor(i / _cols);

					p = getNodePosition(col, row);

					nodes[i].position.setTo(p.x, p.y);
				}
			}
		}

		private function isHexagon():Boolean {
			// Whether it uses a hexagon grid-like distribution (if false, uses a square grid)
			return _rows > 2;
		}

		private function isRowOffsetToTheLeft(__row:int):Boolean {
			// Returns true if the given row is offset to the left (in the case of an hexagon grid)
			return __row % 2 == 1;
		}

		private function isNodeNextToParent(__col:int, __row:int, __childNode:MeshNodeInfo):Boolean {
			// Check if a node in this position would be next to a parent
			if (isNodeParent(__col-1, __row-1, __childNode) && (!isHexagon() || isRowOffsetToTheLeft(__row))) return true;
			if (isNodeParent(__col+0, __row-1, __childNode)) return true;
			if (isNodeParent(__col+1, __row-1, __childNode) && (!isHexagon() || !isRowOffsetToTheLeft(__row))) return true;
			if (isNodeParent(__col-1, __row+0, __childNode)) return true;
			if (isNodeParent(__col+1, __row+0, __childNode)) return true;
			if (isNodeParent(__col-1, __row+1, __childNode) && (!isHexagon() || isRowOffsetToTheLeft(__row))) return true;
			if (isNodeParent(__col+0, __row+1, __childNode)) return true;
			if (isNodeParent(__col+1, __row+1, __childNode) && (!isHexagon() || !isRowOffsetToTheLeft(__row))) return true;
			return false;
		}

		private function getNodeGroupSiblings(__col:int, __row:int, __childNode:MeshNodeInfo):int {
			var numGroupSiblings:int = 0;
			numGroupSiblings += isNodeGroupSibling(__col-1, __row-1, __childNode) && (!isHexagon() || isRowOffsetToTheLeft(__row)) ? 1 : 0;
			numGroupSiblings += isNodeGroupSibling(__col+0, __row-1, __childNode) ? 1 : 0;
			numGroupSiblings += isNodeGroupSibling(__col+1, __row-1, __childNode) && (!isHexagon() || !isRowOffsetToTheLeft(__row)) ? 1 : 0;
			numGroupSiblings += isNodeGroupSibling(__col-1, __row+0, __childNode) ? 1 : 0;
			numGroupSiblings += isNodeGroupSibling(__col+1, __row+0, __childNode) ? 1 : 0;
			numGroupSiblings += isNodeGroupSibling(__col-1, __row+1, __childNode) && (!isHexagon() || isRowOffsetToTheLeft(__row)) ? 1 : 0;
			numGroupSiblings += isNodeGroupSibling(__col+0, __row+1, __childNode) ? 1 : 0;
			numGroupSiblings += isNodeGroupSibling(__col+1, __row+1, __childNode) && (!isHexagon() || !isRowOffsetToTheLeft(__row)) ? 1 : 0;
			return numGroupSiblings;
		}

		// Aux functions
		private function isNodeParent(__col:int, __row:int, __childNode:MeshNodeInfo):Boolean {
			var node:MeshNodeInfo = getNodeAt(__col, __row);
			var parentId:int = nodeParentIds[nodes.indexOf(__childNode)];
			//if (parentId > -1) log("Comparing node at " + nodes.indexOf(__childNode) + " with parent id " + parentId + " to node at " + __col + ", " + __row + "  ==== " + (node != null && parentId >= -1 && parentId == node.id));
			return node != null && parentId >= -1 && parentId == node.id;
		}

		private function isNodeGroupSibling(__col:int, __row:int, __node:MeshNodeInfo):Boolean {
			var node:MeshNodeInfo = getNodeAt(__col, __row);
			var groupId:String = nodeGroupIds[nodes.indexOf(__node)];
			return node != null && node != __node && groupId != null && groupId.length > 0 && groupId == nodeGroupIds[getNodeGridIndex(__col, __row)];
		}

		private function getNodeGridIndex(__col:int, __row:int):int {
			if (__row < 0 || __col < 0 || __row >= _rows || __col >= _cols) return -1;
			return __row * _cols + __col;
		}

		private function assignNode(__col:int, __row:int):void {
			// Create a new node and assign it to a position in the grid list
			var p:int = __row * _cols + __col;
			nodes[p] = new MeshNodeInfo(numNodesAssigned);
			nodeParentIds[p] = parentIds[numNodesAssigned];
			nodeGroupIds[p] = groupIds[numNodesAssigned];
			numNodesAssigned++;

			//log("Node " + p + " at " + __col + ", " + __row + " has parent id = " + nodeParentIds[p]);
		}

		private function swapNodes(__pos1:int, __pos2:int):void {
			// Swap the position of two nodes in the grid
			var node:MeshNodeInfo = nodes[__pos1];
			var parentId:int = nodeParentIds[__pos1];
			var groupId:String = nodeGroupIds[__pos1];

			nodes[__pos1] = nodes[__pos2];
			nodeParentIds[__pos1] = nodeParentIds[__pos2];
			nodeGroupIds[__pos1] = nodeGroupIds[__pos2];

			nodes[__pos2] = node;
			nodeParentIds[__pos2] = parentId;
			nodeGroupIds[__pos2] = groupId;
		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		public function getNodeAt(__col:int, __row:int):MeshNodeInfo {
			if (__row < 0 || __col < 0 || __row >= _rows || __col >= _cols) return null;
			return nodes[__row * _cols + __col];
		}
	}
}
