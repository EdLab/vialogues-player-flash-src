package com.vialogues.youtube
{
	import org.flowplayer.config.Config;
		
	public class Configuration
	{		
		private const PLAYER_URL:String = "http://www.youtube.com/apiplayer?version=3";
		
		private const API_PREFIX:String = "http://gdata.youtube.com/feeds/api/videos/"; 
		private const API_SUFFIX:String = "?v=2";
		/* 
		API Suffix:
		v=2: data api version
		Details see https://developers.google.com/youtube/2.0/developers_guide_protocol_video_entries
		*/
		private const YOUTUBE_DEVELOPER_KEY:String = "AI39si4v0_1qE4h4ZZQUab8tn6AeYgMO9lmmo9kavIZAQmTYoxuRhxzL1Lm0OFyE7Xag6bIBwofkH2Xr2woUa26-f0vmlf813w";
		private const DEFAULT_CLIPHEIGHT:Number = 350;
		private const DEFAULT_CLIPWIDTH:Number = 520;
		private const VERSION_NUMBER:Number = 1.0;

		private var _vid:String; // Youtube video id
		private var _vurl:String; // original Youtube url
		private var _imgurl:String; // splash image url
		private var _gdata:XML;
		private var _embedAllowed:Boolean;
		private var _initTime:int = 0;
		private var _startAfterConnect:Boolean = false;
		private var _securityDomains:Array = [
			"http://www.youtube.com", 
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
		
		public function get player_url():String{
			return PLAYER_URL;
		}
		
		public function get data_api():String{
			if(_vid)
				return API_PREFIX + _vid + API_SUFFIX + "&key=" + YOUTUBE_DEVELOPER_KEY;
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
		
		public function set gdata(s:XML):void{
			_gdata = s;
			
			/* 
			  Youtube uses namespaces in the video data xml. Need to use QName to retrieve media entries -- even for atom elements
			  See http://stackoverflow.com/questions/8160541/as3-parsing-xml 
			*/
			var atomNS:String = _gdata.namespace();
			var mediaNS:String = _gdata.namespace("media");
			var ytNS:String = _gdata.namespace("yt");
			var contentQName:QName = new QName(mediaNS,"content");
			var formatQName:QName = new QName(ytNS,"format");
			var nameQName:QName = new QName(ytNS, "name");
			var accessControlQName:QName = new QName(ytNS, "accessControl");
			
			_vurl = _gdata.descendants(new QName(atomNS,"link")).(attribute("rel")=="alternate").attribute("href");
			_duration = _gdata.descendants(contentQName).(attribute(formatQName)=="5").attribute("duration");
			_embedAllowed = ( _gdata.descendants(accessControlQName).(attribute("action")=="embed").attribute("permission") == "allowed" );
			
			var imageQName:QName = new QName(mediaNS,"thumbnail");
			_imgurl = _gdata.descendants(imageQName).(attribute(nameQName)=="hqdefault").attribute("url");
						
		}
		
		public function get gdata():XML{
			if(_gdata)
				return _gdata;
			
			return new XML();
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