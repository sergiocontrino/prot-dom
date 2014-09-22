request = require 'superagent'
Utils = require './utils/Utils'
_ = require 'underscore'
Q = require 'q'
style = require('./styles/app.css');
Spinner = require 'spin'
$ = require 'jquery'
Graph = require './utils/Graph'
d3 = require 'd3'
mediator = require './utils/Events'
Handlebars = require 'hbsfy/runtime'


class App

	constructor: (@opts) ->

		# Turn our taret string into a jquery object
		@opts.target = $ @opts.target


		# Listener: Switching score types:
		mediator.subscribe "switch-score", =>
			method = $("#{@opts.target.selector} > div.toolbar > div.toolcontrols input[type='radio']:checked");
			cutoff = $("#{@opts.target.selector} > div.toolbar > div.toolcontrols > input.cutoff");
			console.log "cutoff", cutoff
			if method.length > 0 and cutoff.length > 0 then @requery {method: method.val(), cutoff: cutoff.val()}

		# Fetch our loading template
		template = require("./templates/shell.hbs");

		# Render the shell of the application
		@opts.target.html template {}

		toolbartemplate = require './templates/tools.hbs'

		$("#{@opts.target.selector} > div.toolbar").html toolbartemplate {opts: @opts, mediator: mediator}
		radioMethod = $("#{@opts.target.selector} > div.toolbar > div.toolcontrols input[class='" + @opts.method + "']");
		textCutoff = $("#{@opts.target.selector} > div.toolbar > div.toolcontrols input.cutoff");
		radioMethod.prop("checked", true)
		textCutoff.val(@opts.cutoff)

		$('.reload').on "click", ()->
			mediator.publish "switch-score"

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


		Q.when(@call(@opts)).done @renderapp


	# query: (opts) ->
	# 	Q.when(@call(opts)).done @renderapp

	requery: (options) ->

		console.log "requerying with options", options
		Q.when(@call(options)).done @renderapp

	call: (options) =>

		# Create our deferred object, later to be resolved
		deferred = Q.defer()

		# The URL of our web service
		url = "http://atted.jp/cgi-bin/API_coex.cgi?#{@opts.AGIcode}/#{options.method}/#{options.cutoff}"

		# Make a request to the web service
		request.get url, (response) =>

			# Resolve our promise and return the parsed web service response
			# Why aren't they returning JSON??
			# deferred.resolve Utils.responseToJSON response.text
			@allgenes = Utils.responseToJSON response.text
			console.log "ALLGENES", @allgenes
			deferred.resolve true

		# Return our promise
		deferred.promise

	talkValues: (extent, values) ->

		# console.log "values", values

		opts =
			lowest: Math.round(extent[0] * 100) / 100 
			highest: Math.round(extent[1] * 100) / 100 

		template = require("./templates/selected.hbs")

		$('#stats').html template {values: values, opts: opts}
		@rendertable(values)


	filter: (score) ->

		cutoff = _.filter @allgenes, (gene) ->

			gene.score <= score 

		@rendertable cutoff
		@graph.update score

	renderapp: =>

		# template = require './templates/displayer.hbs'

		@spinner.stop()

		# @opts.target.html template { genes: @allgenes, opts: @opts }

		@rendertable @allgenes

		# that = @
		# $("#fader").on("input", () -> that.filter this.value);

		if @graph? then @graph.newdata(@allgenes, @) else @graph = new Graph @allgenes, @
		# @graph = new Graph @allgenes, @

	rendertable: (genes) =>

		if genes.length < 1
			template = require './templates/noresults.hbs'
			$('#atted-table').html template {}
		else
			template = require './templates/table.hbs'
			console.log "sorting..."

			min = d3.min genes, (d) -> d.score

			genes = _.sortBy genes, (item) ->
				if min < 1
					-item.score
				else
					item.score

			$("#{@opts.target.selector} > div.atted-table-wrapper > table.atted-table").html template {genes: genes}
		 	# $('#atted-table').html template {genes: genes}
		
		# Sort our genes by score
		

		# toolbartemplate = require './templates/tools.hbs'

		# $("#{@opts.target.selector} > div.toolbar").html toolbartemplate {mediator: mediator}

		# $('.reload').on "click", ()->
		# 	mediator.publish "switch-score"

		# template = require './templates/table.hbs'
		# $('#atted-table').html template {genes: genes}




module.exports = App