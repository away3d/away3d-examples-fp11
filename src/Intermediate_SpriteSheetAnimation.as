/*

Sprite sheet animation example in Away3d

Demonstrates:

How to use the SpriteSheetAnimator.
- using SpriteSheetMaterial
- using the SpriteSheetHelper for generation of the sprite sheets sources stored in an external swf source.
- multiple animators

How to tween the camera in an endless movement

How to assign an enviroMethod

Code by Fabrice Closier
fabrice3d@gmail.com
http://www.closier.nl

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
	import away3d.animators.SpriteSheetAnimationSet;
	import away3d.animators.SpriteSheetAnimator;
	import away3d.animators.nodes.SpriteSheetClipNode;
	import away3d.containers.*;
	import away3d.entities.*;
	import away3d.events.AssetEvent;
	import away3d.events.LoaderEvent;
	import away3d.library.assets.AssetType;
	import away3d.lights.PointLight;
	import away3d.loaders.Loader3D;
	import away3d.loaders.parsers.AWD2Parser;
	import away3d.materials.*;
	import away3d.materials.lightpickers.StaticLightPicker;
	import away3d.materials.methods.EnvMapMethod;
	import away3d.materials.methods.FogMethod;
	import away3d.textures.BitmapCubeTexture;
	import away3d.textures.Texture2DBase;
	import away3d.tools.helpers.SpriteSheetHelper;

	import caurina.transitions.Tweener;

	import flash.display.*;
	import flash.events.*;
	import flash.geom.Vector3D;
	import flash.net.URLRequest;

	// The tweener swc is provided in the 'libs' package

	[SWF(backgroundColor="#000000", frameRate="60", quality="LOW")]
	
	public class Intermediate_SpriteSheetAnimation extends Sprite
	{
		//signature swf
		[Embed(source="/../embeds/signature.swf", symbol="Signature")]
		public var SignatureSwf:Class;
		
		//the swf file holding timeline animations
		[Embed(source="/../embeds/spritesheets/digits.swf", mimeType="application/octet-stream")]
		private var SourceSWF : Class;
		
		[Embed(source="/../embeds/spritesheets/textures/back_CB0.jpg")]
		private var Back_CB0_Bitmap:Class;
		[Embed(source="/../embeds/spritesheets/textures/back_CB1.jpg")]
		private var Back_CB1_Bitmap:Class;
		[Embed(source="/../embeds/spritesheets/textures/back_CB2.jpg")]
		private var Back_CB2_Bitmap:Class;
		[Embed(source="/../embeds/spritesheets/textures/back_CB3.jpg")]
		private var Back_CB3_Bitmap:Class;
		[Embed(source="/../embeds/spritesheets/textures/back_CB4.jpg")]
		private var Back_CB4_Bitmap:Class;
		[Embed(source="/../embeds/spritesheets/textures/back_CB5.jpg")]
		private var Back_CB5_Bitmap:Class;
		
		//engine variables
		private var _view:View3D;
		private var _loader:Loader3D;
		private var _origin:Vector3D;
		private var _staticLightPicker:StaticLightPicker;
		
		//signature variables
		private var Signature:Sprite;
		private var SignatureBitmap:Bitmap;
		
		//demo variables
		private var _hoursDigits:SpriteSheetMaterial;
		private var _minutesDigits:SpriteSheetMaterial;
		private var _secondsDigits:SpriteSheetMaterial;
		private var _delimiterMaterial:SpriteSheetMaterial;
		private var _pulseMaterial:SpriteSheetMaterial;

		private var _hoursAnimator:SpriteSheetAnimator;
		private var _minutesAnimator:SpriteSheetAnimator;
		private var _secondsAnimator:SpriteSheetAnimator;
		private var _pulseAnimator:SpriteSheetAnimator;
		private var _delimiterAnimator:SpriteSheetAnimator;

		//value set higher to force an update
		private var _lastHour:uint = 24;
		private var _lastSecond:uint = 60;
		private var _lastMinute:uint = 60;
		 
		/**
		 * Constructor
		 */
		public function Intermediate_SpriteSheetAnimation()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			//view setup
			setUpView();
 
			//setup spritesheets and materials
			setUpSpriteSheets();

			//setting up some lights
			setUpLights();
  
			stage.addEventListener(Event.RESIZE, onResize);
			onResize();
		}

		private function setUpView():void
		{
			//setup the view
			_view = new View3D();
			_view.addSourceURL("srcview/index.html");
			addChild(_view);
			
			_view.antiAlias = 2;
			_view.backgroundColor = 0x10c14;

			//setup the camera
 			_view.camera.lens.near = 1000;
			_view.camera.lens.far = 100000;
			_view.camera.x = -17850;
			_view.camera.y = 12390;
			_view.camera.z = -9322;
			
			//saving the origin, as we look at it on enterframe
			_origin = new Vector3D();
			
			//add signature
			Signature = Sprite(new SignatureSwf());
			SignatureBitmap = new Bitmap(new BitmapData(Signature.width, Signature.height, true, 0));
			stage.quality = StageQuality.HIGH;
			SignatureBitmap.bitmapData.draw(Signature);
			stage.quality = StageQuality.LOW;
			addChild(SignatureBitmap);
		}

		/**
		 * Lights setup
		 */
		private function setUpLights():void
		{
			//Note that in 4.0, you could define the radius and falloff as Number.maxValue.
			//this is no longer the case in 4.1. As the default values are high enough, we do not need to declare them for light 1
			var plight1:PointLight = new PointLight();
			plight1.x = 5691;
			plight1.y = 10893;
			plight1.diffuse = 0.3;
			plight1.z = -11242;
			plight1.ambient = 0.3;
			plight1.ambientColor = 0x18235B;
			plight1.color = 0x2E71FF;
			plight1.specular = 0.4;
			_view.scene.addChild(plight1);
			 
			var plight2:PointLight = new PointLight();
			plight2.x = -20250;
			plight2.y = 4545;
			plight2.diffuse = 0.1;
			plight2.z = 500;
			plight2.ambient = 0.09;
			plight2.ambientColor = 0xC2CDFF;
			plight2.radius = 1000;
			plight2.color = 0xFFA825;
			plight2.fallOff = 6759;
			plight2.specular = 0.1;
		 	_view.scene.addChild(plight2);
		 
			var plight3:PointLight = new PointLight();
			plight3.x = -7031;
			plight3.y = 2583;
			plight3.diffuse = 1.3;
			plight3.z = -8319;
			plight3.ambient = 0.01;
			plight3.ambientColor = 0xFFFFFF;
			plight3.radius = 1000;
			plight3.color = 0xFF0500;
			plight3.fallOff = 6759;
			plight3.specular = 0;
			_view.scene.addChild(plight3);
			 
			_staticLightPicker = new StaticLightPicker([plight1, plight2, plight3]);
		}

		/**
		 * In this example the sprite sheets are genererated runtime, the data is stored into different movieclips in an swf file.
		 */
		private function setUpSpriteSheets():void
		{
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, setUpAnimators);
			loader.loadBytes(new SourceSWF());
		}

		/**
		 * Defining the spriteSheetAnimators and their data
		 */
		private function setUpAnimators(e:Event):void
		{
			var loader:Loader = Loader(e.currentTarget.loader);
			loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, setUpAnimators);

			var sourceSwf:MovieClip =  MovieClip(e.currentTarget.content);

			//in example swf, the source swf has a movieclip on stage named: "digits", it will be used for seconds, minutes and hours.
			var animID:String = "digits";
			var sourceMC:MovieClip = sourceSwf[animID];
			//the animation holds 60 frames, as we spread over 2 maps, we'll have 2 maps of 30 frames
			var cols:uint = 6;
			var rows:uint = 5;

			var spriteSheetHelper:SpriteSheetHelper = new SpriteSheetHelper();
			//the spriteSheetHelper has a build method, that will return us one or more maps from our movieclips.
			var diffuseSpriteSheets:Vector.<Texture2DBase> = spriteSheetHelper.generateFromMovieClip(sourceMC, cols, rows, 512, 512, false);

			//We do not have yet geometry to apply on, but we can declare the materials.
			//As they need to be async from each other, we cannot share them in this clock case
			_hoursDigits = new SpriteSheetMaterial(diffuseSpriteSheets);
			_minutesDigits = new SpriteSheetMaterial(diffuseSpriteSheets);
			_secondsDigits = new SpriteSheetMaterial(diffuseSpriteSheets);

			//we declare 3 different animators, as we will need to drive the time animations independantly. Reusing the same set.
			var digitsSet:SpriteSheetAnimationSet = new SpriteSheetAnimationSet();
			var spriteSheetClipNode:SpriteSheetClipNode = spriteSheetHelper.generateSpriteSheetClipNode(animID, cols, rows, 2, 0, 60);
			digitsSet.addAnimation(spriteSheetClipNode);

			_hoursAnimator = new SpriteSheetAnimator(digitsSet);
			_minutesAnimator = new SpriteSheetAnimator(digitsSet);
			_secondsAnimator = new SpriteSheetAnimator(digitsSet);
 
			// the button on top of model gets a nice glowing and pulsing animation
			animID = "pulse";
			//the animation movieclip has 12 frames, we define the row and cols
			cols = 4;
			rows = 3;
			sourceMC = sourceSwf[animID];
			diffuseSpriteSheets = spriteSheetHelper.generateFromMovieClip(sourceMC, cols, rows, 256, 256, false);
			var pulseAnimationSet:SpriteSheetAnimationSet = new SpriteSheetAnimationSet();
			spriteSheetClipNode = spriteSheetHelper.generateSpriteSheetClipNode(animID, cols, rows, 1, 0, 12);
			pulseAnimationSet.addAnimation(spriteSheetClipNode);
			_pulseAnimator = new SpriteSheetAnimator(pulseAnimationSet);
			_pulseAnimator.fps = 12;
			// to make it interresting, it will loop back and fourth. So a full iteration will take 2 seconds
			_pulseAnimator.backAndForth = true;
			_pulseMaterial = new SpriteSheetMaterial(diffuseSpriteSheets);

			// the delimiter,
			animID = "delimiter";
			//the animation has 5 frames, it can fit on one row
			cols = 5;
			rows = 2;
			sourceMC = sourceSwf[animID];
			diffuseSpriteSheets = spriteSheetHelper.generateFromMovieClip(sourceMC, cols, rows, 256, 256, false);
			var delimiterAnimationSet:SpriteSheetAnimationSet = new SpriteSheetAnimationSet();
			spriteSheetClipNode = spriteSheetHelper.generateSpriteSheetClipNode(animID, cols, rows, 1, 0, sourceMC.totalFrames);
			delimiterAnimationSet.addAnimation(spriteSheetClipNode);
			_delimiterAnimator = new SpriteSheetAnimator(delimiterAnimationSet);
			_delimiterAnimator.fps = 6;
			_delimiterMaterial = new SpriteSheetMaterial(diffuseSpriteSheets);
 
			//the required data is ready, time to load our model. We are now sure, all will be there when needed.
			loadModel();
		}
 		
 		/**
		 * we can start load the model
		 */
		private function loadModel():void
		{
			//adding the awd 2.0 source file to the scene
			_loader = new Loader3D();
			Loader3D.enableParser(AWD2Parser);
 
			_loader.addEventListener(AssetEvent.MESH_COMPLETE, onMeshReady);
			_loader.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onLoadedComplete);
			_loader.addEventListener(LoaderEvent.LOAD_ERROR, onLoadedError);
			//the url must be relative to swf once published, change the url for your setup accordingly.
			_loader.load(new URLRequest("assets/tictac/tictac.awd"), null, null, new AWD2Parser());
		}

		private function onLoadedError(event:LoaderEvent):void
		{
			trace("0_o "+event.message);
		}

		/**
		 * assigning the animators
		 */
		private function onMeshReady(event:AssetEvent):void
		{
			if(event.asset.assetType == AssetType.MESH){
				var mesh:Mesh = Mesh(event.asset);
 
				switch (mesh.name){

					case "hours":
						mesh.material = _hoursDigits;
						mesh.animator = _hoursAnimator;
						_hoursAnimator.play("digits");
						break;

					case "minutes":
						mesh.material = _minutesDigits;
						mesh.animator = _minutesAnimator;
						_minutesAnimator.play("digits");
						break;

					case "seconds":
						mesh.material = _secondsDigits;
						mesh.animator = _secondsAnimator;
						_secondsAnimator.play("digits");
						break;

					case "delimiter":
						mesh.material = _delimiterMaterial;
						mesh.animator = _delimiterAnimator;
						_delimiterAnimator.play("delimiter");
						break;

					case "button":
						mesh.material = _pulseMaterial;
						mesh.animator = _pulseAnimator;
						 _pulseAnimator.play("pulse");
						break;
 

					case "furniture":
						mesh.material.lightPicker = _staticLightPicker;
						break;

					case "frontscreen":
						//ignoring lightpicker on this mesh
						break;

					case "chromebody":
						var cubeTexture:BitmapCubeTexture = new BitmapCubeTexture(	Bitmap(new Back_CB0_Bitmap()).bitmapData,
																		Bitmap(new Back_CB1_Bitmap()).bitmapData,
																		Bitmap(new Back_CB2_Bitmap()).bitmapData,
																		Bitmap(new Back_CB3_Bitmap()).bitmapData,
																		Bitmap(new Back_CB4_Bitmap()).bitmapData,
																		Bitmap(new Back_CB5_Bitmap()).bitmapData);

						var envMapMethod:EnvMapMethod = new EnvMapMethod(cubeTexture, 0.1);
						SinglePassMaterialBase(mesh.material).addMethod(envMapMethod);

					default:
						if(!mesh.material.lightPicker)
							mesh.material.lightPicker = _staticLightPicker;

				}

				var fogMethod:FogMethod = new FogMethod(20000, 50000, 0x10C14);
				SinglePassMaterialBase(mesh.material).addMethod(fogMethod);
			}
		}

		private function clearListeners():void
		{
			_loader.removeEventListener(AssetEvent.MESH_COMPLETE, onMeshReady);
			_loader.removeEventListener(LoaderEvent.RESOURCE_COMPLETE, onLoadedComplete);
			_loader.removeEventListener(LoaderEvent.LOAD_ERROR, onLoadedError);
		}

		/**
		 * the model is loaded. Time to display our work
		 */

		private function onLoadedComplete(event:LoaderEvent):void
		{
			 clearListeners();
			
			 _view.scene.addChild(ObjectContainer3D(event.currentTarget));
			addEventListener(Event.ENTER_FRAME, _onEnterFrame);

			startTween();
		}


		/**
		 * updating the digit according to current time
		 */
  		private function updateClock():void
		{
			var date:Date = new Date();
			
			if(_lastHour != date.hours){
				_lastHour = date.hours;
				_hoursAnimator.gotoAndStop(_lastHour + 1);
			}

			if(_lastMinute != date.minutes){
				_lastMinute = date.minutes;
				_minutesAnimator.gotoAndStop(_lastMinute + 1);
			}

			if(_lastSecond != date.seconds){
				_lastSecond = date.seconds;
				_secondsAnimator.gotoAndStop(_lastSecond + 1);
				_delimiterAnimator.gotoAndPlay(1);
			}
		}

		/**
		 * endless tween to add some dramatic!
		 */
		private function startTween():void
		{
			var destX:Number = -(Math.random()*24000)+4000;
			var destY:Number = Math.random()*16000;
			var destZ:Number = 3000+Math.random()*18000;

			Tweener.addTween(	_view.camera, {x:destX, y:destY, z:- destZ,
							time:4+(Math.random()*2), 
							transition:"easeInOutQuad",
							onComplete:startTween });
		}
		
		/**
		 * render loop
		 */
		private function _onEnterFrame(e:Event):void
		{	
			updateClock();
			_view.camera.lookAt(_origin);
			_view.render();
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