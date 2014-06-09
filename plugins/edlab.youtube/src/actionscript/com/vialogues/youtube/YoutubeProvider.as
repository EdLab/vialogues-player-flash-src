package com.vialogues.youtube {
	import com.vialogues.youtube.Configuration;
	
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.system.Security;
	import flash.system.SecurityDomain;
	import flash.utils.Dictionary;
	
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	
	import org.flowplayer.controller.StreamProvider;
	import org.flowplayer.controller.TimeProvider;
	import org.flowplayer.controller.VolumeController;
	import org.flowplayer.model.Clip;
	import org.flowplayer.model.ClipEvent;
	import org.flowplayer.model.ClipEventType;
	import org.flowplayer.model.ClipType;
	import org.flowplayer.model.DisplayProperties;
	import org.flowplayer.model.PlayerEvent;
	import org.flowplayer.model.Playlist;
	import org.flowplayer.model.Plugin;
	import org.flowplayer.model.PluginModel;
	import org.flowplayer.util.Assert;
	import org.flowplayer.util.Log;
	import org.flowplayer.util.PropertyBinder;
	import org.flowplayer.view.Flowplayer;
	
	public class YoutubeProvider implements Plugin, StreamProvider {
		
		private const YOUTUBE_PLAYER_ADS_HEIGHT:Number = 120;
		private var log:Log = new Log(this);
		
		// Flowplayer assets
		private var _config:Configuration;
		private var _model:PluginModel;
		private var _player:Flowplayer;
		private var _clip:Clip;
		private var _timeProvider:TimeProvider;
		private var _pauseAfterStart:Boolean;
		private var _volumeController:YoutubeVolumeController;
		private var _screen:DisplayProperties;
		private var _controls:DisplayProperties;
		private var _duration:Number; // Keeping a duration for reference. This is the duration got from the real video instead of from gdata
		
		private var _autoplay:Boolean;
		private var _loop:Boolean;
		
		// Youtube player assets
		private var _ytplayerLoader:Loader;
		private var _ytplayer:Object;
		private var _playlist:Playlist;
		private var _video:YoutubeVideoContainer;
		private var seekingYoutube:Boolean = false;
		
		public function YoutubeProvider(){
			//silence is gold
		}
		
		/**
		 * Configure plugin. This function is called in the very beginning of the plugin life
		 */
		public function onConfig(model:PluginModel):void{
			log.debug("onconfig() :: ");
			
			if(_model) return;
			
			_model = model;
			_config = new PropertyBinder(new Configuration(), null).copyProperties(model.config) as Configuration;
			// whenever a new config param is added for this plugin, make sure to create a getter and setter in Configuration.as
			
		}
		
		/**
		 * Prepare Youtube player. This function is called only once immediately after onConfig after the plugin is loaded.
		 */
		public function onLoad(player:Flowplayer):void{
			
			_player = player;
			_playlist = _player.playlist;
			_screen = _player.pluginRegistry.getPlugin("screen") as DisplayProperties; // this should be the same as _screen = _player.screen
			_controls = _player.pluginRegistry.getPlugin("controls") as DisplayProperties; 
			
			log.debug("onload() :: autoplay=" + _autoplay);
			
			if(!_playlist.current) {
				log.error("onLoad() :: no clip to play");
				//_model.dispatchError(PluginError.INIT_FAILED);
				return;
			}
			
			_clip = _playlist.current;
			_autoplay = _clip.autoPlay ? true : false; // use the common clip's autoplay setting
			
			_config.initTime = _clip.start ? _clip.start : 0;
			
			// Allow accessing Youtube media servers
			for(var sdom:String in _config.securityDomains) {
				Security.allowDomain(_config.securityDomains[sdom]);
			}
			
			log.debug("onload() :: obtaining youtube chromeless player");

			_ytplayerLoader = new Loader();
			
			// Load the Youtube chromeless player. Chromeless player should be loaded even if the Youtube video is not playable.
			_ytplayerLoader.contentLoaderInfo.addEventListener(Event.INIT, onYTPlayerInit);
			_ytplayerLoader.load(new URLRequest(_config.player_url));

		}
		
		/**
		 * Prepare Youtube clip. This function is called every time to load an old or new Youtube video.
		 */
		private function prepareYoutubeClip(clip:Clip):void {

			// Convert clip type to API. In Javascript, the clip url MUST be something like "api:bCGmUCDj4Nc" as Flowplayer is coded to work this way.
			clip.type = ClipType.API;
			clip.autoPlay = _autoplay;
			clip.autoBuffering = false;
			clip.metaData = false;
			
			clip.startDispatched = false;
			
			// Unbind event listeners (if any) before binding so as to avoid double binding
			clip.unbind(onAllEvents);
			
			clip.onAll(onAllEvents);
			
			// Request video metadata from Youtube data API
			_config.vid = clip.url;
			
			log.debug("prepareYoutubeClip() :: requesting clip data from " + _config.data_api);

			var newVideoData:HTTPService = new HTTPService();
			newVideoData.url = _config.data_api;
			newVideoData.method = "GET";
			newVideoData.resultFormat = "e4x";
			newVideoData.addEventListener(ResultEvent.RESULT, onGDataReceived);
			newVideoData.addEventListener(FaultEvent.FAULT, onGDataFault);
			newVideoData.send();
		}
		
		/**
		 * Handle error while requesting video metadata
		 */
		private function onGDataFault(evt:FaultEvent):void{
			
			log.error("onGDataFault() :: video metadata cannot be retrieved", evt.message);
			
			switch(evt.message.headers.DSStatusCode) {
				case 403: // Forbidden
					_player.showError("The requested video is private. Please contact the video uploader if you think this is a mistake.");
					break;
				case 404: // Not Found
					_player.showError("The requested video is not found. Please double check the video id you provided.");
					break;
				case 500: // Internal Server Error
					_player.showError("The Youtube server responded with an Internal Error code. Please try again later.");
					break;
				default:
					_player.showError("Could not retrieve video information.");
			}
				
		}
		
		/**
		 * Process video metadata upon receiving
		 */
		private function onGDataReceived(evt:ResultEvent):void{
			
			log.debug("onGDataReceived() :: ");
			
			var gdata:XML = evt.result as XML;
			_config.gdata =  gdata;
			_duration = _config.duration;
			
			// Make sure the Youtube video allows embedding
			if(!_config.embedAllowed){
				_player.showError("Embedding disabled by the video owner. Please watch on Youtube at " + youtubeUrl);
				return;
			}
			
			updateClip(_clip, _config);
			
			// Resolve clip URL and start playing
			new YoutubeURLResolver(_config).resolve(this, _clip, onClipUrlResolved);
		}
		
		/**
		 * Update clip metadata
		 */
		private function updateClip(clip:Clip=null,config:Configuration=null):void{
			
			clip = clip ? clip : _clip;
			config = config ? config : _config;
			
			// The metadata object must be manually created for the clip
			clip.metaData = {
				duration: _duration,
				bytesTotal: 0, // video size info will be updated once it becomes available after playback begins
				width: 320, // default video width from youtube api
				height: 240 // default video height from youtube api
			};
			
			log.debug("updateClip()", clip.metaData);
			
		}
		
		/**
		 * Callback function when the youtube player is loaded before ready to accept API calls
		 * Init youtube player
		 */
		private function onYTPlayerInit(event:Event):void {
			
			try{
				
				_ytplayer = _ytplayerLoader.content as Object;
				_ytplayer.addEventListener("onReady", onYTPlayerReady);
				_ytplayer.addEventListener("onError", onYTPlayerError);
				_ytplayer.addEventListener("onStateChange", onYTPlayerStateChange);
				
				log.debug("onYTPlayerInit() :: all listeners added");
				
			} catch(err:Error){
				log.error("onYTPlayerInit() :: "+err.name, err.message);
			}
		}
		
		/**
		 * Callback function when the youtube player is ready to accept API calls
		 */
		private function onYTPlayerReady(event:Event):void{
			
			log.debug("onYTPlayerReady() :: "+event.type);
			
			// setup volume control			
			_volumeController = new YoutubeVolumeController(_player);
			_volumeController.videoObj = _ytplayer;
			_volumeController.volume = _player.volume;
			_volumeController.muted = _player.muted;
			
			_player.onMute(onPlayerVolumeEvents);
			_player.onUnmute(onPlayerVolumeEvents);
			_player.onVolume(onPlayerVolumeEvents);
			
			_video = new YoutubeVideoContainer(_ytplayer);
			
			_clip.setContent(_video);
			// Here, because _video is newly created without content, its width/height is 10
			// Clip originalWidth and originalHeight should be updated once actual video is loaded in _video
			
			_model.dispatchOnLoad(); // Let Flowplayer know this plugin is ready
			
			// log.debug("onYTPlayerReady() :: controller muted = "+_volumeController.muted + "; volume = "+_volumeController.volume);
		}
		
		/**
		 * Callback function when an player error occurs
		 */
		private function onYTPlayerError(event:ErrorEvent):void {
			log.error("onYTPlayerError() :: ", Object(event).data);
		}
		
		/**
		 * Handle Flowplayer volume events
		 */
		private function onPlayerVolumeEvents(event:PlayerEvent):void{
			
			log.debug("onPlayerVolumeEvents() :: "+event.target.toString());
			
			try{
				switch(event.type){
					case "onMute":
						this._volumeController.muted = true;
						break;
					case "onUnmute":
						this._volumeController.muted = false;
						break;
					case "onVolume":
						this._volumeController.volume = event.info as Number;
						break;
				}
			}catch(err:Error){
				log.error("onPlayerVolumeEvents() :: "+err.name, err.message);
			}
		}
		
		/**
		 * Load the Youtube video when clip URL is resolved
		 */
		private function onClipUrlResolved(clip:Clip):void {
			log.debug("onClipUrlResolved() :: " + clip.typeStr + " :: " + clip.completeUrl);
			
			_ytplayer.loadVideoById(_config.vid, _config.initTime ? _config.initTime : 0);
		}
		
		/**** Event handlers **/
		
		/**
		 * Handle all clip events passed from Flowplayer.
		 * Some of these events are already handled by the interface methods of StreamProvider. Do not double handle them.
		 */
		private function onAllEvents(event:ClipEvent):void{
			
			var clip:Clip = event.target as Clip;
			
			switch(event.type){
				case "onBegin":
					log.debug("onAllEvents() :: onBegin :: clip duration is " + clip.duration);
					break;
				case "onStart":
					log.debug("onAllEvents() :: onStart");
					break;
				case "onResume":
					log.debug("onAllEvents() :: onResume");
					break;
				case "onPause":
					log.debug("onAllEvents() :: onPause");
					break;
				case "onSeek":
					log.debug("onAllEvents() :: onSeek :: " + Number(event.info));
					break;
				case "onFinish":
					
					if(_playlist.hasNext()) {
						log.debug("onAllEvents() :: onFinish :: has next video");
					} else {
						log.debug("onAllEvents() :: onFinish :: last video");
						_player.stop();
					}
					
					clip.unbind(onAllEvents);
					clip.startDispatched = false;
					break;
				case "onError":
					log.error("onAllEvents() :: " + event.eventType.name, event.info);
					break;
				case "onResized":
					if(clip.provider == "youtube") {
						// Update the overlay on top of the displaylist so as to keep youtube ads and logo interactable
						try{
							Object(_screen.getDisplayObject()).setVideoApiOverlaySize(_video.width,_video.height-YOUTUBE_PLAYER_ADS_HEIGHT);
						} catch(err:Error){
							log.debug("cannot resize screen overlay ",err);
						}
					}
					break;
				case "onBufferFull":
					log.debug("onAllEvents() :: onBufferFull");
					break;
				default:
					log.debug("onAllEvents() :: " + event.toString() + "; Flowplayer "+_player.state);
					
			}
			
		}
		
		/**
		 * Callback when ytplayer state changes.
		 * Some of these events are already handled by the interface methods of StreamProvider. Do not double handle them.
		 */
		private function onYTPlayerStateChange(event:Event):void {
			
			if(_clip.provider != 'youtube') return;
			
			switch (int(Object(event).data)) {
				case -1: //Params.STATE_UNSTARTED
					break;
				case 0: //Params.STATE_ENDED
					
					// Notify Flowplayer about ending the Youtube clip because they are not often synch
					_clip.dispatch(ClipEventType.LAST_SECOND);
					_clip.dispatch(ClipEventType.FINISH);
					
					break;
				case 1: //Params.STATE_PLAYING
					
					if(!_clip.startDispatched) { // This is when the clip starts playing
						
						_clip.dispatch(ClipEventType.BEGIN);
						/*
						the BEGIN clip event:
						This is always the first event to fire during the 'lifecycle' of a clip, and it 
						does so as soon as the clip's video file has started buffering. Playback of the 
						clip has not yet commenced, but streaming/downloading has been successfully 
						initiated.
						*/
						
						_clip.metaData.bytesTotal = _ytplayer.getVideoBytesTotal() as Number;	
						_clip.duration = _duration;
						_clip.durationFromMetadata = _duration;
						
						// Update clip original dimension since now _video has loaded the Youtube clip.
						// This is required so that the clip is correctly sized from the start.
						_clip.originalWidth = _video.width;
						_clip.originalHeight = _video.height;
						
						_clip.dispatch(ClipEventType.UPDATE);
						
						_clip.dispatch(ClipEventType.START);
						/*
						the START clip event:
						This fires at the point at which playback commences. With autoBuffering set 
						to true it even fires when autoPlay is false, because the clip is paused at 
						the first frame.
						*/
						_clip.startDispatched = true;
						
						log.debug("onYTPlayerStateChange() :: playback begin");
						
						if(_pauseAfterStart && !_autoplay) {
							_clip.dispatch(ClipEventType.PAUSE);// dispatching pause event to clip here will not update player status
							log.debug("onYTPlayerStateChange() :: auto pause after start");
						}
						
					} else { // This is seeking the clip
						
						log.debug("onYTPlayerStatechange() :: resuming");
						
						if(seekingYoutube) {
							_clip.dispatch(ClipEventType.SEEK, (time / duration)); 
							// Dispatch SEEK event instead of RESUME or PAUSE despite the prior state
							// Flowplayer will automatically restore to the prior state
							
							seekingYoutube = false;
						}
					}
					
					break;
				case 2: //Params.STATE_PAUSED
					//_clip.dispatch(ClipEventType.BUFFER_FULL);
					break;
				case 3: //Params.STATE_BUFFERING
					_clip.dispatch(ClipEventType.BUFFER_EMPTY);
					break;
				case 5: //Params.STATE_CUED
					log.debug("onYTPlayerStateChange() :: youtube video is cued");
					break;
				default:
					log.debug("onYTPlayerStateChange() :: " + int(Object(event).data));
			}			
		}
		
		/**
		 * Load Youtube video (interface method)
		 */
		public function load(event:ClipEvent, clip:Clip, pauseAfterStart:Boolean=true):void{			
			
			log.debug("load() :: pauseAfterStart ? " + pauseAfterStart);
			
			_pauseAfterStart = pauseAfterStart;
			_load(clip);
		}
		
		/**
		 * Load Youtube video (internal method)
		 */
		private function _load(clip:Clip, attempts:int = 3):void {
			
			Assert.notNull(clip, "_load(clip): clip cannot be null");
			
			if(!_ytplayer) log.error("_load() :: Youtube chromeless player not loaded");
			
			log.debug("_load() :: " + clip.index);
			
			_clip = clip;
			
			if(clip.provider == "youtube"){ // If clip provider is not Youtube then leave it to Flowplayer
				prepareYoutubeClip(_clip);
			}
			
		}
		
				
		/**** Interface Methods **/
		
		public function pause(event:ClipEvent):void{
			log.debug("pause() :: ");
			if(event) {
				_clip.dispatchEvent(event); // event object is passed when pause is fired through the controlbar
				_pause();
			}
		}
		
		private function _pause():void{
			log.debug("_pause()");
			if(isVideoPlaying()) _ytplayer.pauseVideo();
		}
		
		public function resume(event:ClipEvent):void{
			log.debug("resume() :: ");
			if(event) {
				_clip.dispatchEvent(event); // event object is passed when resume is fired through the controlbar
				_resume();
			}
		}
		
		private function _resume():void{
			log.debug("_resume() :: isVideoPaused=" + isVideoPaused());
			if(isVideoPaused()) _ytplayer.playVideo();
		}
		
		/**
		 * Seek the Flowplayer container
		 */
		public function seek(event:ClipEvent, seconds:Number):void{
			
			if (Math.abs(seconds - time) < 0.5) return; // not seeking if the requested time is too close
			
			log.debug("seek() :: " + seconds);
			
			if(seconds >= 0) _seek(seconds);
			else log.error("seek() :: invalid seek time :: " + seconds);
			
		}
		
		/**
		 * Seek the Youtube Chromeless player
		 */
		private function _seek(seconds:Number):void{
			
			seconds = Math.floor(seconds);
			
			log.debug("_seek() :: " + seconds);
			
			seekingYoutube = true;
			
			_ytplayer.seekTo(seconds, true);
						
			/*
			FIX-NEEDED: Although seekAhead is recommended to set to FALSE before user finishes dragging, we are 
			using TRUE for now because there is no way to tell if the Flowplayer playhead is being dragged.
			*/
		}
		
		public function stop(event:ClipEvent, closeStream:Boolean=false):void{
			log.debug("stop() :: "+event.type);
			_clip.dispatchEvent(event);
		}
		
		private function isVideoPlaying():Boolean{
			return (_ytplayer.getPlayerState() == 1);			
		}
		
		private function isVideoPaused():Boolean{
			return(_ytplayer.getPlayerState() == 2);
		}
		
		public function getDefaultConfig():Object{
			log.debug("getDefaultConfig() :: ");
			
			return {
				backgroundColor: '#000000',
				top: 0,
				left: 0,
				height: '100%',
				width: '100%',
				zIndex: 0
			};
		}
		
		public function getVideo(clip:Clip):DisplayObject{
			
			//clip = _playlist.current;
			log.debug("getVideo() :: " + clip.index);
			
			return _video ? _video : {} as DisplayObject;
		}
		
		public function attachStream(video:DisplayObject):void{
			log.debug("attachStream() :: ");
		}
		
		public function addConnectionCallback(name:String, listener:Function):void{
			//log.debug("addConnectionCallback() :: ");
		}
		
		public function addStreamCallback(name:String, listener:Function):void{
			//log.debug("addStreamCallback() :: ");
		}
		
		public function switchStream(event:ClipEvent, clip:Clip, netStreamPlayOptions:Object=null):void{
			log.debug("switchStream() :: ");
		}
		
		public function get time():Number{			
			//log.debug("get time() :: "+_ytplayer.getCurrentTime());
			return _ytplayer.getCurrentTime(); // don't round the time as that may cause a whole second lag of the video
		}
		
		public function get bufferStart():Number{
			return 0;
			//return _ytplayer && _config.duration ? _ytplayer.getVideoStartBytes() / _ytplayer.getVideoBytesTotal() * _config.duration : 0;
		}
		
		public function get bufferEnd():Number{
			// Simply return the whole video duration to avoid messiness and increase performance 
			//as requesting bytesLoaded too often from chromeless player decreases performance
			return _ytplayer && _duration ? _duration : 0;
			//return _ytplayer && _config.duration ? (_ytplayer.getVideoStartBytes() + _ytplayer.getVideoBytesLoaded()) / _ytplayer.getVideoBytesTotal() * _config.duration : 0;			
		}
		
		public function get allowRandomSeek():Boolean{
			return true;
		}
		
		public function set volumeController(controller:VolumeController):void{
			// do not replace the current volumecontroller as the new one will erase the videoObj
		}
		
		public function get stopping():Boolean{
			//log.debug("get stopping() :: ");
			return false;
		}
		
		public function set playlist(playlist:Playlist):void{
			//log.debug("set playlist",playlist);
			_playlist = playlist;
		}
		
		public function get playlist():Playlist{
			return _playlist;
		}
		
		public function get streamCallbacks():Dictionary{
			return {} as Dictionary;
		}
		
		public function get netStream():NetStream{
			// return an empty netstream
			return {} as NetStream;
		}
		
		public function get netConnection():NetConnection {
			// return an empty net connection
			return {} as NetConnection;
		}
		
		public function set timeProvider(timeProvider:TimeProvider):void {
			log.debug("set timeProvider() :: ");
			_timeProvider = timeProvider;
		}
		
		public function get duration():Number{
			return _duration;
		}
		
		public function get type():String {
			return "api:";
		}
		
		/*** External methods open to Javascript ***/
		
		[External]
		public function get fileSize():Number{
			//log.debug("get fileSize() :: "+_ytplayer.getVideoBytesTotal());
			return _ytplayer.getVideoBytesTotal();
		}
		
		[External]
		public function get splashImageUrl():String{
			return _config.imgurl;
		}
		
		[External]
		public function get youtubeUrl():String{
			return _config.vurl;
		}
		
		[External]
		public function get dataApiUrl():String{
			return _config.data_api;
		}
		
		[External]
		public function get embedAllowed():Boolean{
			return _config.embedAllowed
		}
		
		[External]
		public function set clipInitTime(t:Number):void{
			_config.initTime = t;
		}
		
	}
}