--modified by @sean808080 to include bit.ly authentication and history
--follow @sean808080 at http://twitter.com/sean808080 or http://bit.ly/sean808080 
--based on original twitnews by tinu a.k.a. @hackedunit on twitter 
--usage enter your bit.ly login and api_key in the second and third lines below
--save to ~/Library/Application Support/NetNewsWire/Scripts
--Now you can access the script from the scripts menu on NetNewsWire. 

set charcount_limit to 140
set login to "YOUR BITLY LOGIN"
set api_key to "YOUR BITLY API KEY"

tell application "GrowlHelperApp"
	set the allNotificationsList to {"Success Notification", "Error Notification"}
	set the enabledNotificationsList to {"Success Notification", "Error Notification"}
	
	register as application ¬
		"Twitnews" all notifications allNotificationsList ¬
		default notifications enabledNotificationsList ¬
		icon of application "NetNewsWire"
end tell

tell application "NetNewsWire"
	if index of selected tab = 0 then
		-- We're looking at headlines, so just get the headline URL
		set feed_url to URL of selectedHeadline
		set feed_title to title of selectedHeadline
	else
		-- We're looking at a web view tab, so we need to know which tab
		set i to index of selected tab
		set i to i + 1
		-- Get the tab's URL
		set URL_list to URLs of tabs
		set title_list to titles of tabs
		set feed_url to item i of URL_list
		
		set feed_title to item i of title_list
	end if
	
	set bitly to ¬
		¬
			"curl --stderr /dev/null \"http://api.bit.ly/shorten?longUrl=" & feed_url & "&history=1&version=2.0.1&login=" & login ¬
		& "&apiKey=" & api_key ¬
		& "&history=1\"| grep shortUrl | grep -o http.*[/a-zA-Z0-9]"
	set bitly to (do shell script bitly)
	
end tell

set tweet to feed_title & " " & bitly

-- let the user edit the tweet
set tweet_dialog to display dialog "Edit your Twitter status" with title "TwitNews" default answer tweet cancel button 1 default button 2 buttons {"Cancel", "Send"}
set tweet_action to the button returned of tweet_dialog
if tweet_action = "" or tweet_action = "Cancel" then
	return
else
	set tweet to (text returned of tweet_dialog)
end if

set charcount_tweet to (count characters of tweet)

if charcount_tweet ≤ charcount_limit then
	
	-- get login from keychain
	try
		tell application "Keychain Scripting" to set twitter_key to first generic key of current keychain whose name is "twitnews"
		tell application "Keychain Scripting" to set twitter_login to quoted form of (account of twitter_key & ":" & password of twitter_key)
	on error
		display dialog "Enter your Twitter username" default answer "" buttons {"OK"} default button 1
		set keychain_entry_user to (text returned of result)
		display dialog "Enter your password" default answer "" buttons {"OK"} default button 1
		set keychain_entry_password to (text returned of result)
		tell application "Keychain Scripting" to make new generic key with properties {name:"twitnews", account:keychain_entry_user, password:keychain_entry_password}
		set twitter_login to quoted form of (keychain_entry_user & ":" & keychain_entry_password)
	end try
	
	-- post to twitter
	set twitter_status to quoted form of ("status=" & tweet)
	try
		set tweet_results to do shell script "curl --user " & twitter_login & " --data-binary " & twitter_status & " http://twitter.com/statuses/update.json"
		tell application "GrowlHelperApp"
			notify with name "Success Notification" title "Successfully tweeted" description tweet application name "Twitnews"
		end tell
	on error
		tell application "GrowlHelperApp"
			notify with name "Error Notification" title "Error sending tweet" description tweet application name "Twitnews"
		end tell
	end try
	
else
	tell application "GrowlHelperApp"
		notify with name "Error Notification" title "Error" description "Tweet is more than 140 characters" application name "Twitnews"
	end tell
end if