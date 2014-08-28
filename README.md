#ATTED-II Displayer#

This application displays data fetched from the ATTED-II web service (http://atted.jp/).

##Usage##

Include "atted-displayer.js" in the head of your HTML document, and create a container where the displayer will be rendered. Then instantiate the displayer like so:

    #!javascript
    var displayer = new AttedDisplayer('#attedcontainer');