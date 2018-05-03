package com.zehfernando.geom {
	import flash.geom.Point;
	import flash.geom.Rectangle;
	/**
	 * @author zeh
	 */
	public class GeomUtils {

		// Constants
		public static var WINDING_CLOCKWISE:String = "clockwise";
		public static var WINDING_COUNTERCLOCKWISE:String = "counterclockwise";

		// Others
		public static const DEG2RAD:Number = Math.PI / 180; // Multiply by this number to convert degrees to radians
		public static const RAD2DEG:Number = 180 / Math.PI; // Multiply by this number to convert radians to degrees
		public static const HALF_PI:Number = Math.PI * 0.5;

		[Inline]
		public static function distanceSquared(__p1:Point, __p2:Point):Number {
			return sqr(__p1.x - __p2.x) + sqr(__p1.y - __p2.y);
		}

		[Inline]
		public static function sqr(__x:Number):Number {
			return __x * __x;
		}

		public static function fitRectangle(__insideRect:Rectangle, __outsideRect:Rectangle, __fitAllInside:Boolean = true):Number {
			// Fits a rectangle inside another rectangle, and returns the scale the inner rectangle should have
			// This is good for fitting things in screens, like videos
			// __fitAllInside TRUE = Equivalent to StageScaleMode.SHOW_ALL
			// __fitAllInside FALSE = Equivalent to StageScaleMode.NO_BORDER

			// Screen/border dimensions
			var outsideRatio:Number = __outsideRect.width / __outsideRect.height;

			// Content/inside dimensions
			var insideRatio:Number = __insideRect.width / __insideRect.height;

			// This could be shorter
			var baseScale:Number;
			if (outsideRatio > insideRatio) {
				// Content is taller than screen
				if (__fitAllInside) {
					// Use height as base
					baseScale = __outsideRect.height / __insideRect.height;
				} else {
					// Use width as base
					baseScale = __outsideRect.width / __insideRect.width;
				}
			} else {
				// Content is wider than screen
				if (__fitAllInside) {
					// Use width as base
					baseScale = __outsideRect.width / __insideRect.width;
				} else {
					// Use height as base
					baseScale = __outsideRect.height / __insideRect.height;
				}
			}

			return baseScale;
		}

		public static function getLineSegmentClosestPhaseToPoint(__point:Point, __p1:Point, __p2:Point):Number {
			// Find the position (0-1) where the closest point in the segment is in relation to __point
			var l2:Number = distanceSquared(__p1, __p2);
			if (l2 == 0) return 0;
			return ((__point.x - __p1.x) * (__p2.x - __p1.x) + (__point.y - __p1.y) * (__p2.y - __p1.y)) / l2;
		}

		public static function getPointIsToRightSideOfLine(__point:Point, __p1:Point, __p2:Point):Boolean {
//			log("=> " + GeomUtils.getPointIsToRightSideOfLine(new Point(100, 0), new Point(0, 0), new Point(100, 100))); // Should be: false
//			log("=> " + GeomUtils.getPointIsToRightSideOfLine(new Point(0, 100), new Point(0, 0), new Point(100, 100))); // Should be: true
//			log("=> " + GeomUtils.getPointIsToRightSideOfLine(new Point(100, 100), new Point(100, 0), new Point(0, 100))); // Should be: false
//			log("=> " + GeomUtils.getPointIsToRightSideOfLine(new Point(0, 0), new Point(100, 0), new Point(0, 100))); // Should be: true
//			log("=> " + GeomUtils.getPointIsToRightSideOfLine(new Point(0, 0), new Point(0, 100), new Point(100, 0))); // Should be: false
//			log("=> " + GeomUtils.getPointIsToRightSideOfLine(new Point(100, 100), new Point(0, 100), new Point(100, 0))); // Should be: true
//			log("=> " + GeomUtils.getPointIsToRightSideOfLine(new Point(0, 100), new Point(100, 100), new Point(0, 0))); // Should be: false
//			log("=> " + GeomUtils.getPointIsToRightSideOfLine(new Point(100, 0), new Point(100, 100), new Point(0, 0))); // Should be: true
//			log("=> " + GeomUtils.getPointIsToRightSideOfLine(new Point(-50, 0), new Point(0, 100), new Point(100, 100))); // Should be: false
//			log("=> " + GeomUtils.getPointIsToRightSideOfLine(new Point(200, 0), new Point(0, 100), new Point(100, 100))); // Should be: false
//			log("=> " + GeomUtils.getPointIsToRightSideOfLine(new Point(-50, 200), new Point(0, 100), new Point(100, 100))); // Should be: true
//			log("=> " + GeomUtils.getPointIsToRightSideOfLine(new Point(200, 200), new Point(0, 100), new Point(100, 100))); // Should be: true

			return ((__p2.x - __p1.x)*(__point.y - __p1.y) - (__p2.y - __p1.y)*(__point.x - __p1.x)) > 0;
		}

		public static function getLineSegmentPointClosestToPoint(__point:Point, __p1:Point, __p2:Point):Point {
			// Find the point in this line that is closest to another point

			var l2:Number = distanceSquared(__p1, __p2);
			if (l2 == 0) return __p1.clone();

			var t:Number = ((__point.x - __p1.x) * (__p2.x - __p1.x) + (__point.y - __p1.y) * (__p2.y - __p1.y)) / l2;
			if (t < 0) return __p1.clone();
			if (t > 1) return __p2.clone();
			return Point.interpolate(__p1, __p2, 1-t);
		}

		public static function getLineSegmentDistanceToPoint(__point:Point, __p1:Point, __p2:Point):Number {
			// Find the minimum distance between this line segment and a point
			// http://stackoverflow.com/questions/849211/shortest-distance-between-a-point-and-a-line-segment

			var l2:Number = distanceSquared(__p1, __p2);
			if (l2 == 0) return Point.distance(__point, __p1);

			var t:Number = ((__point.x - __p1.x) * (__p2.x - __p1.x) + (__point.y - __p1.y) * (__p2.y - __p1.y)) / l2;
			if (t < 0) return Point.distance(__point, __p1);
			if (t > 1) return Point.distance(__point, __p2);
			return Math.sqrt(distanceSquared(__point, new Point(__p1.x + t * (__p2.x - __p1.x), __p1.y + t * (__p2.y - __p1.y))));
		}

		public static function offsetPolygonEdges(__points:Vector.<Point>, __amount:Number):Vector.<Point> {
			// Offset all points of a polygon, creating a new set of points that defines all offset lines of the original polygon
			// The new list of points has 2x the original number of points

			var i:int;

			var p:Point, nextP:Point;
			var nextAngle:Number;
			var newPoints:Vector.<Point> = new Vector.<Point>(__points.length * 2, true);

			for (i = 0; i < __points.length; i++) {
				p = __points[i];
				nextP = __points[(i+1) % __points.length];
				nextAngle = Math.atan2(nextP.y - p.y, nextP.x - p.x);
				newPoints[i * 2] = Point.polar(__amount, nextAngle + HALF_PI).add(p);
				newPoints[i * 2 + 1] = Point.polar(__amount, nextAngle + HALF_PI).add(nextP);
			}

			return newPoints;
		}

		public static function decomposePolygon(__points:Vector.<Point>):Vector.<Vector.<Point>> {
			// Decomposes a polygon (as a series of points) into several different polygons, avoiding intersections

			// Check all points for intersections
			var i:int, j:int;
			var p:Point;
			var l:int = __points.length;
			var l1p1:int, l1p2:int;
			var l2p1:int, l2p2:int;
			var allPoints:Vector.<Vector.<Point>> = new Vector.<Vector.<Point>>();

			var allPointsPosition:int = 0;
			allPoints.push(new Vector.<Point>());

			for (i = 0; i < l; i++) {
				l1p1 = i;
				l1p2 = (i + 1) % l;
				allPoints[allPointsPosition].push(__points[l1p1]);
				for (j = 1; j < l; j++) {
					l1p1 = (i + j) % l;
					l1p2 = (i + j + 1) % l;
					p = GeomUtils.getLineIntersection(__points[l1p1].x, __points[l1p1].y, __points[l1p2].x, __points[l1p2].y, __points[l2p1].x, __points[l2p1].y, __points[l2p2].x, __points[l2p2].y);
					if (p != null) {
						// There is an intersection
						allPoints[allPointsPosition].push(p);

						// Continue from the intersection, as a new set of points
						// TODO: doesn't work if the line has two intersections
						allPointsPosition++;
						allPoints.push(new Vector.<Point>());
						allPoints[allPointsPosition].push(p);
					} else {
						// This line doesn't intersect anything, continue in the same polygon
						allPoints[allPointsPosition].push(__points[l1p2]);
					}
				}
			}
			
			return allPoints;
		}



		public static function closePolygonEdgeGaps(__points:Vector.<Point>, __amount:Number):Vector.<Point> {
			// Given a list of points that compose lines (pa, pb, pa, pb, ...) connect all end points with start points when the lines don't intersect, by extending them
			// TODO: allow milter limit and type of connection

			var newPoints:Vector.<Point> = new Vector.<Point>();
			var i:int = 0;
			var fi:int;
			var p:Point; // Intersection
			var skipNextStartPoint:Boolean = false;
			for (i = 0; i < __points.length; i+= 2) {
				fi = (i + 2) % __points.length;
				p = getLineIntersection(__points[i].x, __points[i].y, __points[i+1].x, __points[i+1].y, __points[fi].x, __points[fi].y, __points[fi+1].x, __points[fi+1].y, true);

				if (p != null) {
					// Lines intersect, so just push this line
					if (!skipNextStartPoint) newPoints.push(__points[i]);
					newPoints.push(__points[i+1]);

					skipNextStartPoint = false;
				} else {
					// No segment intersection, must close the gap by finding the intersection as a line
					p = getLineIntersection(__points[i].x, __points[i].y, __points[i+1].x, __points[i+1].y, __points[fi].x, __points[fi].y, __points[fi+1].x, __points[fi+1].y, false);

					if (p == null) {
						// Should never happen
						trace("No intersection between lines?!");
						return null;
					}

					newPoints.push(__points[i]);
					newPoints.push(p);

					skipNextStartPoint = true;
				}
			}

			if (skipNextStartPoint) {
				// Start point of first line should be skipped
				newPoints.splice(0, 1);
			}

			return newPoints;
		}

		public static function inflatePolygon(__points:Vector.<Point>, __amount:Number):Vector.<Vector.<Point>> {
			// Inflates a closed polygon, as defined by a of points
			// The return value needs to be a list of a list because the polygon may be decomposed into two different polygons

			// TODO: milter limit
			// TODO: allow non-loop polygon
			// TODO: allow self-intersecting polygon

			var originalWinding:String = getPolygonWinding(__points);
			if (originalWinding == WINDING_CLOCKWISE) __amount *= -1; //? This should be the opposite
			var p:Point, nextP:Point;
			var nextAngle:Number;

			var nextPA:Point, nextPB:Point;

			var i:int, j:int;

			// Creates a vector of all expanded/contracted lines
			var lines:Vector.<Line> = new Vector.<Line>;
			for (i = 0; i < __points.length; i++) {
				p = __points[i];
				nextP = __points[(i+1) % __points.length];
				nextAngle = Math.atan2(nextP.y - p.y, nextP.x - p.x);
				nextPA = Point.polar(__amount, nextAngle + HALF_PI).add(p);
				nextPB = Point.polar(__amount, nextAngle + HALF_PI).add(nextP);
				lines.push(new Line(nextPA, nextPB, true));
			}

			// Now, check for intersections of subsequent lines
			var otherLine:Line;
			var normalizedJ:int;
			var intersectPoint:Point;
			var itemsToRemove:int;
			var itemsToRemoveStart:int;
			var itemsToRemoveEnd:int;
			for (i = 0; i < lines.length; i++) {
				for (j = i + 1; j < i + lines.length; j++) {
					normalizedJ = j % lines.length;
					otherLine = lines[normalizedJ];
					if (otherLine.intersectsLine(lines[i])) {
						// The two lines intersect!
						// Use the new point as the point for those lines
						intersectPoint = otherLine.intersection(lines[i]);
						lines[i].p2 = intersectPoint;
						otherLine.p1 = intersectPoint;
						// Remove lines in between
						itemsToRemove = j - i - 1;
						if (normalizedJ > i) {
							// Normal sequence
							lines.splice(i+1, itemsToRemove);
							j -= itemsToRemove;
						} else {
							// Sequence loops
							// Removes from here to the end
							itemsToRemoveEnd = lines.length - i - 1;
							itemsToRemoveStart = itemsToRemove - itemsToRemoveEnd;
							lines.splice(i+1, itemsToRemoveEnd);
							// Removes from the start
							lines.splice(0, itemsToRemoveStart);
							i -= itemsToRemoveStart;
							j -= itemsToRemove;
						}
					}
				}
			}

			// Finally, creates new points
			var newPoints:Vector.<Point> = new Vector.<Point>();
			for (i = 0; i < lines.length; i++) {
				newPoints.push(lines[i].p1.clone());
				newPoints.push(lines[i].p2.clone());
			}

			var pp:Vector.<Vector.<Point>> = new Vector.<Vector.<Point>>();
			pp.push(newPoints);
			return pp;
		}

		[Inline]
		public static function getPolygonWinding(__points:Vector.<Point>):String {
			var area:Number = getPolygonArea(__points);
			return area > 0 ? WINDING_COUNTERCLOCKWISE : WINDING_CLOCKWISE;
		}

		[Inline]
		public static function getPolygonArea(__points:Vector.<Point>):Number {
			// Calculate area of non-self-intersecting polygon, assumes it's closed
			var area:Number = 0;
			var j:Number;
			for (var i:int = 0; i < __points.length; i++) {
				j = (i + 1) % __points.length;
				area += __points[j].x * __points[i].y - __points[i].x * __points[j].y;
			}
			return area / 2;
		}

		public static function getLineIntersection(__ax1:Number, __ay1:Number, __ax2:Number, __ay2:Number, __bx1:Number, __by1:Number, __bx2:Number, __by2:Number, __asSegment:Boolean = true):Point {
			// Returns a point containing the intersection between two lines (segment or not)
			// http://keith-hair.net/blog/2008/08/04/find-intersection-point-of-two-lines-in-as3/
			// http://www.gamedev.pastebin.com/f49a054c1 (probably a faster implementation)

			var a1:Number = __ay2 - __ay1;
			var b1:Number = __ax1 - __ax2;
			var a2:Number = __by2 - __by1;
			var b2:Number = __bx1 - __bx2;

			var denom:Number = a1 * b2 - a2 * b1;
			if (denom == 0) return null;

			var c1:Number = __ax2 * __ay1 - __ax1 * __ay2;
			var c2:Number = __bx2 * __by1 - __bx1 * __by2;

			var px:Number = (b1 * c2 - b2 * c1)/denom;
			var py:Number = (a2 * c1 - a1 * c2)/denom;

			if (__asSegment) {
				if (getPointDistance(px, py, __ax2, __ay2) > getPointDistance(__ax1, __ay1, __ax2, __ay2)) return null;
				if (getPointDistance(px, py, __ax1, __ay1) > getPointDistance(__ax1, __ay1, __ax2, __ay2)) return null;
				if (getPointDistance(px, py, __bx2, __by2) > getPointDistance(__bx1, __by1, __bx2, __by2)) return null;
				if (getPointDistance(px, py, __bx1, __by1) > getPointDistance(__bx1, __by1, __bx2, __by2)) return null;
			}

			return new Point(px, py);

		}

		[Inline]
		public static function getPointDistance(__x1:Number, __y1:Number, __x2:Number, __y2:Number):Number {
			// Returns the distance between two points
			// Faster and using less memory than Point.distance
			var dx:Number = __x2 - __x1;
			var dy:Number = __y2 - __y1;
			return Math.sqrt(dx * dx + dy * dy);
		}
	}
}
