package away3d.primitives
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.utils.getTimer;

	import away3d.cameras.Camera3D;
	import away3d.containers.ObjectContainer3D;
	import away3d.containers.View3D;
	import away3d.debug.AwayStats;


	[SWF(backgroundColor="#000000", frameRate="30", quality="LOW")]
	public class WireframePlaneExample extends Sprite
	{

		protected var view:View3D;
		protected var geo:ObjectContainer3D;
		protected var lastTime:int;


		public function WireframePlaneExample()
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
			const cam:Camera3D = view.camera;
			cam.y = 60;
			cam.z = -180;
			cam.lookAt(geo.position);
			geo.rotationX = -15;
			geo.rotationY = 10;

			// add debug stats
			const stats:DisplayObject = addChild(new AwayStats(view));
			stats.x = stage.stageWidth - stats.width;
			stats.y = 0;

			// listen for enterframe to to render updates
			addEventListener(Event.ENTER_FRAME, update);
		}

		protected function createGeo():ObjectContainer3D
		{
			const geometry:WireframePlane = new WireframePlane(100, 100, 10, 10, 0xffffff, 1, "xz");
			return geometry;
		}

		protected function get elapsed():Number
		{
			const now:int = getTimer();
			const value:Number = (lastTime ? (now - lastTime) : now) * .001; // seconds elapsed
			lastTime = now;
			return value;
		}

		protected function update(e:Event):void
		{
			const s:Number = elapsed;

			// apply rotations and render
			geo.rotationX = -30 + 30 * Math.sin(1 * geo.rotationY * Math.PI / 180 - Math.PI * .33); // sit up and lay down
			geo.rotationY += 18 * s; // degrees per second

			view.render();
		}
	}
}
