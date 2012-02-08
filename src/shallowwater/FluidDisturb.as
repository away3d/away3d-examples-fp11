package shallowwater
{

	import flash.display.BitmapData;
	import flash.geom.Vector3D;

	/*
	 Utility class that produces natural disturbances in a fluid simulation.
	 */
	public class FluidDisturb
	{
		private var _fluid:ShallowFluid;
		private var _memoryDisturbances:Vector.<MemoryDisturbance>;

		public function FluidDisturb( fluid:ShallowFluid ) {
			_fluid = fluid;
			_memoryDisturbances = new Vector.<MemoryDisturbance>();
		}

		/*
		 Disturbs the fluid using a bitmap image.
		 */
		public function disturbBitmapInstant( x:Number, y:Number, displacement:Number, image:BitmapData ):void {
			var i:uint, j:uint;
			var ix:Number, iy:Number;
			var gray:uint;

			// Precalculations.
			var imageGridWidth:uint = Math.floor( image.width / _fluid.gridSpacing );
			var imageGridHeight:uint = Math.floor( image.height / _fluid.gridSpacing );
			var sx:uint = Math.floor( _fluid.gridWidth * x ) - Math.floor( imageGridWidth / 2 );
			var sy:uint = Math.floor( _fluid.gridHeight * y ) - Math.floor( imageGridHeight / 2 );
			var ex:uint = sx + imageGridWidth;
			var ey:uint = sy + imageGridHeight;

			// Avoid over flows.
			if( sx < 0 || sy < 0 || ex > _fluid.gridWidth || ey > _fluid.gridHeight )
				return;

			// Loop.
			for( i = sx; i < ex; i++ ) {
				for( j = sy; j < ey; j++ ) {
					ix = Math.floor( image.width * (i - sx) / imageGridWidth );
					iy = Math.floor( image.height * (j - sy) / imageGridHeight );
					gray = image.getPixel( ix, image.height - iy ) & 0x0000FF;
					if( gray != 0 )
						_fluid.displacePoint( i, j, displacement * gray / 256 );
				}
			}
		}

		/*
		 Disturbs the fluid using a bitmap image.
		 The disturbance remains for a given time.
		 */
		public function disturbBitmapMemory( x:Number, y:Number, displacement:Number, image:BitmapData, time:int, speed:Number ):void {
			var disturbance:MemoryDisturbance = new MemoryDisturbance( time, speed );
			_memoryDisturbances.push( disturbance );

			var i:uint, j:uint;
			var ix:Number, iy:Number;
			var gray:uint;

			// Precalculations.
			var imageGridWidth:uint = Math.floor( image.width / _fluid.gridSpacing );
			var imageGridHeight:uint = Math.floor( image.height / _fluid.gridSpacing );
			var sx:uint = Math.floor( _fluid.gridWidth * x ) - Math.floor( imageGridWidth / 2 );
			var sy:uint = Math.floor( _fluid.gridHeight * y ) - Math.floor( imageGridHeight / 2 );
			var ex:uint = sx + imageGridWidth;
			var ey:uint = sy + imageGridHeight;

			// Avoid over flows.
			if( sx < 0 || sy < 0 || ex > _fluid.gridWidth || ey > _fluid.gridHeight )
				return;

			// Loop.
			for( i = sx; i < ex; i++ ) {
				for( j = sy; j < ey; j++ ) {
					ix = Math.floor( image.width * (i - sx) / imageGridWidth );
					iy = Math.floor( image.height * (j - sy) / imageGridHeight );
					gray = image.getPixel( ix, image.height - iy ) & 0x0000FF;
					if( gray != 0 )
						disturbance.addDisturbance( i, j, displacement * gray / 256 );
				}
			}
		}

		/*
		 Disturb a point with no smoothing.
		 Fast, but unnatural.
		 */
		public function disturbPoint( n:Number, m:Number, displacement:Number ):void {
			_fluid.displacePoint( Math.floor( n * _fluid.gridWidth ), Math.floor( m * _fluid.gridHeight ), displacement );
		}

		/*
		 Produces a circular, gaussian bell shaped disturbance in the fluid.
		 Results in natural, jaggedless, drop-like disturbances.
		 n - [0, 1] - x coordinate.
		 m - [0, 1] - y coordinate.
		 displacement - z displacement of the disturbance.
		 radius - controls the opening of the gaussian bell and the wideness of the affected sub-grid.
		 */
		public function disturbPointGaussian( n:Number, m:Number, displacement:Number, radius:Number ):void {
			// Id target point in grid.
			var epiX:uint = Math.floor( n * _fluid.gridWidth );
			var epiY:uint = Math.floor( m * _fluid.gridHeight );

			// Find start point.
			var sX:uint = epiX - radius / 2;
			var sY:uint = epiY - radius / 2;

			// Loop.
			var i:uint, j:uint;
			var x:uint, y:uint, d:Number, dd:Number, dx:Number, dy:Number;
			var maxDis:Number = radius / 2;
			for( i = 0; i < radius; i++ ) {
				for( j = 0; j < radius; j++ ) {
					x = sX + i;
					y = sY + j;

					if( x == epiX && y == epiY ) {
						_fluid.displacePoint( x, y, displacement );
					}
					else {
						// Eval distance to epicenter.
						dx = epiX - x;
						dy = epiY - y;
						dd = dx * dx + dy * dy;
						d = Math.sqrt( dd );

						if( d < maxDis ) {
							_fluid.displacePoint( x, y, displacement * Math.pow( 2, -dd * radius / 100 ) ); // Gaussian distribution (could have many options here).
						}
					}
				}
			}
		}

		public function releaseMemoryDisturbances():void {
			var i:uint, j:uint;
			var loop:uint = _memoryDisturbances.length;
			for( i = 0; i < loop; i++ ) {
				var memoryDisturbance:MemoryDisturbance = _memoryDisturbances[i];
				memoryDisturbance.concluded = true;
			}
		}

		public function updateMemoryDisturbances():void {
			var i:uint, j:uint;
			var loop:uint = _memoryDisturbances.length;
			for( i = 0; i < loop; i++ ) {
				var memoryDisturbance:MemoryDisturbance = _memoryDisturbances[i];

				// Advance the memory disturbance's time.
				memoryDisturbance.update();

				// Check caducity.
				if( memoryDisturbance.concluded ) {
					memoryDisturbance = null;
					_memoryDisturbances.splice( i, 1 );
					i--;
					loop--;
					continue;
				}

				// Update the memory disturbance's points on the fluid.
				var subLoop:uint = memoryDisturbance.disturbances.length;
				for( j = 0; j < subLoop; j++ ) {
					var disturbance:Vector3D = memoryDisturbance.disturbances[j];
					_fluid.displacePointStatic( disturbance.x, disturbance.y, disturbance.z * memoryDisturbance.growth );
				}
			}
		}
	}
}
