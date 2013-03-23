/*

Particle trails in Away3D

Demonstrates:

How to create a complex static parrticle behaviour
How to reuse a particle animation set and particle geometry in multiple animators and meshes
How to create a particle trail

Code by Rob Bateman & Liao Cheng
rob@infiniteturtles.co.uk
http://www.infiniteturtles.co.uk
liaocheng210@126.com

This code is distributed under the MIT License

Copyright (c) The Away Foundation http://www.theawayfoundation.org

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

package {
	import away3d.animators.*;
	import away3d.animators.data.*;
	import away3d.animators.nodes.*;
	import away3d.cameras.*;
	import away3d.containers.*;
	import away3d.controllers.*;
	import away3d.core.base.*;
	import away3d.debug.*;
	import away3d.entities.*;
	import away3d.materials.*;
	import away3d.primitives.*;
	import away3d.tools.helpers.*;
	import away3d.tools.helpers.data.*;
	import away3d.utils.*;

	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	
	[SWF(backgroundColor="#000000", frameRate="60", quality="LOW")]
	
	public class Intermediate_ParticleTrails extends Sprite
	{
		//signature swf
		[Embed(source="/../embeds/signature.swf", symbol="Signature")]
		public var SignatureSwf:Class;
		
		//Particle texture
		[Embed(source="../embeds/cards_suit.png")]
		private var ParticleTexture:Class;
		
		//engine variables
		private var scene:Scene3D;
		private var camera:Camera3D;
		private var view:View3D;
		private var cameraController:HoverController;
		
		//signature variables
		private var Signature:Sprite;
		private var SignatureBitmap:Bitmap;
		
		//material objects
		private var particleMaterial:TextureMaterial;
		
		//particle objects
		private var particleAnimationSet:ParticleAnimationSet;
		private var particleFollowNode:ParticleFollowNode;
		private var particleGeometry:ParticleGeometry;
		
		//scene objects
		private var followTarget1:Object3D;
		private var followTarget2:Object3D;
		private var particleMesh1:Mesh;
		private var particleMesh2:Mesh;
		private var animator1:ParticleAnimator;
		private var animator2:ParticleAnimator;
		
		//navigation variables
		private var angle:Number = 0;
		private var move:Boolean = false;
		private var lastPanAngle:Number;
		private var lastTiltAngle:Number;
		private var lastMouseX:Number;
		private var lastMouseY:Number;
		
		/**
		 * Constructor
		 */
		public function Intermediate_ParticleTrails()
		{
			init();
		}
		
		/**
		 * Global initialise function
		 */
		private function init():void
		{
			initEngine();
			initMaterials();
			initParticles();
			initObjects();
			initListeners();
		}
		
		/**
		 * Initialise the engine
		 */
		private function initEngine():void
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			scene = new Scene3D();
			
			camera = new Camera3D();
			
			view = new View3D();
			view.antiAlias = 4;
			view.scene = scene;
			view.camera = camera;
			
			//setup controller to be used on the camera
			cameraController = new HoverController(camera, null, 45, 20, 1000, 5);
			
			view.addSourceURL("srcview/index.html");
			addChild(view);
			
			//add signature
			Signature = Sprite(new SignatureSwf());
			SignatureBitmap = new Bitmap(new BitmapData(Signature.width, Signature.height, true, 0));
			stage.quality = StageQuality.HIGH;
			SignatureBitmap.bitmapData.draw(Signature);
			stage.quality = StageQuality.LOW;
			addChild(SignatureBitmap);
			
			addChild(new AwayStats(view));
		}
		
		/**
		 * Initialise the materials
		 */
		private function initMaterials():void
		{
			//setup particle material
			particleMaterial = new TextureMaterial(Cast.bitmapTexture(ParticleTexture));
			particleMaterial.blendMode = BlendMode.ADD;
		}
		
		/**
		 * Initialise the particles
		 */
		private function initParticles():void
		{
			//setup the base geometry for one particle
			var plane:Geometry = new PlaneGeometry(30, 30, 1, 1, false);
			
			//create the particle geometry
			var geometrySet:Vector.<Geometry> = new Vector.<Geometry>();
			var setTransforms:Vector.<ParticleGeometryTransform> = new Vector.<ParticleGeometryTransform>();
			var particleTransform:ParticleGeometryTransform;
			var uvTransform:Matrix;
			for (var i:int = 0; i < 1000; i++)
			{
				geometrySet.push(plane);
				particleTransform = new ParticleGeometryTransform();
				uvTransform = new Matrix();
				uvTransform.scale(0.5, 0.5);
				uvTransform.translate(int(Math.random() * 2) / 2, int(Math.random() * 2) / 2);
				particleTransform.UVTransform = uvTransform;
				setTransforms.push(particleTransform);
			}
			
			particleGeometry = ParticleGeometryHelper.generateGeometry(geometrySet, setTransforms);
			
			
			//create the particle animation set
			particleAnimationSet = new ParticleAnimationSet(true, true, true);
			
			//define the particle animations and init function
			particleAnimationSet.addAnimation(new ParticleBillboardNode());
			particleAnimationSet.addAnimation(new ParticleVelocityNode(ParticlePropertiesMode.LOCAL_STATIC));
			particleAnimationSet.addAnimation(new ParticleColorNode(ParticlePropertiesMode.GLOBAL, true, false, false, false, new ColorTransform(), new ColorTransform(1, 1, 1, 0)));
			particleAnimationSet.addAnimation(particleFollowNode = new ParticleFollowNode(true, false));
			particleAnimationSet.initParticleFunc = initParticleProperties;
		}
		
		/**
		 * Initialise the scene objects
		 */
		private function initObjects():void
		{
			//create wireframe axes
			scene.addChild(new WireframeAxesGrid(10,1500));
			
			//create follow targets
			followTarget1 = new Object3D();
			followTarget2 = new Object3D();
			
			//create the particle meshes
			particleMesh1 = new Mesh(particleGeometry, particleMaterial);
			particleMesh1.y = 300;
			scene.addChild(particleMesh1);
			
			particleMesh2 = particleMesh1.clone() as Mesh;
			particleMesh2.y = 300;
			scene.addChild(particleMesh2);
			
			//create and start the particle animators
			animator1 = new ParticleAnimator(particleAnimationSet);
			particleMesh1.animator = animator1;
			animator1.start();
			particleFollowNode.getAnimationState(animator1).followTarget = followTarget1;
			
			animator2 = new ParticleAnimator(particleAnimationSet);
			particleMesh2.animator = animator2;
			animator2.start();
			particleFollowNode.getAnimationState(animator2).followTarget = followTarget2;
		}
		
		/**
		 * Initialise the listeners
		 */
		private function initListeners():void
		{
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.addEventListener(Event.RESIZE, onResize);
			onResize();
		}
		
		
		/**
		 * Initialiser function for particle properties
		 */
		private function initParticleProperties(properties:ParticleProperties):void
		{
			properties.startTime = Math.random()*4.1;
			properties.duration = 4;
			properties[ParticleVelocityNode.VELOCITY_VECTOR3D] = new Vector3D(Math.random() * 100 - 50, Math.random() * 100 - 200, Math.random() * 100 - 50);
		}
		
		/**
		 * Navigation and render loop
		 */
		private function onEnterFrame(event:Event):void
		{
			if (move) {
				cameraController.panAngle = 0.3*(stage.mouseX - lastMouseX) + lastPanAngle;
				cameraController.tiltAngle = 0.3*(stage.mouseY - lastMouseY) + lastTiltAngle;
			}
			
			angle += 0.04;
			followTarget1.x = Math.cos(angle) * 500;
			followTarget1.z = Math.sin(angle) * 500;
			followTarget2.x = Math.sin(angle) * 500;
			
			view.render();
		}
		
		/**
		 * Mouse down listener for navigation
		 */
		private function onMouseDown(event:MouseEvent):void
		{
			lastPanAngle = cameraController.panAngle;
			lastTiltAngle = cameraController.tiltAngle;
			lastMouseX = stage.mouseX;
			lastMouseY = stage.mouseY;
			move = true;
			stage.addEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
		
		/**
		 * Mouse up listener for navigation
		 */
		private function onMouseUp(event:MouseEvent):void
		{
			move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
		
		/**
		 * Mouse stage leave listener for navigation
		 */
		private function onStageMouseLeave(event:Event):void
		{
			move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
		
		/**
		 * stage listener for resize events
		 */
		private function onResize(event:Event = null):void
		{
			view.width = stage.stageWidth;
			view.height = stage.stageHeight;
			SignatureBitmap.y = stage.stageHeight - Signature.height;
		}
	}
}