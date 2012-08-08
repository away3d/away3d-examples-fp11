/*

Globe example in Away3d

Demonstrates:

How to create a textured sphere.
How to use containers to rotate an object.
How to use the PhongBitmapMaterial.

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
	import away3d.arcane;
	import away3d.cameras.*;
	import away3d.containers.*;
	import away3d.controllers.*;
	import away3d.debug.*;
	import away3d.entities.*;
	import away3d.lights.*;
	import away3d.loaders.parsers.*;
	import away3d.materials.*;
	import away3d.materials.lightpickers.*;
	import away3d.materials.methods.*;
	import away3d.materials.utils.*;
	import away3d.primitives.*;
	import away3d.textures.*;
	import away3d.utils.*;
	
	import flash.display.*;
	import flash.events.*;
	import flash.filters.*;
	import flash.geom.*;
	import flash.text.*;
	import flash.ui.*;
	
	use namespace arcane;
	
	[SWF(backgroundColor="#000000", frameRate="30", quality="BEST")]
	public class Intermediate_Globe extends Sprite
	{
		//night map for globe
		[Embed(source="/../embeds/globe/land_lights_16384.jpg")]
    	public static var EarthNight:Class;
		
		//diffuse map for globe
		[Embed(source="/../embeds/globe/land_ocean_ice_2048_match.jpg")]
		public static var EarthDiffuse:Class;
		
		//normal map for globe
		[Embed(source="/../embeds/globe/EarthNormal.png")]
		public static var EarthNormals:Class;
		
		//specular map for globe
		[Embed(source="/../embeds/globe/earth_specular_2048.jpg")]
		public static var EarthSpecular:Class;
		
		//diffuse map for globe
		[Embed(source="/../embeds/globe/cloud_combined_2048.jpg")]
		public static var SkyDiffuse:Class;
		
		//skybox textures
		[Embed(source="/../embeds/skybox/space_posX.jpg")]
		private var PosX:Class;
		[Embed(source="/../embeds/skybox/space_negX.jpg")]
		private var NegX:Class;
		[Embed(source="/../embeds/skybox/space_posY.jpg")]
		private var PosY:Class;
		[Embed(source="/../embeds/skybox/space_negY.jpg")]
		private var NegY:Class;
		[Embed(source="/../embeds/skybox/space_posZ.jpg")]
		private var PosZ:Class;
		[Embed(source="/../embeds/skybox/space_negZ.jpg")]
		private var NegZ:Class;
		
		//lens flare
		[Embed(source="/../embeds/lensflare/flare0.jpg")]
		private var Flare0:Class;
		[Embed(source="/../embeds/lensflare/flare1.jpg")]
		private var Flare1:Class;
		[Embed(source="/../embeds/lensflare/flare2.jpg")]
		private var Flare2:Class;
		[Embed(source="/../embeds/lensflare/flare3.jpg")]
		private var Flare3:Class;
		[Embed(source="/../embeds/lensflare/flare4.jpg")]
		private var Flare4:Class;
		[Embed(source="/../embeds/lensflare/flare5.jpg")]
		private var Flare5:Class;
		[Embed(source="/../embeds/lensflare/flare6.jpg")]
		private var Flare6:Class;
		[Embed(source="/../embeds/lensflare/flare7.jpg")]
		private var Flare7:Class;
		[Embed(source="/../embeds/lensflare/flare8.jpg")]
		private var Flare8:Class;
		[Embed(source="/../embeds/lensflare/flare9.jpg")]
		private var Flare9:Class;
		[Embed(source="/../embeds/lensflare/flare10.jpg")]
		private var Flare10:Class;
		[Embed(source="/../embeds/lensflare/flare11.jpg")]
		private var Flare11:Class;
		[Embed(source="/../embeds/lensflare/flare12.jpg")]
		private var Flare12:Class;
		
    	//signature swf
    	[Embed(source="/../embeds/signature.swf", symbol="Signature")]
    	public var SignatureSwf:Class;
		
		//engine variables
		private var scene:Scene3D;
		private var camera:Camera3D;
		private var view:View3D;
		private var cameraController:HoverController;
		private var awayStats:AwayStats;
		
		//signature variables
		private var Signature:Sprite;
		private var SignatureBitmap:Bitmap;
		
		//material objects
		private var sunMaterial:TextureMaterial;
		private var groundMaterial:TextureMaterial;
		private var cloudMaterial:TextureMaterial;
		private var atmosphereMaterial:ColorMaterial;
		private var atmosphereDiffuseMethod:BasicDiffuseMethod;
		private var atmosphereSpecularMethod:BasicSpecularMethod;
		private var cubeTexture:BitmapCubeTexture;
		
		//scene objects
		private var sun:Sprite3D;
		private var earth:Mesh;
		private var clouds:Mesh;
		private var atmosphere:Mesh;
		private var tiltContainer:ObjectContainer3D;
		private var orbitContainer:ObjectContainer3D;
		private var skyBox:SkyBox;
		
		//light objects
		private var light:PointLight;
		private var lightPicker:StaticLightPicker;
		private var flares:Vector.<FlareObject> = new Vector.<FlareObject>();
		
		//navigation variables
		private var move:Boolean = false;
		private var lastPanAngle:Number;
		private var lastTiltAngle:Number;
		private var lastMouseX:Number;
		private var lastMouseY:Number;
		private var mouseLockX:Number = 0;
		private var mouseLockY:Number = 0;
		private var mouseLocked:Boolean;
		private var flareVisible:Boolean;
		
		/**
		 * Constructor
		 */
		public function Intermediate_Globe() 
		{
			init();
		}
		
		/**
		 * Global initialise function
		 */
		private function init():void
		{
			initEngine();
			initText();
			initLights();
			initLensFlare();
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
			
			//setup camera for optimal skybox rendering
			camera = new Camera3D();
			camera.lens.far = 100000;
			
			view = new View3D();
			view.scene = scene;
			view.camera = camera;
			
			//setup controller to be used on the camera
			cameraController = new HoverController(camera, null, 0, 0, 600, -90, 90);
			cameraController.yFactor = 1;
			
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
			
			addChild(awayStats = new AwayStats(view));
			
			stage.quality = StageQuality.BEST;
		}
		
		/**
		 * Create an instructions overlay
		 */
		private function initText():void
		{
			var text:TextField = new TextField();
			text.defaultTextFormat = new TextFormat("Verdana", 11, 0xFFFFFF);
			text.embedFonts = true;
			text.antiAliasType = AntiAliasType.ADVANCED;
			text.gridFitType = GridFitType.PIXEL;
			text.width = 240;
			text.height = 100;
			text.selectable = false;
			text.mouseEnabled = false;
			text.text = "MOUSE:\n" +
				"\t windowed: click and drag - rotate\n" + 
				"\t fullscreen: mouse move - rotate\n" + 
				"SCROLL_WHEEL - zoom\n" + 
				"SPACE - enables fullscreen mode";
			
			text.filters = [new DropShadowFilter(1, 45, 0x0, 1, 0, 0)];
			
			addChild(text);
		}
		
		/**
		 * Initialise the lights
		 */
		private function initLights():void
		{
			light = new PointLight();
			light.x = 10000;
			light.ambient = 1;
			light.diffuse = 2;
			
			lightPicker = new StaticLightPicker([light]);
		}
		
		private function initLensFlare():void
		{
			flares.push(new FlareObject(new Flare10(),  3.2, -0.01, 147.9));
			flares.push(new FlareObject(new Flare11(),  6,    0,     30.6));
			flares.push(new FlareObject(new Flare7(),   2,    0,     25.5));
			flares.push(new FlareObject(new Flare7(),   4,    0,     17.85));
			flares.push(new FlareObject(new Flare12(),  0.4,  0.32,  22.95));
			flares.push(new FlareObject(new Flare6(),   1,    0.68,  20.4));
			flares.push(new FlareObject(new Flare2(),   1.25, 1.1,   48.45));
			flares.push(new FlareObject(new Flare3(),   1.75, 1.37,   7.65));
			flares.push(new FlareObject(new Flare4(),   2.75, 1.85,  12.75));
			flares.push(new FlareObject(new Flare8(),   0.5,  2.21,  33.15));
			flares.push(new FlareObject(new Flare6(),   4,    2.5,   10.4));
			flares.push(new FlareObject(new Flare7(),   10,   2.66,  50));
		}
		
		/**
		 * Initialise the materials
		 */
		private function initMaterials():void
		{
			cubeTexture = new BitmapCubeTexture(Cast.bitmapData(PosX), Cast.bitmapData(NegX), Cast.bitmapData(PosY), Cast.bitmapData(NegY), Cast.bitmapData(PosZ), Cast.bitmapData(NegZ));
			
			//adjust specular map
			var specBitmap:BitmapData = Cast.bitmapData(EarthSpecular); 
			specBitmap.colorTransform(specBitmap.rect, new ColorTransform(1, 1, 1, 1, 64, 64, 64));
			
			var specular:FresnelSpecularMethod = new FresnelSpecularMethod(true);
			specular.fresnelPower = 1;
			specular.normalReflectance = 0.1;
			specular.shadingModel = SpecularShadingModel.PHONG;
			
			sunMaterial = new TextureMaterial(Cast.bitmapTexture(Flare10));
			sunMaterial.blendMode = BlendMode.ADD;
			
			groundMaterial = new TextureMaterial(Cast.bitmapTexture(EarthDiffuse));
			groundMaterial.specularMethod = specular;
			groundMaterial.specularMap = new BitmapTexture(specBitmap);
			groundMaterial.normalMap = Cast.bitmapTexture(EarthNormals);
			groundMaterial.ambientTexture = Cast.bitmapTexture(EarthNight);
			groundMaterial.lightPicker = lightPicker;
			groundMaterial.gloss = 5;
			groundMaterial.specular = 1;
			groundMaterial.ambientColor = 0xFFFFFF;
			groundMaterial.ambient = 1;
			
			var skyBitmap:BitmapData = new BitmapData(2048, 1024, true, 0xFFFFFFFF);
			skyBitmap.copyChannel(Cast.bitmapData(SkyDiffuse), skyBitmap.rect, new Point(), BitmapDataChannel.RED, BitmapDataChannel.ALPHA);
			
			cloudMaterial = new TextureMaterial(new BitmapTexture(skyBitmap));
			cloudMaterial.alphaBlending = true;
			cloudMaterial.lightPicker = lightPicker;
			cloudMaterial.specular = 0;
			cloudMaterial.ambientColor = 0x1b2048;
			cloudMaterial.ambient = 1;
			
			atmosphereDiffuseMethod =  new CompositeDiffuseMethod(modulateDiffuseMethod);
			atmosphereSpecularMethod =  new CompositeSpecularMethod(modulateSpecularMethod);
			atmosphereSpecularMethod.shadingModel = SpecularShadingModel.PHONG;
			
			atmosphereMaterial = new ColorMaterial(0x1671cc);
			atmosphereMaterial.diffuseMethod = atmosphereDiffuseMethod;
			atmosphereMaterial.specularMethod = atmosphereSpecularMethod;
			atmosphereMaterial.blendMode = BlendMode.ADD;
			atmosphereMaterial.lightPicker = lightPicker;
			atmosphereMaterial.specular = 0.5;
			atmosphereMaterial.gloss = 5;
			atmosphereMaterial.ambientColor = 0x0;
			atmosphereMaterial.ambient = 1;
		}
		
		private function modulateDiffuseMethod(vo : MethodVO, t:ShaderRegisterElement, regCache:ShaderRegisterCache):String
		{
			var viewDirFragmentReg:ShaderRegisterElement = atmosphereDiffuseMethod.viewDirFragmentReg;
			var normalFragmentReg:ShaderRegisterElement = atmosphereDiffuseMethod.normalFragmentReg;
			
			var code:String = "dp3 " + t + ".w, " + viewDirFragmentReg + ".xyz, " + normalFragmentReg + ".xyz\n" + 
							"mul " + t + ".w, " + t + ".w, " + t + ".w\n";
			
			return code;
		}
		
		private function modulateSpecularMethod(vo : MethodVO, t:ShaderRegisterElement, regCache:ShaderRegisterCache):String
		{
			var viewDirFragmentReg:ShaderRegisterElement = atmosphereDiffuseMethod.viewDirFragmentReg;
			var normalFragmentReg:ShaderRegisterElement = atmosphereDiffuseMethod.normalFragmentReg;
			var temp:ShaderRegisterElement = regCache.getFreeFragmentSingleTemp();
			regCache.addFragmentTempUsages(temp, 1);
			
			var code:String = "dp3 " + temp + ", " + viewDirFragmentReg + ".xyz, " + normalFragmentReg + ".xyz\n" + 
							"neg" + temp + ", " + temp + "\n" +
							"mul " + t + ".w, " + t + ".w, " + temp + "\n";
				
				regCache.removeFragmentTempUsage(temp);
			
			return code;
		}
		
		/**
		 * Initialise the scene objects
		 */
		private function initObjects():void
		{
			orbitContainer = new ObjectContainer3D();
			orbitContainer.addChild(light);
			scene.addChild(orbitContainer);
			
			sun = new Sprite3D(sunMaterial, 3000, 3000);
			sun.x = 10000;
			orbitContainer.addChild(sun);
			
			earth = new Mesh(new SphereGeometry(200, 200, 100), groundMaterial);
			
			clouds = new Mesh(new SphereGeometry(202, 200, 100), cloudMaterial);
			
			atmosphere = new Mesh(new SphereGeometry(210, 200, 100), atmosphereMaterial);
			atmosphere.scaleX = -1;
			
			tiltContainer = new ObjectContainer3D();
			tiltContainer.rotationX = -23;
			tiltContainer.addChild(earth);
			tiltContainer.addChild(clouds);
			tiltContainer.addChild(atmosphere);
			
			scene.addChild(tiltContainer);
			
			cameraController.lookAtObject = tiltContainer;
			
			//create a skybox
			skyBox = new SkyBox(cubeTexture);
			scene.addChild(skyBox);
		}
		
		/**
		 * Initialise the listeners
		 */
		private function initListeners():void
		{
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.addEventListener(Event.RESIZE, onResize);
			onResize();
		}
		
		/**
		 * Navigation and render loop
		 */
		private function onEnterFrame(e:Event):void
		{
			earth.rotationY += 0.2;
			clouds.rotationY += 0.21;
			orbitContainer.rotationY += 0.02;
			
			if (stage.mouseLock) {
				cameraController.panAngle = 0.3*mouseLockX;
				cameraController.tiltAngle = 0.3*mouseLockY;
			} else if (move) {
				cameraController.panAngle = 0.3*(stage.mouseX - lastMouseX) + lastPanAngle;
				cameraController.tiltAngle = 0.3*(stage.mouseY - lastMouseY) + lastTiltAngle;
			}
			
			view.render();
			
			updateFlares();
		}
		
		private function updateFlares():void
		{
			var flareVisibleOld:Boolean = flareVisible;
			
			var sunScreenPosition:Vector3D = view.project(sun.scenePosition);
			var xOffset:Number = sunScreenPosition.x - stage.stageWidth/2;
			var yOffset:Number = sunScreenPosition.y - stage.stageHeight/2;
			
			var earthScreenPosition:Vector3D = view.project(earth.scenePosition);
			var earthRadius:Number = 190*stage.stageHeight/earthScreenPosition.z;
			var flareObject:FlareObject;
			
			flareVisible = (sunScreenPosition.x > 0 && sunScreenPosition.x < stage.stageWidth && sunScreenPosition.y > 0 && sunScreenPosition.y  < stage.stageHeight && sunScreenPosition.z > 0 && Math.sqrt(xOffset*xOffset + yOffset*yOffset) > earthRadius)? true : false;
			
			//update flare visibility
			if (flareVisible != flareVisibleOld) {
				for each (flareObject in flares) {
					if (flareVisible)
						addChild(flareObject.sprite);
					else
						removeChild(flareObject.sprite);
				}
			}
			
			//update flare position
			if (flareVisible) {
				var flareDirection:Point = new Point(xOffset, yOffset);
				for each (flareObject in flares) {
					flareObject.sprite.x = sunScreenPosition.x - flareDirection.x*flareObject.position - flareObject.sprite.width/2;
					flareObject.sprite.y = sunScreenPosition.y - flareDirection.y*flareObject.position - flareObject.sprite.height/2;
				}
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
		private function onMouseUp(e:MouseEvent):void
		{
			move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);    
		}
		
		/**
		 * Mouse move listener for mouseLock
		 */
		private function onMouseMove(e:MouseEvent):void
		{
			if (stage.displayState == StageDisplayState.FULL_SCREEN) {
				
				if (mouseLocked && (lastMouseX != 0 || lastMouseY != 0)) {
					e.movementX += lastMouseX;
					e.movementY += lastMouseY;
					lastMouseX = 0;
					lastMouseY = 0;
				}
				
				mouseLockX += e.movementX;
				mouseLockY += e.movementY;
				
				if (!stage.mouseLock) {
					stage.mouseLock = true;
					lastMouseX = stage.mouseX - stage.stageWidth/2;
					lastMouseY = stage.mouseY - stage.stageHeight/2;
				} else if (!mouseLocked) {
					mouseLocked = true;
				}
				
				//ensure bounds for tiltAngle are not eceeded
				if (mouseLockY > cameraController.maxTiltAngle/0.3)
					mouseLockY = cameraController.maxTiltAngle/0.3;
				else if (mouseLockY < cameraController.minTiltAngle/0.3)
					mouseLockY = cameraController.minTiltAngle/0.3;
			}
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
		 * Mouse wheel listener for navigation
		 */
		private function onMouseWheel(event:MouseEvent) : void
		{
			cameraController.distance -= event.delta*5;
			
			if (cameraController.distance < 400)
				cameraController.distance = 400;
			else if (cameraController.distance > 10000)
				cameraController.distance = 10000;
		}
		
		/**
		 * Key down listener for fullscreen
		 */
		private function onKeyDown(event:KeyboardEvent):void
		{
			switch (event.keyCode)
			{
				case Keyboard.SPACE:
					if (stage.displayState == StageDisplayState.FULL_SCREEN) {
						stage.displayState = StageDisplayState.NORMAL;
					} else {
						stage.displayState = StageDisplayState.FULL_SCREEN;
						
						mouseLocked = false;
						mouseLockX = cameraController.panAngle/0.3;
						mouseLockY = cameraController.tiltAngle/0.3;
					}
					break;
			}
		}
		
		/**
		 * stage listener for resize events
		 */
		private function onResize(event:Event = null):void
		{
			view.width = stage.stageWidth;
			view.height = stage.stageHeight;
            SignatureBitmap.y = stage.stageHeight - Signature.height;
			awayStats.x = stage.stageWidth - awayStats.width;
		}
	}	
}

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.BitmapDataChannel;
import flash.geom.Point;

class FlareObject
{
	private var flareSize:Number = 144;
	
	public var sprite:Bitmap;
	
	public var size:Number;
	
	public var position:Number;
	
	public var opacity:Number;
	
	/**
	 * Constructor
	 */
	public function FlareObject(sprite:Bitmap, size:Number, position:Number, opacity:Number) 
	{
		this.sprite = new Bitmap(new BitmapData(sprite.bitmapData.width, sprite.bitmapData.height, true, 0xFFFFFFFF));
		this.sprite.bitmapData.copyChannel(sprite.bitmapData, sprite.bitmapData.rect, new Point(), BitmapDataChannel.RED, BitmapDataChannel.ALPHA);
		this.sprite.alpha = opacity/100;
		this.sprite.smoothing = true;
		this.sprite.scaleX = this.sprite.scaleY = size*flareSize/sprite.width;
		this.size = size;
		this.position = position;
		this.opacity = opacity;
	}
}