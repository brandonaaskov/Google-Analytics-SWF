About
=====

This project provides a Flash plug-in for measuring analytics within
Brightcove video players. It can be used out-of-the-box for simple
analytics or as a framework to customize data.

Setup
=====

If you don't want to modify the code, follow these steps:

1.	Grab the latest `GoogleAnalytics.swf` file from the [Downloads section](https://github.com/BrightcoveOS/Google-Analytics-SWF/downloads)

2.	Upload the file to a server that's URL addressable; make note of that URL

3.	Add `?accountNumber=UA-123456789-0` to the URL (UA-123456789-0 will be
	replaced with your Google Analytics Account Number)

	*	By default, all of these events will be tracked under the Google
		Analytics Category of "Brightcove Player". If you'd like to change that,
		you can specify `playerType` as another parameter,
		e.g. `?accountNumber=UA-123456789-0&playerType=Open%20Source%20Testing`
		
		Also, you can specify the playerType as {playername} to have it dynamically 
		use the name you specified for the player in the Brightcove Studio. 
		e.g. `?accountNumber=UA-123456789-0&playerType={playername}`

		*	Note that the `playerType` must be URL-encoded

	*	Alternatively, these parameters can be added to the publishing code as
		below (`playerType` is optional):

		`<param name="accountNumber" value="UA-123456789-0" /><param name="playerType" value="Open%20Source%20Testing" />`

4.	Log in to your Brightcove account

5.	Edit your Brightcove player and add the URL under the "plugins" tab

6.	Save your player changes
	
If you want to make modifications to the SWF / codebase, follow these steps:

1.	Import the project into either FlexBuilder or FlashBuilder

2.	Add the `.swc` files in the `lib` folder under the project's properties
	setting	

3.	To get a SWF of an optimized size, make sure to do a release build

Usage
=====

To understand how Google Analytics treats Categories, Actions and Labels,
please refer to the Google Analytics
[Event Tracking Guide](http://code.google.com/apis/analytics/docs/tracking/eventTrackerGuide.html).

Google Analytics doesn't track data in real time, but after approximately
one to two hours you should see events appearing in your account. Make sure
you're viewing the current day - by default Google Analytics will show a
different timeframe that doesn't include the current day. In the left-hand
navigation, you'll see a "Content" section, and underneath is "Event
Tracking". Click that to see the overview, categories, actions and labels
from your player(s).

When the media complete event fires, the plug-in is also sending along the
amount of time that a user watched that video. If a user skips around in a
video, you can expect to see a time that's less than the video's duration.
If a user watches a section more than once it is possible that the time
watched for that video will be longer than the video's duration. This shows
up in the "Event Value" column for the event, and appears as the length of
time in seconds. 

The video's "name" is sent through as a customized string. You'll see it
appear as `[Video ID] | [Video Name]`. Including the video ID will allow
you to programmatically use this data at a later time, as well as provide
you an easy method to look up the video up in your Brightcove account.

Current Supported Events
========================

To view a list of supported events, and to see what can potentially be 
tracked, you can view [Action.as in src > com > brightcoveos > Action.as](https://github.com/BrightcoveOS/Google-Analytics-SWF/blob/master/src/com/brightcoveos/Action.as).