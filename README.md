About
=====

Project: Google-Analytics-SWF
Version: 1.0.0
Author: Brandon Aaskov (Brightcove)
Last Modified: 01-05-10

This project provides a Flash plug-in for measuring analytics within
Brightcove video players. It can be used out-of-the-box for simple
analytics or as a framework to customize data.


Download
========

You can download the latest package at the
[GitHub](http://github.com/brightcoveos/Google-Analytics-SWF) page.


Setup
=====

If you don't want to modify the code, follow these steps:

1.	Grab the GoogleAnalytics.swf file from the bin-release directory
2.	Upload the file to a server that's URL addressable: make note of that URL
3.	Add ?accountNumber=UA-123456789-0 (UA-123456789-0 will be replaced with your Google Analytics 
Account Number) to the URL

	>3a.	By default, all of these events will be tracked under the Google Analytics Category of "Brightcove Player". If you'd like to change that, you can specify playerType as another parameter. 
	
	>>?accountNumber=UA-123456789-0&playerType=Open%20Source%20Testing
		
	>Note that the playerType must be URL-encoded. This could be heplful if you want to distinguish 
	>one player from another in your Google Analytics account.
	
	>3b.	Alternatively, these parameters can be added to the publishing code like so (again, the playerType parameter is optional):
		
		<param name="accountNumber" value="UA-123456789-0" />
		<param name="playerType" value="Open%20Source%20Testing" />

4.	Log in to your Brightcove account
5.	Edit your Brightcove Player and add the URL under the "Plugins" tab
6.	Save player changes
	
If you want to make modifications to the SWF/codebase, follow these steps:

1.	Import the project into either FlexBuilder or FlashBuilder
2.	Make sure to add the .swc files in the lib folder in the project's properties setting	
3.	To get a SWF of an optimized size, make sure to do a release build


Usage
=====
To understand how Google Analytics treats Categories, Actions and Labels, you can read up on them here in the [Event Tracking Guide](http://code.google.com/apis/analytics/docs/tracking/eventTrackerGuide.html):

Google Analytics doesn't track data in real time, but after about an hour or two you should see some of the events appearing in your 
account. Make sure you're viewing the current day - by default Google Analytics will show a different timeframe that doesn't include 
the current day. In the left-hand navigation, you'll see a "Content" section, and under that is "Event Tracking". Click that to see the 
overview, categories, actions and labels from your player(s).

When the media complete event fires, we're also sending along the amount of time that a user watched that video. If a user skips 
around in a video, you can expect to see a time that's less than the video's duration. If a user watches a section more than once it 
is possible that the time watched for that video will be longer than the video's duration. This shows up in the "Event Value" column 
for the event, and appears as the time in seconds. 

We're sending the video's "name" through as a customized string. You'll see it appear as [Video ID] | [Video Name]. Including the 
video ID will help you tie this data in with something else later on programmatically if need be, as well as provide you an easy 
method to look that video up in your Brightcove account.

The best way to understand how this works, and to determine if you'd like to tweak the code to match your needs, is to just play 
with it. Get the plugin running in a player, try it with a few different videos, and pass it around to a few people and have them 
generate some traffic to. Once you have some data to look at in your Google Analytics account, you'll have a much easier time 
understanding all of the inner workings.


Current Supported Events
========================
Below is a list of the currently supported events that are being tracked inside the .swf. Media Complete is the only event that also 
sends along an event value with it, which is the amount of time that a user spent watching that video. 

Player Load
Video Load
Media Begin
Media Complete
Fullscreen Entered
Fullscreen Exited
Video Muted
Video Unmuted


Latest Source
=============

Visit [GitHub](http://github.com/brightcoveos/Google-Analytics-SWF) for the
latest source code.

Please note that there is no guarantee of code usability or stability.

Support
=======

File Issues: [GitHub Issue Tracker](http://github.com/brightcoveos/Google-Analytics-SWF/issues/)

Request Support: [Support Forums](http://opensource.brightcove.com/forum/)

Please note that Open Source @ Brightcove projects are **not** supported by
Brightcove and all questions, comments or issues should be reported through
the appropriate OS@B channels. Brightcove Customer Support will **not**
assist you with any Open Source @ Brightcove projects or integrations.