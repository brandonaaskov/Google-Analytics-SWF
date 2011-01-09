/**
 * Brightcove Google Analytics SWF 1.0.0 (5 JANUARY 2011)
 *
 * REFERENCES:
 *	 Website: http://opensource.brightcove.com
 *	 Source: http://github.com/brightcoveos
 *
 * AUTHORS:
 *	 Brandon Aaskov <baaskov@brightcove.com>
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the “Software”),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, alter, merge, publish, distribute,
 * sublicense, and/or sell copies of the Software, and to permit persons to
 * whom the Software is furnished to do so, subject to the following conditions:
 *   
 * 1. The permission granted herein does not extend to commercial use of
 * the Software by entities primarily engaged in providing online video and
 * related services.
 *  
 * 2. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT ANY WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, SUITABILITY, TITLE,
 * NONINFRINGEMENT, OR THAT THE SOFTWARE WILL BE ERROR FREE. IN NO EVENT
 * SHALL THE AUTHORS, CONTRIBUTORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY WHATSOEVER, WHETHER IN AN ACTION OF
 * CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH
 * THE SOFTWARE OR THE USE, INABILITY TO USE, OR OTHER DEALINGS IN THE SOFTWARE.
 *  
 * 3. NONE OF THE AUTHORS, CONTRIBUTORS, NOR BRIGHTCOVE SHALL BE RESPONSIBLE
 * IN ANY MANNER FOR USE OF THE SOFTWARE.  THE SOFTWARE IS PROVIDED FOR YOUR
 * CONVENIENCE AND ANY USE IS SOLELY AT YOUR OWN RISK.  NO MAINTENANCE AND/OR
 * SUPPORT OF ANY KIND IS PROVIDED FOR THE SOFTWARE.
 */

