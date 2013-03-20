/*

Crytek Sponza demo using multipass materials in Away3D

Demonstrates:

How to apply Multipass materials to a model
How to enable cascading shadow maps on a multipass material.
How to setup multiple lightsources, shadows and fog effects all in the same scene.
How to apply specular, normal and diffuse maps to an AWD model.

Code by Rob Bateman & David Lenaerts
rob@infiniteturtles.co.uk
http://www.infiniteturtles.co.uk
david.lenaerts@gmail.com
http://www.derschmale.com

Model re-modeled by Frank Meinl at Crytek with inspiration from Marko Dabrovic's original, converted to AWD by LoTH
contact@crytek.com
http://www.crytek.com/cryengine/cryengine3/downloads
3dflashlo@gmail.com
http://3dflashlo.wordpress.com

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
	import away3d.containers.*;
	import away3d.controllers.*;
	import away3d.core.base.*;
	import away3d.debug.*;
	import away3d.entities.*;
	import away3d.events.*;
	import away3d.library.assets.*;
	import away3d.lights.*;
	import away3d.lights.shadowmaps.*;
	import away3d.loaders.*;
	import away3d.loaders.misc.*;
	import away3d.loaders.parsers.*;
	import away3d.materials.*;
	import away3d.materials.lightpickers.*;
	import away3d.materials.methods.*;
	import away3d.primitives.*;
	import away3d.textures.*;
	import away3d.tools.commands.*;
	import away3d.utils.*;

	import uk.co.soulwire.gui.*;

	import flash.display.*;
	import flash.events.*;
	import flash.filters.*;
	import flash.geom.*;
	import flash.net.*;
	import flash.text.*;
	import flash.ui.*;
	import flash.utils.*;
	
	[SWF(frameRate="30", backgroundColor="#000000")]
	
	public class Advanced_MultiPassSponzaDemo extends Sprite
	{
		//signature swf
    	[Embed(source="/../embeds/signature.swf", symbol="Signature")]
    	public var SignatureSwf:Class;
		
		//skybox texture
		[Embed(source="/../embeds/skybox/hourglass_cubemap.atf", mimeType="application/octet-stream")]
		public static var SkyMapCubeTexture : Class;
		
		//fire texture
		[Embed(source="/../embeds/fire.atf", mimeType="application/octet-stream")]
		public static var FlameTexture : Class;
		
		//root filepath for asset loading
		private var _assetsRoot:String = "assets/";
		
		//default material data strings
		private var _materialNameStrings:Vector.<String> = Vector.<String>(["arch",            "Material__298",  "bricks",            "ceiling",            "chain",             "column_a",          "column_b",          "column_c",          "fabric_g",              "fabric_c",         "fabric_f",               "details",          "fabric_d",             "fabric_a",        "fabric_e",              "flagpole",          "floor",            "16___Default","Material__25","roof",       "leaf",           "vase",         "vase_hanging",     "Material__57",   "vase_round"]);
		
		//private const diffuseTextureStrings:Vector.<String> = Vector.<String>(["arch_diff.atf", "background.atf", "bricks_a_diff.atf", "ceiling_a_diff.atf", "chain_texture.png", "column_a_diff.atf", "column_b_diff.atf", "column_c_diff.atf", "curtain_blue_diff.atf", "curtain_diff.atf", "curtain_green_diff.atf", "details_diff.atf", "fabric_blue_diff.atf", "fabric_diff.atf", "fabric_green_diff.atf", "flagpole_diff.atf", "floor_a_diff.atf", "gi_flag.atf", "lion.atf", "roof_diff.atf", "thorn_diff.png", "vase_dif.atf", "vase_hanging.atf", "vase_plant.png", "vase_round.atf"]);
		//private const normalTextureStrings:Vector.<String> = Vector.<String>(["arch_ddn.atf", "background_ddn.atf", "bricks_a_ddn.atf", null,                "chain_texture_ddn.atf", "column_a_ddn.atf", "column_b_ddn.atf", "column_c_ddn.atf", null,                   null,               null,                     null,               null,                   null,              null,                    null,                null,               null,          "lion2_ddn.atf", null,       "thorn_ddn.atf", "vase_ddn.atf",  null,               null,             "vase_round_ddn.atf"]);
		//private const specularTextureStrings:Vector.<String> = Vector.<String>(["arch_spec.atf", null,            "bricks_a_spec.atf", "ceiling_a_spec.atf", null,                "column_a_spec.atf", "column_b_spec.atf", "column_c_spec.atf", "curtain_spec.atf",      "curtain_spec.atf", "curtain_spec.atf",       "details_spec.atf", "fabric_spec.atf",      "fabric_spec.atf", "fabric_spec.atf",       "flagpole_spec.atf", "floor_a_spec.atf", null,          null,       null,            "thorn_spec.atf", null,           null,               "vase_plant_spec.atf", "vase_round_spec.atf"]);
		
		private const _diffuseTextureStrings:Vector.<String> = Vector.<String>(["arch_diff.jpg", "background.jpg", "bricks_a_diff.jpg", "ceiling_a_diff.jpg", "chain_texture.png", "column_a_diff.jpg", "column_b_diff.jpg", "column_c_diff.jpg", "curtain_blue_diff.jpg", "curtain_diff.jpg", "curtain_green_diff.jpg", "details_diff.jpg", "fabric_blue_diff.jpg", "fabric_diff.jpg", "fabric_green_diff.jpg", "flagpole_diff.jpg", "floor_a_diff.jpg", "gi_flag.jpg", "lion.jpg", "roof_diff.jpg", "thorn_diff.png", "vase_dif.jpg", "vase_hanging.jpg", "vase_plant.png", "vase_round.jpg"]);
		private const _normalTextureStrings:Vector.<String> = Vector.<String>(["arch_ddn.jpg", "background_ddn.jpg", "bricks_a_ddn.jpg", null,                "chain_texture_ddn.jpg", "column_a_ddn.jpg", "column_b_ddn.jpg", "column_c_ddn.jpg", null,                   null,               null,                     null,               null,                   null,              null,                    null,                null,               null,          "lion2_ddn.jpg", null,       "thorn_ddn.jpg", "vase_ddn.jpg",  null,               null,             "vase_round_ddn.jpg"]);
		private const _specularTextureStrings:Vector.<String> = Vector.<String>(["arch_spec.jpg", null,            "bricks_a_spec.jpg", "ceiling_a_spec.jpg", null,                "column_a_spec.jpg", "column_b_spec.jpg", "column_c_spec.jpg", "curtain_spec.jpg",      "curtain_spec.jpg", "curtain_spec.jpg",       "details_spec.jpg", "fabric_spec.jpg",      "fabric_spec.jpg", "fabric_spec.jpg",       "flagpole_spec.jpg", "floor_a_spec.jpg", null,          null,       null,            "thorn_spec.jpg", null,           null,               "vase_plant_spec.jpg", "vase_round_spec.jpg"]);
		private var _numTexStrings:Vector.<uint> = Vector.<uint>([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
		private var _meshReference:Vector.<Mesh> = new Vector.<Mesh>(25);
		
		//flame data objects
		private const _flameData:Vector.<FlameVO> = Vector.<FlameVO>([new FlameVO(new Vector3D(-625, 165, 219), 0xffaa44), new FlameVO(new Vector3D(485, 165, 219), 0xffaa44), new FlameVO(new Vector3D(-625, 165, -148), 0xffaa44), new FlameVO(new Vector3D(485, 165, -148), 0xffaa44)]);
		
		//material dictionaries to hold instances
		private var _textureDictionary:Dictionary = new Dictionary();
		private var _multiMaterialDictionary:Dictionary = new Dictionary();
		private var _singleMaterialDictionary:Dictionary = new Dictionary();
		
		//private var meshDictionary:Dictionary = new Dictionary();
		private var vaseMeshes:Vector.<Mesh> = new Vector.<Mesh>();
		private var poleMeshes:Vector.<Mesh> = new Vector.<Mesh>();
		private var colMeshes:Vector.<Mesh> = new Vector.<Mesh>();
		
		//engien variables
		private var _view:View3D;
		private var _cameraController:FirstPersonController;
		private var _awayStats:AwayStats;
		private var _text:TextField;
		
		//signature variables
		private var Signature:Sprite;
		private var SignatureBitmap:Bitmap;
		
		//gui variables
		private var _singlePassMaterial:Boolean = false;
		private var _multiPassMaterial:Boolean = true;
		private var _cascadeLevels:uint = 3;
		private var _shadowOptions:String = "PCF";
		private var _depthMapSize:uint = 2048;
		private var _lightDirection:Number = Math.PI/2;
		private var _lightElevation:Number = Math.PI/18;
		private var _gui:SimpleGUI;
		
		//light variables
		private var _lightPicker:StaticLightPicker;
		private var _baseShadowMethod:FilteredShadowMapMethod;
		private var _cascadeMethod:CascadeShadowMapMethod;
		private var _fogMethod : FogMethod;
		private var _cascadeShadowMapper:CascadeShadowMapper;
		private var _directionalLight:DirectionalLight;
		private var _lights:Array = new Array();
		
		//material variables
		private var _skyMap:ATFCubeTexture;
		private var _flameMaterial:TextureMaterial;
		private var _numTextures:uint = 0;
		private var _currentTexture:uint = 0;
		private var _loadingTextureStrings:Vector.<String>;
		private var _n:uint = 0;
		private var _loadingText:String;
		
		//scene variables
		private var _meshes:Vector.<Mesh> = new Vector.<Mesh>();
		private var _flameGeometry:PlaneGeometry;
				
		//rotation variables
		private var _move:Boolean = false;
		private var _lastPanAngle:Number;
		private var _lastTiltAngle:Number;
		private var _lastMouseX:Number;
		private var _lastMouseY:Number;
		
		//movement variables
		private var _drag:Number = 0.5;
		private var _walkIncrement:Number = 10;
		private var _strafeIncrement:Number = 10;
		private var _walkSpeed:Number = 0;
		private var _strafeSpeed:Number = 0;
		private var _walkAcceleration:Number = 0;
		private var _strafeAcceleration:Number = 0;
		
		/**
		 * GUI variable for setting material mode to single pass
		 */
		public function get singlePassMaterial():Boolean
		{
			return _singlePassMaterial;
		}
		
		public function set singlePassMaterial(value:Boolean):void
		{
			_singlePassMaterial = value;
			_multiPassMaterial = !value;
			
			updateMaterialPass(value? _singleMaterialDictionary : _multiMaterialDictionary);
		}
		
		/**
		 * GUI variable for setting material mode to multi pass
		 */
		public function get multiPassMaterial():Boolean
		{
			return _multiPassMaterial;
		}
		
		public function set multiPassMaterial(value:Boolean):void
		{
			_multiPassMaterial = value;
			_singlePassMaterial = !value;
			
			updateMaterialPass(value? _multiMaterialDictionary : _singleMaterialDictionary);
		}
		
		/**
		 * GUI variable for setting number of cascade levels.
		 */
		public function get cascadeLevels():uint
		{
			return _cascadeLevels;
		}
		
		public function set cascadeLevels(value:uint):void
		{
			_cascadeLevels = value;
			
			_cascadeShadowMapper.numCascades = value;
		}
		
		/**
		 * GUI variable for setting the active shadow option
		 */
		public function get shadowOptions():String
		{
			return _shadowOptions;
		}
		
		public function set shadowOptions(value:String):void
		{
			_shadowOptions = value;
			
			switch(value) {
				case "Unfiltered":
					_cascadeMethod.baseMethod = new HardShadowMapMethod(_directionalLight);
					break;
				case "Multiple taps":
					_cascadeMethod.baseMethod = new SoftShadowMapMethod(_directionalLight);
					break;
				case "PCF":
					_cascadeMethod.baseMethod = new FilteredShadowMapMethod(_directionalLight);
					break;
				case "Dithered":
					_cascadeMethod.baseMethod = new DitheredShadowMapMethod(_directionalLight);
					break;
			}
		}
		
		/**
		 * GUI variable for setting the depth map size of the shadow mapper.
		 */
		public function get depthMapSize():uint
		{
			return _depthMapSize;
		}
		
		public function set depthMapSize(value:uint):void
		{
			_depthMapSize = value;
			
			_directionalLight.shadowMapper.depthMapSize = value;
		}
		
		/**
		 * GUI variable for setting the direction of the directional lightsource
		 */
		public function get lightDirection():Number
		{
			return _lightDirection*180/Math.PI;
		}
		
		public function set lightDirection(value:Number):void
		{
			_lightDirection = value*Math.PI/180;
			
			updateDirection();
		}
		
		/**
		 * GUI variable for setting The elevation of the directional lightsource
		 */
		public function get lightElevation():Number
		{
			return 90 - _lightElevation*180/Math.PI;
		}
		
		public function set lightElevation(value:Number):void
		{
			_lightElevation = (90 - value)*Math.PI/180;
			
			updateDirection();
		}
		
        /**
         * Constructor
         */
		public function Advanced_MultiPassSponzaDemo()
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
			initGUI();
			initListeners();
			
			
			//count textures
			_n = 0;
			_loadingTextureStrings = _diffuseTextureStrings;
			countNumTextures();
			
			//kickoff asset loading
			_n = 0;
			_loadingTextureStrings = _diffuseTextureStrings;
			load(_loadingTextureStrings[_n]);
		}
		
        /**
         * Initialise the engine
         */
		private function initEngine():void
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
			stage.quality = StageQuality.LOW;
			
			//create the view
			_view = new View3D(null, null, null, false);
			_view.camera.y = 150;
			_view.camera.z = 0;
			
			_view.addSourceURL("srcview/index.html");
			addChild(_view);
			
			//setup controller to be used on the camera
			_cameraController = new FirstPersonController(_view.camera, 90, 0, -80, 80);			
			
			//add signature
			Signature = Sprite(new SignatureSwf());
			SignatureBitmap = new Bitmap(new BitmapData(Signature.width, Signature.height, true, 0));
			stage.quality = StageQuality.HIGH;
			SignatureBitmap.bitmapData.draw(Signature);
			stage.quality = StageQuality.LOW;
			addChild(SignatureBitmap);
            
            //add stats
            addChild(_awayStats = new AwayStats(_view));
		}
        		
		/**
         * Create an instructions overlay
         */
        private function initText():void
		{
            _text = new TextField();
            _text.defaultTextFormat = new TextFormat("Verdana", 11, 0xFFFFFF, null, null, null, null, null, "center");
			_text.embedFonts = true;
			_text.antiAliasType = AntiAliasType.ADVANCED;
			_text.gridFitType = GridFitType.PIXEL;
            _text.width = 300;
            _text.height = 250;
            _text.selectable = false;
            _text.mouseEnabled = true;
            _text.wordWrap = true;
            _text.filters = [new DropShadowFilter(1, 45, 0x0, 1, 0, 0)];
            addChild(_text);
        }
		
        /**
         * Initialise the lights
         */
		private function initLights():void
		{
			//create lights array
			_lights = new Array();
			
			//create global directional light
			_cascadeShadowMapper = new CascadeShadowMapper(3);
			_cascadeShadowMapper.lightOffset = 20000;
			_directionalLight = new DirectionalLight(-1, -15, 1);
			_directionalLight.shadowMapper = _cascadeShadowMapper;
			_directionalLight.color = 0xeedddd;
			_directionalLight.ambient = .35;
			_directionalLight.ambientColor = 0x808090;
			_view.scene.addChild(_directionalLight);
			_lights.push(_directionalLight);
			
			updateDirection();
			
			//creat flame lights
			var flameVO:FlameVO;
			for each (flameVO in _flameData)
			{
				var light : PointLight = flameVO.light = new PointLight();
				light.radius = 200;
				light.fallOff = 600;
				light.color = flameVO.color;
				light.y = 10;
				_lights.push(light);
			}
			
			//create our global light picker
			_lightPicker = new StaticLightPicker(_lights);
			_baseShadowMethod = new FilteredShadowMapMethod(_directionalLight);
			
			//create our global fog method
			_fogMethod = new FogMethod(0, 4000, 0x9090e7);
			_cascadeMethod = new CascadeShadowMapMethod(_baseShadowMethod);
		}
		
        /**
         * Initialise the scene materials
         */		
		private function initMaterials():void
		{
			//create skybox texture map
			_skyMap = new ATFCubeTexture(new SkyMapCubeTexture());
			
			//create flame material
			//_flameMaterial = new TextureMaterial(Cast.bitmapTexture(FlameTexture));
			_flameMaterial = new TextureMaterial(new ATFTexture(new FlameTexture()));
			_flameMaterial.blendMode = BlendMode.ADD;
			_flameMaterial.animateUVs = true;
			
		}
		        
        /**
         * Initialise the scene objects
         */
        private function initObjects():void
		{
			//create skybox
            _view.scene.addChild(new SkyBox(_skyMap));
			
			//create flame meshes
			_flameGeometry = new PlaneGeometry(40, 80, 1, 1, false, true);
			var flameVO:FlameVO;
			for each (flameVO in _flameData)
			{
				var mesh : Mesh = flameVO.mesh = new Mesh(_flameGeometry, _flameMaterial);
				mesh.position = flameVO.position;
				mesh.subMeshes[0].scaleU = 1/16;
				_view.scene.addChild(mesh);
				mesh.addChild(flameVO.light);
			}
		}
		
		/**
		 * Initialise the GUI
		 */
		private function initGUI():void
		{
			var shadowOptions:Array = [
				{label:"Unfiltered", data:"Unfiltered"},
				{label:"PCF", data:"PCF"},
				{label:"Multiple taps", data:"Multiple taps"},
				{label:"Dithered", data:"Dithered"}
			];
			
			var depthMapSize:Array = [
				{label:"512", data:512},
				{label:"1024", data:1024},
				{label:"2048", data:2048}
			];
			
			_gui = new SimpleGUI(this, "");
			
			_gui.addColumn("Instructions");
			var instr:String = "Click and drag on the stage to rotate camera.\n";
			instr += "Keyboard arrows and WASD to move.\n";
			instr += "F to enter Fullscreen mode.\n";
			instr += "C to toggle camera mode between walk and fly.\n";
			_gui.addLabel(instr);
			
			_gui.addColumn("Material Settings");
			_gui.addToggle("singlePassMaterial", {label:"Single pass"});
			_gui.addToggle("multiPassMaterial", {label:"Multiple pass"});
			
			_gui.addColumn("Shadow Settings");
			_gui.addStepper("cascadeLevels", 1, 4, {label:"Cascade level"});
			_gui.addComboBox("shadowOptions", shadowOptions, {label:"Filter method"});
			_gui.addComboBox("depthMapSize", depthMapSize, {label:"Depth map size"});
			
			
			_gui.addColumn("Light Position");
			_gui.addSlider("lightDirection", 0, 360, {label:"Direction", tick:0.1});
			_gui.addSlider("lightElevation", 0, 90, {label:"Elevation", tick:0.1});
			_gui.show();
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
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			onResize();
		}
		
		/**
		 * Updates the mateiral mode between single pass and multi pass
		 */
		private function updateMaterialPass(materialDictionary:Dictionary):void
		{
			var mesh:Mesh;
			var name:String;
			for each (mesh in _meshes) {
				if (mesh.name == "sponza_04" || mesh.name == "sponza_379")
					continue;
				name = mesh.material.name;
				var textureIndex:int = _materialNameStrings.indexOf(name);
				if (textureIndex == -1 || textureIndex >= _materialNameStrings.length)
					continue;
				
				mesh.material = materialDictionary[name];
			}
		}
		
		/**
		 * Updates the direction of the directional lightsource
		 */
		private function updateDirection():void
		{
			_directionalLight.direction = new Vector3D(
				Math.sin(_lightElevation)*Math.cos(_lightDirection),
				-Math.cos(_lightElevation),
				Math.sin(_lightElevation)*Math.sin(_lightDirection)
			);
		}
		
		/**
		 * Count the total number of textures to be loaded
		 */
		private function countNumTextures():void
		{
			_numTextures++;
			
			//skip null textures
			while (_n++ < _loadingTextureStrings.length - 1)
				if (_loadingTextureStrings[_n])
					break;
			
			//switch to next teture set
			if (_n < _loadingTextureStrings.length) {
				countNumTextures();
			} else if (_loadingTextureStrings == _diffuseTextureStrings) {
				_n = 0;
				_loadingTextureStrings = _normalTextureStrings;
				countNumTextures();
			} else if (_loadingTextureStrings == _normalTextureStrings) {
				_n = 0;
				_loadingTextureStrings = _specularTextureStrings;
				countNumTextures();
			}
		}
		
        /**
         * Global binary file loader
         */
        private function load(url:String):void
		{
			var loader:URLLoader = new URLLoader();
            loader.dataFormat = URLLoaderDataFormat.BINARY;
			
            switch (url.substring(url.length - 3)) {
                case "AWD": 
                case "awd": 
					_loadingText = "Loading Model";
                    loader.addEventListener(Event.COMPLETE, parseAWD, false, 0, true);
                    break;
                case "png": 
                case "jpg": 
					_currentTexture++;
					_loadingText = "Loading Textures";
                    loader.addEventListener(Event.COMPLETE, parseBitmap);
					url = "sponza/" + url;
                    break;
				case "atf": 
					_currentTexture++;
					_loadingText = "Loading Textures";
                    loader.addEventListener(Event.COMPLETE, onATFComplete);
					url = "sponza/atf/" + url;
                    break;
            }
			
            loader.addEventListener(ProgressEvent.PROGRESS, loadProgress, false, 0, true);
			var urlReq:URLRequest = new URLRequest(_assetsRoot+url);
 			loader.load(urlReq);
			
        }
        
		/**
         * Display current load
         */
        private function loadProgress(e:ProgressEvent):void
		{
            var P:int = int(e.bytesLoaded / e.bytesTotal * 100);
            if (P != 100) {
                log(_loadingText + '\n' + ((_loadingText == "Loading Model")? int((e.bytesLoaded / 1024) << 0) + 'kb | ' + int((e.bytesTotal / 1024) << 0) + 'kb' : _currentTexture + ' | ' + _numTextures));
			} else if (_loadingText == "Loading Model") {
				_text.visible = false;
			}
        }
        
		/**
		 * Parses the ATF file
		 */
		private function onATFComplete(e:Event):void
		{
            var loader:URLLoader = URLLoader(e.target);
            loader.removeEventListener(Event.COMPLETE, onATFComplete);
			
			if (!_textureDictionary[_loadingTextureStrings[_n]])
			{
				_textureDictionary[_loadingTextureStrings[_n]] = new ATFTexture(loader.data);
			}
				
            loader.data = null;
            loader.close();
			loader = null;
			
			
			//skip null textures
			while (_n++ < _loadingTextureStrings.length - 1)
				if (_loadingTextureStrings[_n])
					break;
			
			//switch to next teture set
            if (_n < _loadingTextureStrings.length) {
                load(_loadingTextureStrings[_n]);
			} else if (_loadingTextureStrings == _diffuseTextureStrings) {
				_n = 0;
				_loadingTextureStrings = _normalTextureStrings;
				load(_loadingTextureStrings[_n]);
			} else if (_loadingTextureStrings == _normalTextureStrings) {
				_n = 0;
				_loadingTextureStrings = _specularTextureStrings;
				load(_loadingTextureStrings[_n]);
			} else {
            	load("sponza/sponza.awd");
            }
        }
		
		
		/**
		 * Parses the Bitmap file
		 */
        private function parseBitmap(e:Event):void 
		{
            var urlLoader:URLLoader = e.target as URLLoader;
            var loader:Loader = new Loader();
            loader.loadBytes(urlLoader.data);
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onBitmapComplete, false, 0, true);
            urlLoader.removeEventListener(Event.COMPLETE, parseBitmap);
            urlLoader.removeEventListener(ProgressEvent.PROGRESS, loadProgress);
            loader = null;
        }
        
		/**
		 * Listener function for bitmap complete event on loader
		 */
        private function onBitmapComplete(e:Event):void
		{
            var loader:Loader = LoaderInfo(e.target).loader;
            loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onBitmapComplete);
			
			//create bitmap texture in dictionary
			if (!_textureDictionary[_loadingTextureStrings[_n]])
            	_textureDictionary[_loadingTextureStrings[_n]] = (_loadingTextureStrings == _specularTextureStrings)? new SpecularBitmapTexture((e.target.content as Bitmap).bitmapData) : Cast.bitmapTexture(e.target.content);
				
            loader.unload();
            loader = null;
			
			//skip null textures
			while (_n++ < _loadingTextureStrings.length - 1)
				if (_loadingTextureStrings[_n])
					break;
			
			//switch to next teture set
            if (_n < _loadingTextureStrings.length) {
                load(_loadingTextureStrings[_n]);
			} else if (_loadingTextureStrings == _diffuseTextureStrings) {
				_n = 0;
				_loadingTextureStrings = _normalTextureStrings;
				load(_loadingTextureStrings[_n]);
			} else if (_loadingTextureStrings == _normalTextureStrings) {
				_n = 0;
				_loadingTextureStrings = _specularTextureStrings;
				load(_loadingTextureStrings[_n]);
			} else {
            	load("sponza/sponza.awd");
            }
        }
		
        /**
         * Parses the AWD file
         */
        private function parseAWD(e:Event):void
		{
			log("Parsing Data");
            var loader:URLLoader = e.target as URLLoader;
            var loader3d:Loader3D = new Loader3D(false);
			var context:AssetLoaderContext = new AssetLoaderContext();
			//context.includeDependencies = false;
			context.dependencyBaseUrl = "assets/sponza/";
            loader3d.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete, false, 0, true);
            loader3d.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceComplete, false, 0, true);
            loader3d.loadData(loader.data, context, null, new AWDParser());
			
            loader.removeEventListener(ProgressEvent.PROGRESS, loadProgress);
            loader.removeEventListener(Event.COMPLETE, parseAWD);
            loader = null;
        }
        
        /**
         * Listener function for asset complete event on loader
         */
        private function onAssetComplete(event:AssetEvent):void
		{
			if (event.asset.assetType == AssetType.MESH) {
				//store meshes
				_meshes.push(event.asset as Mesh);
			}
		}
		
		/**
         * Triggered once all resources are loaded
         */
        private function onResourceComplete(e:LoaderEvent):void
		{
			var merge:Merge = new Merge(false, false, true);
			merge=merge;
			
			_text.visible = false;
			
            var loader3d:Loader3D = e.target as Loader3D;
            loader3d.removeEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
            loader3d.removeEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceComplete);
			
			//reassign materials
			var mesh:Mesh;
			var name:String;
			
			for each (mesh in _meshes) {
				if (mesh.name == "sponza_04" || mesh.name == "sponza_379")
					continue;
				
				var num:Number = Number(mesh.name.substring(7));
				
				name = mesh.material.name;
				
				if (name == "column_c" && (num < 22 || num > 33))
					continue;
				
				var colNum:Number = (num - 125);
				if (name == "column_b") {
					if (colNum  >=0 && colNum < 132 && (colNum % 11) < 10) {
						colMeshes.push(mesh);
						continue;
					} else {
						colMeshes.push(mesh);
						var colMerge:Merge = new Merge();
						var colMesh:Mesh = new Mesh(new Geometry());
						colMerge.applyToMeshes(colMesh, colMeshes);
						mesh = colMesh;
						colMeshes = new Vector.<Mesh>();
					}
				}
				
				var vaseNum:Number = (num - 334);
				if (name == "vase_hanging" && (vaseNum % 9) < 5) {
					if (vaseNum  >=0 && vaseNum < 370 && (vaseNum % 9) < 4) {
						vaseMeshes.push(mesh);
						continue;
					} else {
						vaseMeshes.push(mesh);
						var vaseMerge:Merge = new Merge();
						var vaseMesh:Mesh = new Mesh(new Geometry());
						vaseMerge.applyToMeshes(vaseMesh, vaseMeshes);
						mesh = vaseMesh;
						vaseMeshes = new Vector.<Mesh>();
					}
				}
				
				var poleNum:Number = num - 290;
				if (name == "flagpole") {
					if (poleNum >=0 && poleNum < 320 && (poleNum % 3) < 2) {
						poleMeshes.push(mesh);
						continue;
					} else if (poleNum >=0) {
						poleMeshes.push(mesh);
						var poleMerge:Merge = new Merge();
						var poleMesh:Mesh = new Mesh(new Geometry());
						poleMerge.applyToMeshes(poleMesh, poleMeshes);
						mesh = poleMesh;
						poleMeshes = new Vector.<Mesh>();
					}
				}
				
				if (name == "flagpole" && (num == 260 || num == 261 || num == 263 || num == 265 || num == 268 || num == 269 || num == 271 || num == 273))
					continue;
				
				var textureIndex:int = _materialNameStrings.indexOf(name);
				if (textureIndex == -1 || textureIndex >= _materialNameStrings.length)
					continue;
				
				_numTexStrings[textureIndex]++;
				
				var textureName:String = _diffuseTextureStrings[textureIndex];
				var normalTextureName:String;
				var specularTextureName:String;
				
				//store single pass materials for use later
				var singleMaterial:TextureMaterial = _singleMaterialDictionary[name];
				
				if (!singleMaterial) {
					
					//create singlepass material
					singleMaterial = new TextureMaterial(_textureDictionary[textureName]);
					
					singleMaterial.name = name;
					singleMaterial.lightPicker = _lightPicker;
					singleMaterial.addMethod(_fogMethod);
					singleMaterial.mipmap = true;
					singleMaterial.repeat = true;
					singleMaterial.specular = 2;
					
					//use alpha transparancy if texture is png
					if (textureName.substring(textureName.length - 3) == "png")
						singleMaterial.alphaThreshold = 0.5;
					
					//add normal map if it exists
					normalTextureName = _normalTextureStrings[textureIndex];
					if (normalTextureName)
						singleMaterial.normalMap = _textureDictionary[normalTextureName];
					
					//add specular map if it exists
					specularTextureName = _specularTextureStrings[textureIndex];
					if (specularTextureName)
						singleMaterial.specularMap = _textureDictionary[specularTextureName];
					
					_singleMaterialDictionary[name] = singleMaterial;
					
				}

				//store multi pass materials for use later
				var multiMaterial:TextureMultiPassMaterial = _multiMaterialDictionary[name];
				
				if (!multiMaterial) {
					
					//create multipass material
					multiMaterial = new TextureMultiPassMaterial(_textureDictionary[textureName]);
					multiMaterial.name = name;
					multiMaterial.lightPicker = _lightPicker;
					multiMaterial.shadowMethod = _cascadeMethod;
					multiMaterial.addMethod(_fogMethod);
					multiMaterial.mipmap = true;
					multiMaterial.repeat = true;
					multiMaterial.specular = 2;
					
					
					//use alpha transparancy if texture is png
					if (textureName.substring(textureName.length - 3) == "png")
						multiMaterial.alphaThreshold = 0.5;
					
					//add normal map if it exists
					normalTextureName = _normalTextureStrings[textureIndex];
					if (normalTextureName)
						multiMaterial.normalMap = _textureDictionary[normalTextureName];
					
					//add specular map if it exists
					specularTextureName = _specularTextureStrings[textureIndex];
					if (specularTextureName)
						multiMaterial.specularMap = _textureDictionary[specularTextureName];
					
					//add to material dictionary
					_multiMaterialDictionary[name] = multiMaterial;
				}
				/*
				if (_meshReference[textureIndex]) {
					var m:Mesh = mesh.clone() as Mesh;
					m.material = multiMaterial;
					_view.scene.addChild(m);
					continue;
				}
				*/
				//default to multipass material
				mesh.material = multiMaterial;
				
				_view.scene.addChild(mesh);
				
				_meshReference[textureIndex] = mesh;
			}
			
			var z:uint = 0;
			
			while (z < _numTexStrings.length)
			{
				trace(_diffuseTextureStrings[z], _numTexStrings[z]);
				z++;
			}
			
			initMaterials();
			initObjects();
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
			
			if (_walkSpeed || _walkAcceleration) {
				_walkSpeed = (_walkSpeed + _walkAcceleration)*_drag;
				if (Math.abs(_walkSpeed) < 0.01)
					_walkSpeed = 0;
				_cameraController.incrementWalk(_walkSpeed);
			}
			
			if (_strafeSpeed || _strafeAcceleration) {
				_strafeSpeed = (_strafeSpeed + _strafeAcceleration)*_drag;
				if (Math.abs(_strafeSpeed) < 0.01)
					_strafeSpeed = 0;
				_cameraController.incrementStrafe(_strafeSpeed);
			}
			
			//animate flames
			var flameVO:FlameVO;
			for each (flameVO in _flameData) {
				//update flame light
				var light : PointLight = flameVO.light;
				
				if (!light)
					continue;
				
				light.fallOff = 380+Math.random()*20;
				light.radius = 200+Math.random()*30;
				light.diffuse = .9+Math.random()*.1;
				
				//update flame mesh
				var mesh : Mesh = flameVO.mesh;
				
				if (!mesh)
					continue;
				
				var subMesh : SubMesh = mesh.subMeshes[0];
				subMesh.offsetU += 1/16;
				subMesh.offsetU %= 1;
				mesh.rotationY = Math.atan2(mesh.x - _view.camera.x, mesh.z - _view.camera.z)*180/Math.PI;
			}
			
			_view.render();
			
		}
		
				
		/**
		 * Key down listener for camera control
		 */
		private function onKeyDown(event:KeyboardEvent):void
		{
			switch (event.keyCode) {
				case Keyboard.UP:
				case Keyboard.W:
					_walkAcceleration = _walkIncrement;
					break;
				case Keyboard.DOWN:
				case Keyboard.S:
					_walkAcceleration = -_walkIncrement;
					break;
				case Keyboard.LEFT:
				case Keyboard.A:
					_strafeAcceleration = -_strafeIncrement;
					break;
				case Keyboard.RIGHT:
				case Keyboard.D:
					_strafeAcceleration = _strafeIncrement;
					break;
				case Keyboard.F:
					stage.displayState = StageDisplayState.FULL_SCREEN;
					break;
				case Keyboard.C:
					_cameraController.fly = !_cameraController.fly;
			}
		}
		
		/**
		 * Key up listener for camera control
		 */
		private function onKeyUp(event:KeyboardEvent):void
		{
			switch (event.keyCode) {
				case Keyboard.UP:
				case Keyboard.W:
				case Keyboard.DOWN:
				case Keyboard.S:
					_walkAcceleration = 0;
					break;
				case Keyboard.LEFT:
				case Keyboard.A:
				case Keyboard.RIGHT:
				case Keyboard.D:
					_strafeAcceleration = 0;
					break;
			}
		}
		
		/**
		 * Mouse down listener for navigation
		 */
		private function onMouseDown(event:MouseEvent):void
		{
			_move = true;
			_lastPanAngle = _cameraController.panAngle;
			_lastTiltAngle = _cameraController.tiltAngle;
			_lastMouseX = stage.mouseX;
			_lastMouseY = stage.mouseY;
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
			
			_text.x = (stage.stageWidth - _text.width)/2;
			_text.y = (stage.stageHeight - _text.height)/2;
			
			SignatureBitmap.y = stage.stageHeight - Signature.height;
			
			_awayStats.x = stage.stageWidth - _awayStats.width;
		}
		
        /**
         * log for display info
         */
        private function log(t:String):void
		{
            _text.htmlText = t;
			_text.visible = true;
        }
	}
}
import away3d.entities.*;
import away3d.lights.*;

import flash.geom.*;

/**
 * Data class for the Flame objects
 */
internal class FlameVO
{
	public var position : Vector3D;
	public var color : uint;
	public var mesh : Mesh;
	public var light : PointLight;
	
	public function FlameVO(position : Vector3D, color : uint)
	{
		this.position = position;
		this.color = color;
	}
}
