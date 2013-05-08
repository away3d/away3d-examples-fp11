/*

Sprite sheet animation example in Away3d

Demonstrates:

How to use the SpriteSheetAnimator.
- using TextureMaterial for single maps animations
- using SpriteSheetMaterial for multiple maps animations
- using the SpriteSheetHelper

Code by Fabrice Closier
fabrice3d@gmail.com
http://www.closier.nl

This code is distributed under the MIT License

Copyright (c) The Away Foundation http://www.theawayfoundation.org

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

package {
	import away3d.animators.SpriteSheetAnimationSet;
	import away3d.animators.SpriteSheetAnimator;
	import away3d.animators.nodes.SpriteSheetClipNode;
	import away3d.containers.*;
	import away3d.entities.*;
	import away3d.materials.*;
	import away3d.primitives.*;
	import away3d.textures.BitmapTexture;
	import away3d.textures.Texture2DBase;
	import away3d.tools.helpers.SpriteSheetHelper;
	import away3d.utils.*;

	import flash.display.*;
	import flash.events.*;
	import flash.geom.Vector3D;

	[SWF(backgroundColor="#000000", frameRate="60", quality="LOW")]
	
	public class Basic_SpriteSheetAnimation extends Sprite
	{
		//the sprite sheets sources
		[Embed(source="../embeds/spritesheets/testSheet1.jpg")]
		public static var testSheet1:Class;

		[Embed(source="../embeds/spritesheets/testSheet2.jpg")]
		public static var testSheet2:Class;
		
		//engine variables
		private var _view:View3D;
		 
		/**
		 * Constructor
		 */
		public function Basic_SpriteSheetAnimation()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			//setup the view
			_view = new View3D();
			addChild(_view);
			
			//setup the camera
			_view.camera.z = -1500;
			_view.camera.y = 200;
			_view.camera.lookAt(new Vector3D());
			
			//setup the meshes and their SpriteSheetAnimator
			prepareSingleMap();
			prepareMultipleMaps();
			
			//setup the render loop
			addEventListener(Event.ENTER_FRAME, _onEnterFrame);
			stage.addEventListener(Event.RESIZE, onResize);
			onResize();
		}

		/**
		 * setting up the spritesheets with a single map
		 */
		private function prepareSingleMap():void
		{
			//if the animation is something that plays non stop, and fits a single map,
			// you can use a regular TextureMaterial
			var material:TextureMaterial = new TextureMaterial(Cast.bitmapTexture(testSheet1));

			// the name of the animation
			var animID:String = "mySingleMapAnim";
			// to simplify the generation of the required nodes for the animator, away3d has an helper class.
			var spriteSheetHelper:SpriteSheetHelper = new SpriteSheetHelper();
			// first we make our SpriteSheetAnimationSet, which will hold one or more spriteSheetClipNode
			var spriteSheetAnimationSet:SpriteSheetAnimationSet = new SpriteSheetAnimationSet();
			// in this case our simple map is composed of 4 cells: 2 rows, 2 colums
			var spriteSheetClipNode:SpriteSheetClipNode = spriteSheetHelper.generateSpriteSheetClipNode(animID, 2, 2);
			//we can now add the animation to the set.
			spriteSheetAnimationSet.addAnimation(spriteSheetClipNode);
			// Finally we can build the animator and add the animation set to it.
			var spriteSheetAnimator:SpriteSheetAnimator = new SpriteSheetAnimator(spriteSheetAnimationSet);

			// construct the receiver geometry, in this case a plane;
			var mesh:Mesh = new Mesh(new PlaneGeometry(700, 700, 1, 1, false), material);
			mesh.x = -400;
			//asign the animator
			mesh.animator = spriteSheetAnimator;
			// because our very simple map has only 4 images in itself, playing it the same speed as the swf would be way too fast.
			spriteSheetAnimator.fps = 4;
			//start play the animation
			spriteSheetAnimator.play(animID);
  
			_view.scene.addChild(mesh);
		}

		/**
		* Because one animation may require more resolution or duration. The animation source may be spreaded over multiple sources
		* A dedicated material handles the maps management
		*/
		private function prepareMultipleMaps():void
		{
			//the first map, we the beginning of the animation
			var bmd1:BitmapData = Bitmap(new testSheet1()).bitmapData;
			var texture1:BitmapTexture = new BitmapTexture(bmd1);

			//the rest of teh animation
			var bmd2:BitmapData = Bitmap(new testSheet2()).bitmapData;
			var texture2:BitmapTexture = new BitmapTexture(bmd2);

			var diffuses:Vector.<Texture2DBase> = Vector.<Texture2DBase>([texture1, texture2]);
			var material:SpriteSheetMaterial = new SpriteSheetMaterial(diffuses);

			// the name of the animation
			var animID:String = "myMultipleMapsAnim";
			// to simplify the generation of the required nodes for the animator, away3d has an helper class.
			var spriteSheetHelper:SpriteSheetHelper = new SpriteSheetHelper();
			// first we make our SpriteSheetAnimationSet, which will hold one or more spriteSheetClipNode
			var spriteSheetAnimationSet:SpriteSheetAnimationSet = new SpriteSheetAnimationSet();
			// in this case our simple map is composed of 4 cells: 2 rows, 2 colums
			// note compared to the above "prepareSingleMap" method, we now pass a third parameter (2): how many maps are used inthis animation
			var spriteSheetClipNode:SpriteSheetClipNode = spriteSheetHelper.generateSpriteSheetClipNode(animID, 2, 2, 2);
			//we can now add the animation to the set and build the animator
			spriteSheetAnimationSet.addAnimation(spriteSheetClipNode);
			var spriteSheetAnimator:SpriteSheetAnimator = new SpriteSheetAnimator(spriteSheetAnimationSet);

			// construct the reciever geometry, in this case a plane;
			var mesh:Mesh = new Mesh(new PlaneGeometry(700, 700, 1, 1, false), material);
			mesh.x = 400;
			//asign the animator
			mesh.animator = spriteSheetAnimator;
			//the frame rate at which the animation should be played
			spriteSheetAnimator.fps = 10;
			//we can set the animation to play back and forth
			spriteSheetAnimator.backAndForth = true;

			//start play the animation
			spriteSheetAnimator.play(animID);
  
			_view.scene.addChild(mesh);
		}
		
		/**
		 * render loop
		 */
		private function _onEnterFrame(e:Event):void
		{	
			_view.render();
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