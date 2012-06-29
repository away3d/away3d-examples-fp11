/*

3D Tweening example in Away3d

Demonstrates:

How to use Tweener within a 3D coordinate system.
How to create a 3D mouse event listener on a scene object.
How to return the scene coordinates of a mouse click on the surface of a scene object.

Code by Rob Bateman
rob@infiniteturtles.co.uk
http://www.infiniteturtles.co.uk

This code is distributed under the MIT License

Copyright (c)  

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

package
{
	import away3d.containers.*;
	import away3d.core.pick.*;
	import away3d.entities.*;
	import away3d.events.*;
	import away3d.materials.*;
	import away3d.primitives.*;
	import away3d.utils.*;
	
	import caurina.transitions.Tweener;
	import caurina.transitions.properties.CurveModifiers;
	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.Vector3D;

	[SWF(backgroundColor="#000000", frameRate="60", quality="LOW")]
	
	public class Basic_Tweening3D extends Sprite
	{
		//plane texture
		[Embed(source="/../embeds/floor_diffuse.jpg")]
		public static var FloorDiffuse:Class;
		
		//cube texture jpg
		[Embed(source="/../embeds/trinket_diffuse.jpg")]
		public static var TrinketDiffuse:Class;
		
		//engine variables
		private var _view:View3D;
		
		//scene objects
		private var _plane:Mesh; 
		private var _cube:Mesh;
		
		/**
		 * Constructor
		 */
		public function Basic_Tweening3D()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			//setup the view
			_view = new View3D();
			addChild(_view);
			
			//setup the camera
			_view.camera.z = -600;
			_view.camera.y = 500;
			_view.camera.lookAt(new Vector3D());
			
			//setup the scene
			_cube = new Mesh(new CubeGeometry(100, 100, 100, 1, 1, 1, false), new TextureMaterial(Cast.bitmapTexture(TrinketDiffuse)));
			_cube.y = 50;
			_view.scene.addChild(_cube);
			
			_plane = new Mesh(new PlaneGeometry(700, 700), new TextureMaterial(Cast.bitmapTexture(FloorDiffuse)));
			_plane.pickingCollider = PickingColliderType.AS3_FIRST_ENCOUNTERED;
			_plane.mouseEnabled = true;
			_view.scene.addChild(_plane);
			
			//add mouse listener
			_plane.addEventListener(MouseEvent3D.MOUSE_UP, _onMouseUp);
			
			//initialize Tweener curve modifiers
			CurveModifiers.init();
			
			//setup the render loop
			addEventListener(Event.ENTER_FRAME, _onEnterFrame);
			stage.addEventListener(Event.RESIZE, onResize);
			onResize();
		}
		
		/**
		 * render loop
		 */
		private function _onEnterFrame(e:Event):void
		{
			_view.render();
		}
		
		/**
		 * mesh listener for mouse up interaction
		 */
		private function _onMouseUp(ev:MouseEvent3D) : void
		{
			Tweener.addTween(_cube, { time:0.5, x:ev.scenePosition.x, z:ev.scenePosition.z, _bezier:{x:_cube.x, z:ev.scenePosition.z} });
		}
		
		/**
		 * stage listener for resize events
		 */
		private function onResize(event:Event = null):void
		{
			_view.width = stage.stageWidth;
			_view.height = stage.stageHeight;
		}
	}
}
