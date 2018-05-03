package com.firstborn.pepsi.display.gpu.brand.particles {
	import com.firstborn.pepsi.application.FountainFamily;
	import com.zehfernando.geom.QuadraticBezierCurve;
	import com.zehfernando.transitions.Equations;
	import com.zehfernando.utils.RandomGenerator;

	import flash.geom.Point;
	/**
	 * @author zeh fernando
	 */
	public class ParticleCreatorFactoryLine implements IParticleCreatorFactory {

		// A line segment that can spawn new particles

		// Properties
		private var p0:Point;
		private var p1:Point;
		private var maxHeight:Number;

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function ParticleCreatorFactoryLine(__p0:Point, __p1:Point, __maxHeight:Number) {
			p0 = __p0;
			p1 = __p1;
			maxHeight = __maxHeight;
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function createParticlePath():QuadraticBezierCurve {
			// Find min and max starting angle (within the screen)

			// Find position
			var f:Number = Equations.quadInOut(Math.random());

			// Find starting point
			var p:Point = Point.interpolate(p0, p1, 1-f);

			var height:Number = RandomGenerator.getInRange(0.8, 1) * maxHeight;

			// Find end point (highly biasedtowards the center)
			var pTop:Point = new Point(p.x + (FountainFamily.platform.width * RandomGenerator.getInRange(0.25, 0.5) - p.x) * 0.5 + RandomGenerator.getInRange(-10, 10), p.y - height);

			// Find control point
			var pControl:Point = Point.interpolate(p, pTop, RandomGenerator.getInRange(0.6, 0.75));
			pControl.x += (pTop.x - pControl.x) * 0.8;

			// Create curve
			return new QuadraticBezierCurve(p, pControl, pTop);
		}
	}
}
