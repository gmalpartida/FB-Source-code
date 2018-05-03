package com.firstborn.pepsi.display.gpu.brand.particles {
	import com.zehfernando.geom.QuadraticBezierCurve;
	/**
	 * @author zeh fernando
	 */
	public interface IParticleCreatorFactory {

		function createParticlePath():QuadraticBezierCurve;
	}
}
