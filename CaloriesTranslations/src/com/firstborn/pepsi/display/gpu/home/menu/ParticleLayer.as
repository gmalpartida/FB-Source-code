package com.firstborn.pepsi.display.gpu.home.menu {
	import starling.display.Image;
	import starling.display.Sprite;

	import com.firstborn.pepsi.application.FountainFamily;
	import com.firstborn.pepsi.data.TextureProfile;
	import com.firstborn.pepsi.display.gpu.home.menu.mesh.MeshInfo;
	import com.zehfernando.data.types.Color;
	import com.zehfernando.transitions.Equations;
	import com.zehfernando.utils.MathUtils;
	import com.zehfernando.utils.RandomGenerator;

	import flash.geom.Point;

	/**
	 * @author zeh fernando
	 */
	public class ParticleLayer extends Sprite {

		// Layer of particles around a menu mesh

		// Constants
		private static const MAX_DISTANCE:int = 60; // Maximum distance, in pixels, from the owner blob
		private static const MIN_DISTANCE:int = 0; // Margin between blobs and the particle
		private static const MIN_DISTANCE_PARTICLES:int = 2; // Margin between a particle and other particles that belong to other blobs
		private static const MIN_PARTICLE_RADIUS:Number = 2; // Minimum radius, in pixels
		private static const MAX_PARTICLE_RADIUS:Number = 20; // Maximum radius, in pixels, when the target has a scale of 1
		private static const MAX_PARTICLE_RADIUS_TOTAL:Number = MAX_PARTICLE_RADIUS * 2; // Maximum radius, in pixels, for all particles created
		private static const MAX_Y_MARGIN:Number = 0;		// Max margin for outside
		private static const MAX_X_MARGIN:Number = 20;

		// Properties
		private var particleNumberScale:Number;
		private var particleSizeScale:Number;
		private var particleAlphaScale:Number;
		private var particleClusterChance:Number;
		private var particleClusterItemsMax:int;

		// Instances
		private var particles:Vector.<ParticleInfo>;
		private var mesh:MeshInfo;
		private var textureInfo:TextureProfile;
		private var blobsSprites:Vector.<BlobSpritesInfo>;
		private var mainMenu:MainMenu;

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function ParticleLayer(__mesh:MeshInfo, __blobsSprites:Vector.<BlobSpritesInfo>, __mainMenu:MainMenu, __particleNumberScale:Number, __particleSizeScale:Number, __particleAlphaScale:Number, __particleClusterChance:Number, __particleClusterItemsMax:int) {
			mesh = __mesh;
			blobsSprites = __blobsSprites;
			mainMenu = __mainMenu;
			particleNumberScale = __particleNumberScale;
			particleSizeScale = __particleSizeScale;
			particleAlphaScale = __particleAlphaScale;
			particleClusterChance = __particleClusterChance;
			particleClusterItemsMax = __particleClusterItemsMax;

			particles = new Vector.<ParticleInfo>();
			textureInfo = FountainFamily.platform.getTextureProfile("blob-particles");

			createParticles();
		}

		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		private function createParticles():void {
			//var ti:int = getTimer();

			// Creates particles for all sprites
			var i:int, j:int;
			var particlesToCreate:int;
			var particlesCreated:int;
			var angle:Number;
			var lastAngle:Number;
			var useLastAngle:Boolean;
			var radius:Number;						// POSITION radius
			var lastRadius:Number;
			var tries:int;
			var position:Point;
			var particleRadius:Number;				// Radius of the particle itself
			var particleAlpha:Number;				// Alpha of the particle itself
			var distance:Number;
			var minDistanceFromInvalidArea:Number;
			var particleColor:Color;
			var image:Image;
			var particle:ParticleInfo;

			// Makes a list of all positions and radiuses (for later verification)
			var positions:Vector.<Point> = new Vector.<Point>(blobsSprites.length, true);
			var radii:Vector.<Number> = new Vector.<Number>(blobsSprites.length, true);
			var minX:Number, maxX:Number;
			var minY:Number, maxY:Number;
			for (i = 0; i < blobsSprites.length; i++) {
				positions[i] = blobsSprites[i].nodeInfo.position;
				radii[i] = blobsSprites[i].nodeRadius;
				if (isNaN(minX) || positions[i].x - radii[i] < minX) minX = positions[i].x - radii[i];
				if (isNaN(maxX) || positions[i].x + radii[i] > maxX) maxX = positions[i].x + radii[i];
				if (isNaN(minY) || positions[i].y - radii[i] < minY) minY = positions[i].y - radii[i];
				if (isNaN(maxY) || positions[i].y + radii[i] > maxY) maxY = positions[i].y + radii[i];
			}

			var distanceToParent:Number;
			var maxParticleRadius:Number, minParticleRadius:Number;
			var maxTries:int;
			var r:Number;
			var particleRadiusTotal:Number;
			var itemsInCluster:uint;

			for (i = 0; i < blobsSprites.length; i++) {
				particlesToCreate = Math.round((RandomGenerator.getInIntegerRange(0, 2) + Math.round(MathUtils.map(blobsSprites[i].nodeInfo.scale, 1, 2, 3, 7))) * particleNumberScale);
				particlesCreated = 0;

				maxTries = particlesToCreate * 3;

				lastAngle = -1;

				itemsInCluster = 0;

				particleRadiusTotal = 0;

				maxParticleRadius = MAX_PARTICLE_RADIUS * blobsSprites[i].nodeInfo.scale * particleSizeScale;
				minParticleRadius = MIN_PARTICLE_RADIUS * particleSizeScale;

				// Creates particles at a random location
				tries = 0;

				createLoop:
				while (particlesCreated < particlesToCreate && tries < maxTries) {
					useLastAngle = itemsInCluster < particleClusterItemsMax ? (Math.random() < particleClusterChance) : false; // chance of creating a cluster
					if (useLastAngle) itemsInCluster++;

					// Picks a random location, but more frequently close to the bubble
					if (useLastAngle && lastAngle >= 0) {
						// Near the last angle (to create clusters)
						angle = lastAngle + RandomGenerator.getInRange(-0.12, 0.12);
						radius = lastRadius + RandomGenerator.getInRange(-(MAX_DISTANCE - MIN_DISTANCE) / 8, (MAX_DISTANCE - MIN_DISTANCE) / 8);
					} else {
						// New position
						angle = Math.random() * Math.PI * 2;
						r = Math.random();
						if (r < 0.1) {
							// 10% of chance of using the whole range, with bias to closer to the target
							radius = MathUtils.map(Equations.circIn(Math.random()), 0, 1, blobsSprites[i].nodeRadius + MIN_DISTANCE + 0.01, blobsSprites[i].nodeRadius + MAX_DISTANCE - minParticleRadius);
						} else {
							// 90% of chance of being next to the target, with bias to max size
							radius = blobsSprites[i].nodeRadius + MIN_DISTANCE + maxParticleRadius * Equations.circOut(Math.random());
						}
						//radius = blobsSprites[i].nodeRadius + MIN_DISTANCE + 0.1;
						//radius = blobsSprites[i].nodeRadius + MIN_DISTANCE + maxParticleRadius + 0.1;
					}

					// Checks if it's valid or not
					minDistanceFromInvalidArea = -1;
					position = Point.polar(radius, angle).add(blobsSprites[i].nodeInfo.position);

					distanceToParent = Point.distance(position, blobsSprites[i].nodeInfo.position) - blobsSprites[i].nodeRadius - MIN_DISTANCE;

					tries++;

					// Checks if it's inside or collides with another blob
					for (j = 0; j < positions.length; j++) {
						if (blobsSprites[i].nodeInfo.position != positions[j]) {
							distance = Point.distance(position, positions[j]) - radii[j] - MIN_DISTANCE;
							if (distance < 0) {
								// Colliding with another blob
								continue createLoop;
//							} else if (distance < distanceToParent) {
//								// Too close to a different blob
//								continue createLoop;
							} else {
								// Is valid, but calculate safe distance
								if (minDistanceFromInvalidArea < 0 || distance < minDistanceFromInvalidArea) {
									minDistanceFromInvalidArea = distance;
								}
							}
						}
					}

					// Checks if it hits a particle that belongs to another blob
					for (j = 0; j < particles.length; j++) {
						if (particles[j].parentNodeSpriteInfo != blobsSprites[i]) {
							distance = Point.distance(position, particles[j].positionGlobal) - particles[j].radius - MIN_DISTANCE_PARTICLES;
							if (distance < 0) {
								// Colliding with another particle
								continue createLoop;
							} else {
								// Is valid, but calculate safe distance
								if (minDistanceFromInvalidArea < 0 || distance < minDistanceFromInvalidArea) {
									minDistanceFromInvalidArea = distance;
								}
							}
						}
					}

					// Decide on size
					particleRadius = Math.min(maxParticleRadius, minDistanceFromInvalidArea, distanceToParent) * MathUtils.map(radius - blobsSprites[i].nodeRadius, MIN_DISTANCE + (MAX_DISTANCE - MIN_DISTANCE) * 0.7, MAX_DISTANCE, 1, 0, true);
					particleRadius = Math.min(particleRadius, MAX_PARTICLE_RADIUS_TOTAL * blobsSprites[i].nodeRadius - particleRadiusTotal);
					particleRadius = Math.max(particleRadius, minParticleRadius);

					if (particleRadius > minParticleRadius + (maxParticleRadius - minParticleRadius) * 0.5 && minDistanceFromInvalidArea > maxParticleRadius * 2) {
						// Never create a big particle too far from other targets
						continue createLoop;
					}

					// Check if it's outside the allowed box
					if (position.x - particleRadius < minX - MAX_X_MARGIN || position.x + particleRadius > maxX + MAX_X_MARGIN || position.y - particleRadius < minY - MAX_Y_MARGIN || position.y + particleRadius > maxY + MAX_Y_MARGIN) {
						continue createLoop;
					}

					particleRadiusTotal += particleRadius;

					// Particle can be created
					lastAngle = angle;
					lastRadius = radius;

					// Color
					particleColor = blobsSprites[i].beverage.getDesign().getParticleHomeColor();

					// Create image
					image = new Image(FountainFamily.textureLibrary.getBlobParticlesTexture());
					image.pivotX = image.width * 0.5;
					image.pivotY = image.height * 0.5;
					image.smoothing = textureInfo.smoothing;
					image.color = particleColor.toRRGGBB();
					addChild(image);

					//particleRadius = minParticleRadius * 2;
					//var radius:Number = Math.min(MathUtils.map(Equations.quadIn(Math.random()), 0, 1, MIN_PARTICLE_RADIUS, MAX_PARTICLE_RADIUS), minDistanceFromInvalidArea, maxRadiusDueToDistance);

					// Decide alpha
					particleAlpha = MathUtils.map(particleColor.a, 0, 1, 0, 1) * (useLastAngle ? 0.6 : 1);

					// Create actual particle
					particle = new ParticleInfo(image, particleAlpha * particleAlphaScale, particleRadius, position.subtract(blobsSprites[i].nodeInfo.position), blobsSprites[i]);
					particles.push(particle);

					particlesCreated++;
				}

				//if (particlesToCreate - particlesCreated > 3) warn("Skipped the creation of " + (particlesToCreate - particlesCreated) + " particles");
			}
		}

		private function destroyParticles():void {
			while (particles.length > 0) {
				removeChild(particles[0].image);
				particles[0].image.texture.dispose();
				particles[0].image.dispose();
				particles.splice(0, 1);
			}
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function update(__currentTimeSeconds:Number, __tickDeltaTimeSeconds:Number, __currentTick:int):void {
			var vis:Number = MathUtils.map(mainMenu.brandTransitionPhase, 0, 0.3, 1, 0, true);
			//var vis:Number = mainMenu.visibility;
			if (mainMenu.brandTransitionPhase < 1) {
				for each (var particle:ParticleInfo in particles) {
					particle.visibility = vis;
					particle.update(__currentTimeSeconds, __tickDeltaTimeSeconds, __currentTick);
				}
			}
		}

		public function recreate():void {
			destroyParticles();
			createParticles();
		}

		override public function dispose():void {
			destroyParticles();
			super.dispose();
		}
	}

}
import starling.display.Image;

import com.firstborn.pepsi.display.gpu.home.menu.BlobSpritesInfo;
import com.zehfernando.transitions.Equations;
import com.zehfernando.utils.MathUtils;
import com.zehfernando.utils.RandomGenerator;

import flash.geom.Point;

class ParticleInfo {

	// Properties
	private var alpha:Number;
	public var radius:Number;
	private var position:Point;
	public var positionGlobal:Point;

	private var rotationSpeed:Number;
	private var scaleCycleTime:Number;

	public var visibility:Number;
	public var smoothAnimation:Boolean;

	// Instances
	public var image:Image;
	public var parentNodeSpriteInfo:BlobSpritesInfo;

	// Temp vars
	private var p:Point;
	private var f:Number;
	private var scale:Number;


	// ================================================================================================================
	// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

	public function ParticleInfo(__image:Image, __alpha:Number, __radius:Number, __position:Point, __parentNodeSpriteInfo:BlobSpritesInfo) {
		image = __image;
		alpha = __alpha;
		radius = __radius;
		position = __position;
		parentNodeSpriteInfo = __parentNodeSpriteInfo;
		positionGlobal = __position.add(parentNodeSpriteInfo.nodeInfo.position);

		rotationSpeed = (RandomGenerator.getBoolean() ? 1 : -1) * RandomGenerator.getInRange(5, 18);
		scaleCycleTime = RandomGenerator.getInRange(4, 10);
		visibility = 1;
		smoothAnimation = false;

		// Radius and image cannot change later!
		scale = radius / (image.texture.frame == null ? image.texture.width : image.texture.frame.width) * 2;
	}


	// ================================================================================================================
	// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

	public function update(__currentTimeSeconds:Number, __tickDeltaTimeSeconds:Number, __currentTick:int):void {
		image.rotation = __currentTimeSeconds * Math.PI * 2 / rotationSpeed;
		image.alpha = visibility * alpha * parentNodeSpriteInfo.alpha;

		// Makes the particle float at half the amount of influence
		p = parentNodeSpriteInfo.nodeInfo.position;
		var newXPos:Number = (p.x + parentNodeSpriteInfo.offsetX + (parentNodeSpriteInfo.offsetXFloat + parentNodeSpriteInfo.offsetXImpact) * 0.3 + position.x);
		var newYPos:Number = (p.y + parentNodeSpriteInfo.offsetY + (parentNodeSpriteInfo.offsetYFloat + parentNodeSpriteInfo.offsetYImpact) * 0.3 + position.y);

		if (smoothAnimation) {
			image.x += (newXPos - image.x)/2;
			image.y += (newYPos - image.y)/2;
		} else {
			image.x = newXPos;
			image.y = newYPos;
		}

		image.scaleX = image.scaleY = scale * MathUtils.map(Math.sin(__currentTimeSeconds / scaleCycleTime * Math.PI * 2), -1, 1, 0.7, 1);

		// Contract when disappearing
		if (visibility != 1) {
			f = Equations.backOut(visibility);
			image.x = MathUtils.map(f, 1, 0, image.x, parentNodeSpriteInfo.nodeInfo.position.x + parentNodeSpriteInfo.offsetX);
			image.y = MathUtils.map(f, 1, 0, image.y, parentNodeSpriteInfo.nodeInfo.position.y + parentNodeSpriteInfo.offsetY);
		}
	}
}
