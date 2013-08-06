package com.vialogues.youtube
{
	import flash.events.NetStatusEvent;
	
	import org.flowplayer.controller.ClipURLResolver;
	import org.flowplayer.controller.StreamProvider;
	import org.flowplayer.model.Clip;
	
	public class YoutubeURLResolver implements ClipURLResolver {
		private var _config:Configuration;
		
		public function YoutubeURLResolver(config:Configuration) {
			_config = config;
		}
		
		public function set onFailure(listener:Function):void {
		}
		
		public function resolve(provider:StreamProvider, clip:Clip, successListener:Function):void {
			try{
				clip.setResolvedUrl(this,_config.vid);
				clip.provider = "youtube";
				
				successListener(clip);
			} catch(err:Error){ }
		}
		
		/**
		 * Called when a netStatusEvent is received.
		 * @param event
		 * @return if false, the streamProvider will ignore this event and will not send any events for it
		 */
		public function handeNetStatusEvent(event:NetStatusEvent):Boolean {
			return false;
		}
	}
}