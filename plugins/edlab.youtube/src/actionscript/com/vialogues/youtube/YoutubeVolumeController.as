package com.vialogues.youtube {	
	import org.flowplayer.model.PlayerEvent;
	import org.flowplayer.util.Log;
	import org.flowplayer.view.PlayerEventDispatcher;
	
	public class YoutubeVolumeController  {
		
		private var _videoObj:Object;
		private var _playerEventDispatcher:PlayerEventDispatcher;
		private var log:Log = new Log(this);
		
		public function YoutubeVolumeController(playerEventDispatcher:PlayerEventDispatcher) {	
			_playerEventDispatcher = playerEventDispatcher;
		}
		
		public function set videoObj(obj:Object):void{
			_videoObj = obj;
		}
				
		public function get volume():Number {
			log.debug("get volume() :: "+_videoObj.getVolume());
			return _videoObj.getVolume();
		}
		
		public function set volume(volumePercentage:Number):void {			
			if (this.volume == volumePercentage) return;
			
			var wasMuted:Boolean = this.muted;
			
			if (volumePercentage > 100) {
				volumePercentage = 100;
			}
			
			if (volumePercentage < 0) {
				volume = 0;
			}
			
			_videoObj.setVolume(volumePercentage);
			log.debug("set volume() :: to "+volumePercentage);
			
			// keep muted
			if(wasMuted) doMute();
						
		}
		
		public function get muted():Boolean {
			log.debug("get muted() ::"+_videoObj.isMuted());
			return _videoObj.isMuted();
		}
		
		public function set muted(muteIt:Boolean):void {
			log.debug("set muted() :: "+muteIt);
			if (muteIt) {
				doMute();
			} else {
				unMute();
			}
		}
		
		private function doMute():void {
			if(muted) return;
			
			_videoObj.mute();

			log.debug("doMute() :: isMuted = "+_videoObj.isMuted());
		}
		
		private function unMute():void {
			if(!muted) return;
			
			_videoObj.unMute();
			
			log.debug("unMute() :: isMuted = "+_videoObj.isMuted());
		}
		
		private function dispatchEvent(event:PlayerEvent):void {
			_playerEventDispatcher.dispatchEvent(event);
		}
	}
}