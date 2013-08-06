/*
 * Author: Thomas Dubois, <thomas _at_ flowplayer org>
 * This file is part of Flowplayer, http://flowplayer.org
 *
 * Copyright (c) 2011 Flowplayer Ltd
 *
 * Released under the MIT License:
 * http://www.opensource.org/licenses/mit-license.php
 */
package org.flowplayer.controls.volume {
    
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	
	import org.flowplayer.controls.Controlbar;
	import org.flowplayer.controls.SkinClasses;
	import org.flowplayer.controls.buttons.SliderConfig;
	import org.flowplayer.model.Clip;
	import org.flowplayer.model.ClipEvent;
	import org.flowplayer.model.PlayerEvent;
	import org.flowplayer.model.Status;
	import org.flowplayer.ui.buttons.ConfigurableWidget;
	import org.flowplayer.ui.buttons.WidgetDecorator;
	import org.flowplayer.ui.controllers.AbstractWidgetController;
	import org.flowplayer.view.AbstractSprite;
	import org.flowplayer.view.Flowplayer;

	public class VolumeController extends AbstractWidgetController {
		
		public function VolumeController() {
			super();
		}
	
		override public function init(player:Flowplayer, controlbar:DisplayObjectContainer, defaultConfig:Object):ConfigurableWidget {
			super.init(player, controlbar, defaultConfig);
			initializeVolume();		
			
			return _widget;
		}
	
		override public function get name():String {
			return "volume";
		}
	
		override public function get defaults():Object {
			return {
				tooltipEnabled: true,
				visible: true,
				enabled: true
			};
		}
	
		public function initializeVolume():void {
			var volume:Number = _player.volume;
            log.info("initializing volume to " + volume);
            (_widget as VolumeSlider).value = volume;
		}
		
		override protected function createWidget():void {
			_widget = new VolumeSlider(_config as SliderConfig, _player, _controlbar);
            //#443 disabling tabbing for accessibility options
            setInaccessible(_widget);
        }


		override protected function createDecorator():void {
			_decoratedView = new WidgetDecorator(SkinClasses.getDisplayObject("fp.VolumeTopEdge"),
												 SkinClasses.getDisplayObject("fp.VolumeRightEdge"),
												 SkinClasses.getDisplayObject("fp.VolumeBottomEdge"),
												 SkinClasses.getDisplayObject("fp.VolumeLeftEdge")).init(_widget);;
		}


		override protected function initWidget():void {
			_widget.addEventListener(org.flowplayer.controls.volume.VolumeSlider.DRAG_EVENT, onVolumeChanged);
			_widget.visible = false;
			initializeVolume();
		}

		override protected function addPlayerListeners():void {
			_player.onVolume(onPlayerVolumeEvent);
		}
		
		private function onPlayerVolumeEvent(event:PlayerEvent):void {
			(_widget as VolumeSlider).value = event.info as Number
		}

		private function onVolumeChanged(event:Event):void {
			_player.volume = VolumeSlider(event.target).value;
		}
		
		// TODO: check this guy
		public function set tooltipTextFunc(tooltipTextFunc:Function):void {
            (_widget as VolumeSlider).tooltipTextFunc = tooltipTextFunc;
        }
		
		public function showVolume():void {
			var vol:VolumeSlider = _widget as VolumeSlider;
			vol.showSlider();
		}
		           
		public function hideVolume():void {
			var vol:VolumeSlider = _widget as VolumeSlider;
			vol.hideSlider();
		}
		
		public function getWidget():VolumeSlider {
			return _widget as VolumeSlider;
		}


	}
}

