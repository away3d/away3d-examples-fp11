package shallowwater
{

	import flash.display.Shader;
	import flash.display.ShaderJob;
	import flash.utils.ByteArray;

	/*
		 Calculates displacement, normals and tangents for a fluid grid simulation
		 using shallow water wave equations.
		 Uses pixel bender shaders via number vectors.
		 */
	public class ShallowFluid
	{
		private var _width:uint;
		private var _height:uint;
		private var _spacing:Number;
		private var _k1:Number, _k2:Number, _k3:Number;
		private var _points:Vector.<Vector.<Number>>;
		private var _renderBuffer:uint = 1;
		private var _normals:Vector.<Number>;
		private var _tangents:Vector.<Number>;
		private var _dt:Number;
		private var _realWaveSpeed:Number;
		private var _wantedWaveSpeed:Number;
		private var _viscosity:Number;

		[Embed("/../embeds/pb/WaveDisplacement.pbj", mimeType="application/octet-stream")]
		private var DisplacementShaderClass:Class;
		private var _displacementShader:Shader;

		[Embed("/../embeds/pb/WaveNormals.pbj", mimeType="application/octet-stream")]
		private var NormalsShaderClass:Class;
		private var _normalsShader:Shader;

		[Embed("/../embeds/pb/WaveTangents.pbj", mimeType="application/octet-stream")]
		private var TangentsShaderClass:Class;
		private var _tangentsShader:Shader;

		public function ShallowFluid( n:uint, m:uint, d:Number, t:Number, c:Number, mu:Number ) {
			_width = n;
			_height = m;
			_spacing = d;
			_dt = t;
			_viscosity = mu;

			// Init buffers.
			_points = new Vector.<Vector.<Number>>();
			_points[0] = new Vector.<Number>();
			_points[1] = new Vector.<Number>();
			_normals = new Vector.<Number>();
			_tangents = new Vector.<Number>();

			// Fill buffers.
			var a:uint, j:uint, i:uint;
			var count:uint = n * m;
			for( j = 0; j < m; j++ ) {
				var y:Number = d * j;
				for( i = 0; i < n; i++ ) {
					_points[0].push( d * i, y, 0.0 );
					_points[1].push( d * i, y, 0.0 );
					_normals.push( 0.0, 0.0, 2.0 * d );
					_tangents.push( 2.0 * d, 0.0, 0.0 );
					a++;
				}
			}

			// Initialize normals shader.
			_normalsShader = new Shader( new NormalsShaderClass() as ByteArray );
			_normalsShader.data.dd.value = [-2.0 * d];

			// Initialize normals shader.
			_tangentsShader = new Shader( new TangentsShaderClass() as ByteArray );
			_tangentsShader.data.dd.value = [-2.0 * d];

			// Initialize displacement shader.
			_displacementShader = new Shader( new DisplacementShaderClass() as ByteArray );
			switchBuffers();

			// Evaluate wave speed number and init constants.
			speed = c;
		}

		/*
		 Performa a calculation cycle.
		 */
		public function evaluate():void {
			// Evaluate displacement.
			var displacementJob:ShaderJob = new ShaderJob( _displacementShader, _points[1 - _renderBuffer], _width, _height );
			displacementJob.start( true );

			// Evaluate normals.
			var normalsJob:ShaderJob = new ShaderJob( _normalsShader, _normals, _width, _height );
			normalsJob.start( true );

			// Evaluate tangents.
			var tangentsJob:ShaderJob = new ShaderJob( _tangentsShader, _tangents, _width, _height );
			tangentsJob.start( true );

			switchBuffers();
		}

		/*
		 Displaces a point in the current and previous buffer to a
		 given position.
		 */
		public function displacePointStatic( n:uint, m:uint, displacement:Number ):void {
			var index:int = _width * m + n;
			_points[_renderBuffer][3 * index + 2] = displacement;
			_points[1 - _renderBuffer][3 * index + 2] = displacement;
		}

		/*
		 Displaces a point in the current and previous buffer by a
		 given amount.
		 */
		public function displacePoint( n:uint, m:uint, displacement:Number ):void {
			var index:int = _width * m + n;
			_points[_renderBuffer][3 * index + 2] += displacement;
			_points[1 - _renderBuffer][3 * index + 2] += displacement;
		}

		/*
		 WaveSpeed.
		 Changes the speed of the simulation, with other collateral effects.
		 Input between >0 and <1.
		 */
		public function set speed( value:Number ):void {
			_wantedWaveSpeed = value;
			_realWaveSpeed = value * (_spacing / (2 * _dt)) * Math.sqrt( _viscosity * _dt + 2 );
			preCalculateConstants();
		}

		public function get speed():Number {
			return _realWaveSpeed;
		}

		/*
		 Viscosity.
		 */
		public function get viscosity():Number {
			return _viscosity;
		}

		public function set viscosity( value:Number ):void {
			_viscosity = value;
			speed = _wantedWaveSpeed;
			preCalculateConstants();
		}

		/*
		 Get fluid normals.
		 */
		public function get normals():Vector.<Number> {
			return _normals;
		}

		/*
		 Get fluid tangents.
		 */
		public function get tangents():Vector.<Number> {
			return _tangents;
		}

		/*
		 Get fluid points.
		 */
		public function get points():Vector.<Number> {
			return _points[_renderBuffer];
		}

		/*
		 Get fluid dimensions.
		 */
		public function get gridWidth():Number {
			return _width;
		}

		public function get gridHeight():Number {
			return _height;
		}

		public function get gridSpacing():Number {
			return _spacing;
		}

		private function preCalculateConstants():void {
			var f1:Number = _realWaveSpeed * _realWaveSpeed * _dt * _dt / (_spacing * _spacing);
			var f2:Number = 1 / (_viscosity * _dt + 2);
			_k1 = (4 - 8 * f1) * f2;
			_k2 = (_viscosity * _dt - 2) * f2;
			_k3 = 2 * f1 * f2;

			_displacementShader.data.k1.value = [_k1];
			_displacementShader.data.k2.value = [_k2];
			_displacementShader.data.k3.value = [_k3];
			_displacementShader.data.dims.value = [_width - 1, _height - 1];
		}

		private function switchBuffers():void {
			_renderBuffer = 1 - _renderBuffer;

			_displacementShader.data.currentBuffer.input = _points[_renderBuffer];
			_displacementShader.data.previousBuffer.input = _points[1 - _renderBuffer];
			_displacementShader.data.currentBuffer.width = _width;
			_displacementShader.data.currentBuffer.height = _height;
			_displacementShader.data.previousBuffer.width = _width;
			_displacementShader.data.previousBuffer.height = _height;

			_normalsShader.data.currentBuffer.input = _points[_renderBuffer];
			_normalsShader.data.currentBuffer.width = _width;
			_normalsShader.data.currentBuffer.height = _height;

			_tangentsShader.data.currentBuffer.input = _points[_renderBuffer];
			_tangentsShader.data.currentBuffer.width = _width;
			_tangentsShader.data.currentBuffer.height = _height;
		}
	}
}
