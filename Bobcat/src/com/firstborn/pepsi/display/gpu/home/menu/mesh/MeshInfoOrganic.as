package com.firstborn.pepsi.display.gpu.home.menu.mesh {
	import com.zehfernando.geom.Line;
	import com.zehfernando.utils.MathUtils;

	import flash.geom.Point;
	/**
	 * @author zeh fernando
	 */
	public class MeshInfoOrganic extends MeshInfo {

		/**
		 *
		 * This systems builds a bidimensional, square grid then distributes the nodes in that grid.
		 * The grid has a varying number of cols and rows, depending on the number of needed items.
		 * On each square, the top-right corner has a "connection" with the bottom left node. This makes it work as a triangular/hexagonal mesh.
		 * It is built as a square grid for easier distribution though, and then skewed.
		 * The distribution starts from the center, going to the corners in a diagonal (top left to bottom right)
		 * After distributing, every item is scaled depending on their proximity to the center of the mesh.
		 *
		 * E.g., with 2 cols and 2 rows:
		 *
		 *  O
		 *  | \
		 *  |   \
		 *  |     O
		 *  |   / |
		 *  | /   |
		 *  O     |
		 *    \   |
		 *      \ |
		 *        O
		 *
		 * Or 3 cols and 2 rows:
		 *
		 *  O
		 *  | \
		 *  |   \
		 *  |     O
		 *  |   / | \
		 *  | /   |   \
		 *  O     |     O
		 *    \   |   / |
		 *      \ | /   |
		 *        O     |
		 *          \   |
		 *            \ |
		 *              O
		 *
		 * The original system had a proper hexagon/triangle-based distribution, but it didn't conform to what the
		 * designs actually needed. The square grid-based one follows the proposed designs more easily.
		 */

		// Constants
		private static const MAX_NODES:int = 16; // Absolute maximum number of items to guarantee a good design
		private static const LINK_ROTATION_ANGLE:Number = 45 * MathUtils.DEG2RAD; // Normally should be 30 because it's half of 60, the right angle for a equilateral triangle
		private static const TIMES_TO_SMOOTH_DISTANCE:int = 30; // Times to re-adjust distance... since it's an approximation

		// Properties
		private var _cols:int;						// Cols on the node grid
		private var _rows:int;						// Rows on the node grid
		private var startCol:int;					// Position of the first node ("start")
		private var startRow:int;
		private var nodeParentIds:Vector.<int>;			// List a node's parent id: follows the grid id but contains the original list id
		private var nodeGroupIds:Vector.<String>;		// List a node's group id (a string): follows the grid id

		private var numNodesAssigned:int;				// Number of nodes with an id already assigned

		private var leftmostColUsed:int;			// Boundaries with nodes that have ids actually assigned to them
		private var rightmostColUsed:int;
		private var topmostRowUsed:int;
		private var bottommostRowUsed:int;
		private var importanceOrderedNodes:Vector.<MeshNodeInfo>;

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function MeshInfoOrganic(__numNodes:int, __parentIds:Vector.<int>, __groupIds:Vector.<String>, __customParameters:String) {
			super(__numNodes, __parentIds, __groupIds, __customParameters);
		}


		// ================================================================================================================
		// EXTENDED INTERFACE ---------------------------------------------------------------------------------------------

		override protected function setDefaultValues():void {
			super.setDefaultValues();

            var test : Number = 16; //12 before
            var test2 : Number = -2; //-20 before
			numNodesAssigned = 0;
			leftmostColUsed = -1;
			rightmostColUsed = -1;
			topmostRowUsed = -1;
			bottommostRowUsed = -1;
			paddingTop = 0;
			paddingBottom = MathUtils.map(_numNodes, 8, test, 0, test2, true);
			paddingLeft = MathUtils.map(_numNodes, 8, test, 0, test2, true);
			paddingRight = MathUtils.map(_numNodes, 8, test, 0, test2, true);

			importanceOrderedNodes = new Vector.<MeshNodeInfo>();
		}

		override protected function createNodes():void {
			createNodeList();
			if (numNodes > 0) {
				assignStartId();
				assignSecondaryIds();
				assignAdvancedIds();
				assignNodeScales();
				assignNodePositions();
				reshuffleNodes();
				smoothNodePositions();
			}
		}

		override protected function createOrderedLists():void {
			var r:int, c:int;
			var i:int;

			// Organic: visual organization diagonally

			// Create a list of the nodeinfos ordered by the suggested order for hardware ADA
			orderedNodesByFocus = new Vector.<MeshNodeInfo>();

			i = 0;
			for (r = 0; r < _rows + _cols - 1; r++) {
				// Normal (left-top diagonal)
				// for (col = Math.max(0, row - mesh.rows + 1); col < mesh.cols && row - col >= 0; col++) {
				// Flipped (left-top diagonal with flipped column order)
				for (c = Math.min(_cols - 1, r); c >= 0 && c > r - _rows; c--) {
					orderedNodesByFocus[i] = getNodeAt(c, r - c);
					i++;
				}
			}

			// Create a list of nodeinfos ordered for animation
			orderedNodesByAppearance = new Vector.<MeshNodeInfo>();

			i = 0;
			for (r = 0; r < _rows + _cols - 1; r++) {
				for (c = Math.min(_cols - 1, r); c >= 0 && c > r - _rows; c--) {
					orderedNodesByAppearance[i] = getNodeAt(c, r - c);
					i++;
				}
			}
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private function createNodeList():void {
			// Calculate the number of grid cols (not cell cols) depending on the number of items
			// This comes from a testing spreadsheet, while creating a curve that fits into every condition
			// (Just a quadratic distribution along the line, with some offseting, rounding and scaling)
			// 1 item:1 col, 2:2, 3:2, 4:2, 5:3, 6:3, ... 12:3, 13:4, 14:4, ...
			_cols = Math.floor((1-((1-(Math.min(MAX_NODES, _numNodes+3)/MAX_NODES))*(1-(Math.min(MAX_NODES, _numNodes+3)/MAX_NODES))))*4);

			// Same for rows
			// 1 item:1 row, 2:1, 3:2, 4:2, 5:3, ... 9:3, 10:4, ...
			_rows = Math.round((1-((1-(Math.min(MAX_NODES, _numNodes+1)/MAX_NODES))*(1-(Math.min(MAX_NODES, _numNodes+1)/MAX_NODES))))*4);

			// 5 is a special case; should be 2 rows, but we use 3 to better distribute items around a center node
			if (_numNodes == 5) _rows = 3;

			// Another special case, when the menu is empty
			if (_numNodes == 0) _cols = _rows = 0;

			// Now that we know the number of columns and rows, we can distribute the items

			// Create a grid of nodes
			// Each item will contain the index of the menuItem that goes there
			nodes = new Vector.<MeshNodeInfo>(_cols * _rows, true);
			nodeParentIds = new Vector.<int>(nodes.length, true);
			nodeGroupIds = new Vector.<String>(nodes.length, true);
		}

		private function assignStartId():void {
			// Marks one node as being the "start" node
			// Start from slightly off center
			startCol = Math.floor((_cols-1)*0.5);
			startRow = Math.floor((_rows+1)*0.35);

			// Assign it
			assignNode(startCol, startRow);
		}

		private function assignSecondaryIds():void {
			// Marks the nodes around the "start" node with their respective ids

			var i:int;
			var row:int, col:int;

			// Find how many links go next to the starting point.. a bit hardcoded
			// 1 item:0 links, 2:1, 3:2, 4:3, 5:4, 6:4, 7:4, 8:5, 9:6, 10:6, 11:6, ...
			var startingLinks:int = _numNodes < 6 ? _numNodes - 1 : (_numNodes > 8 ? 6 : Math.ceil((_numNodes+1)*0.5));

			// Assign the starting links around the starting point... very manual

			if (startingLinks >= 1) {
				// Right link: if links > 0 ===> col+1
				assignNode(startCol + 1, startRow);
			}
			if (startingLinks == 2 || startingLinks == 3 || startingLinks == 6) {
				// Upper right link: if links == 2 or 3 or 6 ===> col+1, row-1
				assignNode(startCol + 1, startRow - 1);
			}
			if (startingLinks >= 3) {
				// Upper link: if links >= 3 ===> row-1
				assignNode(startCol, startRow - 1);
			}
			if (startingLinks >= 4) {
				// Left link: if links >= 4 ===> col-1
				assignNode(startCol - 1, startRow);
			}
			if (startingLinks >= 5) {
				// Lower left link: if links >= 5 ===> col-1, row+1
				assignNode(startCol - 1, startRow + 1);
			}
			if (startingLinks >= 4) {
				// Lower link: if links >= 4 ===> row+1
				assignNode(startCol, startRow + 1);
			}

			//log("Using " + _numNodes + " items; grid dimensions = " + rows + " rows, " + cols + " cols; starting links: " + startingLinks + "; nodes missing assignment: " + (_numNodes-numNodesAssigned));

			if (numNodesAssigned < _numNodes) {
				// Still has items missing assignment (> 5, although up to 7 may have been assigned so far)

				for (i = 0; i < nodes.length; i++) {
					col = i % _cols;
					row = Math.floor(i / _cols);
					if (nodes[i] != null) {
						// This item is used
						if (col < leftmostColUsed)	leftmostColUsed = col;
						if (col > rightmostColUsed)	rightmostColUsed = col;
						if (row < topmostRowUsed)	topmostRowUsed = row;
						if (row > bottommostRowUsed)	bottommostRowUsed = row;
					}
				}

				// Assign to corners if possible

				// Bottom right
				if (nodes[rightmostColUsed + bottommostRowUsed * _cols] == null) {
					assignNode(bottommostRowUsed, rightmostColUsed);
				}

				// Top left
				if (numNodesAssigned < _numNodes && nodes[leftmostColUsed + topmostRowUsed * _cols] == null) {
					assignNode(leftmostColUsed, topmostRowUsed);
				}
			}
		}

		private function assignAdvancedIds():void {
			// Marks all the remaining nodes with ids where possible

			if (numNodesAssigned < _numNodes) {
				// Still has items missing assignment (> 9)

				var rowToBeUsed:int;
				var colToBeUsed:int;

				// Try to put them under everything, starting from the center
				rowToBeUsed = bottommostRowUsed + 1;

				var colShift:int;

				while (numNodesAssigned < _numNodes && rowToBeUsed < _rows) {
					colShift = 0;

					while (numNodesAssigned < _numNodes && colShift < colsUsed) {
						// Start moving to the right, then alternate with the left
						if (colShift % 2 == 1) {
							colToBeUsed = startCol + (colShift + 1) / 2;
						} else {
							colToBeUsed = startCol - colShift / 2;
						}

						if (colToBeUsed >= leftmostColUsed && colToBeUsed <= rightmostColUsed) {
							if (nodes[colToBeUsed + rowToBeUsed * _cols] == null) {
								assignNode(colToBeUsed, rowToBeUsed);
							}
						}

						colShift++;
					}

					rowToBeUsed++;
				}

				if (numNodesAssigned < _numNodes) {
					// Still has items missing assignment (> 12)

					// Try to put them to the left of everything, on the right side
					colToBeUsed = rightmostColUsed + 1;

					var rowShift:int;

					while (numNodesAssigned < _numNodes && colToBeUsed < _cols) {
						rowShift = 0;

						while (numNodesAssigned < _numNodes && rowShift < rowsUsed) {
							// Start moving down, then alternate with up
							if (rowShift % 2 == 1) {
								rowToBeUsed = startRow + (rowShift + 1) / 2;
							} else {
								rowToBeUsed = startRow - rowShift / 2;
							}

							if (rowToBeUsed >= topmostRowUsed && rowToBeUsed <= bottommostRowUsed) {
								if (nodes[colToBeUsed + rowToBeUsed * _cols] == null) {
									assignNode(colToBeUsed, rowToBeUsed);
								}
							}

							rowShift++;
						}

						colToBeUsed++;
					}
				}
			}

			//log("  Nodes still missing assignment: " + (_numNodes-numNodesAssigned));
		}

		private function assignNodeScales():void {
			// Set the scale of every node, based on its position in the grid

			// Assumes the center ("start") node is maximum scale, and the rest follows
			var colScale:Number; // Scale because of x position (0-1)
			var rowScale:Number; // Scale because of y position (0-1)

			var i:int;
			var row:int, col:int;

			for (i = 0; i < nodes.length; i++) {
				if (nodes[i] != null) {
					col = i % _cols;
					row = Math.floor(i / _cols);

					colScale = MathUtils.map(col, startCol, col > startCol ? _cols-1 : 0, 1, 0);
					rowScale = MathUtils.map(row, startRow, row > startRow ? _rows-1 : 0, 1, 0);
					nodes[i].scale = 1 + (rowScale * colScale) / 5 + (rowScale + colScale) / 5;
					//nodes[i].scale = 1;
				}
			}
		}

		private function assignNodePositions():void {
			// Set the position of every node in the form of a square grid

			var px:Number, py:Number;

			var i:int;
			var row:int, col:int;

			// Twisted grid

			// First, distributes to the grid equally
			for (i = 0; i < nodes.length; i++) {
				if (nodes[i] != null) {
					col = i % _cols;
					row = Math.floor(i / _cols);

					// Initial points (on a grid)
					px = col * (NODE_RADIUS_STANDARD * 2 + minimumNodeDistance);
					py = row * (NODE_RADIUS_STANDARD * 2 + minimumNodeDistance);

					// Standard grid
					//itemPositionGrid[i] = new Point(px, py);

					// Rotated by the angle
					nodes[i].position = Point.polar(col * (NODE_RADIUS_STANDARD * 2 + minimumNodeDistance), LINK_ROTATION_ANGLE);
					nodes[i].position.y += py;
				}
			}

			// Flips the position of all nodes.. ugh
			// It'd be better for this to not be needed (use a configurable angle for the menu orientation),
			// but the menu design angle was changed later in development when the mesh algorithm was already completed

			for (i = 0; i < nodes.length; i++) {
				if (nodes[i] != null) nodes[i].position.x *= -1;
			}

		}

		private function reshuffleNodes():void {
			// Tries to shuffle nodes around, getting them closer to groups or parents

			// Creates a list of proximities
			var i:int, j:int;

//			for (i = 0; i < nodes.length; i++) {
//				if (nodes[i] != null) {
//					log(i + " : id " + nodes[i].id + " => next = " + isPositionNextToNodeParent(i, nodes[i]) + ", siblings = " + getPositionNodeGroupSiblings(i, nodes[i]));
//				} else {
//					log(i + " : id null => next = " + false + ", siblings = N/A");
//				}
//			}

			// Now, shuffle nodes around by finding better positions
			var allNodes:Vector.<MeshNodeInfo> = nodes.concat();
			var isNextToParentItem:Boolean;
			var groupSiblingsItem:int;
			var distanceToCenterItem:Number;
			var isNextToParentItemNew:Boolean;
			var groupSiblingsItemNew:int;
			var distanceToCenterItemNew:Number;
			var selectedPos:int;
			var selectedScore:Number;
			var currentScore:Number;

			var isNextToParentUnderItem:Boolean;
			var groupSiblingsUnderItem:int;
			var isNextToParentUnderItemNew:Boolean;
			var groupSiblingsUnderItemNew:int;

			var oldPos:int;
			var timesToShuffle:int = 10;
			var minScore:Number = 0;

			while (timesToShuffle > 0) {

				for (i = 0; i < allNodes.length; i++) {
					if (allNodes[i] != null && allNodes[i].id != 0) {
						// Find a better position for this node
						oldPos = nodes.indexOf(allNodes[i]);
						isNextToParentItem = isPositionNextToNodeParent(oldPos, allNodes[i]);
						groupSiblingsItem = getPositionNodeGroupSiblings(oldPos, allNodes[i]);
						distanceToCenterItem = getPositionDistanceToCenter(oldPos);
						selectedPos = -1;
						selectedScore = 0;

//						log("Testing node " + i + " (id = " + allNodes[i].id + ") at " + oldPos + " (siblings = " + groupSiblingsItem + ")");

						for (j = 0; j < nodes.length; j++) {

							if (nodes[j] != null && nodes[j].id != 0 && nodes[j] != allNodes[i]) {
								isNextToParentItemNew = isPositionNextToNodeParent(j, allNodes[i]);
								groupSiblingsItemNew = getPositionNodeGroupSiblings(j, allNodes[i]);
								distanceToCenterItemNew = getPositionDistanceToCenter(j);

//								log("  Testing against node at " + j + " (siblings = " + groupSiblingsItemNew + "), distances = " + distanceToCenterItem + " => " + distanceToCenterItemNew);

								if ((isNextToParentItemNew && !isNextToParentItem) || (groupSiblingsItemNew > groupSiblingsItem && isNextToParentItemNew == isNextToParentItem) || nodeGroupIds[oldPos] == nodeGroupIds[j]) {
								//if (isNextToParentItemNew && !isNextToParentItem || (groupSiblingsItemNew > groupSiblingsItem && isNextToParentItemNew == isNextToParentItem)) {
									// This new one is a better position
									// Calculate a score
									currentScore = 0;
									// Next to parent (new): 5 points
									if (isNextToParentItemNew && !isNextToParentItem) currentScore += 5;
									// Moving close to/away from siblings: +-1 point per sibling
									currentScore += groupSiblingsItemNew - groupSiblingsItem;

									// Also check the negative score by moving the item under it
									isNextToParentUnderItem = isPositionNextToNodeParent(j, nodes[j]);
									groupSiblingsUnderItem = getPositionNodeGroupSiblings(j, nodes[j]);
									isNextToParentUnderItemNew = isPositionNextToNodeParent(oldPos, nodes[j]);
									groupSiblingsUnderItemNew = getPositionNodeGroupSiblings(oldPos, nodes[j]);

									// Away from parent: -5 points
									if (isNextToParentUnderItem && !isNextToParentUnderItemNew) currentScore -= 5;
									// Next to parent: +5 points
									if (!isNextToParentUnderItem && isNextToParentUnderItemNew) currentScore += 5;
									// Moving close to/away from siblings: +-1 point per sibling
									currentScore += groupSiblingsUnderItemNew - groupSiblingsUnderItem;

									// Lower id closer to center: +1 point if the lower id is closer
									if (distanceToCenterItem > distanceToCenterItemNew) {
										if (allNodes[i].id < nodes[j].id) currentScore += 1;
										if (allNodes[i].id > nodes[j].id) currentScore -= 1;
									} else if (distanceToCenterItem < distanceToCenterItemNew) {
										if (allNodes[i].id > nodes[j].id) currentScore += 1;
										if (allNodes[i].id < nodes[j].id) currentScore -= 1;
									}

									if (currentScore > selectedScore && currentScore > minScore) {
										// Best so far!
										selectedScore = currentScore;
										selectedPos = j;

//										log("  Found a best pos: item at " + oldPos + " should switch with " + j + ", score = " + currentScore);
//										log("    siblings original => new = [" + j + "] " + groupSiblingsItemNew + " prev = [" + oldPos + "] " + groupSiblingsItem);
//										log("    siblings under => new = [" + oldPos + "] " + groupSiblingsUnderItemNew + " prev = [" + j + "] " + groupSiblingsUnderItem);
									}
								} else {
									// Not a better position
								}
							}
						}

						if (selectedPos > -1) {
//							log("=====> Best position: item at " + oldPos + " should swap with item at " + selectedPos + ", score is " + selectedScore);
							swapNodes(oldPos, selectedPos);
						}
					}
				}

				minScore += 0.5;
				timesToShuffle--;
			}

//			for (i = 0; i < nodes.length; i++) {
//				if (nodes[i] != null) {
//					log(i + " : id " + nodes[i].id + " => next = " + isPositionNextToNodeParent(i, nodes[i]) + ", siblings = " + getPositionNodeGroupSiblings(i, nodes[i]));
//				} else {
//					log(i + " : id null => next = " + false + ", siblings = N/A");
//				}
//			}

		}

		private function smoothNodePositions():void {
			// Try to move nodes around evely based on scale of neighbors, so the minimum node distance is maintained, starting from the center point

			var distance:int;
			var i:int, j:int, k:int;
			var nodeRadius:int;
			var topRow:int;
			var bottomRow:int;
			var leftCol:int;
			var rightCol:int;

			// First adjustment, to create minimum distance
			// Does it from the center, irradiating vertically and horizontally
			//log("-- " + colsUsed, rowsUsed);
			for (i = 0; i < TIMES_TO_SMOOTH_DISTANCE; i++) {
				for (nodeRadius = 0; nodeRadius < colsUsed || nodeRadius < rowsUsed; nodeRadius++) {
					if (nodeRadius == 0) {
						// Center
						adjustNodeByDistance(startCol, startRow);
					} else {
						// Everything around the center
						topRow = startRow - nodeRadius;
						bottomRow = startRow + nodeRadius;
						leftCol = startCol - nodeRadius;
						rightCol = startCol + nodeRadius;

						for (distance = 0; distance < nodeRadius; distance++) {

							// Top, L & R
							adjustNodeByDistance(startCol - distance, topRow);
							if (distance > 0) adjustNodeByDistance(startCol + distance, topRow);

							// Bottom, L & R
							adjustNodeByDistance(startCol - distance, bottomRow);
							if (distance > 0) adjustNodeByDistance(startCol + distance, bottomRow);

							// Left, up & down
							if (startRow - distance != topRow) {
								adjustNodeByDistance(leftCol, startRow - distance);
								if (distance > 0) adjustNodeByDistance(leftCol, startRow + distance);

								// Right, up & down
								adjustNodeByDistance(rightCol, startRow - distance);
								if (distance > 0) adjustNodeByDistance(rightCol, startRow + distance);
							}
						}
					}
				}
			}

			// Does approximation based on each brand's groups
			var timesToSmoothGroups:int = MathUtils.map(_numNodes, 8, 12, 0, TIMES_TO_SMOOTH_DISTANCE, true);

			for (i = 0; i < timesToSmoothGroups; i++) {
				// Moves some items closer to the center
				for (j = 1; j < importanceOrderedNodes.length; j++) {
					if (j % 2 == 1) {
						adjustNodesDistance(importanceOrderedNodes[0], importanceOrderedNodes[j], 0.05, 0, 0);
					} else {
						adjustNodesDistance(importanceOrderedNodes[0], importanceOrderedNodes[j], 0.01, 0, 0);
					}
				}

				// Approximate items based on group
//				for (j = 0; j < importanceOrderedNodes.length; j++) {
//					if (groupIds[importanceOrderedNodes[j].id].length > 0) {
//						// A node with a valid group id; search for all other nodes in the same group
//						for (k = j + 1; k < importanceOrderedNodes.length; k++) {
//							if (groupIds[importanceOrderedNodes[j].id] == groupIds[importanceOrderedNodes[k].id]) {
//								// Same group
//								adjustNodesDistance(importanceOrderedNodes[j], importanceOrderedNodes[k], 0.1, 0, 0.5, NODE_RADIUS_STANDARD * 2);
//							}
//						}
//					}
//				}

				// Always make sure all items are at least the a minimum distance from each other
				for (j = 0; j < importanceOrderedNodes.length; j++) {
					for (k = j + 1; k < importanceOrderedNodes.length; k++) {
						if (importanceOrderedNodes[k] != null) {
							adjustNodesDistance(importanceOrderedNodes[j], importanceOrderedNodes[k], 0, 0.5);
						}
					}
				}
			}

		}

		// Aux functions
		private function isPositionNextToNodeParent(__pos:int, __childNode:MeshNodeInfo):Boolean {
			// Check if a node in this position us close to a parent
			var nodeIndex:int = nodes.indexOf(__childNode);
			var parentId:int = nodeParentIds[nodeIndex];
			for (var i:int = 0; i < nodes.length; i++) {
				if (nodes[i] != null && nodes[i] != __childNode && parentId != -1 && nodes[i].id == parentId) {
					// This is the parent, return true if it's considered "close"
					return Point.distance(nodes[i].position, __childNode.position) < nodes[i].scale * NODE_RADIUS_STANDARD + nodes[__pos].scale * NODE_RADIUS_STANDARD + minimumNodeDistance * 2;
				}
			}
			// No parent
			return false;
		}

		private function getPositionNodeGroupSiblings(__pos:int, __node:MeshNodeInfo):int {
			// Find the number of siblings near a node
			var numGroupSiblings:int = 0;
			var nodeIndex:int = nodes.indexOf(__node);
			var groupId:String = nodeGroupIds[nodeIndex];

			for (var i:int = 0; i < nodes.length; i++) {
				//if (nodes[i] != null && nodes[i] != __node && groupId != null && groupId.length > 0 && nodeGroupIds[i] == groupId) {
				if (i != __pos && nodes[i] != null && nodes[i] != __node && groupId != null && groupId.length > 0 && nodeGroupIds[i] == groupId) {
					// This is a sibling, check distance
					if (Point.distance(nodes[i].position, nodes[__pos].position) < nodes[i].scale * NODE_RADIUS_STANDARD + nodes[__pos].scale * NODE_RADIUS_STANDARD + minimumNodeDistance * 2) {
						numGroupSiblings++;
					}
				}
			}

			return numGroupSiblings;
		}

		private function getPositionDistanceToCenter(__pos:int):int {
			if (nodes[__pos] != null) {
				return Point.distance(nodes[__pos].position, getNodeById(0).position);
			}
			return -1;
		}

		private function swapNodes(__pos1:int, __pos2:int):void {
			// Swap the position of two nodes in the grid
			var node:MeshNodeInfo = nodes[__pos1];
			var parentId:int = nodeParentIds[__pos1];
			var groupId:String = nodeGroupIds[__pos1];
			var nodeScale:Number = nodes[__pos2].scale;
			var nodePosition:Point = nodes[__pos2].position.clone();

			nodes[__pos1] = nodes[__pos2];
			nodes[__pos1].scale = node.scale;
			nodes[__pos1].position.copyFrom(node.position);
			nodeParentIds[__pos1] = nodeParentIds[__pos2];
			nodeGroupIds[__pos1] = nodeGroupIds[__pos2];

			nodes[__pos2] = node;
			nodes[__pos2].scale = nodeScale;
			nodes[__pos2].position.copyFrom(nodePosition);
			nodeParentIds[__pos2] = parentId;
			nodeGroupIds[__pos2] = groupId;
		}

		private function assignNode(__col:int, __row:int):void {
			// Create a new node and assign it to the position __pos
			var p:int = __row * _cols + __col;
			nodes[p] = new MeshNodeInfo(numNodesAssigned);
			nodeParentIds[p] = parentIds[numNodesAssigned];
			nodeGroupIds[p] = groupIds[numNodesAssigned];
			numNodesAssigned++;

			importanceOrderedNodes.push(nodes[__row * _cols + __col]);

			if (__col < leftmostColUsed		|| leftmostColUsed == -1)	leftmostColUsed = __col;
			if (__col > rightmostColUsed	|| rightmostColUsed == -1)	rightmostColUsed = __col;
			if (__row < topmostRowUsed		|| topmostRowUsed == -1)	topmostRowUsed = __row;
			if (__row > bottommostRowUsed	|| bottommostRowUsed == -1)	bottommostRowUsed = __row;
		}

		private function adjustNodeByDistance(__col:int, __row:int):void {
			// Does all adjustments necessary to smooth the position of a node

			if (__col < leftmostColUsed || __col > rightmostColUsed || __row < topmostRowUsed || __row > bottommostRowUsed) return;

			var nodePos:int = __row * _cols + __col;

			if (nodes[nodePos] != null) {

				// Move everything away from this item as needed

				// Left
				if (__col > leftmostColUsed) adjustNodesDistance(nodes[nodePos], nodes[nodePos-1]); //, Math.PI * 2 + LINK_ROTATION_ANGLE);

				// Right
				if (__col < rightmostColUsed) adjustNodesDistance(nodes[nodePos], nodes[nodePos+1]); //, LINK_ROTATION_ANGLE);

				// Above
				if (__row > topmostRowUsed) adjustNodesDistance(nodes[nodePos], nodes[nodePos-_cols]); //, - Math.PI * 0.5);

				// Below
				if (__row < bottommostRowUsed) adjustNodesDistance(nodes[nodePos], nodes[nodePos+_cols]); //, Math.PI * 0.5);

				// Below-left diagonal
				if (__col > leftmostColUsed && __row < bottommostRowUsed) adjustNodesDistance(nodes[nodePos], nodes[nodePos-1+_cols]); //, Math.PI * 0.75);

				// Above-right diagonal
				if (__col < rightmostColUsed && __row > topmostRowUsed) adjustNodesDistance(nodes[nodePos], nodes[nodePos+1-_cols]); //, - Math.PI * 0.25);
			}
		}

		private function adjustNodesDistance(__node0:MeshNodeInfo, __node1:MeshNodeInfo, __closeAmount:Number = 0.25, __awayAmount:Number = 0.5, __anchor:Number = 0.5, __onlyIfDistanceBelow:Number = NaN, __desiredAngle:Number = NaN):void {
			// Adjust the distance between two nodes to be more than the minimum distance

			if (__node1 == null) return;

			var line:Line = new Line(__node0.position, __node1.position, true);

			// Bias towards the angle (only used in vertical links?)
//			if (!isNaN(__desiredAngle)) {
//				// Re-adjust angle
//				var la:Number = line.angle;
//				if (Math.abs(la - __desiredAngle) > Math.PI) {
//					if (la > __desiredAngle) {
//						la -= Math.PI;
//					} else {
//						la += Math.PI;
//					}
//				}
//				line.setAngle(la - (la - __desiredAngle) / 20);
//			}

			var radiusNode0:Number = __node0.scale * NODE_RADIUS_STANDARD;
			var radiusNode1:Number = __node1.scale * NODE_RADIUS_STANDARD;
			var desiredDistance:Number = radiusNode0 + minimumNodeDistance + radiusNode1;
			var l:Number = line.length;
			var nodeDistance:Number = l - radiusNode0 - radiusNode1;
			if (isNaN(__onlyIfDistanceBelow) || nodeDistance < __onlyIfDistanceBelow) {
				if (l < desiredDistance) {
					// Too close, must set them apart (more aggressively)
					if (__awayAmount > 0)	line.setLength(l - (l - desiredDistance) / (1 / __awayAmount), __anchor);
				} else {
					// Too far, must get them closer (not as aggressively)
					if (__closeAmount > 0) line.setLength(l - (l - desiredDistance) / (1 / __closeAmount), __anchor);
				}
			}

			__node1.position.setTo(line.p2.x, line.p2.y);
			__node0.position.setTo(line.p1.x, line.p1.y);
		}


		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		private function get colsUsed():int {
			return rightmostColUsed - leftmostColUsed + 1;
		}

		private function get rowsUsed():int {
			return bottommostRowUsed - topmostRowUsed + 1;
		}

		public function getNodeAt(__col:int, __row:int):MeshNodeInfo {
			return nodes[__row * _cols + __col];
		}
	}
}
