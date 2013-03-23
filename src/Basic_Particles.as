/*

Basic GPU-based particle animation example in Away3d

Demonstrates:

How to use the ParticleAnimationSet to define static particle behaviour.
How to create particle geometry using the ParticleGeometryHelper class.
How to apply a particle animation to a particle geometry set using ParticleAnimator.
How to create a random spray of particles eminating from a central point.

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
	import away3d.containers.*;
	import away3d.controllers.*;
	import away3d.core.base.*;
	import away3d.debug.*;
	import away3d.entities.*;
	import away3d.materials.*;
	import away3d.primitives.*;
	import away3d.tools.helpers.*;
	import away3d.utils.*;

	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	
	[SWF(backgroundColor="#000000", frameRate="60")]
	public class Basic_Particles extends Sprite
	{
		//signature swf
		[Embed(source="/../embeds/signature.swf", symbol="Signature")]
		private var SignatureSwf:Class;
		
		//particle image
		[Embed(source="/../embeds/blue.png")]
		private var ParticleImg:Class;
		
		//engine variables
		private var _view:View3D;
		private var _cameraController:HoverController;
		
		//signature variables
		private var Signature:Sprite;
		private var SignatureBitmap:Bitmap;
		
		//particle variables
		private var _particleAnimationSet:ParticleAnimationSet;
		private var _particleMesh:Mesh;
		private var _particleAnimator:ParticleAnimator;
		
		//navigation variables
		private var _move:Boolean = false;
		private var _lastPanAngle:Number;
		private var _lastTiltAngle:Number;
		private var _lastMouseX:Number;
		private var _lastMouseY:Number;
		
		/**
		 * Constructor
		 */
		public function Basic_Particles()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			_view = new View3D();
			_view.addSourceURL("srcview/index.html");
			addChild(_view);
			
			//add signature
			Signature = Sprite(new SignatureSwf());
			SignatureBitmap = new Bitmap(new BitmapData(Signature.width, Signature.height, true, 0));
			stage.quality = StageQuality.HIGH;
			SignatureBitmap.bitmapData.draw(Signature);
			stage.quality = StageQuality.LOW;
			addChild(SignatureBitmap);
			
			_cameraController = new HoverController(_view.camera, null, 45, 20, 1000);
			
			addChild(new AwayStats(_view));
			
			//setup the particle geometry
			var plane:Geometry = new PlaneGeometry(10, 10, 1, 1, false);
			var geometrySet:Vector.<Geometry> = new Vector.<Geometry>();
			for (var i:int = 0; i < 20000; i++)
				geometrySet.push(plane);
			
			//setup the particle animation set
			_particleAnimationSet = new ParticleAnimationSet(true, true);
			_particleAnimationSet.addAnimation(new ParticleBillboardNode());
			_particleAnimationSet.addAnimation(new ParticleVelocityNode(ParticlePropertiesMode.LOCAL_STATIC));
			_particleAnimationSet.initParticleFunc = initParticleFunc;
			
			//setup the particle material
			var material:TextureMaterial = new TextureMaterial(Cast.bitmapTexture(ParticleImg));
			material.blendMode = BlendMode.ADD;
			
			//setup the particle animator and mesh
			_particleAnimator = new ParticleAnimator(_particleAnimationSet);
			_particleMesh = new Mesh(ParticleGeometryHelper.generateGeometry(geometrySet), material);
			_particleMesh.animator = _particleAnimator;
			_view.scene.addChild(_particleMesh);
			
			//start the animation
			_particleAnimator.start();
			
			//add listeners
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.addEventListener(Event.RESIZE, onResize);
			onResize();
		}
		
		/**
		 * Initialiser function for particle properties
		 */
		private function initParticleFunc(prop:ParticleProperties):void
		{
			prop.startTime = Math.random()*5 - 5;
			prop.duration = 5;
			var degree1:Number = Math.random() * Math.PI ;
			var degree2:Number = Math.random() * Math.PI * 2;
			var r:Number = Math.random() * 50 + 400;
			prop[ParticleVelocityNode.VELOCITY_VECTOR3D] = new Vector3D(r * Math.sin(degree1) * Math.cos(degree2), r * Math.cos(degree1) * Math.cos(degree2), r * Math.sin(degree2));
		}
		
		/**
		 * Navigation and render loop
		 */		
		private function onEnterFrame(event:Event):void
		{
			if (_move)
			{
				_cameraController.panAngle = 0.3*(stage.mouseX - _lastMouseX) + _lastPanAngle;
				_cameraController.tiltAngle = 0.3*(stage.mouseY - _lastMouseY) + _lastTiltAngle;
			}
			_view.render();
		}
		
		/**
		 * Mouse down listener for navigation
		 */		
		private function onMouseDown(event:MouseEvent):void
		{
			_lastPanAngle = _cameraController.panAngle;
			_lastTiltAngle = _cameraController.tiltAngle;
			_lastMouseX = stage.mouseX;
			_lastMouseY = stage.mouseY;
			_move = true;
			stage.addEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
		
		/**
		 * Mouse up listener for navigation
		 */		
		private function onMouseUp(event:MouseEvent):void
		{
			_move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
		
		/**
		 * Mouse stage leave listener for navigation
		 */
		private function onStageMouseLeave(event:Event):void
		{
			_move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
		
		/**
		 * stage listener for resize events
		 */
		private function onResize(event:Event = null):void
		{
			_view.width = stage.stageWidth;
			_view.height = stage.stageHeight;
			SignatureBitmap.y = stage.stageHeight - Signature.height;
		}
	}
}
