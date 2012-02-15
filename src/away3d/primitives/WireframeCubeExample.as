package away3d.primitives
{
	import away3d.cameras.Camera3D;
	import away3d.containers.ObjectContainer3D;
	import away3d.containers.View3D;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.utils.getTimer;
	
	[SWF(backgroundColor="#000000", frameRate="30", quality="LOW")]
	public class WireframeCubeExample extends Sprite
	{
		
		protected var view:View3D;
		protected var geo:ObjectContainer3D;
		protected var lastTime:int;
		
		public function WireframeCubeExample()
		{
			super();
			
			// create a viewport and add it to the stage
			view = new View3D();
			view.backgroundColor = 0x2a2a2a;
			addChild(view);
			
			// add geometry to the scene
			geo = createGeo();
			view.scene.addChild(geo);
			
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
		
		protected function createGeo():ObjectContainer3D
		{
			var geometry:WireframeCube = new WireframeCube(100, 100, 100);
			return geometry;
		}
	}
}