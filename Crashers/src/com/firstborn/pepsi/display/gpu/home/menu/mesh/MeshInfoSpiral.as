package com.firstborn.pepsi.display.gpu.home.menu.mesh {
	import com.zehfernando.geom.CubicBezierCurve;
	import com.zehfernando.geom.GeomUtils;
	import com.zehfernando.geom.Line;
	import com.zehfernando.geom.Path;
	import com.zehfernando.transitions.Equations;
	import com.zehfernando.utils.MathUtils;
	import com.zehfernando.utils.console.Console;
	import com.zehfernando.utils.console.error;
	import com.zehfernando.utils.console.log;
	import com.zehfernando.utils.console.warn;

	import flash.geom.Point;
	/**
	 * @author zeh fernando
	 */
	public class MeshInfoSpiral extends MeshInfo {

		// Constants
		private static const PARENT_NODE_PENETRATION:Number = 50;									// How much of an overlap exists between a "parent" and a child node, in pixels
		private static const MAX_PARENT_CHILD_PAIRS:int = 3;										// Maximum number of parent-child pairs allowed
		private static const MAX_CHILD_PER_PARENT:int = 1;											// Maximum number of children a parent node can have
		private static const DESIRED_ANGLES:Vector.<Number> = new <Number>[40, 330, 190, 300, 200, 135, 90];				// Desired angles for nodes in relation to their pivots, in degrees, clockwise, 0 = right; cycles through the list sequentially
		private static const DESIRED_ANGLES_CHILD:Vector.<Number> = new <Number>[260, 180, 120];	// Desired angles for nodes in relation to their pivots (when the pivot is a parent), in degrees, clockwise, 0 = right; cycles through the list sequentially

		private static const PATH_SCALE_X:Number = 1.15;
		private static const PATH_SCALE_Y:Number = 1;

		private static const SIZE_LOGO_MIN:Number = 1; // [[Size exploration: 1.1]]
		private static const SIZE_LOGO_MAX:Number = 1;
		private static const CENTER_SPOT_IN_PATH:Number = 0.65;										// "Center" along the line, where the starting/most important node is placed (0 = right end, 1 = left end)
		private static const CENTER_SPOT_IN_PATH_FOR_SIZE:Number = 0.5;								// "Center" along the line, where the biggest items are placed
		private static const NODE_SCALE_MAX:Number = 2.8;											// Scale of the biggest node
		private static const NODE_SCALE_MIN:Number = 1; // [[Size exploration: 1.2]]				// Scale of the smallest node
		private static const PRECISION_ANGLE:Number = 2;											// Angle precision when finding a suitable spot; the smaller, the more precise but also slower
		private static const NODE_SCALE_CHILD_MIN:Number = 0.55;									// Scale of children nodes when in a parent-child pair with the minimum parent size
		private static const NODE_SCALE_CHILD_MAX:Number = 0.55;									// Scale of children nodes when in a parent-child pair with the maximum parent size
		private static const MAXIMUM_DISTANCE_FROM_PATH_INSIDE:Number = NODE_RADIUS_STANDARD * NODE_SCALE_MAX * 1.3;		// Maximum distance a node can be from the path, inside/up (includes the whole node body)
		private static const MAXIMUM_DISTANCE_FROM_PATH_OUTSIDE:Number = NODE_RADIUS_STANDARD * NODE_SCALE_MAX * 0.7;		// Maximum distance a node can be from the path, outside/down (includes the whole node body)

		private static const MAXIMUM_DISTANCE_FROM_PATH_INSIDE_8:Number = NODE_RADIUS_STANDARD * NODE_SCALE_MAX * 0.7;		// Maximum distance a node can be from the path, inside/up (includes the whole node body)
		private static const MAXIMUM_DISTANCE_FROM_PATH_OUTSIDE_8:Number = NODE_RADIUS_STANDARD * NODE_SCALE_MAX * 0.2;		// Maximum distance a node can be from the path, outside/down (includes the whole node body)

		private static const TIMES_TO_SMOOTH_DISTANCE:int = 30; // Times to re-adjust distance... since it's an approximation

		// Instances
		private var path:Path;
		private var numChildren:Vector.<int>;								// Number of children for each node (if it's a parent node)
		private var importanceOrderedNodes:Vector.<MeshNodeInfo>;
		private var nodeParentIds:Vector.<int>;								// List a node's parent id: follows the grid id but contains the original list id
		private var nodeGroupIds:Vector.<String>;							// List a node's group id (a string): follows the grid id
		private var nodeConnectedToParent:Vector.<Boolean>;					// Whether each node is connected to its parent
		private var nodeConnectedToChild:Vector.<Boolean>;					// Whether each node is connected to one of its children


		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function MeshInfoSpiral(__numNodes:int, __parentIds:Vector.<int>, __groupIds:Vector.<String>, __customParameters:String) {
			numChildren = new Vector.<int>(__parentIds.length);
			super(__numNodes, __parentIds, __groupIds, __customParameters);
		}

		// ================================================================================================================
		// EXTENDED INTERFACE ---------------------------------------------------------------------------------------------

		override protected function setDefaultValues():void {
			super.setDefaultValues();
			minimumNodeDistance = MathUtils.map(_numNodes, 12, 16, NODE_DISTANCE_MINIMUM, NODE_DISTANCE_MINIMUM, true);
			paddingTop = 0;
			paddingBottom = -20;
			paddingLeft = -20;
			paddingRight = -20;
		}

		override protected function createNodes():void {
			createNodeList();
			createPath();
			distributeNodes();
			reshuffleNodes();
			smoothNodePositions();
		}

		override protected function createOrderedLists():void {
			var i:int;

			// Create a list of the nodeinfos ordered by the suggested order for hardware ADA
			// Simple list from beginning to end (never used)
			orderedNodesByFocus = new Vector.<MeshNodeInfo>();

			for (i = 0; i < nodes.length; i++) {
				orderedNodesByFocus[i] = nodes[i];
			}

			// Create a list of nodeinfos ordered for animation and following the line
			orderedNodesByAppearance = new Vector.<MeshNodeInfo>();
			var unorderedNodes:Vector.<MeshNodeInfo> = nodes.concat();

			var closestNodeIndex:int;
			var closestNodeDistance:Number;
			var distance:Number;

			while (unorderedNodes.length > 0) {
				closestNodeIndex = -1;
				closestNodeDistance = NaN;

				for (i = 0; i < unorderedNodes.length; i++) {
					distance = path.getClosestPositionNormalized(unorderedNodes[i].position);
					if (closestNodeIndex == -1 || distance < closestNodeDistance) {
						closestNodeIndex = i;
						closestNodeDistance = distance;
					}
				}

				orderedNodesByAppearance.push(unorderedNodes[closestNodeIndex]);
				unorderedNodes.splice(closestNodeIndex, 1);
				//log("Pos => " + closestNodeIndex + " / " + unorderedNodes.length + " @ " + closestNodeDistance);
			}
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private function createNodeList():void {
			// Create a simple list of nodes
			// Each item will contain the index of the menuItem that goes there
			nodes = new Vector.<MeshNodeInfo>(_numNodes, true);
			importanceOrderedNodes = new Vector.<MeshNodeInfo>();

			nodeParentIds = new Vector.<int>(nodes.length, true);
			nodeGroupIds = new Vector.<String>(nodes.length, true);
			nodeConnectedToParent = new Vector.<Boolean>(nodes.length, true);
			nodeConnectedToChild = new Vector.<Boolean>(nodes.length, true);

			// Simple list
			var i:int;
			for (i = 0; i < nodes.length; i++) {
				nodes[i] = new MeshNodeInfo(i);
				importanceOrderedNodes[i] = nodes[i];
				nodeParentIds[i] = parentIds[i];
				nodeGroupIds[i] = groupIds[i];
				nodeConnectedToParent[i] = false;
				nodeConnectedToChild[i] = false;
			}
		}

		private function createPath():void {
			// Create a path where the menu will be distributed in

			var c1:CubicBezierCurve = new CubicBezierCurve(new Point(766.967, 930.268), new Point(1149.847, 1123.692), new Point(948.737, 1816.805), new Point(569.077, 1775.615));
			var c2:CubicBezierCurve = new CubicBezierCurve(c1.p2, new Point(138.736, 1728.928), new Point(-6.427, 1125.14), new Point(202.653, 674.5));

			// Converts points to path
			var points:Vector.<Point> = new Vector.<Point>();
			var numPointsPerCurve:int = 10; // The more points, the more precise, but also the slower it is to find points
			var i:int;
			for (i = 0; i < numPointsPerCurve; i++) points.push(c1.getPointOnCurve(i/numPointsPerCurve));
			for (i = 0; i <= numPointsPerCurve; i++) points.push(c2.getPointOnCurve(i/numPointsPerCurve));
			path = Path.fromPoints(points);
			path.scale(PATH_SCALE_X, PATH_SCALE_Y);
		}

		private function distributeNodes():void {
			// Distribute nodes along the path

			var newNodePositionDefinition:NodePositionDefinition;
			var numAssignedNodes:int = 0;
			var numChildParentPairs:int = 0;
			var numNormalPairs:int = 0;

			var i:int;

			Console.timeStart("menu-spiral");

			for (i = 0; i < nodes.length; i++) {
				if (i == 0) {
					// First node; centered in the same position on the path, following a perpendicular line
					newNodePositionDefinition = getBestPositionForFirstNode();
				} else {
					// Secondary nodes, distributed by proximity to another node, and to the path
					newNodePositionDefinition = getBestPositionForNode(i, numAssignedNodes, numChildParentPairs, numNormalPairs);

					// Update pair totals
					if (newNodePositionDefinition.pivotIsParent) {
						numChildParentPairs++;
						numChildren[newNodePositionDefinition.parentId]++;
					} else {
						numNormalPairs++;
					}
				}

				// Update totals
				numAssignedNodes++;

				if (isNaN(newNodePositionDefinition.position.x)) log("node => " + i + " @ " + newNodePositionDefinition.position);

				nodes[i].position = newNodePositionDefinition.position;
				nodes[i].scale = newNodePositionDefinition.scale;
				nodes[i].parentId = newNodePositionDefinition.parentId;
				nodes[i].logoScaleMultiplier = newNodePositionDefinition.logoScale;
				if (newNodePositionDefinition.pivotIsParent) {
					nodeConnectedToParent[i] = true;
					nodeConnectedToChild[nodes[i].parentId] = true;
				}
			}

			Console.timeEnd("menu-spiral");
		}

		private function getBestPositionForFirstNode():NodePositionDefinition {
			// Find the position for the first, most important node

			var l:Number = path.length;
			var pathPos:Point = path.getPosition(CENTER_SPOT_IN_PATH * l);
			var pathPosBefore:Point = path.getPosition(CENTER_SPOT_IN_PATH * l - 1);
			var pathPosAfter:Point = path.getPosition(CENTER_SPOT_IN_PATH * l + 1);
			var tangentLine:Line = new Line(pathPosBefore, pathPosAfter);
			var nodeRadius:Number = NODE_RADIUS_STANDARD * NODE_SCALE_MAX;
			var possibleLine:Line = new Line(Point.polar(MAXIMUM_DISTANCE_FROM_PATH_OUTSIDE - nodeRadius, tangentLine.angle + Math.PI/2), Point.polar(MAXIMUM_DISTANCE_FROM_PATH_OUTSIDE - nodeRadius, tangentLine.angle - Math.PI/2));

			var newNodePositionDefinition:NodePositionDefinition = new NodePositionDefinition();

			newNodePositionDefinition.position = pathPos.add(possibleLine.getPointNormalized(0)); // 0..1, where 0 = bottom and 1 = top
			newNodePositionDefinition.scale = NODE_SCALE_MAX;
			newNodePositionDefinition.logoScale = SIZE_LOGO_MAX;
			newNodePositionDefinition.pivotIsParent = false;
			newNodePositionDefinition.parentId = -1;
			newNodePositionDefinition.pivotIsGroup = false;

			return newNodePositionDefinition;
		}

		private function getBestPositionForNode(__nodeIndex:int, __numAssignedNodes:int, __numChildParentPairs:int, __numNormalPairs:int):NodePositionDefinition {
			// Find the best position for a given node (by biggest size), returning the position, scale and parent id

			// Get list of ordered nodes that can be the pivot for each node
			var possiblePivotNodes:Vector.<MeshNodeInfo> = getListOfOrderedPossiblePivotNodes(__nodeIndex, __numAssignedNodes);

			var i:int;

			var newNodePositionDefinition:NodePositionDefinition;
			var bestNewNodePositionDefinition:NodePositionDefinition;

			// Check all poossible pivot nodes to see where it can go
			// This is a weird loop because it has to leak vars that will be used later. Kinda weird.
			var pathDistanceScale:Number = 1;
			while (pathDistanceScale < 10 && bestNewNodePositionDefinition == null) {
				bestNewNodePositionDefinition = null;

				for (i = 0; i < possiblePivotNodes.length; i++) {
					newNodePositionDefinition = getBestPositionForNodeInPivot(__nodeIndex, possiblePivotNodes[i], __numAssignedNodes, pathDistanceScale, __numChildParentPairs, __numNormalPairs);

					if (newNodePositionDefinition != null) {
						// Nodes attached to parents have priority; then, nodes attached to groups; then, everything else
						if (bestNewNodePositionDefinition == null || (newNodePositionDefinition.scale > bestNewNodePositionDefinition.scale && (!bestNewNodePositionDefinition.pivotIsParent && (newNodePositionDefinition.pivotIsGroup || !bestNewNodePositionDefinition.pivotIsGroup)))) {
							// This is the new best node
							bestNewNodePositionDefinition = newNodePositionDefinition;
						}
					}
				}

				if (bestNewNodePositionDefinition == null) {
					// No positions found, try again with path distance ignored
					warn("No line position found for node " + __nodeIndex + ", will multiply path scale");
					pathDistanceScale *= 1.2;
				}

			}

			if (bestNewNodePositionDefinition == null) {
				error("Error! No valid positions found for node " + __nodeIndex + "!");
			}

			return bestNewNodePositionDefinition;
		}

		private function getBestPositionForNodeInPivot(__nodeIndex:int, __pivotNode:MeshNodeInfo, __assignedNodeListLength:int, __pathDistanceScale:Number, __numChildParentPairs:int, __numNormalPairs:int):NodePositionDefinition {
			// Given a node index and a pivot, return the best position for this node to have around the pivot

			// Vars
			var i:int;

			// Gather necessary data
			var nodeParentId:int = parentIds[__nodeIndex];
			var pivotIsParentNode:Boolean = nodeParentId == __pivotNode.id && __numChildParentPairs < MAX_PARENT_CHILD_PAIRS && numChildren[nodeParentId] < MAX_CHILD_PER_PARENT && __nodeIndex < parentIds.length * 0.32; // Only a small part of the initial nodes can have parent-child pairs
			var pivotIsSameGroup:Boolean = groupIds[__nodeIndex] == groupIds[__pivotNode.id];
			var nodeImportance:Number = MathUtils.map(__nodeIndex, 0, nodes.length - 1, 1, 0); // 1..0, from most importance (center) to end of node list
			var nodeScale:Number = MathUtils.map(Equations.expoInOut(nodeImportance), 1, 0, NODE_SCALE_MAX, NODE_SCALE_MIN);
			var logoScale:Number = 1;
			if (pivotIsParentNode) {
				nodeScale = Math.min(nodeScale, MathUtils.map(nodeImportance, 1, 0, NODE_SCALE_CHILD_MAX, NODE_SCALE_CHILD_MIN) * __pivotNode.scale);
				nodeScale = Math.max(nodeScale, NODE_SCALE_MIN);
				//nodeScale *= MathUtils.map(nodeImportance, 1, 0, NODE_SCALE_CHILD_MAX, NODE_SCALE_CHILD_MIN);
			}
			// Ghetto way to make 3 items more important/bigger
			if (__numNormalPairs > 1 && !pivotIsParentNode) nodeScale *= MathUtils.map(nodeImportance, 1, 0, 0.7, 1);
			var nodeScale2:Number;
			//var nodeScale:Number = MathUtils.map(nodeImportance, 1, 0, NODE_SCALE_MAX, NODE_SCALE_MIN);
			var nodeRadius:Number = NODE_RADIUS_STANDARD * nodeScale;

			// Radius for initial check; only does the actual radius check when we know the final scale (in case of parent-child relationships
			var preliminaryNodeRadius:Number = nodeRadius * 0.5;

			var pivotNodePosition:Point = __pivotNode.position;
			var pivotNodeId:int = __pivotNode.id;

			// Check all angles around the this node to find all valid positions (brute force radial raycasting)
			var validAngles:Vector.<Number> = new Vector.<Number>();
			var validAngleSizes:Vector.<Number> = new Vector.<Number>();
			var validAnglePositions:Vector.<Point> = new Vector.<Point>();

			// Shapes are attached to each other when the pivot node is also the parent
			var distanceFromPivot:Number = getIdealNodeDistance(__pivotNode.scale, nodeScale, pivotIsParentNode);

			// Decide on the most desired angle
			var desiredAngle:Number;
			var minAngle:Number, maxAngle:Number;

			minAngle = 0;
			maxAngle = 360;
			if (pivotIsParentNode) {
				desiredAngle = DESIRED_ANGLES_CHILD[__numChildParentPairs % DESIRED_ANGLES_CHILD.length];
			} else {
				desiredAngle = DESIRED_ANGLES[__numNormalPairs % DESIRED_ANGLES.length];
			}

			// Find the maximum distance allowed from the path, ignoring the radius of the node
			var closestPathPhase:Number;
			var maximumValidDistanceFromPath:Number;
			var distanceFromPath:Number;
			var rightSideOfPath:Boolean;
			var newPos:Point;

			// Bridge was meant to support 12-16 brands only, so the ranges take that into account
			var maximumDistanceOutsideSansRadius:Number = MAXIMUM_DISTANCE_FROM_PATH_OUTSIDE * (pivotIsParentNode ? 2 : 1) * MathUtils.map(_numNodes, 12, 16, 0.75, 1, true);
			var maximumDistanceInsideSansRadius:Number = MAXIMUM_DISTANCE_FROM_PATH_INSIDE * (pivotIsParentNode ? 2 : 1) * MathUtils.map(_numNodes, 12, 16, 0.75, 1, true);

			if (_numNodes < 12) {
				// Later, it was decided that it could also support 8-12 brands, but without breaking existing layouts, so this is a special case
				maximumDistanceOutsideSansRadius = MAXIMUM_DISTANCE_FROM_PATH_OUTSIDE_8 * (pivotIsParentNode ? 2 : 1) * MathUtils.map(_numNodes, 8, 12, 0.75, 1, true);
				maximumDistanceInsideSansRadius = MAXIMUM_DISTANCE_FROM_PATH_INSIDE_8 * (pivotIsParentNode ? 2 : 1) * MathUtils.map(_numNodes, 8, 12, 0.75, 1, true);
			}

			var maximumDistanceSansRadius:Number;
			var maximumScaleAllowed:Number; // Scale because of position on path (1..0, where 1 = center and 0 = end of path)

			for (i = minAngle; i < maxAngle; i += PRECISION_ANGLE) {
				// Check if it's a valid angle (one that doesn't hit other nodes)

				newPos = Point.polar(distanceFromPivot - nodeRadius + preliminaryNodeRadius, i * GeomUtils.DEG2RAD).add(pivotNodePosition);

				if (!checkIfBubblesCollide(newPos, preliminaryNodeRadius, __assignedNodeListLength, pivotIsParentNode ? nodeParentId : -1)) {
					// Doesn't collide, so it's a valid position

					// Also check if it's near the path (first pass)
					distanceFromPath = path.getDistance(newPos);
					rightSideOfPath = path.getPositionSideRight(newPos);
					maximumDistanceSansRadius = (rightSideOfPath ? maximumDistanceInsideSansRadius : maximumDistanceOutsideSansRadius);

					// Doesn't care about path distance (second pass)
					if (rightSideOfPath) maximumDistanceSansRadius *= __pathDistanceScale;

					// Check first to avoid finding the position too many times
					if (distanceFromPath <= maximumDistanceSansRadius) {

						// Find what point of the path is closest to the tentative node position
						closestPathPhase = path.getClosestPositionNormalized(newPos);

						// Find the maximum distance allowed from the path (based on position) and the additional scale based on path position
						if (closestPathPhase > CENTER_SPOT_IN_PATH_FOR_SIZE) {
							// To the left of the center (end)
							maximumValidDistanceFromPath = MathUtils.map(closestPathPhase, 1, CENTER_SPOT_IN_PATH_FOR_SIZE, 0, maximumDistanceSansRadius);
							maximumScaleAllowed = MathUtils.map(closestPathPhase, 1, CENTER_SPOT_IN_PATH_FOR_SIZE, 0, 1);
						} else {
							// To the right of the center (beginning)
							maximumValidDistanceFromPath = MathUtils.map(closestPathPhase, 0, CENTER_SPOT_IN_PATH_FOR_SIZE, 0, maximumDistanceSansRadius);
							maximumScaleAllowed = MathUtils.map(closestPathPhase, 0, CENTER_SPOT_IN_PATH_FOR_SIZE, 0, 1);
						}

						if (distanceFromPath <= maximumValidDistanceFromPath) {
							// It's close enough to the path
							if (pivotIsParentNode) {
								// Attached to parent

								// Re-check size
								newPos = Point.polar(distanceFromPivot, i * GeomUtils.DEG2RAD).add(pivotNodePosition);
								if (!checkIfBubblesCollide(newPos, NODE_RADIUS_STANDARD * nodeScale, __assignedNodeListLength, nodeParentId)) {
									// Can add
									// Ignore actual size due to path proximity
									validAngles.push(i);
									validAngleSizes.push(nodeScale);
									validAnglePositions.push(newPos);
								}
							} else {
								// Not attached to parent, normal pair

								// Re-check size
								nodeScale2 = Math.min(nodeScale, MathUtils.map(Math.pow(maximumScaleAllowed, 1.8), 1, 0, NODE_SCALE_MAX, NODE_SCALE_MIN));
								newPos = Point.polar(distanceFromPivot - nodeRadius + NODE_RADIUS_STANDARD * nodeScale2, i * GeomUtils.DEG2RAD).add(pivotNodePosition);
								if (!checkIfBubblesCollide(newPos, NODE_RADIUS_STANDARD * nodeScale2, __assignedNodeListLength, nodeParentId)) {
									// Can add
									// Use size due to path proximity as the maximum
									validAngles.push(i);
									validAngleSizes.push(nodeScale2);
									validAnglePositions.push(newPos);
								}
							}
						}
					}
				}
			}

			if (validAngles.length == 0) {
				// No valid angles found
				return null;
			} else {

				// Finally, create the node at a position closest to the desired angle
				var selectedAnglePos:int;
				var selectedAngleDistance:Number;
				var angleDistance:Number;

				// Picks the angle that is closest to the bottom
				selectedAnglePos = -1;
				for (i = 0; i < validAngles.length; i++) {
					angleDistance = Math.abs(validAngles[i] - desiredAngle);
					if (angleDistance > 180) angleDistance = desiredAngle + 360 - validAngles[i];
					if (selectedAnglePos < 0 || angleDistance < selectedAngleDistance) {
						selectedAngleDistance = angleDistance;
						selectedAnglePos = i;
					}
				}

				var newNodePositionDefinition:NodePositionDefinition = new NodePositionDefinition();
				newNodePositionDefinition.position = validAnglePositions[selectedAnglePos];
				newNodePositionDefinition.scale = validAngleSizes[selectedAnglePos];
				newNodePositionDefinition.logoScale = MathUtils.map(nodeImportance, 1, 0, SIZE_LOGO_MAX, SIZE_LOGO_MIN);
				newNodePositionDefinition.pivotIsParent = pivotIsParentNode;
				newNodePositionDefinition.parentId = pivotIsParentNode ? pivotNodeId : -1;
				newNodePositionDefinition.pivotIsGroup = pivotIsSameGroup;

				return newNodePositionDefinition;
			}
		}

		private function getListOfOrderedPossiblePivotNodes(__nodeIndex:int, __nodeListLength:int):Vector.<MeshNodeInfo> {
			// Create a list of all possible pivot nodes for a node, in order of preference

			var list:Vector.<MeshNodeInfo> = new Vector.<MeshNodeInfo>();
			var i:int;

			// First, add the parent node if one is found
			if (parentIds[__nodeIndex] >= 0 && parentIds[__nodeIndex] < __nodeListLength) list.push(nodes[parentIds[__nodeIndex]]);

			// Then, add all nodes that belong to the same group
			if (groupIds[__nodeIndex] != null && groupIds[__nodeIndex].length > 0) {
				for (i = 0; i < __nodeListLength; i++) {
					if (groupIds[__nodeIndex] == groupIds[i] && list.indexOf(nodes[i]) == -1) list.push(nodes[i]);
				}
			}

			// Then, add everything else
			for (i = 0; i < __nodeListLength; i++) {
				if (list.indexOf(nodes[i]) == -1) list.push(nodes[i]);
			}

			return list;
		}

		private function checkIfBubblesCollide(__newPosition:Point, __newRadius:Number, __nodeListLength:int, __allowedId:int = -1):Boolean {
			// Check whether a given point with a radius collides with the area of any of the existing nodes
			var i:int;
			for (i = 0; i < __nodeListLength; i++) {
				if (i != __allowedId && Point.distance(__newPosition, nodes[i].position) - __newRadius - nodes[i].scale * NODE_RADIUS_STANDARD < minimumNodeDistance) return true;
			}
			return false;
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
			var closenessToStartItem:Number;
			var scaleItem:Number;
			var isNextToParentItemNew:Boolean;
			var groupSiblingsItemNew:int;
			var positionInPath:Number;
			var closenessToStartItemNew:Number;
			var scaleItemNew:Number;
			var selectedPos:int;
			var selectedScore:Number;
			var currentScore:Number;

			var isNextToParentUnderItem:Boolean;
			var groupSiblingsUnderItem:int;
			var isNextToParentUnderItemNew:Boolean;
			var groupSiblingsUnderItemNew:int;

			var oldPos:int;
			var timesToShuffle:int = 30;
			var minScore:Number = 0;
			var sizeDiff:Number;

			while (timesToShuffle > 0) {

				for (i = 0; i < allNodes.length; i++) {
					if (allNodes[i] != null && allNodes[i].id != 0) {
						// Find a better position for this node
						oldPos = nodes.indexOf(allNodes[i]);

						// If is a parent or child in a parent-child pair, don't swap anything
						if (nodeConnectedToParent[oldPos] || nodeConnectedToChild[oldPos]) continue;

						isNextToParentItem = isPositionNextToNodeParent(oldPos, allNodes[i]);
						groupSiblingsItem = getPositionNodeGroupSiblings(oldPos, allNodes[i]);
						if (groupSiblingsItem > 0) groupSiblingsItem++;
						positionInPath = path.getClosestPositionNormalized(allNodes[i].position);
						closenessToStartItem = positionInPath < CENTER_SPOT_IN_PATH ? positionInPath / CENTER_SPOT_IN_PATH : (1 - positionInPath) / (1 - CENTER_SPOT_IN_PATH);
						scaleItem = allNodes[i].scale;
						selectedPos = -1;
						selectedScore = 0;

//						log("Testing node " + i + " (id = " + allNodes[i].id + ") at " + oldPos + " (siblings = " + groupSiblingsItem + ")");

						for (j = 0; j < nodes.length; j++) {

							if (nodes[j] != null && nodes[j].id != 0 && nodes[j] != allNodes[i] && !nodeConnectedToParent[j] && !nodeConnectedToChild[j]) {
								isNextToParentItemNew = isPositionNextToNodeParent(j, allNodes[i]);
								groupSiblingsItemNew = getPositionNodeGroupSiblings(j, allNodes[i]);
								if (groupSiblingsItemNew > 0) groupSiblingsItemNew++;
								positionInPath = path.getClosestPositionNormalized(nodes[j].position);
								closenessToStartItemNew = positionInPath < CENTER_SPOT_IN_PATH ? positionInPath / CENTER_SPOT_IN_PATH : (1 - positionInPath) / (1 - CENTER_SPOT_IN_PATH);
								scaleItemNew = nodes[j].scale;

//								log("  Testing against node at " + j + " (siblings = " + groupSiblingsItemNew + "), distances = " + distanceToCenterItem + " => " + distanceToCenterItemNew);

								if (!(isNextToParentItemNew && !isNextToParentItem) || (groupSiblingsItemNew > groupSiblingsItem && isNextToParentItemNew == isNextToParentItem) || nodeGroupIds[oldPos] == nodeGroupIds[j]) {
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
									if (groupSiblingsUnderItem > 0) groupSiblingsUnderItem++;
									isNextToParentUnderItemNew = isPositionNextToNodeParent(oldPos, nodes[j]);
									groupSiblingsUnderItemNew = getPositionNodeGroupSiblings(oldPos, nodes[j]);
									if (groupSiblingsUnderItemNew > 0) groupSiblingsUnderItemNew++;

									// Away from parent: -5 points
									if (isNextToParentUnderItem && !isNextToParentUnderItemNew) currentScore -= 5;
									// Next to parent: +5 points
									if (!isNextToParentUnderItem && isNextToParentUnderItemNew) currentScore += 5;
									// Moving close to/away from siblings: +-1 point per sibling
									currentScore += groupSiblingsUnderItemNew - groupSiblingsUnderItem;

									// Lower id closer to center: +1 point if the lower id is closer
									// The bigger the difference between the item sizes, the lowest the score
									sizeDiff = Math.abs(scaleItemNew - scaleItem) / (MeshInfoSpiral.NODE_SCALE_MAX - NODE_SCALE_MIN) * 2;
									if (scaleItemNew > scaleItem) {
										// The new position is bigger
										if (allNodes[i].id < nodes[j].id) currentScore += 1;
										if (allNodes[i].id > nodes[j].id) currentScore -= 1;
									} else if (scaleItem > scaleItemNew) {
										// The new position is smaller
										if (allNodes[i].id > nodes[j].id) currentScore += 1;
										if (allNodes[i].id < nodes[j].id) currentScore -= 1;
									}
									// Also use position in line: +0.5 point if the position is closer
									if (closenessToStartItemNew > closenessToStartItem) {
										// The new position is closer to center
										if (allNodes[i].id < nodes[j].id) currentScore += 1;
										if (allNodes[i].id > nodes[j].id) currentScore -= 1;
									} else if (closenessToStartItem > closenessToStartItemNew) {
										// The new position is further way from center
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

				minScore += 0.01;
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

		private function swapNodes(__pos1:int, __pos2:int):void {
			// Swap the position of two nodes in the grid
			var node:MeshNodeInfo = nodes[__pos1];
			var parentId:int = nodeParentIds[__pos1];
			var groupId:String = nodeGroupIds[__pos1];
			var nodeItemConnectedToParent:Boolean = nodeConnectedToParent[__pos1];
			var nodeItemConnectedToChild:Boolean = nodeConnectedToChild[__pos1];
			var nodeScale:Number = nodes[__pos2].scale;
			var nodePosition:Point = nodes[__pos2].position.clone();

			nodes[__pos1] = nodes[__pos2];
			nodes[__pos1].scale = node.scale;
			nodes[__pos1].position.copyFrom(node.position);
			nodeParentIds[__pos1] = nodeParentIds[__pos2];
			nodeGroupIds[__pos1] = nodeGroupIds[__pos2];
			nodeConnectedToParent[__pos1] = nodeConnectedToParent[__pos2];
			nodeConnectedToChild[__pos1] = nodeConnectedToChild[__pos2];

			nodes[__pos2] = node;
			nodes[__pos2].scale = nodeScale;
			nodes[__pos2].position.copyFrom(nodePosition);
			nodeParentIds[__pos2] = parentId;
			nodeGroupIds[__pos2] = groupId;
			nodeConnectedToParent[__pos2] = nodeItemConnectedToParent;
			nodeConnectedToChild[__pos2] = nodeItemConnectedToChild;
		}

		private function isPositionNextToNodeParent(__pos:int, __childNode:MeshNodeInfo):Boolean {
			// Check if a node in this position is close to a parent
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

		private function getIdealNodeDistance(__nodeScale1:Number, __nodeScale2:Number, __isParentChildPair:Boolean):Number {
			return NODE_RADIUS_STANDARD * __nodeScale1 + minimumNodeDistance + NODE_RADIUS_STANDARD * __nodeScale2  - (__isParentChildPair ? PARENT_NODE_PENETRATION : 0);
		}

		private function getPositionNodeGroupSiblings(__pos:int, __node:MeshNodeInfo):int {
			// Find the number of siblings near a node
			var numGroupSiblings:int = 0;
			var nodeIndex:int = nodes.indexOf(__node);
			var groupId:String = nodeGroupIds[nodeIndex];

			for (var i:int = 0; i < nodes.length; i++) {
				if (i != __pos && nodes[i] != null && nodes[i] != __node && groupId != null && groupId.length > 0 && nodeGroupIds[i] == groupId) {
					// This is a sibling, check distance
//					if (nodeIndex == 1) log("Found sibling for node " + nodeIndex + " group " + groupId + " at position " + __pos + " => sibling " + i);
					if (Point.distance(nodes[i].position, nodes[__pos].position) <= nodes[i].scale * NODE_RADIUS_STANDARD + nodes[__pos].scale * NODE_RADIUS_STANDARD + NODE_RADIUS_STANDARD * 1) {
//						if (nodeIndex == 1) log("   is close enough");
						numGroupSiblings++;
					}
				}
			}

			return numGroupSiblings;
		}

		private function smoothNodePositions():void {
			// Try to move nodes around evely based on scale of neighbors, so the minimum node distance is maintained, starting from the center point

			var i:int, j:int, k:int;
			var p:Point;

			// Does approximation based on each brand's groups
			var timesToSmoothGroups:int = TIMES_TO_SMOOTH_DISTANCE;

			for (i = 0; i < timesToSmoothGroups; i++) {
				// Approximate items based on group
//				for (j = 0; j < importanceOrderedNodes.length; j++) {
//					if (groupIds[importanceOrderedNodes[j].id].length > 0) {
//						// A node with a valid group id; search for all other nodes in the same group
//						for (k = j + 1; k < importanceOrderedNodes.length; k++) {
//							if (groupIds[importanceOrderedNodes[j].id] == groupIds[importanceOrderedNodes[k].id] && groupIds[importanceOrderedNodes[k].id] != null && groupIds[importanceOrderedNodes[k].id].length > 0) {
//								// Same group
//								adjustNodesDistance(importanceOrderedNodes[j], importanceOrderedNodes[k], 0.01, 0, 0.5, NODE_RADIUS_STANDARD * 4);
//							}
//						}
//					}
//				}

				// Move some items as close as possible to the curve
//				for (j = 1; j < importanceOrderedNodes.length; j++) {
//					p = path.getClosestPoint(importanceOrderedNodes[j].position);
//					// TODO: maybe read the actual positions on the curve and force a zigzag pattern
//					adjustNodePointDistance(importanceOrderedNodes[j], p, MathUtils.map(importanceOrderedNodes[j].scale, NODE_SCALE_MIN, NODE_SCALE_MAX, 0.2, 0.1), 10);
//				}

				// Redistribute along the curve

				// Find what part of the curve is used first
				var minPathPos:Number = NaN;
				var maxPathPos:Number = NaN;
				var pos:Number;
				for (j = 1; j < importanceOrderedNodes.length; j++) {
					pos = path.getClosestPositionNormalized(importanceOrderedNodes[j].position);
					if (isNaN(minPathPos) || pos < minPathPos) minPathPos = pos;
					if (isNaN(maxPathPos) || pos > maxPathPos) maxPathPos = pos;
				}

				// Move items as close as possible to the curve, also distributing it along the curve (centered)
				var l:Number = path.length;
				var diff:Number = (1 - (maxPathPos - minPathPos)) / 2;
				for (j = 0; j < importanceOrderedNodes.length; j++) {
					pos = path.getClosestPositionNormalized(importanceOrderedNodes[j].position);
					pos = MathUtils.map(pos, minPathPos, maxPathPos, diff, 1-diff);
					p = path.getPosition(pos * l);
					// TODO: maybe read the actual positions on the curve and force a zigzag pattern
					adjustNodePointDistance(importanceOrderedNodes[j], p, MathUtils.map(importanceOrderedNodes[j].scale, NODE_SCALE_MIN, NODE_SCALE_MAX, 0.2, 0.1), 10);
				}

				// Always make sure all items are at least the a minimum distance from each other
				for (j = 0; j < importanceOrderedNodes.length; j++) {
					for (k = j + 1; k < importanceOrderedNodes.length; k++) {
						if (importanceOrderedNodes[j].parentId == importanceOrderedNodes[k].id && nodeConnectedToParent[nodes.indexOf(importanceOrderedNodes[j])] || importanceOrderedNodes[k].parentId == importanceOrderedNodes[j].id && nodeConnectedToParent[nodes.indexOf(importanceOrderedNodes[k])]) {
							// Parent-child nodes
							adjustNodesDistance(importanceOrderedNodes[j], importanceOrderedNodes[k], 0.8, 0.8, j == 0 ? 0.1 : MathUtils.map(importanceOrderedNodes[j].scale - importanceOrderedNodes[k].scale, (NODE_SCALE_MAX - NODE_SCALE_MIN)/1, (NODE_SCALE_MIN - NODE_SCALE_MAX)/1, 0, 1, true));
						} else {
							// Normal nodes
							adjustNodesDistance(importanceOrderedNodes[j], importanceOrderedNodes[k], 0.001, 0.8, j == 0 ? 0.1 : MathUtils.map(importanceOrderedNodes[j].scale - importanceOrderedNodes[k].scale, (NODE_SCALE_MAX - NODE_SCALE_MIN)/1, (NODE_SCALE_MIN - NODE_SCALE_MAX)/1, 0, 1, true));
						}
					}
				}
			}

		}

		private function adjustNodePointDistance(__node:MeshNodeInfo, __point:Point, __closeAmount:Number = 0.25, __maxLength:Number = 5):void {
			// Adjusts the distance between a node and a point
			var line:Line = new Line(__point, __node.position, true);

			var desiredDistance:Number = 0;
			var l:Number = line.length;
			var newLength:Number = MathUtils.clamp(l - (l - desiredDistance) / (1 / __closeAmount), l - __maxLength, l + __maxLength);

			line.setLength(newLength, 0);

			__node.position.setTo(line.p2.x, line.p2.y);
		}

		private function adjustNodesDistance(__node0:MeshNodeInfo, __node1:MeshNodeInfo, __closeAmount:Number = 0.25, __awayAmount:Number = 0.5, __anchor:Number = 0.5, __onlyIfDistanceBelow:Number = NaN):void {
			// Adjusts the distance between two nodes

			if (__node1 == null) return;

			var line:Line = new Line(__node0.position, __node1.position, true);

			var radiusNode0:Number = __node0.scale * NODE_RADIUS_STANDARD;
			var radiusNode1:Number = __node1.scale * NODE_RADIUS_STANDARD;
			var nodeId0:int = nodes.indexOf(__node0);
			var nodeId1:int = nodes.indexOf(__node1);
			var desiredDistance:Number = getIdealNodeDistance(__node0.scale, __node1.scale, (nodeConnectedToParent[nodeId0] && nodeParentIds[nodeId0] == __node1.id) || (nodeConnectedToParent[nodeId1] && nodeParentIds[nodeId1] == __node0.id));
			//var desiredDistance:Number = radiusNode0 + minimumNodeDistance + radiusNode1;
			var l:Number = line.length;
			var nodeDistance:Number = l - radiusNode0 - radiusNode1;
			if (isNaN(__onlyIfDistanceBelow) || nodeDistance < __onlyIfDistanceBelow) {
				if (l < desiredDistance) {
					// Too close, must set them apart (more aggressively)
					if (__awayAmount > 0) line.setLength(l - (l - desiredDistance) / (1 / __awayAmount), __anchor);
				} else {
					// Too far, must get them closer (not as aggressively)
					if (__closeAmount > 0) line.setLength(l - (l - desiredDistance) / (1 / __closeAmount), __anchor);
				}
			}

			__node1.position.setTo(line.p2.x, line.p2.y);
			__node0.position.setTo(line.p1.x, line.p1.y);
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		override public function shuffleNodes():void {
			distributeNodes();
			calculateBoundaries();
			createOrderedLists();
		}

		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		public function getPath():Path {
			// Used for testing purposes
			return path;
		}
	}
}
import flash.geom.Point;
// A temp class, just for the function to be more self-contained
class NodePositionDefinition {

	// Properties
	public var position:Point;
	public var scale:Number;
	public var parentId:int;
	public var pivotIsParent:Boolean;
	public var pivotIsGroup:Boolean;
	public var logoScale:Number;


	// ================================================================================================================
	// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

	public function NodePositionDefinition() {
	}

}