package away3d.primitives
{
	import away3d.cameras.Camera3D;
	import away3d.containers.View3D;
	import away3d.entities.Mesh;
	import away3d.lights.DirectionalLight;
	import away3d.lights.LightBase;
	import away3d.materials.ColorMaterial;
	import away3d.tools.helpers.LightsHelper;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.utils.getTimer;
	
	[SWF(backgroundColor="#000000", frameRate="30", quality="LOW")]
	public class CubeExample extends Sprite
	{
		
		protected var view:View3D;
		protected var geo:Mesh;
		protected var lastTime:int;
		
		public function CubeExample()
		{
			super();
			
			// create a viewport and add it to the stage
			view = new View3D();
			view.backgroundColor = 0x2a2a2a;
			addChild(view);
			
			// add geometry to the scene
			geo = createGeo();
			view.scene.addChild(geo);
			
			// add lighting to the scene
			var lights:Vector.<LightBase> = createLights();
			for (var i:uint = 0; i < lights.length; i++) view.scene.addChild(lights[i]);
			
			// apply lighting to geometry
			LightsHelper.addStaticLightsToMaterials(geo, lights);
			
			// set the camera and object for a good view
			var cam:Camera3D = view.camera;
			cam.y = 60;
			cam.z = -200;
			cam.lookAt(geo.position);
			geo.rotationY = -15;
			
			// listen for enterframe to to render updates
			addEventListener(Event.ENTER_FRAME,update);
		}
		
		protected function update(e:Event):void
		{
			var s:Number = elapsed;
			
			// apply rotations and render
			geo.rotationX += 7 * s; // degrees per second
			geo.rotationY += 12 * s; // degrees per second
			
			view.render();
		}
		
		protected function get elapsed():Number
		{
			var now:int = getTimer();
			var value:Number = (lastTime ? (now - lastTime) : now) * .001; // seconds elapsed
			lastTime = now;
			return value;
		}
		
		protected function createGeo():Mesh
		{
			var geometry:CubeGeometry = new CubeGeometry();
			var material:ColorMaterial = new ColorMaterial();
			var mesh:Mesh = new Mesh(geometry, material);
			return mesh;
		}
		
		protected function createLights():Vector.<LightBase>
		{
			// simple two-point light setup: key, fill
			var key:DirectionalLight = new DirectionalLight(.5, -1, .75);
			key.color = 0xffffff;
			key.ambient = 0;
			key.diffuse = .75;
			key.specular = .4;
			
			var fill:DirectionalLight = new DirectionalLight(-1, .5, .75);
			fill.color = 0xffffff;
			fill.ambient = 0;
			fill.diffuse = .25;
			fill.specular = 0;
			
			var lights:Vector.<LightBase> = new <LightBase>[key, fill];
			return lights;
		}
	}
}