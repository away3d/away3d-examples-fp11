/*

Vertex animation example in Away3d using the MD2 format

Demonstrates:

How to use the AssetLibrary class to load an embedded internal md2 model.
How to clone an asset from the AssetLibrary and apply different mateirals.
How to load animations into an animation set and apply to individual meshes.

Code by Rob Bateman
rob@infiniteturtles.co.uk
http://www.infiniteturtles.co.uk

Perelith Knight, by James Green (no email given)

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
	import away3d.animators.*;
	import away3d.containers.*;
	import away3d.controllers.*;
	import away3d.debug.*;
	import away3d.entities.*;
	import away3d.events.*;
	import away3d.library.*;
	import away3d.library.assets.*;
	import away3d.lights.*;
	import away3d.loaders.parsers.*;
	import away3d.materials.*;
	import away3d.materials.lightpickers.*;
	import away3d.materials.methods.*;
	import away3d.primitives.*;
	import away3d.utils.Cast;
	
	import flash.display.*;
	import flash.events.*;
	import flash.filters.*;
	import flash.geom.*;
	import flash.text.*;
	import flash.ui.*;
	
	import utils.*;
	
	[SWF(backgroundColor="#000000", frameRate="30", quality="LOW")]
	public class Intermediate_PerelithKnightMD2 extends Sprite
	{
		//signature swf
		[Embed(source="/../embeds/signature.swf", symbol="Signature")]
		public static var SignatureSwf:Class;
		
		//plane textures
		[Embed(source="/../embeds/floor_diffuse.jpg")]
		public static var FloorDiffuse:Class;
		
		//Perelith Knight diffuse texture 1
		[Embed(source="/../embeds/pknight/pknight1.png")]
		public static var PKnightTexture1:Class;
		
		//Perelith Knight diffuse texture 2
		[Embed(source="/../embeds/pknight/pknight2.png")]
		public static var PKnightTexture2:Class;
		
		//Perelith Knight diffuse texture 3
		[Embed(source="/../embeds/pknight/pknight3.png")]
		public static var PKnightTexture3:Class;
		
		//Perelith Knight diffuse texture 4
		[Embed(source="/../embeds/pknight/pknight4.png")]
		public static var PKnightTexture4:Class;
		
		//Perelith Knight model
		[Embed(source="/../embeds/pknight/pknight.md2", mimeType="application/octet-stream")]
		public static var PKnightModel:Class;
		
		//array of textures for random sampling
		private var _pKnightTextures:Vector.<Bitmap> = Vector.<Bitmap>([new PKnightTexture1(), new PKnightTexture2(), new PKnightTexture3(), new PKnightTexture4()]);
		private var _pKnightMaterials:Vector.<TextureMaterial> = new Vector.<TextureMaterial>();
		
		//engine variables
		private var _view:View3D;
		private var _cameraController:HoverController;
		
		//signature variables
		private var _signature:Sprite;
		private var _signatureBitmap:Bitmap;
		
		//stats
		private var _stats:AwayStats;
		
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
		private var _keyUp:Boolean;
		private var _keyDown:Boolean;
		private var _keyLeft:Boolean;
		private var _keyRight:Boolean;
		private var _lookAtPosition:Vector3D = new Vector3D();
		private var _animationSet:VertexAnimationSet;
		
		/**
		 * Constructor
		 */
		public function Intermediate_PerelithKnightMD2()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			//setup the view
			_view = new View3D();
			_view.addSourceURL("srcview/index.html");
			addChild(_view);
			
			//setup the camera for optimal rendering
			_view.camera.lens.far = 5000;
			
			//setup controller to be used on the camera
			_cameraController = new HoverController(_view.camera, null, 45, 20, 2000, 5);
			
			//setup the help text
			var text:TextField = new TextField();
			text.defaultTextFormat = new TextFormat("Verdana", 11, 0xFFFFFF);
			text.embedFonts = true;
			text.antiAliasType = AntiAliasType.ADVANCED;
			text.gridFitType = GridFitType.PIXEL;
			text.width = 240;
			text.height = 100;
			text.selectable = false;
			text.mouseEnabled = false;
			text.text = "Click and drag - rotate\n" + 
				"Cursor keys / WSAD / ZSQD - move\n" + 
				"Scroll wheel - zoom";
			
			text.filters = [new DropShadowFilter(1, 45, 0x0, 1, 0, 0)];
			
			addChild(text);
			
			//setup the lights for the scene
			_light = new DirectionalLight(-0.5, -1, -1);
			_light.ambient = 0.4;
			_lightPicker = new StaticLightPicker([_light]);
			_view.scene.addChild(_light);
			
			//setup parser to be used on AssetLibrary
			AssetLibrary.loadData(new PKnightModel(), null, null, new MD2Parser());
			AssetLibrary.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
			AssetLibrary.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceComplete);
			
			//create a global shadow map method
			_shadowMapMethod = new FilteredShadowMapMethod(_light);
			
			//setup floor material
			_floorMaterial = new TextureMaterial(Cast.bitmapTexture(FloorDiffuse));
			_floorMaterial.lightPicker = _lightPicker;
			_floorMaterial.specular = 0;
			_floorMaterial.ambient = 1;
			_floorMaterial.shadowMethod = _shadowMapMethod;
			_floorMaterial.repeat = true;
			
			//setup Perelith Knight materials
			for (var i:uint = 0; i < _pKnightTextures.length; i++) {
				var bitmapData:BitmapData = _pKnightTextures[i].bitmapData;
				var knightMaterial:TextureMaterial = new TextureMaterial(Cast.bitmapTexture(bitmapData));
				knightMaterial.normalMap = Cast.bitmapTexture(BitmapFilterEffects.normalMap(bitmapData));
				knightMaterial.specularMap = Cast.bitmapTexture(BitmapFilterEffects.outline(bitmapData));
				knightMaterial.lightPicker = _lightPicker;
				knightMaterial.gloss = 30;
				knightMaterial.specular = 1;
				knightMaterial.ambient = 1;
				knightMaterial.shadowMethod = _shadowMapMethod;
				_pKnightMaterials.push(knightMaterial);
			}
			
			//setup the floor
			_floor = new Mesh(new PlaneGeometry(5000, 5000), _floorMaterial);
			_floor.geometry.scaleUV(5, 5);
			
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
			addChild(_stats = new AwayStats(_view));
			
			//add listeners
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.addEventListener(Event.MOUSE_LEAVE, onMouseUp);
			stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
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
			
			if (_keyUp)
				_lookAtPosition.x -= 10;
			if (_keyDown)
				_lookAtPosition.x += 10;
			if (_keyLeft)
				_lookAtPosition.z -= 10;
			if (_keyRight)
				_lookAtPosition.z += 10;
			
			_cameraController.lookAtPosition = _lookAtPosition;
			
			_view.render();
		}
		
		/**
		 * Listener function for asset complete event on loader
		 */
		private function onAssetComplete(event:AssetEvent):void
		{
			if (event.asset.assetType == AssetType.MESH) {
				_mesh = event.asset as Mesh;
				
				//adjust the ogre mesh
				_mesh.y = 120;
				_mesh.scale(5);
				
			} else if (event.asset.assetType == AssetType.ANIMATION_SET) {
				_animationSet = event.asset as VertexAnimationSet;
			}
		}
		
		/**
		 * Listener function for resource complete event on loader
		 */
		private function onResourceComplete(event:LoaderEvent):void
		{
			//create 20 x 20 different clones of the ogre
			var numWide:Number = 20;
			var numDeep:Number = 20;
			var k:uint = 0;
			for (var i:uint = 0; i < numWide; i++) {
				for (var j:uint = 0; j < numDeep; j++) {
					//clone mesh
					var clone:Mesh = _mesh.clone() as Mesh;
					clone.x = (i-(numWide-1)/2)*5000/numWide;
					clone.z = (j-(numDeep-1)/2)*5000/numDeep;
					clone.castsShadows = true;
					clone.material = _pKnightMaterials[uint(Math.random()*_pKnightMaterials.length)];
					_view.scene.addChild(clone);
					
					//create animator
					var vertexAnimator:VertexAnimator = new VertexAnimator(_animationSet);
					
					//play specified state
					vertexAnimator.play(_animationSet.animationNames[int(Math.random()*_animationSet.animationNames.length)], null, Math.random()*1000);
					clone.animator = vertexAnimator;
					k++;
				}
			}
		}
		/**
		 * Key down listener for animation
		 */
		private function onKeyDown(event:KeyboardEvent):void
		{
			switch (event.keyCode) {
				case Keyboard.UP: 
				case Keyboard.W: 
				case Keyboard.Z: //fr
					_keyUp = true;
					break;
				case Keyboard.DOWN: 
				case Keyboard.S: 
					_keyDown = true;
					break;
				case Keyboard.LEFT: 
				case Keyboard.A: 
				case Keyboard.Q: //fr
					_keyLeft = true;
					break;
				case Keyboard.RIGHT: 
				case Keyboard.D: 
					_keyRight = true;
					break;
			}
		}
		
		/**
		 * Key up listener
		 */
		private function onKeyUp(event:KeyboardEvent):void
		{
			switch (event.keyCode) {
				case Keyboard.UP: 
				case Keyboard.W: 
				case Keyboard.Z: //fr
					_keyUp = false;
					break;
				case Keyboard.DOWN: 
				case Keyboard.S: 
					_keyDown = false;
					break;
				case Keyboard.LEFT: 
				case Keyboard.A: 
				case Keyboard.Q: //fr
					_keyLeft = false;
					break;
				case Keyboard.RIGHT: 
				case Keyboard.D: 
					_keyRight = false;
					break;
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
		}
		
		/**
		 * Mouse up listener for navigation
		 */
		private function onMouseUp(event:Event):void
		{
			_move = false;
		}
		
		/**
		 * Mouse wheel listener for navigation
		 */
		private function onMouseWheel(ev:MouseEvent):void
		{
			_cameraController.distance -= ev.delta * 5;
			
			if (_cameraController.distance < 100)
				_cameraController.distance = 100;
			else if (_cameraController.distance > 2000)
				_cameraController.distance = 2000;
		}
		
		/**
		 * Stage listener for resize events
		 */
		private function onResize(event:Event = null):void
		{
			_view.width = stage.stageWidth;
			_view.height = stage.stageHeight;
			_signatureBitmap.y = stage.stageHeight - _signature.height;
			_stats.x = stage.stageWidth - _stats.width;
		}
	}
}
