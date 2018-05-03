package com.firstborn.pepsi.display.gpu.home.menu.mesh {
	import com.zehfernando.geom.Line;
	import com.zehfernando.utils.console.error;

	import flash.geom.Point;
	/**
	 * @author zeh fernando
	 */
	public class MeshInfoCustom extends MeshInfo {

		// Custom mesh: all positions are hardcoded

		// Constants
		public static var TIMES_TO_SMOOTH_DISTANCE:int = 30; // Times to re-adjust distance, if necessary (when parent/child relationships exist)

		// Properties
		private var customNodeInfos:Vector.<CustomNodeInfo>;


		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function MeshInfoCustom(__numNodes:int, __parentIds:Vector.<int>, __groupIds:Vector.<String>, __customParameters:String) {
			super(__numNodes, __parentIds, __groupIds, __customParameters);
		}


		// ================================================================================================================
		// EXTENDED INTERFACE ---------------------------------------------------------------------------------------------

		override protected function setDefaultValues():void {
			super.setDefaultValues();

			minimumNodeDistance = NODE_DISTANCE_MINIMUM * 0.5; // Less aggressive

			parseCustomParameters();
		}

		override protected function createNodes():void {
			createNodeList();
			smoothNodePositions();
		}

		override protected function createOrderedLists():void {
			super.createOrderedLists();

			// Create a list of the nodeinfos ordered by the suggested order for hardware ADA (reuses the default list)
			orderedNodesByFocus = nodes;

			// Create a list of nodeinfos ordered for animation (order of appearance)
			orderedNodesByAppearance = nodes.concat();
			orderedNodesByAppearance.sort(sortMeshNodeInfoByAnimationPosition);
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private function parseCustomParameters():void {
			// Parse the custom parameter string into a list of positions and radiuses
			// Also sets paddings

			var positionGroups:Array = JSON.parse(customParameters.replace(/\/\*.*?\*\//sg, "")) as Array;

			var positions:Array;

			var i:int, j:int;

			// Find initial values
			var allCustomNodeInfos:Vector.<Vector.<CustomNodeInfo>> = new Vector.<Vector.<CustomNodeInfo>>();
			var allCustomNodePaddings:Vector.<Array> = new Vector.<Array>();

			for (i = 0; i < positionGroups.length; i++) {
				allCustomNodeInfos.push(new Vector.<CustomNodeInfo>());
				allCustomNodePaddings.push(positionGroups[i]["padding"]);
				positions = positionGroups[i]["positions"];
				for (j = 0; j < positions.length - 2; j += 3) {
					allCustomNodeInfos[i].push(new CustomNodeInfo(positions[j], positions[j+1], positions[j+2]));
				}
			}

			// Find the list of CustomNodeInfos that most closely match the number of items needed
			var selectedIndex:int = -1;
			var selectedNumPositions:int = -1;
			var thisNumPositions:int;

			for (i = 0; i < allCustomNodeInfos.length; i++) {
				thisNumPositions = allCustomNodeInfos[i].length;
				if (selectedIndex == -1 || (thisNumPositions > selectedNumPositions && thisNumPositions <= _numNodes) || (thisNumPositions < selectedNumPositions && thisNumPositions >= _numNodes) || (thisNumPositions >= _numNodes && selectedNumPositions < _numNodes)) {
					// A better selection than the current
					selectedIndex = i;
					selectedNumPositions = allCustomNodeInfos[selectedIndex].length;
					if (thisNumPositions == _numNodes) {
						// Exact number, no need to search for more
						break;
					}
				}
			}

			// Create proper list
			customNodeInfos = allCustomNodeInfos[selectedIndex].concat();

			// Sort from biggest to smallest
			customNodeInfos.sort(sortCustomNodeInfoByRadius);

			// Set padding
			paddingTop = allCustomNodePaddings[selectedIndex][0];
			paddingRight = allCustomNodePaddings[selectedIndex][1];
			paddingBottom = allCustomNodePaddings[selectedIndex][2];
			paddingLeft = allCustomNodePaddings[selectedIndex][3];
		}

		private function createNodeList():void {
			// Create a grid of nodes
			// Each item will contain the index of the menuItem that goes there
			nodes = new Vector.<MeshNodeInfo>(_numNodes, true);

			if (customNodeInfos.length != _numNodes) {
				error("Error! Could not find exact number of node positions for custom menu! Using list with " + customNodeInfos.length + " node positions, needed list with " + nodes.length + "!");
			}

			var nodeInfo:CustomNodeInfo;
			for (var i:int = 0; i < nodes.length; i++) {
				nodeInfo = customNodeInfos[i % customNodeInfos.length];
				nodes[i] = new MeshNodeInfo(i);
				nodes[i].position = new Point(nodeInfo.x, nodeInfo.y);
				nodes[i].scale = nodeInfo.radius / MeshInfo.NODE_RADIUS_STANDARD;
				nodes[i].parentId = parentIds[i];
				nodes[i].logoScaleMultiplier = 1; // TODO: use weighted size, with bigger logo when the bubble is small?
			}
		}

		private function smoothNodePositions():void {
			// Smooth the node positions if needed, in case nodes are touching in a non parent-child relationship. NO TOUCHING!

			var i:int, j:int, k:int;

			for (i = 0; i < TIMES_TO_SMOOTH_DISTANCE; i++) {
				// Always make sure all items are at least the a minimum distance from each other
				for (j = 0; j < nodes.length; j++) {
					for (k = j + 1; k < nodes.length; k++) {
						if (nodes[j].parentId != nodes[k].id && nodes[k].parentId != nodes[j].id) {
							// Normal nodes, shouldn't be touching. NO TOUCHING!
							adjustNodesDistance(nodes[j], nodes[k], minimumNodeDistance, 0, 0.8, 0.5, minimumNodeDistance);
						}
					}
				}
			}
		}

		private function adjustNodesDistance(__node0:MeshNodeInfo, __node1:MeshNodeInfo, __desiredDistance:Number, __closeAmount:Number = 0.25, __awayAmount:Number = 0.5, __anchor:Number = 0.5, __onlyIfDistanceBelow:Number = NaN):void {
			// Adjusts the distance between two nodes

			if (__node1 == null) return;

			var line:Line = new Line(__node0.position, __node1.position, true);

			var radiusNode0:Number = __node0.scale * NODE_RADIUS_STANDARD;
			var radiusNode1:Number = __node1.scale * NODE_RADIUS_STANDARD;
			var l:Number = line.length;
			var nodeDistance:Number = l - radiusNode0 - radiusNode1;
			if (isNaN(__onlyIfDistanceBelow) || nodeDistance < __onlyIfDistanceBelow) {
				if (nodeDistance < __desiredDistance) {
					// Too close, must set them apart (more aggressively)
					if (__awayAmount > 0) line.setLength(l - (nodeDistance - __desiredDistance) * __awayAmount, __anchor);
				} else {
					// Too far, must get them closer (not as aggressively)
					if (__closeAmount > 0) line.setLength(l - (nodeDistance - __desiredDistance) * __closeAmount, __anchor);
				}
			}

			__node1.position.setTo(line.p2.x, line.p2.y);
			__node0.position.setTo(line.p1.x, line.p1.y);
		}

		private function sortCustomNodeInfoByRadius(a:CustomNodeInfo, b:CustomNodeInfo):Number {
			// Sort from biggest to smallest nodes
			return a.radius > b.radius ? -1 : (a.radius == b.radius ? 0 : 1);
		}

		private function sortMeshNodeInfoByAnimationPosition(a:MeshNodeInfo, b:MeshNodeInfo):Number {
			// Sort by desired animation sequence:
			// Left side: diagonal from top left to top right; right side: diagonal from bottom left to bottom right
			var midX:Number = boundaries.x + boundaries.width * 0.5;

			// Nodes on opposite sites
			if (a.position.x < midX && b.position.x > midX) return 1;
			if (a.position.x > midX && b.position.x < midX) return -1;

			if (a.position.x < midX) {
				// Nodes on the left
				return a.position.x + a.position.y < b.position.x + b.position.y ? 1 : -1;
			} else {
				// Nodes on the right
				return a.position.x - a.position.y < b.position.x - b.position.y ? 1 : -1;
			}
		}
	}
}


// ================================================================================================================
// HELPER CLASSES -------------------------------------------------------------------------------------------------

internal class CustomNodeInfo {
	public var x:Number;
	public var y:Number;
	public var radius:Number;

	public function CustomNodeInfo(__x:Number, __y:Number, __radius:Number) {
		x = __x;
		y = __y;
		radius = __radius;
	}
}