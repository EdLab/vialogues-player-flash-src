/*
* Author: eye8
*/
package org.flowplayer.controls.controllers {
	
	import flash.external.ExternalInterface;
	import flash.geom.ColorTransform;
	
	import org.flowplayer.controls.SkinClasses;
	import org.flowplayer.ui.buttons.ButtonEvent;
	import org.flowplayer.ui.controllers.AbstractButtonController;
	import org.flowplayer.model.ClipEvent;
	
	public class ClosedCaptionButtonController extends AbstractButtonController {
		
		private var captionUrl:String;
		private static var defaultColorTransform:ColorTransform;
		
		public function ClosedCaptionButtonController() {
			super();
			defaultColorTransform = new ColorTransform();
		}
		
		override public function get name():String {
			return "closedCaption";
		}
		
		override public function get defaults():Object {
			
			captionUrl = _player.currentClip.getCustomProperty("captionUrl") as String;
			
			toggleCCBtn(captionUrl ? true : false);
			
			return {
				tooltipEnabled: false,
				tooltipLabel: "Toggle CC",
				visible: captionUrl ? true : false,
				enabled: true
			};
		}
		
		override protected function get faceClass():Class {
			return SkinClasses.getClass("fp.ClosedCaptionButton");
		}
		
		override protected function onButtonClicked(event:ButtonEvent):void {
			
			try { 
				
				// switch on/off caption by toggling "captionContent" plugin
				var togglePlugin:Boolean = _player.togglePlugin("captionContent");
				
				// change "cc" button widget color
				toggleCCBtn(togglePlugin);
				
			} catch(err:Error) {
				log.error("unable to toggle Closed Caption", err);
			}
		}
		
		/**
		 * Toggling "CC" button color
		 */
		private function toggleCCBtn(toggleOn:Boolean):void {
			
			if(toggleOn) { // turn button color to white
				var newCol:ColorTransform = new ColorTransform();
				newCol.color = 0xffffff;
				view.transform.colorTransform = newCol;
				log.debug("toggle on cc");
			} else { // remove white button color
				view.transform.colorTransform = defaultColorTransform;
				log.debug("toggle off cc");
			}
			
		}
	}
}

