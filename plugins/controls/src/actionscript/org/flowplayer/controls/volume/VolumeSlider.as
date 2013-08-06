/*
 * This file is part of Flowplayer, http://flowplayer.org
 *
 * By: Anssi Piirainen, <support@flowplayer.org>
 *Copyright (c) 2008-2011 Flowplayer Oy *
 * Released under the MIT License:
 * http://www.opensource.org/licenses/mit-license.php
 */

package org.flowplayer.controls.volume {
	
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    
    import org.flowplayer.controls.SkinClasses;
    import org.flowplayer.controls.buttons.AbstractSlider;
    import org.flowplayer.controls.buttons.SliderConfig;
    import org.flowplayer.controls.config.Config;
    import org.flowplayer.view.AnimationEngine;
    import org.flowplayer.view.Flowplayer;

	/**
	 * @author api
	 */
	public class VolumeSlider extends AbstractSlider {
		public static const DRAG_EVENT:String = AbstractSlider.DRAG_EVENT;

		private var _volumeBar:Sprite;
		private var _volumeBox:Sprite;
		private var _isMouseOver:Boolean = false;

        override public function get name():String {
            return "volume";
        }

		public function VolumeSlider(config:SliderConfig, player:Flowplayer, controlbar:DisplayObject) {
			super(config, player, controlbar);
			tooltipTextFunc = function(percentage:Number):String {
                if (percentage > 100) return "100%";
                if (percentage < 0) return "0%";
				return Math.round(percentage) + "%";
			};
			
			createBox();
			createBars();
            enableDragging(true);
			
			addListeners();
		}
		
		private function createBox():void {
			var padding:Number = SkinClasses.defaults.volumeBoxPadding;
			_volumeBox = new Sprite();
			_volumeBox.graphics.beginFill(SkinClasses.defaults.backgroundColor);
			_volumeBox.graphics.drawRect(-1 * padding, -1 * this.height / 2, 2 * padding + SkinClasses.getVolumeSliderWidth(), 2 * padding + SkinClasses.getVolumeSliderHeight() );
			_volumeBox.graphics.endFill();
			_volumeBox.alpha = 0.75; // FIX-NEEDED: the box covers part of the sliderbar background
			addChild(_volumeBox);
			
			swapChildren(_volumeBox, _dragger);
			
		}
		
		private function createBars():void {
			_volumeBar = new Sprite();
			addChild(_volumeBar);
			swapChildren(_dragger, _volumeBar);
		}
		
		override public function configure(config:Object):void {
			super.configure(config);
			
			onSetValue();
		}
		
        override protected function onSetValue():void {
			var pos:Number = value/100 * (width - _dragger.width);	
			if ( pos < 0 || pos > width )
				return;
            _dragger.x = pos;
			drawBar(_volumeBar, volumeColor, volumeAlpha, _config.gradient, 0, pos + _dragger.width / 2);
        }

		override protected function isToolTipEnabled():Boolean {
			return _config.draggerButtonConfig.tooltipEnabled;
		}

		protected function get volumeColor():Number {			
			if (isNaN(_config.color) || _config.color == -2 ) return backgroundColor;
            return _config.color;
        }

		protected function get volumeAlpha():Number {
			return 1;
        }
		
		private function addListeners():void{
			addEventListener(MouseEvent.ROLL_OVER, function(evt:MouseEvent):void{
				_isMouseOver = true;
				showSlider();
			});
			
			addEventListener(MouseEvent.ROLL_OUT, function(evt:MouseEvent):void{
				_isMouseOver = false;
				hideSlider();
			});
		}
		
		public function get isMouseOver():Boolean {
			return _isMouseOver;
		}
		
		public function showSlider():void {
			if(!this.visible) this.visible = true;
		}
		
		public function hideSlider():void {
			if(this.visible && !isMouseOver && !isDragging) this.visible = false;
		}
	}
}
