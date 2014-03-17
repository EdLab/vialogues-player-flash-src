/*
* Author: eye8
*/
package org.flowplayer.controls.controllers {
	
	import flash.external.ExternalInterface;
	import flash.geom.ColorTransform;
	
	import org.flowplayer.controls.SkinClasses;
	import org.flowplayer.ui.buttons.ButtonEvent;
	import org.flowplayer.ui.controllers.AbstractToggleButtonController;
	import org.flowplayer.model.ClipEvent;
	
	public class ToggleCCButtonController extends AbstractToggleButtonController {
		
		private var captionUrl:String;
		
		public function ToggleCCButtonController() {
			super();
		}
		
		override public function get name():String {
			return "ccOff";
		}
		
		override public function get defaults():Object {
			
			return {
				tooltipEnabled: false,
				tooltipLabel: "CC Off",
				visible: captionUrl ? true : false,
				enabled: true
			};
		}
		
		override public function get downName():String {
			return "ccOn";
		}
		
		override public function get downDefaults():Object {

			return {
				tooltipEnabled: false,
				tooltipLabel: "CC On",
				visible: captionUrl ? true : false,
				enabled: true
			};
		}
		
		override protected function get faceClass():Class {
			return SkinClasses.getClass("fp.ClosedCaptionOffButton");
		}
		
		override protected function get downFaceClass():Class {
			return SkinClasses.getClass("fp.ClosedCaptionOnButton");
		}
		
		override protected function setDefaultState():void {
			captionUrl = _player.currentClip.getCustomProperty("captionUrl") as String;
			log.debug("caption file url:: " + captionUrl);
			isDown = true;
		}
		
		override protected function onButtonClicked(event:ButtonEvent):void {	
			
			try { 
				// switch on/off caption by toggling "captionContent" plugin
				isDown = _player.togglePlugin("captionContent");
			} catch(err:Error) {
				log.error("unable to toggle Closed Caption", err);
			}
		}

	}
}

