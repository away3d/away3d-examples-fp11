package away3d.primitives
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.utils.getTimer;

	import away3d.containers.ObjectContainer3D;
	import away3d.containers.View3D;
	import away3d.debug.AwayStats;
	import away3d.textures.BitmapCubeTexture;


	[SWF(backgroundColor="#000000", frameRate="30", quality="LOW")]
	public class SkyBoxExample extends Sprite
	{

		[Embed(source="/../embeds/skybox/grid-negX.png")]
		protected const SkyNegX:Class;
		[Embed(source="/../embeds/skybox/grid-negY.png")]
		protected const SkyNegY:Class;
		[Embed(source="/../embeds/skybox/grid-negZ.png")]
		protected const SkyNegZ:Class;

		[Embed(source="/../embeds/skybox/grid-posX.png")]
		protected const SkyPosX:Class;
		[Embed(source="/../embeds/skybox/grid-posY.png")]
		protected const SkyPosY:Class;
		[Embed(source="/../embeds/skybox/grid-posZ.png")]
		protected const SkyPosZ:Class;

		protected var view:View3D;
		protected var lastTime:int;


		public function SkyBoxExample()
		{
			super();

			// create a viewport and add geometry to its scene
			view = new View3D();
			view.scene.addChild(createGeo());
			addChild(view);

			// add debug stats
			const stats:DisplayObject = addChild(new AwayStats(view));
			stats.x = stage.stageWidth - stats.width;
			stats.y = 0;

			// listen for enterframe to to render updates
			addEventListener(Event.ENTER_FRAME, update);
		}

		protected function createGeo():ObjectContainer3D
		{
			// skybox has its own mesh primitive, and uses a BitmapCubeTexture as its material
			const material:BitmapCubeTexture = new BitmapCubeTexture(new SkyPosX().bitmapData, new SkyNegX().bitmapData, new SkyPosY().bitmapData, new SkyNegY().bitmapData, new SkyPosZ().bitmapData, new SkyNegZ().bitmapData);
			const geometry:SkyBox = new SkyBox(material);

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
			// apply rotations and render
			view.camera.rotationX = 75 * Math.sin(2 * view.camera.rotationY * Math.PI / 180); // neck bob
			view.camera.rotationY += 12 * elapsed; // degrees per second

			view.render();
		}
	}
}
