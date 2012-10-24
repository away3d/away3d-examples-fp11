package li.picking.overview.src
{

	import away3d.lights.PointLight;

	import li.base.src.ListingBase;

	public class PickingOverviewListingBase extends ListingBase
	{
		private var _light:PointLight;

		public function PickingOverviewListingBase() {
			super();
		}

		override protected function onSetup():void {
			super.onSetup();
			_light = new PointLight();
			_view.scene.addChild( _light );
		}

		override protected function onUpdate():void {
			super.onUpdate();
			_light.position = _view.camera.position;
		}
	}
}
