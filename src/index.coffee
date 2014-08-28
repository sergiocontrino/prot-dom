request = require 'superagent'
Utils = require './utils/Utils'
_ = require 'underscore'
Q = require 'q'
style = require('./style/app.css');
Spinner = require 'spin'
$ = require 'jquery'

class App

	constructor: (@target) ->

		# Turn our taret string into a jquery object
		@target = $ @target

		# Fetch our loading template
		template = require("./templates/loading.hbs");

		# Render the loading template to the DOM
		@target.html template {}

		# Options for the spinner:
		opts =
			lines: 13 # The number of lines to draw
			length: 20 # The length of each line
			width: 10 # The line thickness
			radius: 30 # The radius of the inner circle
			corners: 1 # Corner roundness (0..1)
			rotate: 0 # The rotation offset
			direction: 1 # 1: clockwise, -1: counterclockwise
			color: "#000" # #rgb or #rrggbb or array of colors
			speed: 1 # Rounds per second
			trail: 60 # Afterglow percentage
			shadow: false # Whether to render a shadow
			hwaccel: false # Whether to use hardware acceleration
			className: "spinner" # The CSS class to assign to the spinner
			zIndex: 2e9 # The z-index (defaults to 2000000000)
			top: "100%" # Top position relative to parent
			left: "100%" # Left position relative to parent

		# Create a loading spinner
		@spinner = new Spinner(opts).spin();

		# Get the spinner container from the loading template
		@loadingtarget = $ '#searching_spinner_center'

		# Add the spinner to the DOM
		@loadingtarget.append @spinner.el

		# First make a request to the web service, then render the results
		# when the request is fulfilled
		Q.when(@call()).then @render

	call: =>

		# Create our deferred object, later to be resolved
		deferred = Q.defer()

		# The URL of our web service
		url = 'http://atted.jp/cgi-bin/API_coex.cgi?At1g01010/mr/100'

		# Make a request to the web service
		request.get url, (response) =>

			# Resolve our promise and return the parsed web service response
			# Why aren't they returning JSON??
			deferred.resolve Utils.responseToJSON response.text

		# Return our promise
		deferred.promise

	render: (genes) =>
		
		# Sort our genes by score
		genes = _.sortBy genes, (item) ->
		 	-item.score

		# Require our table template
		template = require './templates/template.hbs'

		# Stop our spinner
		@spinner.stop()

		# Render the table to the DOM
		@target.append template { genes: genes }

module.exports = App