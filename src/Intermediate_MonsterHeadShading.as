/*

3D Head scan example in Away3d

Demonstrates:

How to use the AssetLibrary to load an internal OBJ model.
How to set custom material methods on a model.
How a natural skin texture can be achived with sub-surface diffuse shading and fresnel specular shading.

Code by Rob Bateman & David Lenaerts
rob@infiniteturtles.co.uk
http://www.infiniteturtles.co.uk
david.lenaerts@gmail.com
http://www.derschmale.com

Model by Lee Perry-Smith, based on a work at triplegangers.com,  licensed under CC

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

package
{
	import away3d.cameras.*;
	import away3d.containers.*;
	import away3d.controllers.*;
	import away3d.core.base.*;
	import away3d.debug.*;
	import away3d.entities.*;
	import away3d.events.*;
	import away3d.library.*;
	import away3d.library.assets.*;
	import away3d.lights.*;
	import away3d.lights.shadowmaps.*;
	import away3d.loaders.misc.*;
	import away3d.loaders.parsers.*;
	import away3d.materials.*;
	import away3d.materials.lightpickers.*;
	import away3d.materials.methods.*;
	import away3d.utils.*;
	
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import flash.utils.*;
	
	[SWF(backgroundColor="#000000", frameRate="30", quality="LOW")]
	
	public class Intermediate_MonsterHeadShading extends Sprite
	{
		//signature swf
		[Embed(source="/../embeds/signature.swf", symbol="Signature")]
		public var SignatureSwf:Class;
		
		//Infinite, 3D head model
		[Embed(source="/../embeds/head.obj", mimeType="application/octet-stream")]
		private var HeadModel:Class;
		
		//
		[Embed(source="/../embeds/diffuseGradient.jpg")]
		private var DiffuseGradient : Class;
		
		//Diffuse map texture
		[Embed(source="/../embeds/monsterhead_diffuse.jpg")]
		private var Diffuse:Class;
		
		//Specular map texture
		[Embed(source="/../embeds/monsterhead_specular.jpg")]
		private var Specular:Class;
		
		//Normal map texture
		[Embed(source="/../embeds/monsterhead_normals.jpg")]
		private var Normal:Class;
		
		//engine variables
		private var scene:Scene3D;
		private var camera:Camera3D;
		private var view:View3D;
		private var cameraController:HoverController;
		
		//signature variables
		private var Signature:Sprite;
		private var SignatureBitmap:Bitmap;
		
		//material objects
		private var headMaterial:TextureMultiPassMaterial;
		private var softShadowMethod:SoftShadowMapMethod;
		private var fresnelMethod:FresnelSpecularMethod;
		private var diffuseMethod:BasicDiffuseMethod;
		private var specularMethod:BasicSpecularMethod;
		
		//scene objects
		private var blueLight:PointLight;
		private var redLight:PointLight;
		private var directionalLight:DirectionalLight;
		private var lightPicker:StaticLightPicker;
		private var headModel:Mesh;
		private var advancedMethod:Boolean = true;
		
		//navigation variables
		private var move:Boolean = false;
		private var lastPanAngle:Number;
		private var lastTiltAngle:Number;
		private var lastMouseX:Number;
		private var lastMouseY:Number;
		
		/**
		 * Constructor
		 */
		public function Intermediate_MonsterHeadShading()
		{
			init();
		}
		
		/**
		 * Global initialise function
		 */
		private function init():void
		{
			initEngine();
			initLights();
			initMaterials();
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
			camera.lens.near = 20;
			camera.lens.far = 1000;
			
			view = new View3D();
			view.antiAlias = 4;
			view.scene = scene;
			view.camera = camera;
			
			//setup controller to be used on the camera
			cameraController = new HoverController(camera, null, 225, 10, 800);
			cameraController.yFactor = 1;
			
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
		 * Initialise the lights in a scene
		 */
		private function initLights():void
		{
			var initialAzimuth : Number = .6;
			var initialArc : Number = 2;
			var x : Number = Math.sin(initialAzimuth)*Math.cos(initialArc);
			var y : Number = -Math.cos(initialAzimuth);
			var z : Number = Math.sin(initialAzimuth)*Math.sin(initialArc);
			
			// main light casting the shadows
			directionalLight = new DirectionalLight(x, y, z);
			directionalLight.color = 0xffeedd;
			directionalLight.ambient = 1;
			directionalLight.specular = .3;
			directionalLight.ambientColor = 0x101025;
			directionalLight.castsShadows = true;
			DirectionalShadowMapper(directionalLight.shadowMapper).lightOffset = 1000;
			scene.addChild(directionalLight);
			
			// blue point light coming from the right
			blueLight = new PointLight();
			blueLight.color = 0x4080ff;
			blueLight.x = 3000;
			blueLight.z = 700;
			blueLight.y = 20;
			scene.addChild(blueLight);
			
			// red light coming from the left
			redLight = new PointLight();
			redLight.color = 0x802010;
			redLight.x = -2000;
			redLight.z = 800;
			redLight.y = -400;
			scene.addChild(redLight);
			
			lightPicker = new StaticLightPicker([directionalLight, blueLight, redLight]);
			
		}
		
		/**
		 * Initialise the materials
		 */
		private function initMaterials():void
		{
			//setup custom multipass material
			headMaterial = new TextureMultiPassMaterial(Cast.bitmapTexture(Diffuse));
			headMaterial.normalMap = Cast.bitmapTexture(Normal);
			headMaterial.lightPicker = lightPicker;
			headMaterial.ambientColor = 0x303040;
			
			// create soft shadows with a lot of samples for best results. With the current method setup, any more samples would fail to compile
			softShadowMethod = new SoftShadowMapMethod(directionalLight, 29);
			softShadowMethod.range = 3;	// the sample radius defines the softness of the shadows
			softShadowMethod.epsilon = .005;
			headMaterial.shadowMethod = softShadowMethod;
			
			// create specular reflections that are stronger from the sides
			fresnelMethod = new FresnelSpecularMethod(true);
			fresnelMethod.fresnelPower = 3;
			headMaterial.specularMethod = fresnelMethod;
			headMaterial.specularMap = Cast.bitmapTexture(Specular);
			headMaterial.specular = 3;
			headMaterial.gloss = 10;
			
			// very low-cost and crude subsurface scattering for diffuse shading
			headMaterial.diffuseMethod = new GradientDiffuseMethod(Cast.bitmapTexture(DiffuseGradient));
		}
		
		/**
		 * Initialise the scene objects
		 */
		private function initObjects():void
		{
			//enable the AWD parser for use
			AssetLibrary.enableParser(AWDParser);
			
			//ignore dependencies
			var assetLoaderContext:AssetLoaderContext = new AssetLoaderContext(false);
			assetLoaderContext.includeDependencies
			//setup load
			AssetLibrary.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
			AssetLibrary.load(new URLRequest("assets/MonsterHead.awd"), assetLoaderContext);
		}
		
		/**
		 * Initialise the listeners
		 */
		private function initListeners():void
		{
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			stage.addEventListener(Event.RESIZE, onResize);
			onResize();
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
			
			view.render();
		}
		
		/**
		 * Listener function for asset complete event on loader
		 */
		private function onAssetComplete(event:AssetEvent):void
		{
			if (event.asset.assetType == AssetType.MESH) {
				headModel = event.asset as Mesh;
				headModel.geometry.scale(4); //TODO scale cannot be performed on mesh when using sub-surface diffuse method
				headModel.y = -20;
				
				var subMesh:SubMesh;
				for each (subMesh in headModel.subMeshes)
					subMesh.material = headMaterial;
				
				scene.addChild(headModel);
			}
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
		 * Key up listener for swapping between standard diffuse & specular shading, and sub-surface diffuse shading with fresnel specular shading
		 */
		private function onKeyUp(event:KeyboardEvent):void
		{
			advancedMethod = !advancedMethod;
			
			headMaterial.gloss = (advancedMethod)? 10 : 50;
			headMaterial.specular = (advancedMethod)? 3 : 1;
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