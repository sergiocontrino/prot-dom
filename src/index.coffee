request = require 'superagent'
Utils = require './utils/Utils'
_ = require 'underscore'
Q = require 'q'
style = require('./styles/app.css');
Spinner = require 'spin'
$ = require 'jquery'
Graph = require './utils/Graph'
d3 = require 'd3'


class App

	constructor: (@opts) ->

		# Turn our taret string into a jquery object
		@opts.target = $ @opts.target

		# Fetch our loading template
		template = require("./templates/displayer.hbs");

		# Render the loading template to the DOM
		@opts.target.html template {}

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
		# @loadingtarget.append @spinner.el

		# First make a request to the web service, then render the results
		# when the request is fulfilled
		Q.when(@call()).done @renderapp

	call: =>

		# Create our deferred object, later to be resolved
		deferred = Q.defer()

		# The URL of our web service
		url = "http://atted.jp/cgi-bin/API_coex.cgi?#{@opts.AGIcode}/mr/200"

		# @allgenes = Utils.responseToJSON "{[At3g05360,7.48],[At3g25610,8.00],[At2g15480,8.37],[At3g25250,14.07],[At1g17180,14.70],[At2g15490,15.91],[At2g47000,16.12],[At1g17170,16.97],[At1g62300,17.32],[At4g05020,18.33],[At1g74360,19.21],[At3g48850,19.49],[At3g53150,20.20],[At3g50910,23.98],[At3g59700,25.10],[At1g78340,26.83],[At4g39670,28.46],[At3g47730,28.91],[At3g46930,29.22],[At4g12120,29.46],[At3g63380,32.63],[At1g67800,34.79],[At3g28210,35.68],[At3g22370,36.78],[At1g32940,37.47],[At1g08050,38.88],[At5g42010,39.24],[At5g48410,41.57],[At5g14730,41.64],[At3g22910,42.71],[At2g41380,42.77],[At5g20910,43.99],[At5g18270,44.90],[At1g10050,45.92],[At4g24160,46.10],[At2g32020,46.62],[At1g68690,46.90],[At3g09010,49.40],[At2g43000,51.22],[At1g62840,52.25],[At4g26470,54.86],[At3g13100,56.00],[At1g02220,59.33],[At4g22530,60.07],[At1g01340,60.10],[At5g40010,61.11],[At4g37370,63.95],[At5g02780,64.17],[At1g69930,64.25],[At3g54420,65.73],[At1g65690,66.87],[At5g48400,67.08],[At5g62480,70.16],[At4g13180,70.89],[At4g39270,71.75],[At5g42830,72.99],[At3g09270,73.00],[At2g38250,73.68],[At1g74590,73.89],[At5g67340,74.67],[At4g22070,75.26],[At2g37980,75.89],[At3g48450,77.63],[At2g41730,78.49],[At3g26470,78.69],[At1g23550,79.90],[At1g32350,81.24],[At1g69790,84.12],[At1g01010,87.24],[At5g54860,89.06],[At3g44190,89.43],[At3g10500,89.47],[At3g57380,90.42],[At5g11210,90.86],[At1g71530,92.65],[At5g38900,93.25],[At5g57480,94.60],[At3g28580,96.98],[At4g18950,97.86],[At2g29480,98.29],[At3g03610,98.87]}"
		# @allgenes = Utils.responseToJSON "{[At3g05360,1.0],[At3g25610,2.00],[At2g15480,8.37],[At3g25250,14.07],[At1g17180,14.70],[At2g15490,15.91],[At2g47000,16.12],[At1g17170,16.97]}"

		# deferred.resolve true
		# Make a request to the web service
		request.get url, (response) =>

			# Resolve our promise and return the parsed web service response
			# Why aren't they returning JSON??
			# deferred.resolve Utils.responseToJSON response.text
			@allgenes = Utils.responseToJSON response.text
			deferred.resolve true

		# Return our promise
		deferred.promise

	filter: (score) ->

		cutoff = _.filter @allgenes, (gene) ->

			gene.score <= score 

		@rendertable cutoff
		@graph.update score

	renderapp: =>

		settings =
			max: Math.ceil d3.max @allgenes, (d) -> d.score
			min: d3.min @allgenes, (d) -> d.score

		template = require './templates/displayer.hbs'

		@spinner.stop()

		@opts.target.html template { genes: @allgenes, settings: settings, opts: @opts }

		@rendertable @allgenes

		that = @
		$("#fader").on("input", () -> that.filter this.value);

		@graph = new Graph @allgenes

	rendertable: (genes) =>
		
		# Sort our genes by score
		genes = _.sortBy genes, (item) ->
		 	item.score

		template = require './templates/table.hbs'

		$('#atted-table').html template {genes: genes}

module.exports = App