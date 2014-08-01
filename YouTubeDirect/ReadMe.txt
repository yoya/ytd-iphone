The code is the project is a reference implementation for an iOS
application that captures video, uploads it to YouTube, and submits the
video to a YouTube Direct instance.

More information about YouTube Direct can be found at

http://code.google.com/p/ytd-iphone/

Before building the application, make sure to update constants in
YouTubeDirect-Info.plist (look for TODOs in that file).

# Checkout GData library using svn into project's as specified:
svn checkout http://gdata-objectivec-client.googlecode.com/svn/trunk/ YouTubeDirect/opensource/GData

# Checkout Google-Toolbox-for-Mac library using svn as specified:
svn checkout http://google-toolbox-for-mac.googlecode.com/svn/trunk/ YouTubeDirect/opensource/google-toolbox-for-mac
