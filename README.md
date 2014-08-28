#ATTED-II Displayer#

This application displays data fetched from the ATTED-II web service (http://atted.jp/).

##Usage##

Include "atted-displayer.js" in the head of your HTML document, and create a container where the displayer will be rendered. Then instantiate the displayer like so:

    #!javascript
    var displayer = new AttedDisplayer('#attedcontainer');
    
##Development##

The displayer uses a grunt based build process to browserify the code.

Upon initial cloning of the repo, install the node modules:

<code>sudo npm install</code>

Then build the project:

<code>npm run setup</code>

The build process runs automatically when files in the /src folder are modified:

<code>npm start</code>

