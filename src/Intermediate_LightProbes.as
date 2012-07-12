/*

 Light probe usage in Away3D 4.0

 Demonstrates:

 How to use the Loader3D object to load an embedded internal obj model.
 How to use LightProbe objects in combination with StaticLightPicker to simulate indirect lighting
 How to use shadow mapping with point lights

 Code by David Lenaerts
 www.derschmale.com

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
	import away3d.cameras.Camera3D;
	import away3d.containers.Scene3D;
	import away3d.containers.View3D;
	import away3d.controllers.LookAtController;
	import away3d.debug.AwayStats;
	import away3d.entities.Mesh;
	import away3d.events.AssetEvent;
	import away3d.library.AssetLibrary;
	import away3d.library.assets.AssetType;
	import away3d.lights.LightProbe;
	import away3d.lights.PointLight;
	import away3d.loaders.misc.AssetLoaderContext;
	import away3d.loaders.parsers.OBJParser;
	import away3d.materials.LightSources;
	import away3d.materials.TextureMaterial;
	import away3d.materials.lightpickers.StaticLightPicker;
	import away3d.materials.methods.FresnelSpecularMethod;
	import away3d.materials.methods.HardShadowMapMethod;
	import away3d.materials.methods.LightMapMethod;
	import away3d.materials.methods.RimLightMethod;
	import away3d.textures.BitmapTexture;
	import away3d.textures.SpecularBitmapTexture;

	import cornell.CornellDiffuseEnvMapFL;
	import cornell.CornellDiffuseEnvMapFR;
	import cornell.CornellDiffuseEnvMapNL;
	import cornell.CornellDiffuseEnvMapNR;

	import flash.display.Bitmap;
	import flash.display.BitmapData;

	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Vector3D;
	import flash.ui.Keyboard;

	[SWF(backgroundColor="#000000", frameRate="60")]

	public class Intermediate_LightProbes extends Sprite
	{
		//signature swf
		[Embed(source="/../embeds/signature.swf", symbol="Signature")]
		public var SignatureSwf : Class;

		// cornell baked lighting map
		[Embed(source="/../embeds/cornell.obj", mimeType="application/octet-stream")]
		private var CornellOBJ : Class;

		[Embed(source="/../embeds/head.obj", mimeType="application/octet-stream")]
		private var HeadOBJ : Class;

		// cornell map with baked AO and irradiance
		[Embed(source="/../embeds/cornell_baked.jpg")]
		private var CornellTexture : Class;

		// cornell map with baked AO and irradiance
		[Embed(source="/../embeds/cornellWallNormals.jpg")]
		private var CornellNormals : Class;

		[Embed(source="/../embeds/head_diffuse.jpg")]
		private var HeadAlbedo : Class;

		[Embed(source="/../embeds/head_normals.jpg")]
		private var HeadNormals : Class;

		[Embed(source="/../embeds/head_specular.jpg")]
		private var HeadSpecular : Class;

		[Embed(source="/../embeds/head_AO.jpg")]
		private var HeadOcclusion : Class;

		//engine variables
		private var scene : Scene3D;
		private var camera : Camera3D;
		private var view : View3D;
		private var cameraController : LookAtController;

		//signature variables
		private var Signature : Sprite;
		private var SignatureBitmap : Bitmap;

		//light objects
		private var mainLight : PointLight;
		private var lightProbeFL : LightProbe;
		private var lightProbeFR : LightProbe;
		private var lightProbeNL : LightProbe;
		private var lightProbeNR : LightProbe;

		private var mesh : Mesh;

		// movement related
		private var xDir : Number = 0;
		private var zDir : Number = 0;
		private var speed : Number = 2;
		private var mouseDown : Boolean;
		private var referenceMouseX : Number;

		private var headTexture : BitmapTexture;
		private var whiteTexture : BitmapTexture;
		private var headMaterial : TextureMaterial;

		/**
		 * Constructor
		 */
		public function Intermediate_LightProbes()
		{
			init();
		}

		/**
		 * Global initialise function
		 */
		private function init() : void
		{
			initEngine();
			initLights();
			initObjects();
			initListeners();
		}

		/**
		 * Initialise the engine
		 */
		private function initEngine() : void
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;

			scene = new Scene3D();

			camera = new Camera3D();
			camera.lens.far = 2000;
			camera.lens.near = 20;
			camera.lookAt(new Vector3D(0, 0, 1000));

			view = new View3D();
			view.antiAlias = 16;
			view.scene = scene;
			view.camera = camera;

			//setup controller to be used on the camera
			cameraController = new LookAtController(camera);

			//view.addSourceURL("srcview/index.html");
			addChild(view);

			//add signature
			Signature = Sprite(new SignatureSwf());
			SignatureBitmap = new Bitmap(new BitmapData(Signature.width, Signature.height, true, 0));
			SignatureBitmap.bitmapData.draw(Signature);
			addChild(SignatureBitmap);

			addChild(new AwayStats(view));
		}

		private function initLights() : void
		{
			mainLight = new PointLight();
			mainLight.castsShadows = true;
			// maximum, small scene
			mainLight.shadowMapper.depthMapSize = 1024;
			mainLight.y = 120;
			mainLight.color = 0xffffff;
			mainLight.diffuse = 1;
			mainLight.specular = 1;
			mainLight.radius = 400;
			mainLight.fallOff = 500;
			mainLight.ambient = 0xa0a0c0;
			mainLight.ambient = .5;
			scene.addChild(mainLight);

			// each map was taken at position +/-75, 0,  +-/75
			lightProbeFL = new LightProbe(new CornellDiffuseEnvMapFL());
			lightProbeFL.x = -75;
			lightProbeFL.z = 75;
			scene.addChild(lightProbeFL);
			lightProbeFR = new LightProbe(new CornellDiffuseEnvMapFR());
			lightProbeFR.x = 75;
			lightProbeFR.z = 75;
			scene.addChild(lightProbeFR);
			lightProbeNL = new LightProbe(new CornellDiffuseEnvMapNL());
			lightProbeNL.x = -75;
			lightProbeNL.z = -75;
			scene.addChild(lightProbeNL);
			lightProbeNR = new LightProbe(new CornellDiffuseEnvMapNR());
			lightProbeNR.x = 75;
			lightProbeNR.z = -75;
			scene.addChild(lightProbeNR);
		}

		/**
		 * Initialise the listeners
		 */
		private function initListeners() : void
		{
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.addEventListener(Event.RESIZE, onResize);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			onResize();
		}

		private function onMouseDown(event : MouseEvent) : void
		{
			mouseDown = true;
			referenceMouseX = stage.mouseX;
		}

		private function onMouseUp(event : MouseEvent) : void
		{
			mouseDown = false;
		}

		/**
		 * Navigation and render loop
		 */
		private function onEnterFrame(event : Event) : void
		{
			if (!mouseDown) {
				camera.x = camera.x*.9 + (stage.stageWidth*.5 - mouseX)*.05;
				camera.y = camera.y*.9 + (stage.stageHeight*.5 - mouseY)*.05;
				camera.z = - 300;
			}

			if (mesh) {
				if (mouseDown) {
					mesh.rotationY += (referenceMouseX - stage.mouseX)/5
					referenceMouseX = stage.mouseX;
				}
				mesh.x += xDir*speed;
				mesh.z += zDir*speed;
				if (mesh.x < -75) mesh.x = -75;
				else if (mesh.x > 75) mesh.x = 75;
				if (mesh.z < -75) mesh.z = -75;
				else if (mesh.z > 75) mesh.z = 75;
			}

			cameraController.update();

			view.render();
		}

		/**
		 * Initialise the scene objects
		 */
		private function initObjects() : void
		{
			AssetLibrary.enableParser(OBJParser);

			AssetLibrary.addEventListener(AssetEvent.ASSET_COMPLETE, onCornellComplete);
			AssetLibrary.loadData(CornellOBJ);
		}

		/**
		 * Listener function for asset complete event on loader
		 */
		private function onCornellComplete(event : AssetEvent) : void
		{
			var material : TextureMaterial;
			var mesh : Mesh;

			if (event.asset.assetType == AssetType.MESH) {
				mesh = Mesh(event.asset);
				//create material object and assign it to our mesh
				material = new TextureMaterial(new BitmapTexture(new CornellTexture().bitmapData));
				material.normalMap = new BitmapTexture(new CornellNormals().bitmapData);
				material.lightPicker = new StaticLightPicker([mainLight]);
				material.shadowMethod = new HardShadowMapMethod(mainLight);
				material.specular = .25;
				material.gloss = 20;
				mesh.material = material;
				mesh.scale(100);
				mesh.geometry.subGeometries[0].autoDeriveVertexNormals = true;

				scene.addChild(mesh);

				AssetLibrary.removeEventListener(AssetEvent.ASSET_COMPLETE, onCornellComplete);
				AssetLibrary.addEventListener(AssetEvent.ASSET_COMPLETE, onHeadComplete);
				AssetLibrary.loadData(HeadOBJ, new AssetLoaderContext(false));
			}
		}

		/**
		 * Listener function for asset complete event on loader
		 */
		private function onHeadComplete(event : AssetEvent) : void
		{
			var specularMethod : FresnelSpecularMethod;

			if (event.asset.assetType == AssetType.MESH) {
				mesh = Mesh(event.asset);
				//create material object and assign it to our mesh
				headTexture = new BitmapTexture(new HeadAlbedo().bitmapData);
				whiteTexture = new BitmapTexture(new BitmapData(512, 512, false, 0xbbbbaa));
				headMaterial = new TextureMaterial(headTexture);
				headMaterial.normalMap = new BitmapTexture(new HeadNormals().bitmapData);
				headMaterial.specularMap = new SpecularBitmapTexture(new HeadSpecular().bitmapData);
				specularMethod = new FresnelSpecularMethod();
				specularMethod.normalReflectance = .2;
				headMaterial.specularMethod = specularMethod;
				headMaterial.gloss = 10;
				headMaterial.addMethod(new RimLightMethod(0xffffff, .4, 5, RimLightMethod.ADD));
				headMaterial.addMethod(new LightMapMethod(new BitmapTexture(new HeadOcclusion().bitmapData)));
				headMaterial.lightPicker = new StaticLightPicker([mainLight, lightProbeFL, lightProbeFR, lightProbeNL, lightProbeNR]);
				headMaterial.diffuseLightSources = LightSources.PROBES;
				headMaterial.specularLightSources = LightSources.LIGHTS;

				// turn off ambient contribution from lights, it's included in the probes' contribution
				headMaterial.ambient = 0;
				mesh.scale(20);
				mesh.material = headMaterial;
				cameraController.lookAtObject = mesh;
				scene.addChild(mesh);
			}
		}

		/**
		 * Key down listener for animation
		 */
		private function onKeyDown(event : KeyboardEvent) : void
		{
			switch (event.keyCode) {
				case Keyboard.UP:
						zDir = 1;
					break;
				case Keyboard.DOWN:
						zDir = -1;
					break;
				case Keyboard.LEFT:
						xDir = -1;
					break;
				case Keyboard.RIGHT:
						xDir = 1;
					break;
			}
		}

		private function onKeyUp(event : KeyboardEvent) : void
		{
			switch (event.keyCode) {
				case Keyboard.UP:
				case Keyboard.DOWN:
						zDir = 0;
					break;
				case Keyboard.LEFT:
				case Keyboard.RIGHT:
						xDir = 0;
					break;
				case Keyboard.SPACE:
						switchTextures();
					break;
			}
		}

		private function switchTextures() : void
		{
			if (!headMaterial) return;

			if (headMaterial.texture == whiteTexture)
				headMaterial.texture = headTexture;
			else
				headMaterial.texture = whiteTexture;
		}

		/**
		 * stage listener for resize events
		 */
		private function onResize(event : Event = null) : void
		{
			view.width = stage.stageWidth;
			view.height = stage.stageHeight;
			SignatureBitmap.y = stage.stageHeight - Signature.height;
		}
	}
}
