package shallowwater
{

	import flash.geom.Vector3D;
	import flash.utils.getTimer;

	public class MemoryDisturbance
	{
		private var _disturbances:Vector.<Vector3D>;
		private var _targetTime:int;
		private var _elapsedTime:uint;
		private var _startTime:uint;
		private var _concluded:Boolean;
		private var _growthRate:Number;
		private var _growth:Number;

		/*
		 time is the time that the disturbance will last.
		 if -1, disturbance lasts until manually concluded.
		 */
		public function MemoryDisturbance( time:int, speed:Number ) {
			_targetTime = time;
			_startTime = getTimer();
			_disturbances = new Vector.<Vector3D>();
			_growth = 0;
			_growthRate = speed;
		}

		public function get growth():Number {
			return _growth;
		}

		public function get disturbances():Vector.<Vector3D> {
			return _disturbances;
		}

		public function addDisturbance( x:uint, y:uint, displacement:Number ):void {
			_disturbances.push( new Vector3D( x, y, displacement ) );
		}

		public function update():void {
			if( _concluded )
				return;

			_growth += _growthRate;
			_growth = _growth > 1 ? 1 : _growth;

			if( _targetTime < 0 )
				return;

			_elapsedTime = getTimer() - _startTime;

			if( _elapsedTime >= _targetTime )
				_concluded = true;
		}

		public function get concluded():Boolean {
			return _concluded;
		}

		public function set concluded( value:Boolean ):void {
			_concluded = value;
		}
	}
}
