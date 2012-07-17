/*

MD2 file loading example in Away3d

Demonstrates:

How to use the AssetLibrary class to load an embedded internal md2 model.
How to map an external asset reference inside a file to an internal embedded asset.
How to clone an asset from the AssetLibrary and apply different animation sequences.

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
	import away3d.materials.methods.FilteredShadowMapMethod;
	import away3d.animators.*;
	import away3d.containers.*;
	import away3d.controllers.*;
	import away3d.debug.*;
	import away3d.entities.*;
	import away3d.events.*;
	import away3d.library.*;
	import away3d.library.assets.*;
	import away3d.lights.*;
	import away3d.loaders.misc.*;
	import away3d.loaders.parsers.*;
	import away3d.materials.*;
	import away3d.materials.lightpickers.*;
	import away3d.primitives.*;
	import away3d.utils.Cast;
	
	import flash.display.*;
	import flash.events.*;
	
	[SWF(backgroundColor="#000000", frameRate="30", quality="LOW")]
	public class Basic_LoadMD2 extends Sprite
	{
		//signature swf
		[Embed(source="/../embeds/signature.swf", symbol="Signature")]
		public static var SignatureSwf:Class;
		
		//plane textures
		[Embed(source="/../embeds/floor_diffuse.jpg")]
		public static var FloorDiffuse:Class;
		
		//ogre diffuse texture
		[Embed(source="/../embeds/ogre/ogre_diffuse.jpg")]
		public static var OgreDiffuse:Class;
		
		//ogre normal map texture
		[Embed(source="/../embeds/ogre/ogre_normals.png")]
		public static var OgreNormals:Class;
		
		//ogre specular map texture
		[Embed(source="/../embeds/ogre/ogre_specular.jpg")]
		public static var OgreSpecular:Class;
		
		//solider ant model
		[Embed(source="/../embeds/ogre/ogre.md2",mimeType="application/octet-stream")]
		public static var OgreModel:Class;
		
		//pre-cached names of the states we want to use
		public static var stateNames:Array = ["stand", "sniffsniff", "deathc", "attack", "crattack", "run", "paina", "cwalk", "crpain", "cstand", "deathb", "salute_alt", "painc", "painb", "flip", "jump"];
		
		//engine variables
		private var _view:View3D;
		private var _cameraController:HoverController;
		
		//signature variables
		private var _signature:Sprite;
		private var _signatureBitmap:Bitmap;
		
		//light objects
		private var _light:DirectionalLight;
		private var _lightPicker:StaticLightPicker;
		
		//material objects
		private var _floorMaterial:TextureMaterial;
		private var _shadowMapMethod:FilteredShadowMapMethod;
		
		//scene objects
		private var _floor:Mesh;
		private var _mesh:Mesh;
		
		//navigation variables
		private var _move:Boolean = false;
		private var _lastPanAngle:Number;
		private var _lastTiltAngle:Number;
		private var _lastMouseX:Number;
		private var _lastMouseY:Number;
		private var _animationSet:VertexAnimationSet;
		
		/**
		 * Constructor
		 */
		public function Basic_LoadMD2()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			//setup the view
			_view = new View3D();
			_view.addSourceURL("srcview/index.html");
			addChild(_view);
			
			//setup controller to be used on the camera
			_cameraController = new HoverController(_view.camera, null, 45, 20, 1000, -90);
			
			//setup the lights for the scene
			_light = new DirectionalLight(0, -1, -1);
			_lightPicker = new StaticLightPicker([_light]);
			_view.scene.addChild(_light);
			
			//setup the url map for textures in the 3ds file
			var assetLoaderContext:AssetLoaderContext = new AssetLoaderContext();
			assetLoaderContext.mapUrlToData("igdosh.jpg", new OgreDiffuse());
			
			//setup parser to be used on AssetLibrary
			AssetLibrary.loadData(new OgreModel(), assetLoaderContext, null, new MD2Parser());
			AssetLibrary.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
			
			//setup materials
			_shadowMapMethod = new FilteredShadowMapMethod(_light);
			_floorMaterial = new TextureMaterial(Cast.bitmapTexture(FloorDiffuse));
			_floorMaterial.lightPicker = _lightPicker;
			_floorMaterial.specular = 0;
			_floorMaterial.shadowMethod = _shadowMapMethod;
			_floor = new Mesh(new PlaneGeometry(1000, 1000), _floorMaterial);
			
			//setup the scene
			_view.scene.addChild(_floor);
			
			//add signature
			_signature = new SignatureSwf();
			_signatureBitmap = new Bitmap(new BitmapData(_signature.width, _signature.height, true, 0));
			stage.quality = StageQuality.HIGH;
			_signatureBitmap.bitmapData.draw(_signature);
			stage.quality = StageQuality.LOW;
			addChild(_signatureBitmap);
			
			//add stats panel
			addChild(new AwayStats(_view));
			
			//add listeners
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
			if (_move) {
				_cameraController.panAngle = 0.3*(stage.mouseX - _lastMouseX) + _lastPanAngle;
				_cameraController.tiltAngle = 0.3*(stage.mouseY - _lastMouseY) + _lastTiltAngle;
			}
			
			_view.render();
		}
		
		/**
		 * Listener function for asset complete event on loader
		 */
		private function onAssetComplete(event:AssetEvent):void
		{
			if (event.asset.assetType == AssetType.MESH) {
				_mesh = event.asset as Mesh;
				
				//adjust the ogre material
				var material:TextureMaterial = _mesh.material as TextureMaterial;
				material.specularMap = Cast.bitmapTexture(OgreSpecular);
				material.normalMap = Cast.bitmapTexture(OgreNormals);
				material.lightPicker = _lightPicker;
				material.gloss = 30;
				material.specular = 1;
				material.ambientColor = 0x303040;
				material.ambient = 1;
				material.shadowMethod = _shadowMapMethod;
				
				//adjust the ogre mesh
				_mesh.y = 120;
				_mesh.scale(5);
				
				
				//create 16 different clones of the ogre
				var numWide:Number = 4;
				var numDeep:Number = 4;
				var k:uint = 0;
				for (var i:uint = 0; i < numWide; i++) {
					for (var j:uint = 0; j < numDeep; j++) {
						//clone mesh
						var clone:Mesh = _mesh.clone() as Mesh;
						clone.x = (i-(numWide-1)/2)*1000/numWide;
						clone.z = (j-(numDeep-1)/2)*1000/numDeep;
						clone.castsShadows = true;
						
						_view.scene.addChild(clone);
						
						//create animator
						var vertexAnimator:VertexAnimator = new VertexAnimator(_animationSet);
						
						//play specified state
						vertexAnimator.play(stateNames[i*numDeep + j]);
						clone.animator = vertexAnimator;
						k++;
					}
				}
			} else if (event.asset.assetType == AssetType.ANIMATION_SET) {
				_animationSet = event.asset as VertexAnimationSet;
			}
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
			_signatureBitmap.y = stage.stageHeight - _signature.height;
		}
	}
}
