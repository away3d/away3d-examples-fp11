package cornell
{
	import away3d.textures.BitmapCubeTexture;

	import flash.display.BitmapData;

	public class CornellDiffuseEnvMapFR extends BitmapCubeTexture
	{
		[Embed(source="/../embeds/cornellEnvMap/posXposZ/posX.jpg")]
		private var PosX : Class;
		[Embed(source="/../embeds/cornellEnvMap/posXposZ/negX.jpg")]
		private var NegX : Class;
		[Embed(source="/../embeds/cornellEnvMap/posXposZ/posY.jpg")]
		private var PosY : Class;
		[Embed(source="/../embeds/cornellEnvMap/posXposZ/negY.jpg")]
		private var NegY : Class;
		[Embed(source="/../embeds/cornellEnvMap/posXposZ/posZ.jpg")]
		private var PosZ : Class;
		[Embed(source="/../embeds/cornellEnvMap/posXposZ/negZ.jpg")]
		private var NegZ : Class;

		private var _posX : BitmapData;
		private var _negX : BitmapData;
		private var _posY : BitmapData;
		private var _negY : BitmapData;
		private var _posZ : BitmapData;
		private var _negZ : BitmapData;

		public function CornellDiffuseEnvMapFR()
		{
			super (	_posX = new PosX().bitmapData, _negX = new NegX().bitmapData,
					_posY = new PosY().bitmapData, _negY = new NegY().bitmapData,
					_posZ = new PosZ().bitmapData, _negZ = new NegZ().bitmapData
					);
		}


		override public function dispose() : void
		{
			super.dispose();
			_posX.dispose();
			_negX.dispose();
			_posY.dispose();
			_negY.dispose();
			_posZ.dispose();
			_negZ.dispose();
		}
	}
}
