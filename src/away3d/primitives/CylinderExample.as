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
	
	public class CylinderExample extends Sprite
	{
		
		protected var view:View3D;
		protected var geo:Mesh;
		protected var lastTime:int;
		
		public function CylinderExample()
		{
			super();
			
			// create a viewport and add it to the stage
			view = new View3D();
			view.backgroundColor = 0x333333;
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
			cam.z = -240;
			cam.lookAt(geo.position);
			geo.rotationX = -30;
			
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
			var geometry:CylinderGeometry = new CylinderGeometry();
			var material:ColorMaterial = new ColorMaterial(0xee7722);
			var mesh:Mesh = new Mesh(geometry, material);
			
			return mesh;
		}
		
		protected function createLight():LightBase
		{
			var light:DirectionalLight = new DirectionalLight(1, -1, 1);
			light.color = 0xffffff;
			light.diffuse = .8;
			
			return light;
		}
	}
}