package li.materials.globe.src
{

	import away3d.entities.Mesh;
	import away3d.lights.PointLight;
	import away3d.materials.ColorMaterial;
	import away3d.materials.TextureMaterial;
	import away3d.primitives.SkyBox;
	import away3d.primitives.SphereGeometry;
	import away3d.textures.BitmapCubeTexture;
	import away3d.utils.Cast;

	import li.base.ListingBase;

	public class GlobeListing02 extends ListingBase
	{
		// Diffuse map for globe.
		[Embed(source="/../embeds/globe/land_ocean_ice_2048_match.jpg")]
		public static var EarthDiffuse:Class;

		// Normal map for globe.
		[Embed(source="/../embeds/globe/EarthNormal.png")]
		public static var EarthNormals:Class;

		// Specular map for globe.
		[Embed(source="/../embeds/globe/earth_specular_2048.jpg")]
		public static var EarthSpecular:Class;

		// Skybox textures.
		[Embed(source="../../../../embeds/skybox/space_posX.jpg")]
		private var PosX:Class;
		[Embed(source="../../../../embeds/skybox/space_negX.jpg")]
		private var NegX:Class;
		[Embed(source="../../../../embeds/skybox/space_posY.jpg")]
		private var PosY:Class;
		[Embed(source="../../../../embeds/skybox/space_negY.jpg")]
		private var NegY:Class;
		[Embed(source="../../../../embeds/skybox/space_posZ.jpg")]
		private var PosZ:Class;
		[Embed(source="../../../../embeds/skybox/space_negZ.jpg")]
		private var NegZ:Class;

		private var _earth:Mesh;

		public function GlobeListing02() {
			super();
		}

		override protected function onSetup():void {

			// View settings.
			_view.camera.lens.far = 12000;

			createSun();
			createEarth();
			createSpace();
		}

		private function createSun():void {

			// Light object.
			var light:PointLight = new PointLight();
			light.x = 10000;
			light.diffuse = 2;
			light.ambient = 1;
			_lightPicker.lights = [ light ];

			// Geometry.
			var sun:Mesh = new Mesh( new SphereGeometry( 500 ), new ColorMaterial( 0xFFFFFF ) );
			sun.x = 10000;
			_view.scene.addChild( sun );
		}

		private function createEarth():void {

			// Material.
			var earthMaterial:TextureMaterial = new TextureMaterial( Cast.bitmapTexture( EarthDiffuse ) );
			earthMaterial.normalMap = Cast.bitmapTexture( EarthNormals );
			earthMaterial.specularMap = Cast.bitmapTexture( EarthSpecular );
			earthMaterial.gloss = 5;
			earthMaterial.specular = 0.75;
			earthMaterial.ambient = 0.2;
			earthMaterial.lightPicker = _lightPicker;

			// Geometry.
			_earth = new Mesh( new SphereGeometry( 100, 200, 100 ), earthMaterial );
			_view.scene.addChild( _earth );
		}

		private function createSpace():void {

			// Cube texture.
			var cubeTexture:BitmapCubeTexture = new BitmapCubeTexture(
					Cast.bitmapData( PosX ), Cast.bitmapData( NegX ),
					Cast.bitmapData( PosY ), Cast.bitmapData( NegY ),
					Cast.bitmapData( PosZ ), Cast.bitmapData( NegZ ) );

			// Skybox geometry.
			var skyBox:SkyBox = new SkyBox( cubeTexture );
			_view.scene.addChild( skyBox );
		}

		override protected function onUpdate():void {
			super.onUpdate();
			_earth.rotationY += 0.1;
		}
	}
}
