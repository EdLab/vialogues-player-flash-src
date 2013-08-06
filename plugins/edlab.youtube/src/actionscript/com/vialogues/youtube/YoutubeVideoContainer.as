package com.vialogues.youtube
{
	import flash.display.DisplayObject;
	
	import org.flowplayer.view.AbstractSprite;
	
	public class YoutubeVideoContainer extends  AbstractSprite
	{
		private var _player:DisplayObject;
		
		public function YoutubeVideoContainer(obj:Object) {
			super();
			
			_player = obj as DisplayObject;
			updateVideoSize(320, 240);
			addChild(_player);
		}
		
		private function updateVideoSize(w:Number = 0,h:Number = 0):void{
			Object(_player).setSize(w ? w : width, h ? h : height);
		}
		
		public function set player(obj:Object):void{
			log.debug("set player():",obj);
			_player = obj as DisplayObject;
			updateVideoSize();
			
			removeChildren();
			addChild(_player);
			
		}
		
		public function get player():Object{
			return _player;
		}
		
		override protected function onResize():void{
			updateVideoSize();
		}
		
	}
}