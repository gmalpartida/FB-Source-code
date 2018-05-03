package com.firstborn.pepsi.display.gpu.common.blobs {
	import com.zehfernando.data.types.NoiseSequence;
	import com.zehfernando.utils.MathUtils;

	import flash.display.CapsStyle;
	import flash.display.GraphicsPath;
	import flash.display.GraphicsPathCommand;
	import flash.display.GraphicsSolidFill;
	import flash.display.GraphicsStroke;
	import flash.display.IGraphicsData;
	import flash.display.JointStyle;
	import flash.display.LineScaleMode;
	import flash.display.Shape;

	/**
	 * @author zeh fernando
	 */
	public class BlobShape extends Shape {

		// Constants
		private static const SHAPE_SEGMENTS:int = 500;						// Segments for the whole shape... more = more precise, but slower to generate. It's high to avoid Flash's antialias "snapping" that produces some weird curves when the angle is near multiples of 45
		public static const NOISE_RADIUS_SCALE_STANDARD:Number = 0.15;

		// Properties
		private var radius:Number;

		private var colorSolid:uint;
		private var alphaSolid:Number;
		private var colorStroke:uint;
		private var alphaStroke:Number;

		// Instances
		private var noiseSequenceA:NoiseSequence;
		private var noiseSequenceB:NoiseSequence;

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function BlobShape(__radius:Number, __colorSolid:uint, __alphaSolid:Number, __colorStroke:uint, __alphaStroke:Number, __strokeWidth:Number, __noiseRadiusScale:Number = NaN, __octavesA:int = 2, __octavesB:int = 1, __normalizeRadius:Boolean = false, __randomSeed:int = -1) {
			radius = __radius;
			noiseSequenceA = new NoiseSequence(__octavesA, __randomSeed);
			noiseSequenceB = new NoiseSequence(__octavesB, __randomSeed);
			colorSolid = __colorSolid;
			alphaSolid = __alphaSolid;
			colorStroke = __colorStroke;
			alphaStroke = __alphaStroke;
			if (isNaN(__noiseRadiusScale)) __noiseRadiusScale = NOISE_RADIUS_SCALE_STANDARD;

			// Create the shape

			// Need to create it first
			var pathCoordinates:Vector.<Number>;
			var pathCommands:Vector.<int>;
			var i:int;
			var f:Number;
			var angle:Number;
			var noiseRadius:Number = radius * __noiseRadiusScale; // How much to shrink
			var n:Number;

			var shapeData:Vector.<IGraphicsData> = new Vector.<IGraphicsData>();

			// Colors
			if (alphaStroke >= 0) shapeData.push(new GraphicsStroke(__strokeWidth, false, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.ROUND, 3, new GraphicsSolidFill(colorStroke & 0xffffff, alphaStroke)));
			if (alphaSolid >= 0) shapeData.push(new GraphicsSolidFill(colorSolid & 0xffffff, alphaSolid));

			// Path
			pathCommands = new Vector.<int>(SHAPE_SEGMENTS + 1, true);
			pathCoordinates = new Vector.<Number>(pathCommands.length * 2, true);

			// Normalize all positions to enforce the correct radius
			var minRadius:Number = NaN;
			var maxRadius:Number = NaN;
			var radii:Vector.<Number> = new Vector.<Number>(SHAPE_SEGMENTS, true);
			for (i = 0; i < SHAPE_SEGMENTS; i++) {
				f = (i % SHAPE_SEGMENTS)/SHAPE_SEGMENTS;
				n = (radius + ((noiseSequenceA.getNumber(f)*noiseSequenceB.getNumber(f)-1)/2) * noiseRadius - __strokeWidth/2);

				radii[i] = n;

				if (isNaN(minRadius) || n < minRadius) minRadius = n;
				if (isNaN(maxRadius) || n > maxRadius) maxRadius = n;
			}

			for (i = 0; i <= SHAPE_SEGMENTS; i++) {
				if (i == 0) {
					pathCommands[i] = GraphicsPathCommand.MOVE_TO;
				} else {
					pathCommands[i] = GraphicsPathCommand.LINE_TO;
				}

				f = (i % SHAPE_SEGMENTS)/SHAPE_SEGMENTS;
				angle = f * Math.PI * 2;

				n = radii[i % SHAPE_SEGMENTS];
				if (__normalizeRadius) n = MathUtils.map(n, minRadius, maxRadius, __radius - noiseRadius, __radius);

				pathCoordinates[i * 2] = Math.cos(angle) * n;
				pathCoordinates[i * 2 + 1] = Math.sin(angle) * n;
			}

			shapeData.push(new GraphicsPath(pathCommands, pathCoordinates));

			graphics.drawGraphicsData(shapeData);
		}
	}
}
