package com.vialogues.youtube
{
	import org.flowplayer.config.Config;
	import org.flowplayer.util.Log;
		
	public class Configuration
	{		
		private const PLAYER_URL:String = "http://www.youtube.com/apiplayer?version=3";
		
		private const API_PREFIX:String = "https://www.googleapis.com/youtube/v3/videos/";
		private const YOUTUBE_DEVELOPER_KEY:String = "AIzaSyB_2uykRwVkf0rciJmJc04h0njKEPo3mtc"; // YouTube public API key for edlabdata@gmail.com
		private const ADDITIONAL_API_PARAMS:String = "&part=status,snippet,contentDetails&key=" + YOUTUBE_DEVELOPER_KEY;
		private const DEFAULT_CLIPHEIGHT:Number = 350;
		private const DEFAULT_CLIPWIDTH:Number = 520;
		private const VERSION_NUMBER:Number = 1.0;
		
		private var log:Log = new Log(this);

		private var _vid:String; // Youtube video id
		private var _vurl:String; // original Youtube url
		private var _imgurl:String; // splash image url
		private var _gdata:Object;
		private var _embedAllowed:Boolean;
		private var _initTime:int;
		private var _firstPlayback:Boolean = true;
		private var _startAfterConnect:Boolean = false;
		private var _securityDomains:Array = [
			"http://www.youtube.com", 
			"https://www.youtube.com", 
			"http://s.ytimg.com", 
			"http://i.ytimg.com",
			"http://i1.ytimg.com",
			"http://i2.ytimg.com",
			"http://i3.ytimg.com",
			"http://i4.ytimg.com",
		];
				
		private var _streamCallbacks:Array;
		private var _netConnectionUrl:String;
		private var _proxyType:String = "best";
		private var _failoverDelay:Number = 250;
		
		private var _duration:Number = 0;
		private var _clipWidth:Number;
		private var _clipHeight:Number;
		private var _loadSplashImage:Boolean = false;
		
		private function ISO8601ToSeconds(s:String):Number {
			
			log.debug("ISO8601ToSeconds :: video duration raw data :: " + s.toString());
			var result:Array = s.match(/PT(\d*H)?(\d*M)?(\d*S)?/); //PT2H28M13S => {0:PT2H28M13S,1:2H,2:28M,3:13S}
			var multipliers:Object = {
				'S': 1,
				'M': 60,
				'H': 3600
			};
			var duration:Number = 0;
			for (var i:uint=1; i<result.length; i++) {
				if(result[i]){
					var ele:String = result[i];
					var multiplier:String = ele.substr(ele.length-1);
					log.debug(multiplier, multipliers[multiplier].toString(), ele.substr(0,ele.length-1));
					duration += (multipliers[multiplier] * Number(ele.substr(0,ele.length-1)));
				}
			}
			log.debug("ISO8601ToSeconds :: video duration converted to :: " + duration.toString());
			return duration;
		}
		
		public function get player_url():String{
			return PLAYER_URL;
		}
		
		public function get data_api():String{
			if(_vid)
				return API_PREFIX + '?id=' + _vid + ADDITIONAL_API_PARAMS; //https://www.googleapis.com/youtube/v3/videos/?id=Pq6emY4D4Xs&part=status&key=AIzaSyB_2uykRwVkf0rciJmJc04h0njKEPo3mtc
			return null;
		}
		
		public function set vid(s:String):void{
			var temp:Array = s.split("api:");
			if(temp.length==2 && temp[1]!="") _vid = temp[1];
			else _vid = s;
		}
		
		public function get vid():String{
			return _vid;
		}
		
		public function get vurl():String{
			return _vurl;
		}
		
		public function get imgurl():String{
			return _imgurl;
		}
		
		public function set gdata(s:Object):void{
			_gdata = s;
			
			var vid_obj:Object = _gdata.items[0];
			
			_vurl = "https://youtu.be/" + vid_obj.id;
			_duration = ISO8601ToSeconds(vid_obj.contentDetails.duration);
			_embedAllowed = vid_obj.status.embeddable;
			_imgurl = vid_obj.snippet.thumbnails.high ? vid_obj.snippet.thumbnails.high.url : vid_obj.snippet.thumbnails.medium.url
		}
		
		public function get gdata():Object{
			if(_gdata)
				return _gdata;
			
			return new Object();
		}
		
		public function set initTime(s:int):void{
			_initTime = s;
		}
		
		public function get initTime():int{
			return _initTime;
		}
		
		public function get duration():Number{
			return _duration;
		}
		
		public function set startAfterConnect(s:Boolean):void{
			_startAfterConnect = s;
		}
		
		public function get startAfterConnect():Boolean{
			return _startAfterConnect;
		}
		
		public function set securityDomains(s:Array):void{
			_securityDomains = s;
		}
		
		public function get securityDomains():Array{
			return _securityDomains;
		}
		
		public function set clipWidth(n:Number):void{
			_clipWidth = n;
		}
		
		public function get clipWidth():Number {
			if(!_clipWidth) return DEFAULT_CLIPWIDTH;
			return _clipWidth;
		}
		
		public function set clipHeight(n:Number):void{
			_clipHeight = n;
		}
		
		public function get clipHeight():Number {
			if(!_clipHeight) return DEFAULT_CLIPHEIGHT;
			return _clipHeight;
		}
		
		public function get embedAllowed():Boolean {
			return _embedAllowed;
		}
		
		public function set loadSplashImage(s:Boolean):void {
			_loadSplashImage = s;
		}
		
		public function get loadSplashImage():Boolean {
			return _loadSplashImage;
		}
	}
}