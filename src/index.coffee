request = require 'superagent'
Utils = require './utils/Utils'
_ = require 'underscore'
Q = require 'q'
style = require('./styles/app.css');
Spinner = require 'spin'
$ = require 'jquery'
Graph = require './utils/Graph'
# Graph = {}
# NewGraph = require './utils/NewGraph'

mediator = require './utils/Events'
Handlebars = require 'hbsfy/runtime'
# intermine = require 'imjs'
# intermine = require 'imjs'
imjs = require '../bower_components/imjs/js/im'


class App

	constructor: (@opts, @callback) ->

		# console.log "intermine", intermine





		# Turn our taret string into a jquery object
		@opts.target = $ @opts.target

		if !@opts.cutoff then @opts.cutoff = 0.6
		if !@opts.method then @opts.method = 'cor'

		# Listener: Switching score types:
		mediator.subscribe "switch-score", =>
			method = $("#{@opts.target.selector} > div.toolbar > div.toolcontrols input[type='radio']:checked");
			cutoff = $("#{@opts.target.selector} > div.toolbar > div.toolcontrols > input.cutoff");
			if method.length > 0 and cutoff.length > 0 then @requery {method: method.val(), cutoff: cutoff.val()}

		mediator.subscribe "load-defaults", =>

			radioMethod = $("#{@opts.target.selector} > div.toolbar > div.toolcontrols input[class='" + @opts.method + "']");
			textCutoff = $("#{@opts.target.selector} > div.toolbar > div.toolcontrols input.cutoff");
			radioMethod.prop("checked", true)
			textCutoff.val(@opts.cutoff)

			@requery {method: @opts.method, cutoff: @opts.cutoff}

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

		$('.defaults').on "click", ()->
			mediator.publish "load-defaults"

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
		@loadingtarget = $("#{@opts.target.selector} > div.atted-table-wrapper")

		console.log "spinner", @loadingtarget

		# Add the spinner to the DOM
		@loadingtarget.append @spinner.el

		# First make a request to the web service, then render the results
		# when the request is fulfilled


		Q.when(@call(@opts)).done @renderapp

		# console.log "value from ask", @ask(@opts)


		# Q.when(@ask(@opts)).done (values) ->
		# 	console.log "finished asking", values


	# query: (opts) ->
	# 	Q.when(@call(opts)).done @renderapp


	getValues: () ->
		"test"



	requery: (options) ->

		# console.log "reuqerying with options", options
		Q.when(@call(options)).done @renderapp

	call: (options, deferred) =>

		# Create our deferred object, later to be resolved
		deferred ?= Q.defer()

		# The URL of our web service
		url = "http://atted.jp/cgi-bin/API_coex.cgi?#{@opts.AGIcode}/#{options.method}/#{options.cutoff}"
		# url = "http://intermine.modencode.org/thalemineval/service/version"
		# Make a request to the web service
		request.get url, (response) =>

			console.log "making initial request"

			console.log "RESPONSE", response
			# Resolve our promise and return the parsed web service response
			# Why aren't they returning JSON??
			# deferred.resolve Utils.responseToJSON response.text
			@allgenes = Utils.responseToJSON response.text

			# deferred.resolve true

			if @allgenes.length >= options.guarantee
				deferred.resolve true
			else
				options.cutoff -= 0.1
				@call(options, deferred)

		# Return our promise
		deferred.promise

	talkValues: (extent, values, total) ->

		# console.log "values", values


		opts =
			lowest: if values.length < 1 then 0 else values[0].score
			# lowest: values[0].score
			highest: if values.length < 1 then 0 else values[values.length - 1].score
			# highest: values[values.length - 1].score
			# lowest: Math.round(extent[0] * 100) / 100 
			# highest: Math.round(extent[1] * 100) / 100 

		template = require("./templates/selected.hbs")

		$("#{@opts.target.selector} > div.stats").html template {values: values, opts: opts, total: total}

		# $('#stats').html template {values: values, opts: opts}
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

		# if @graph? then @graph.newdata(@allgenes, @) else @graph = new Graph @allgenes, @
		# if @graph? then @graph.newdata(@allgenes, @) else @graph = new Graph @allgenes, @
		@graph = new Graph @allgenes, @

		newarr = []
		_.each @allgenes, (next) ->
			newarr.push next.name

		do callback newarr

	rendertable: (genes) =>



		if genes.length < 1

			template = require './templates/noresults.hbs'
			# $('#atted-table').html template {}
			$("#{@opts.target.selector} > div.atted-table-wrapper").html template {}


		else
			# Check to see if the table needs to be added

			table = $("#{@opts.target.selector} > div.atted-table-wrapper > table.atted-table")

			if !table.length then $("#{@opts.target.selector} > div.atted-table-wrapper").html("<table class='atted-table collection-table'></table>")


			template = require './templates/table.hbs'


			# min = d3.min genes, (d) -> d.score
			min = []

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