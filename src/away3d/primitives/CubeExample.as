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
	
	public class CubeExample extends Sprite
	{
		
		protected var view:View3D;
		protected var userTransform:UserTransform;
		protected var geo:Mesh;
		
		public function CubeExample()
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
			cam.z = -120;
			cam.lookAt(geo.position);
			geo.rotationY = -15;
			
			// let user manipulate camera orientation
			userTransform = new UserTransform(stage, geo.transform);
			
			// listen for enterframe to to render updates
			addEventListener(Event.ENTER_FRAME,update);
		}
		
		protected function update(e:Event):void
		{
			// apply current user rotations
			userTransform.update();
			geo.transform = userTransform.value;
			
			// render the view
			view.render();
		}
		
		protected function createGeo():Mesh
		{
			// cube has its own geo primitive, and can color or texture materials
			var geometry:CubeGeometry = new CubeGeometry(25, 50, 75);
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