package com.vialogues.youtube
{
	import com.vialogues.youtube.YoutubeProvider;
	
	import flash.display.Sprite;
	
	import org.flowplayer.model.PluginFactory;
	
	public class Youtube extends Sprite implements PluginFactory
	{		
		public function newPlugin():Object
		{
			return new YoutubeProvider();
		}
	}
}