package {
	import com.brightcove.api.APIModules;
	import com.brightcove.api.CustomModule;
	import com.brightcove.api.dtos.VideoDTO;
	import com.brightcove.api.events.AdEvent;
	import com.brightcove.api.events.CuePointEvent;
	import com.brightcove.api.events.ExperienceEvent;
	import com.brightcove.api.events.MediaEvent;
	import com.brightcove.api.modules.AdvertisingModule;
	import com.brightcove.api.modules.CuePointsModule;
	import com.brightcove.api.modules.ExperienceModule;
	import com.brightcove.api.modules.VideoPlayerModule;
	import com.brightcoveos.Action;
	import com.brightcoveos.Category;
	import com.google.analytics.GATracker;
	
	import flash.display.LoaderInfo;

	public class GoogleAnalytics extends CustomModule
	{
		/*
		This account ID can be hardcoded here, or passed in via a parameter on the plugin, 
		in the embed code for the player, or the URL of the page.
		
		1) Plugin Parameter: http://mydomain.com/GoogleAnalytics.swf?accountNumber=UA-123456-0
		2) Embed Code Parameter: <param name="accountNumber" value="UA-123456-0" />
		3) Page URL: http://somedomain.com/section/category/page?accountNumber=UA-123456-0
		*/
		private static var ACCOUNT_NUMBER:String = "";
		private static const VERSION:String = "1.0.3";
		
		private var _experienceModule:ExperienceModule;
		private var _videoPlayerModule:VideoPlayerModule;
		private var _cuePointsModule:CuePointsModule;
		private var _advertisingModule:AdvertisingModule;
		private var _currentVideo:VideoDTO;
		private var _customVideoID:String;
		
		private var _debugEnabled:Boolean = false;
		private var _tracker:GATracker;
		private var _mediaComplete:Boolean = true;
		private var _currentPosition:Number;
		private var _previousTimestamp:Number;
		private var _timeWatched:Number; //stored in milliseconds
		private var _videoMuted:Boolean = false;
		private var _trackSeekForward:Boolean = false;
		private var _trackSeekBackward:Boolean = false;
		
		override protected function initialize():void
		{
			_experienceModule = player.getModule(APIModules.EXPERIENCE) as ExperienceModule;
			_videoPlayerModule = player.getModule(APIModules.VIDEO_PLAYER) as VideoPlayerModule;
			_cuePointsModule = player.getModule(APIModules.CUE_POINTS) as CuePointsModule;
			_advertisingModule = player.getModule(APIModules.ADVERTISING) as AdvertisingModule;
			
			debug("Version " + GoogleAnalytics.VERSION);
			_debugEnabled = (getParamValue('debug') == "true") ? true : false;
			
			setupEventListeners();
			
			_currentVideo = _videoPlayerModule.getCurrentVideo();
			_customVideoID = getCustomVideoID(_currentVideo);
			
			setAccountNumber();
			setPlayerType();
			createCuePoints(_currentVideo);
			
			debug("GA Debug Enabled = " + _debugEnabled);
			_tracker = new GATracker(_experienceModule.getStage(), GoogleAnalytics.ACCOUNT_NUMBER, "AS3", _debugEnabled);
			
			_tracker.trackEvent(Category.VIDEO, Action.PLAYER_LOAD, _experienceModule.getExperienceURL());
			_tracker.trackEvent(Category.VIDEO, Action.VIDEO_LOAD, _customVideoID);
			
			var referrerURL:String = _experienceModule.getReferrerURL();
			if(referrerURL)
			{
				var trackingAction:String = Action.REFERRER_URL + referrerURL;
				_tracker.trackEvent(Category.VIDEO, trackingAction, _customVideoID);
			}
		}
		
		private function setupEventListeners():void
		{
			_experienceModule.addEventListener(ExperienceEvent.ENTER_FULLSCREEN, onEnterFullScreen);
			_experienceModule.addEventListener(ExperienceEvent.EXIT_FULLSCREEN, onExitFullScreen);
			
			_videoPlayerModule.addEventListener(MediaEvent.CHANGE, onMediaChange);
			_videoPlayerModule.addEventListener(MediaEvent.PLAY, onMediaPlay);
			_videoPlayerModule.addEventListener(MediaEvent.PROGRESS, onMediaProgress);
			_videoPlayerModule.addEventListener(MediaEvent.VOLUME_CHANGE, onVolumeChange);
			_videoPlayerModule.addEventListener(MediaEvent.MUTE_CHANGE, onMuteChange);
			_videoPlayerModule.addEventListener(MediaEvent.SEEK, onSeek);
			
			_cuePointsModule.addEventListener(CuePointEvent.CUE, onCuePoint);
			
			if(_advertisingModule) //check to make sure ads are enabled first
			{
				_advertisingModule.addEventListener(AdEvent.AD_START, onAdStart);
				_advertisingModule.addEventListener(AdEvent.AD_PAUSE, onAdPause);
				_advertisingModule.addEventListener(AdEvent.AD_POSTROLLS_COMPLETE, onAdPostrollsComplete);
				_advertisingModule.addEventListener(AdEvent.AD_RESUME, onAdResume);
				_advertisingModule.addEventListener(AdEvent.AD_COMPLETE, onAdComplete);
				_advertisingModule.addEventListener(AdEvent.EXTERNAL_AD, onExternalAd);
			}
		}
		
		private function onEnterFullScreen(pEvent:ExperienceEvent):void
		{
			_tracker.trackEvent(Category.VIDEO, Action.ENTER_FULLSCREEN, _customVideoID);
		}
		
		private function onExitFullScreen(pEvent:ExperienceEvent):void
		{
			_tracker.trackEvent(Category.VIDEO, Action.EXIT_FULLSCREEN, _customVideoID);
		}		
		
		private function onMediaChange(pEvent:MediaEvent):void
		{
			_currentVideo = _videoPlayerModule.getCurrentVideo();
			_customVideoID = getCustomVideoID(_currentVideo);
			_tracker.trackEvent(Category.VIDEO, Action.VIDEO_LOAD, _customVideoID);
			
			_previousTimestamp = new Date().getTime();
			_timeWatched = 0;
		}
		
		private function onMediaPlay(pEvent:MediaEvent):void
		{
			if(_mediaComplete)
			{
				_tracker.trackEvent(Category.VIDEO, Action.MEDIA_BEGIN, _customVideoID);
				
				_previousTimestamp = new Date().getTime();
				_timeWatched = 0;
				
				_mediaComplete = false;
			}
		}
		
		private function onMediaProgress(pEvent:MediaEvent):void
		{
			_currentPosition = pEvent.position;
			updateTrackedTime();
			
			/*
			This will track the media complete event when the user has watched 98% or more of the video. 
			Why do it this way and not use the Player API's event? The mediaComplete event will 
			only fire once, so if a video is replayed, it won't fire again. Why 98%? If the video's 
			duration is 3 minutes, it might really be 3 minutes and .145 seconds (as an example). When 
			we track the position here, there's a very high likelihood that the current position will 
			never equal the duration's value, even when the video gets to the very end. We use 98% since 
			short videos may never see 99%: if the position is 15.01 seconds and the video's duration 
			is 15.23 seconds, that's just over 98% and that's not an unlikely scenario. If the video is 
			long-form content (let's say an hour), that leaves 1.2 minutes of video to play before the 
			true end of the video. However, most content of that length has credits where a user will 
			drop off anyway, and in most cases content owners want to still track that as a media 
			complete event. Feel free to change this logic as needed, but do it cautiously and test as 
			much as you possibly can!
			*/
			if(pEvent.position/pEvent.duration > .98 && !_mediaComplete)
			{
				onMediaComplete(pEvent);
			}
			
			
			//track seek events
			if(_trackSeekForward)
			{
				_tracker.trackEvent(Category.VIDEO, Action.SEEK_FORWARD, _customVideoID);
				_trackSeekForward = false;
			}
			
			if(_trackSeekBackward)
			{
				_tracker.trackEvent(Category.VIDEO, Action.SEEK_BACKWARD, _customVideoID);
				_trackSeekBackward = false;
			}
		}
		
		/**
		 * This gets fired from the onMediaProgress handler and not from the Player API. Also 
		 * tracks the total time watched by the user for the video.
		 */ 
		private function onMediaComplete(pEvent:MediaEvent):void
		{
			_mediaComplete = true;
			
			_tracker.trackEvent(Category.VIDEO, Action.MEDIA_COMPLETE, _customVideoID, Math.round(_timeWatched));
		}
		
		private function onVolumeChange(pEvent:MediaEvent):void
		{
			var volume:Number = _videoPlayerModule.getVolume();
			
			if(volume == 0)
			{
				_videoMuted = true;
				
				_tracker.trackEvent(Category.VIDEO, Action.VIDEO_MUTED, _customVideoID);
			}
			else
			{
				if(_videoMuted)
				{
					_videoMuted = false;
					
					_tracker.trackEvent(Category.VIDEO, Action.VIDEO_UNMUTED, _customVideoID);
				}
			}
		}
		
		private function onMuteChange(pEvent:MediaEvent):void
		{
			if(_videoPlayerModule.isMuted())
			{
				_tracker.trackEvent(Category.VIDEO, Action.VIDEO_MUTED, _customVideoID);
			}
			else
			{
				_tracker.trackEvent(Category.VIDEO, Action.VIDEO_UNMUTED, _customVideoID);
			}
		}
		
		private function onSeek(pEvent:MediaEvent):void
		{
			if(pEvent.position > _currentPosition)
			{
				_trackSeekForward = true;
			}
			else
			{
				_trackSeekBackward = true;	
			}
		}
		
		private function onCuePoint(pEvent:CuePointEvent):void
		{
			if(pEvent.cuePoint.type == 2 && pEvent.cuePoint.name == "milestone")
            {   
                switch(pEvent.cuePoint.metadata)
                {
                	case "25%":
                		_tracker.trackEvent(Category.VIDEO, Action.MILESTONE_25, _customVideoID);
                		break;
                	case "50%":
                		_tracker.trackEvent(Category.VIDEO, Action.MILESTONE_50, _customVideoID);
                		break;
                	case "75%":
                		_tracker.trackEvent(Category.VIDEO, Action.MILESTONE_75, _customVideoID);
                		break;
                }
            }
		}
		
		/**
         * @private
         */
        protected function createCuePoints(pVideo:VideoDTO):void
        {
            var percent25:Object = {
                type: 2, //chapter cue point
                name: "milestone",
                metadata: "25%",
                time: (pVideo.length/1000) * .25
            };
            var percent50:Object = {
                type: 2, //chapter cue point
                name: "milestone",
                metadata: "50%",
                time: (pVideo.length/1000) * .5
            };
            var percent75:Object = {
                type: 2, //chapter cue point
                name: "milestone",
                metadata: "75%",
                time: (pVideo.length/1000) * .75
            };
            
            _cuePointsModule.addCuePoints(_currentVideo.id, [percent25, percent50, percent75]);
        }
        
        private function onAdStart(pEvent:AdEvent):void
        {
        	_tracker.trackEvent(Category.VIDEO, Action.AD_START, _customVideoID);
        }
        
        private function onAdPause(pEvent:AdEvent):void
        {
        	_tracker.trackEvent(Category.VIDEO, Action.AD_PAUSE, _customVideoID);
        }
       
        private function onAdPostrollsComplete(pEvent:AdEvent):void
        {
        	_tracker.trackEvent(Category.VIDEO, Action.AD_POSTROLLS_COMPLETE, _customVideoID);
        }
        
        private function onAdResume(pEvent:AdEvent):void
        {
        	_tracker.trackEvent(Category.VIDEO, Action.AD_RESUME, _customVideoID);
        }
        
        private function onAdComplete(pEvent:AdEvent):void
        {
        	_tracker.trackEvent(Category.VIDEO, Action.AD_COMPLETE, _customVideoID);
        }
        
        private function onExternalAd(pEvent:AdEvent):void
        {
        	_tracker.trackEvent(Category.VIDEO, Action.EXTERNAL_AD, _customVideoID);
        }

		
		/**
		 * Keeps track of the aggregate time the user has been watching the video. If a user watches 10 seconds, 
		 * skips forward, watches another 10 seconds, skips again and watches 30 more seconds, the _timeWatched 
		 * will track as 50 seconds when the mediaComplete event fires. 
		 */ 
		private function updateTrackedTime():void
		{
			var currentTimestamp:Number = new Date().getTime();
			var timeElapsed:Number = (currentTimestamp - _previousTimestamp)/1000;
			_previousTimestamp = currentTimestamp;
			
			//check if it's more than 2 seconds in case the user paused or changed their local time or something
			if(timeElapsed < 2) 
			{
				_timeWatched += timeElapsed;
			}  
		}
		
		private function setAccountNumber():void
		{
			GoogleAnalytics.ACCOUNT_NUMBER = getParamValue('accountNumber');
			
			if(!GoogleAnalytics.ACCOUNT_NUMBER)
			{
				throw new Error('The Google Analytics account number has not been defined. This is required for the analytics SWF to function properly.');
			}
			else
			{
				debug("Account Number = " + GoogleAnalytics.ACCOUNT_NUMBER);
			}
		}
		
		private function setPlayerType():void
		{
			var playerType:String = unescape(getParamValue('playerType'));
			
			if(playerType)
			{
				Category.VIDEO = playerType;
			}
			
			debug("playerType = " + Category.VIDEO);
		}
		
		private function getCustomVideoID(currentVideo:VideoDTO):String
		{
			var customVideoID:String = currentVideo.id + " | " + currentVideo.displayName;
			return customVideoID;
		}
		
		private function debug(message:String):void
		{
			_experienceModule.debug("GoogleAnalytics: " + message);
		}
		
		/**
		 * Looks for the @param key in the URL of the page, the publishing code of the player, and 
		 * the URL for the SWF itself (in that order) and returns its value.
		 */
		public function getParamValue(key:String):String
		{
			//1: check url params for the value
			var url:String = _experienceModule.getExperienceURL();
			if(url.indexOf("?") !== -1)
			{
				var urlParams:Array = url.split("?")[1].split("&");
				for(var i:uint = 0; i < urlParams.length; i++)
				{
					var keyValuePair:Array = urlParams[i].split("=");
					if(keyValuePair[0] == key) 
					{
						return keyValuePair[1];
					}
				}
			}
			
			//2: check player params for the value
			var playerParam:String = _experienceModule.getPlayerParameter(key);
			if(playerParam) 
			{
				return playerParam;
			}
			
			//3: check plugin params for the value
			var pluginParams:Object = LoaderInfo(this.root.loaderInfo).parameters;
			for(var param:String in pluginParams)
			{
				if(param == key) 
				{
					return pluginParams[param];
				}
			}
					
			return null;
		}
	}
}
