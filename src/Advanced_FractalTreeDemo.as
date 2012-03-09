/*

Dynamic tree generation and placement in a night-time scene

Demonstrates:

How to create a height map and splat map from scratch to use for realistic terrain
How to use fratacl algorithms to create a custom tree-generating geometry primitive
How to save GPU memory by cloning complex.

Code by Rob Bateman & Alejadro Santander
rob@infiniteturtles.co.uk
http://www.infiniteturtles.co.uk
Alejandro Santander
http://www.lidev.com.ar/

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
	import away3d.debug.*;
	import away3d.entities.*;
	import away3d.extrusions.*;
	import away3d.lights.*;
	import away3d.materials.*;
	import away3d.materials.lightpickers.*;
	import away3d.materials.methods.*;
	import away3d.primitives.*;
	import away3d.textures.*;
	
	import com.bit101.components.Label;
	
	import flash.display.*;
	import flash.events.*;
	import flash.filters.*;
	import flash.geom.*;
	import flash.net.*;
	import flash.ui.*;
	import flash.utils.*;
	
	import shallowwater.*;
	
	import uk.co.soulwire.gui.*;
	
	
	[SWF(backgroundColor="#000000", frameRate="30", quality="LOW")]
	
	public class Advanced_FractalTreeDemo extends Sprite
	{
		//signature swf
		[Embed(source="/../embeds/signature.swf", symbol="Signature")]
		public var SignatureSwf:Class;
		
		//skybox
		[Embed(source="/../embeds/skybox/grimnight_posX.png")]
		private var EnvPosX:Class;
		[Embed(source="/../embeds/skybox/grimnight_posY.png")]
		private var EnvPosY:Class;
		[Embed(source="/../embeds/skybox/grimnight_posZ.png")]
		private var EnvPosZ:Class;
		[Embed(source="/../embeds/skybox/grimnight_negX.png")]
		private var EnvNegX:Class;
		[Embed(source="/../embeds/skybox/grimnight_negY.png")]
		private var EnvNegY:Class;
		[Embed(source="/../embeds/skybox/grimnight_negZ.png")]
		private var EnvNegZ:Class;
		
		//tree diffuse map
		[Embed (source="../embeds/tree/bark0.jpg")]
		public var TrunkDiffuse:Class;
		
		//tree normal map
		[Embed (source="../embeds/tree/barkNRM.png")]
		public var TrunkNormals:Class;
		
		//tree specular map
		[Embed (source="../embeds/tree/barkSPEC.png")]
		public var TrunkSpecular:Class;
		
		//leaf diffuse map
		[Embed (source="../embeds/tree/leaf4.jpg")]
		public var LeafDiffuse:Class;
		
		//splat texture maps
		[Embed(source="/../embeds/terrain/grass.jpg")]
		private var Grass:Class;
		[Embed(source="/../embeds/terrain/rock.jpg")]
		private var Rock:Class;
		
		//engine variables
		private var scene:Scene3D;
		private var camera:Camera3D;
		private var view:View3D;
		private var awayStats:AwayStats;
		private var cameraController:HoverController;
		
		//signature variables
		private var Signature:Sprite;
		private var SignatureBitmap:Bitmap;
		
		//light objects
		private var moonLight:DirectionalLight;
		private var cameraLight:PointLight;
		private var skyLight:DirectionalLight;
		private var lightPicker:StaticLightPicker;
		private var fogMethod:FogMethod;
		
		//material objects
		private var heightMapData:BitmapData;
		private var blendBitmapData:BitmapData;
		private var destPoint:Point = new Point();
		private var blendTexture:BitmapTexture;
		private var terrainMethod:TerrainDiffuseMethod;
		private var terrainMaterial:TextureMaterial;
		private var trunkMaterial:TextureMaterial;
		private var leafMaterial:TextureMaterial;
		private var cubeTexture:BitmapCubeTexture;
		
		//scene objects
		private var terrain:Elevation;
		private var tree:Mesh;
		private var foliage:Mesh;
		private var gui:SimpleGUI;
		
		//navigation variables
		private var move:Boolean = false;
		private var lastPanAngle:Number;
		private var lastTiltAngle:Number;
		private var lastMouseX:Number;
		private var lastMouseY:Number;
		private var tiltSpeed:Number = 2;
		private var panSpeed:Number = 2;
		private var distanceSpeed:Number = 1000;
		private var tiltIncrement:Number = 0;
		private var panIncrement:Number = 0;
		private var distanceIncrement:Number = 0;
		
		//gui objects
		private var treeCountLabel:Label;
		private var polyCountLabel:Label;
		private var terrainPolyCountLabel:Label;
		private var treePolyCountLabel:Label;
		
		//tree configuration variables
		private var treeLevel:uint = 10;
		private var treeCount:uint = 25;
		private var treeTimer:Timer;
		private var treeDelay:uint = 0;
		private var treeSize:Number = 1000;
		private var treeMin:Number = 0.75
		private var treeMax:Number = 1.25;
		
		//foliage configuration variables
		private var leafSize:Number = 300;
		private var leavesPerCluster:uint = 5;
		private var leafClusterRadius:Number = 400;
		
		//terrain configuration variables
		private var terrainY:Number = -10000;
		private var terrainWidth:Number = 200000;
		private var terrainHeight:Number = 50000;
		private var terrainDepth:Number = 200000;
		private var cameraTerrainHeight:Number = 5000;
		
		private var currentTreeCount:uint;
		private var polyCount:uint;
		private var terrainPolyCount:uint;
		private var treePolyCount:uint;
		private var clonesCreated:Boolean;
		
		public var minAperture:Number = 0.4;
		public var maxAperture:Number = 0.5;
		public var minTwist:Number = 0.3;
		public var maxTwist:Number = 0.6;
		
		/**
		 * Constructor
		 */
		public function Advanced_FractalTreeDemo()
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
			initGUI();
			initListeners();
		}
		
		/**
		 * Initialise the engine
		 */
		private function initEngine():void
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			view = new View3D();
			scene = view.scene;
			camera = view.camera;
			camera.lens.far = 1000000;
			
			//setup controller to be used on the camera
			cameraController = new HoverController(camera, null, 0, 10, 25000, 0, 70);
			
			view.addSourceURL("srcview/index.html");
			addChild(view);
			
			//add signature
			Signature = Sprite(new SignatureSwf());
			SignatureBitmap = new Bitmap(new BitmapData(Signature.width, Signature.height, true, 0));
			stage.quality = StageQuality.HIGH;
			SignatureBitmap.bitmapData.draw(Signature);
			stage.quality = StageQuality.LOW;
			addChild(SignatureBitmap);
			
			awayStats = new AwayStats(view);
			addChild(awayStats);
		}
		
		/**
		 * Initialise the lights
		 */
		private function initLights():void
		{
			moonLight = new DirectionalLight();
			moonLight.position = new Vector3D(3500, 4500, 10000); // Appear to come from the moon in the sky box.
			moonLight.lookAt(new Vector3D(0, 0, 0));
			moonLight.diffuse = 0.5;
			moonLight.specular = 0.25;
			moonLight.color = 0xFFFFFF;
			scene.addChild(moonLight);
			cameraLight = new PointLight();
			cameraLight.diffuse = 0.25;
			cameraLight.specular = 0.25;
			cameraLight.color = 0xFFFFFF;
			cameraLight.radius = 1000;
			cameraLight.fallOff = 2000;
			scene.addChild(cameraLight);
			skyLight = new DirectionalLight();
			skyLight.diffuse = 0.1;
			skyLight.specular = 0.1;
			skyLight.color = 0xFFFFFF;
			scene.addChild(skyLight);
			
			lightPicker = new StaticLightPicker([moonLight, cameraLight, skyLight]);
			
			//create a global fog method
			fogMethod = new FogMethod(0, 200000, 0x000000);
		}
		
		/**
		 * Initialise the material
		 */
		private function initMaterials():void
		{
			//create skybox texture
			cubeTexture = new BitmapCubeTexture(new EnvPosX().bitmapData, new EnvNegX().bitmapData, new EnvPosY().bitmapData, new EnvNegY().bitmapData, new EnvPosZ().bitmapData, new EnvNegZ().bitmapData);
			
			//create tree material
			trunkMaterial = new TextureMaterial(new BitmapTexture(new TrunkDiffuse().bitmapData));
			trunkMaterial.normalMap = new BitmapTexture(new TrunkNormals().bitmapData);
			trunkMaterial.specularMap = new BitmapTexture(new TrunkSpecular().bitmapData);
			trunkMaterial.diffuseMethod = new BasicDiffuseMethod();
			trunkMaterial.specularMethod = new BasicSpecularMethod();
			trunkMaterial.addMethod(fogMethod);
			trunkMaterial.lightPicker = lightPicker;
			
			//create leaf material
			leafMaterial = new TextureMaterial(new BitmapTexture(new LeafDiffuse().bitmapData));
			leafMaterial.addMethod(fogMethod);
			leafMaterial.lightPicker = lightPicker;
			
			//create height map
			heightMapData = new BitmapData(512, 512, false, 0x0);
			heightMapData.perlinNoise(200, 200, 4, uint(1000*Math.random()), false, true, 7, true);
			heightMapData.draw(createGradientSprite(512, 512, 1, 0));
			
			//create terrain diffuse method
			blendBitmapData = heightMapData.clone();
			blendBitmapData.threshold(blendBitmapData, blendBitmapData.rect, destPoint, ">", 0x444444, 0xFF00FF00, 0xFFFFFF, true);
			blendBitmapData.colorTransform(blendBitmapData.rect, new ColorTransform(1, 1, 1, 1, 255, 0, 0, 0));
			blendBitmapData.applyFilter(blendBitmapData, blendBitmapData.rect, destPoint, new BlurFilter(16, 16, 3));
			blendTexture = new BitmapTexture(blendBitmapData);
			terrainMethod = new TerrainDiffuseMethod([new BitmapTexture(new Grass().bitmapData), new BitmapTexture(new Rock().bitmapData), new BitmapTexture(new BitmapData(512, 512, false, 0x000000))], blendTexture, [1, 20, 20, 1]);
			
			//create terrain material
			terrainMaterial = new TextureMaterial(new BitmapTexture(heightMapData));
			terrainMaterial.diffuseMethod = terrainMethod;
			terrainMaterial.addMethod(new FogMethod(0, 200000, 0x000000)); //TODO: global fog method affects splats when updated
			terrainMaterial.lightPicker = lightPicker;
		}
		
		/**
		 * Initialise the scene objects
		 */
		private function initObjects():void
		{		
			//create skybox.
			scene.addChild(new SkyBox(cubeTexture));
			
			
			
			//create terrain
			terrain = new Elevation(terrainMaterial, heightMapData, terrainWidth, terrainHeight, terrainDepth, 65, 65);
			terrain.y = terrainY;
			terrain.smoothHeightMap();
			scene.addChild(terrain);
			
			terrainPolyCount = terrain.geometry.subGeometries[0].vertexData.length/3;
			polyCount += terrainPolyCount;
		}
		
		/**
		 * Initialise the GUI
		 */
		private function initGUI():void
		{
			gui = new SimpleGUI(this);
			
			gui.addColumn("Instructions");
			var instr:String = "Click and drag to rotate camera.\n\n";
			instr += "Arrows and WASD also rotate camera.\n\n";
			instr += "Z and X zoom camera.\n\n";
			instr += "Create a tree, then clone it to\n";
			instr += "populate the terrain with trees.\n";
			gui.addLabel(instr);
			gui.addColumn("Tree");
			gui.addSlider("minAperture", 0, 1, {label:"min aperture", tick:0.01});
			gui.addSlider("maxAperture", 0, 1, {label:"max aperture", tick:0.01});
			gui.addSlider("minTwist", 0, 1, {label:"min twist", tick:0.01});
			gui.addSlider("maxTwist", 0, 1, {label:"max twist", tick:0.01});
			gui.addButton("Generate Fractal Tree", {callback:generateTree, width:160});
			gui.addColumn("Forest");
			gui.addButton("Clone!", {callback:generateClones});
			treeCountLabel = gui.addControl(Label, {text:"trees: 0"}) as Label;
			polyCountLabel = gui.addControl(Label, {text:"polys: 0"}) as Label;
			treePolyCountLabel = gui.addControl(Label, {text:"polys/tree: 0"}) as Label;
			terrainPolyCountLabel = gui.addControl(Label, {text:"polys/terrain: 0"}) as Label;
			gui.show();
			
			updateLabels();
		}
		
		/**
		 * Initialise the listeners
		 */
		private function initListeners():void
		{
			
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			view.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			view.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.addEventListener(Event.RESIZE, onResize);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			onResize();
		}
		
		public function generateTree():void
		{
			if(tree) {
				currentTreeCount--;
				scene.removeChild(tree);
				tree = null;
			}
			
			if(foliage) {
				scene.removeChild(foliage);
				foliage = null;
			}
			
			createTreeShadow(0, 0);
			
			
			// Create tree.
			var treeGeometry:FractalTreeRound = new FractalTreeRound(treeSize, 10, 3, minAperture, maxAperture, minTwist, maxTwist, treeLevel)
			tree = new Mesh(treeGeometry, trunkMaterial);
			tree.rotationY = 360*Math.random();
			tree.y = terrain != null ? terrain.y + terrain.getHeightAt(tree.x, tree.z) : 0;
			scene.addChild(tree);
			
			// Create tree leaves.
			foliage = new Mesh(new Foliage(treeGeometry.leafPositions, leavesPerCluster, leafSize, leafClusterRadius), leafMaterial);
			foliage.x = tree.x;
			foliage.y = tree.y;
			foliage.z = tree.z;
			foliage.rotationY = tree.rotationY;
			scene.addChild(foliage);
			
			// Count.
			currentTreeCount++;
			treePolyCount = tree.geometry.subGeometries[0].vertexData.length/3 + foliage.geometry.subGeometries[0].vertexData.length/3;
			polyCount += treePolyCount;
			updateLabels();
		}
		
		public function generateClones():void
		{
			if(!tree || clonesCreated)
				return;
			
			// Start tree creation.
			if(treeCount > 0) {
				treeTimer = new Timer(treeDelay, treeCount - 1);
				treeTimer.addEventListener(TimerEvent.TIMER, onTreeTimer);
				treeTimer.start();
			}
			
			clonesCreated = true;
		}
		
		private function createTreeShadow(x:Number, z:Number):void
		{
			// Paint on the terrain's shadow blend layer
			var matrix:Matrix = new Matrix();
			var dx:Number = (x/terrainWidth + 0.5)*512 - 8;
			var dy:Number = (-z/terrainDepth + 0.5)*512 - 8;
			matrix.translate(dx, dy);
			var treeShadowBitmapData = new BitmapData(16, 16, false, 0x0000FF);
			treeShadowBitmapData.draw(createGradientSprite(16, 16, 0, 1), matrix);
			blendBitmapData.draw(treeShadowBitmapData, matrix, null, BlendMode.ADD);
			
			// Update the terrain.
			blendTexture.bitmapData = blendBitmapData; // TODO: invalidation routine not active for blending texture
		}
		
		private function createGradientSprite(width:Number, height:Number, alpha1:Number, alpha2:Number):Sprite
		{
			var gradSpr:Sprite = new Sprite();
			var matrix:Matrix = new Matrix();
			matrix.createGradientBox(width, height, 0, 0, 0);
			gradSpr.graphics.beginGradientFill(GradientType.RADIAL, [0xFF000000, 0xFF000000], [alpha1, alpha2], [0, 255], matrix);
			gradSpr.graphics.drawRect(0, 0, width, height);
			gradSpr.graphics.endFill();
			return gradSpr;
		}
		
		private function updateLabels():void
		{
			treeCountLabel.text = "trees: " + currentTreeCount;
			polyCountLabel.text = "polys: " + polyCount;
			treePolyCountLabel.text = "polys/tree: " + treePolyCount;
			terrainPolyCountLabel.text = "polys/terrain: " + terrainPolyCount;
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
			
			cameraController.panAngle += panIncrement;
			cameraController.tiltAngle += tiltIncrement;
			cameraController.distance += distanceIncrement;
			
			// Update light.
			cameraLight.transform = camera.transform.clone();
			
			view.render();
		}
		
		/**
		 * Key down listener for camera control
		 */
		private function onKeyDown(event:KeyboardEvent):void
		{
			switch (event.keyCode) {
				case Keyboard.UP:
				case Keyboard.W:
					tiltIncrement = tiltSpeed;
					break;
				case Keyboard.DOWN:
				case Keyboard.S:
					tiltIncrement = -tiltSpeed;
					break;
				case Keyboard.LEFT:
				case Keyboard.A:
					panIncrement = panSpeed;
					break;
				case Keyboard.RIGHT:
				case Keyboard.D:
					panIncrement = -panSpeed;
					break;
				case Keyboard.Z:
					distanceIncrement = distanceSpeed;
					break;
				case Keyboard.X:
					distanceIncrement = -distanceSpeed;
					break;
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
					tiltIncrement = 0;
					break;
				case Keyboard.LEFT:
				case Keyboard.A:
				case Keyboard.RIGHT:
				case Keyboard.D:
					panIncrement = 0;
					break;
				case Keyboard.Z:
				case Keyboard.X:
					distanceIncrement = 0;
					break;
			}
		}
		
		/**
		 * Mouse down listener for navigation
		 */
		private function onMouseDown(event:MouseEvent):void
		{
			move = true;
			lastPanAngle = cameraController.panAngle;
			lastTiltAngle = cameraController.tiltAngle;
			lastMouseX = stage.mouseX;
			lastMouseY = stage.mouseY;
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
			awayStats.x = stage.stageWidth - awayStats.width;
		}
		
		/**
		 * stage listener for resize events
		 */
		private function onTreeTimer(event:TimerEvent):void
		{
			//create tree clone.
			var treeClone:Mesh = tree.clone() as Mesh;
			treeClone.x = terrainWidth*Math.random() - terrainWidth/2;
			treeClone.z = terrainDepth*Math.random() - terrainDepth/2;
			treeClone.y = terrain != null ? terrain.y + terrain.getHeightAt(treeClone.x, treeClone.z) : 0;
			treeClone.rotationY = 360*Math.random();
			treeClone.scale((treeMax - treeMin)*Math.random() + treeMin);
			scene.addChild(treeClone);
			
			//create foliage clone.
			var foliageClone:Mesh = foliage.clone() as Mesh;
			foliageClone.x = treeClone.x;
			foliageClone.y = treeClone.y;
			foliageClone.z = treeClone.z;
			foliageClone.rotationY = treeClone.rotationY;
			foliageClone.scale(treeClone.scaleX);
			scene.addChild(foliageClone);
			
			//create tree shadow clone.
			createTreeShadow(treeClone.x, treeClone.z);
			
			//count.
			currentTreeCount++;
			polyCount += treePolyCount;
			updateLabels();
		}		
		
	}
}
