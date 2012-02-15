package away3d.primitives
{
	import away3d.cameras.Camera3D;
	import away3d.containers.View3D;
	import away3d.entities.Mesh;
	import away3d.lights.DirectionalLight;
	import away3d.lights.LightBase;
	import away3d.materials.ColorMaterial;
	import away3d.materials.lightpickers.StaticLightPicker;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.utils.getTimer;
	
	[SWF(backgroundColor="#000000", frameRate="30", quality="LOW")]
	public class PlaneExample extends Sprite
	{
		
		protected var view:View3D;
		protected var geo:Mesh;
		protected var lastTime:int;
		
		public function PlaneExample()
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
			var light:LightBase = createLight();
			view.scene.addChild(light);
			
			// apply lighting to geometry
			geo.material.lightPicker = new StaticLightPicker([light]);
			// LightsHelper.addStaticLightToMaterials(geo, light); // <-- this is another alternative
			
			// set the camera and object for a good view
			var cam:Camera3D = view.camera;
			cam.y = 60;
			cam.z = -180;
			cam.lookAt(geo.position);
			geo.rotationX = -15;
			geo.rotationY = 10;
			
			// listen for enterframe to to render updates
			addEventListener(Event.ENTER_FRAME,update);
		}
		
		protected function update(e:Event):void
		{
			var s:Number = elapsed;

			// apply rotations and render
			geo.rotationX = -30 + 30 * Math.sin(1*geo.rotationY*Math.PI/180 - Math.PI*.33); // sit up and lay down
			geo.rotationY += 18 * s; // degrees per second
			
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
			var geometry:PlaneGeometry = new PlaneGeometry(); // default yUp means horizontal plane (normal is +y)
			var material:ColorMaterial = new ColorMaterial();
			var mesh:Mesh = new Mesh(geometry, material);
			return mesh;
		}
		
		protected function createLight():LightBase
		{
			var light:DirectionalLight = new DirectionalLight(0, -1, 1);
			light.color = 0xffffff;
			light.ambient = 0;
			light.diffuse = .75;
			light.specular = .4;
			
			return light;
		}
	}
}