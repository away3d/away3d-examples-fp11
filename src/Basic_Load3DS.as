/*

3ds file loading example in Away3d

Demonstrates:

How to use the Loader3D object to load an embedded internal 3ds model.
How to map an external asset reference inside a file to an internal embedded asset
How to extract material data and use it to set custom material properties on a model.

Code by Rob Bateman
rob@infiniteturtles.co.uk
http://www.infiniteturtles.co.uk

This code is distributed under the MIT License

Copyright (c)  

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
	import away3d.loaders.*;
	import away3d.loaders.misc.*;
	import away3d.loaders.parsers.*;
	import away3d.materials.*;
	import away3d.materials.lightpickers.StaticLightPicker;
	import away3d.materials.methods.*;
	import away3d.primitives.*;
	import away3d.textures.*;
	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.text.*;
	import flash.utils.*;
	
	[SWF(backgroundColor="#000000", frameRate="30", quality="LOW")]
	
	public class Basic_Load3DS extends Sprite
	{
		//signature swf
		[Embed(source="/../embeds/signature.swf", symbol="Signature")]
		public var SignatureSwf:Class;
		
		//solider ant texture
		[Embed(source="/../embeds/soldier_ant.jpg")]
		private var AntTexture:Class;
		
		//solider ant model
		[Embed(source="/../embeds/soldier_ant.3ds",mimeType="application/octet-stream")]
		private var AntModel:Class;
		
		//ground texture
		[Embed(source="/../embeds/CoarseRedSand.jpg")]
		private var SandTexture:Class;
		
		//engine variables
		private var scene:Scene3D;
		private var camera:Camera3D;
		private var view:View3D;
		private var cameraController:HoverController;
		
		//signature variables
		private var Signature:Sprite;
		private var SignatureBitmap:Bitmap;
		
		//material objects
		private var groundMaterial:TextureMaterial;
		
		//scene objects
		private var light:DirectionalLight;
		private var lightPicker:StaticLightPicker;
		private var direction:Vector3D;
		private var loader:Loader3D;
		private var ground:Mesh;
		
		//navigation variables
		private var move:Boolean = false;
		private var lastPanAngle:Number;
		private var lastTiltAngle:Number;
		private var lastMouseX:Number;
		private var lastMouseY:Number;
		
		/**
		 * Constructor
		 */
		public function Basic_Load3DS()
		{
			init();
		}
		
		/**
		 * Global initialise function
		 */
		private function init():void
		{
			initEngine();
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
			
			//setup camera for optimal shadow rendering
			camera = new Camera3D();
			camera.lens.far = 2100;
			
			view = new View3D();
			view.scene = scene;
			view.camera = camera;
			
			//setup controller to be used on the camera
			cameraController = new HoverController(camera, null, 45, 20, 1000, 10);
			
			//setup parser to be used on loader3D
			Parsers.enableAllBundled();
			
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
		 * Initialise the scene objects
		 */
		private function initObjects():void
		{
			
			light = new DirectionalLight(-1, -1, 1);
			direction = new Vector3D(-1, -1, 1);
			lightPicker = new StaticLightPicker([light]);
			
			scene.addChild(light);
			
			var assetLoaderContext:AssetLoaderContext = new AssetLoaderContext();
			assetLoaderContext.mapUrlToData("texture.jpg", new AntTexture());
			
			loader = new Loader3D();
			loader.scale(300);
			loader.z = -200;
			loader.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
			loader.loadData(new AntModel(), assetLoaderContext);
			
			scene.addChild(loader);
			
			groundMaterial = new TextureMaterial(new BitmapTexture((new SandTexture()).bitmapData));
			groundMaterial.shadowMethod = new FilteredShadowMapMethod(light);
			groundMaterial.lightPicker = lightPicker;
			groundMaterial.specular = 0;
			ground = new Mesh(new PlaneGeometry(1000, 1000), groundMaterial);
			scene.addChild(ground);
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
		 * Navigation and render loop
		 */
		private function onEnterFrame(event:Event):void
		{
			if (move) {
				cameraController.panAngle = 0.3*(stage.mouseX - lastMouseX) + lastPanAngle;
				cameraController.tiltAngle = 0.3*(stage.mouseY - lastMouseY) + lastTiltAngle;
			}
			
			direction.x = -Math.sin(getTimer()/4000);
			direction.z = -Math.cos(getTimer()/4000);
			light.direction = direction;
			
			view.render();
		}
		
		/**
		 * Listener function for asset complete event on loader
		 */
		private function onAssetComplete(event:AssetEvent):void
		{
			if (event.asset.assetType == AssetType.MESH) {
				var mesh:Mesh = event.asset as Mesh;
				mesh.castsShadows = true;
			} else if (event.asset.assetType == AssetType.MATERIAL) {
				var material:TextureMaterial = event.asset as TextureMaterial;
				material.shadowMethod = new FilteredShadowMapMethod(light);
				material.lightPicker = lightPicker;
				material.gloss = 30;
				material.specular = 1;
				material.ambientColor = 0x303040;
				material.ambient = 1;
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
