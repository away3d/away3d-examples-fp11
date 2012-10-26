package li.picking.overview.src
{

	import away3d.lights.PointLight;

	import li.base.ListingBase;

	public class PickingOverviewListingBase extends ListingBase
	{
		private var _light:PointLight;

		public function PickingOverviewListingBase() {
			super();
		}

		override protected function initAway3d():void {
			super.initAway3d();
			_light = new PointLight();
			_lightPicker.lights = [ _light ];
			_view.scene.addChild( _light );
		}

		override protected function onUpdate():void {
			super.onUpdate();
			_light.position = _view.camera.position;
		}
	}
}
