request = require 'superagent'
Utils = require './utils/Utils'
_ = require 'underscore'
Q = require 'q'
style = require('./styles/app.css');
Spinner = require 'spin'
$ = require 'jquery'
# Graph = require './utils/Graph'
mediator = require './utils/Events'
Handlebars = require 'hbsfy/runtime'

class App

	constructor: (@opts, @callback, @queryhook) ->

		# Execute our prehook, if it exists.
		@defaultopts = _.clone @opts

		# Turn our target string into a jquery object
		@opts.target = $ @opts.target
		@currentcutoff = 0

		if !@opts.cutoff then @opts.cutoff = 0.6
		if !@opts.method then @opts.method = 'cor'

		# Listener: Switching score types:
		# mediator.subscribe "switch-score", =>
		# 	method = $("#{@opts.target.selector} > div.toolbar > div.toolcontrols input[type='radio']:checked");
		# 	cutoff = $("#{@opts.target.selector} > div.toolbar > div.toolcontrols > input.cutoff");
		# 	@opts.method = method.val()
		# 	if cutoff.val()? and cutoff.val() != "" then @opts.origcutoff = cutoff.val() else @opts.origcutoff = @defaultopts.origcutoff
		# 	if cutoff.val()? and cutoff.val() != "" then @opts.cutoff = cutoff.val() else @opts.cutoff = @defaultopts.cutoff
		# 	if method.length > 0 and cutoff.length > 0 then @requery @opts, false

		# mediator.subscribe "load-defaults", =>

		# 	radioMethod = $("#{@opts.target.selector} > div.toolbar > div.toolcontrols input[class='" + @opts.method + "']");
		# 	textCutoff = $("#{@opts.target.selector} > div.toolbar > div.toolcontrols input.cutoff");
		# 	radioMethod.prop("checked", true)
		# 	textCutoff.val(@defaultopts.origcutoff)

		# 	# @requery {method: @opts.method, cutoff: @opts.cutoff}
		# 	@requery @defaultopts, true

		# Fetch our loading template
		template = require("./templates/shell.hbs");

		# Render the shell of the application
		@opts.target.html template {}

		toolbartemplate = require './templates/tools.hbs'

		# $("#{@opts.target.selector} > div.toolbar").html toolbartemplate {opts: @opts, mediator: mediator}
		# radioMethod = $("#{@opts.target.selector} > div.toolbar > div.toolcontrols input[class='" + @opts.method + "']");
		# textCutoff = $("#{@opts.target.selector} > div.toolbar > div.toolcontrols input.cutoff");
		# radioMethod.prop("checked", true)
		# textCutoff.val(@opts.cutoff)

		# $('.reload').on "click", ()->
		# 	mediator.publish "switch-score"

		# $('.defaults').on "click", ()->
		# 	mediator.publish "load-defaults"

		# Options for the spinner:
		@spinneropts =
			lines: 13 # The number of lines to draw
			length: 10 # The length of each line
			width: 6 # The line thickness
			radius: 20 # The radius of the inner circle
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

		# Get the spinner container from the loading template
		@loadingtarget = $ '#searching_spinner_center'
		@wrapper = $("#{@opts.target.selector} > div.atted-table-wrapper")

		@loadingmessage = $("#{@opts.target.selector} > div.atted-table-wrapper > div.atted-loading-message")


		@spinel = @wrapper.find(".searching_spinner_center")

		# target = document.getElementById "searching_spinner_center"
		@spinner = new Spinner(@spinneropts).spin(@spinel[0]);

		@loadingmessage.show()

		@lastoptions = @opts

		# Execute our pre-query hook, if it exists.
		if @queryhook? then do @queryhook


		Q.when(@call(@opts, null, true))
			.then @getResolutionJob
			.then @waitForResolutionJob
			.then @fetchResolutionJob
			.then (results) =>

				@resolvedgenes = results.body.results.matches.MATCH
				@resolvedgenes = _.map @resolvedgenes, (gene) =>
					gene.score = @scoredict[gene.summary.primaryIdentifier]
					return gene

				do @renderapp

	getResolutionJob: (genes) =>


		deferred = Q.defer()
		#console.log @allgenes
		# Pluck the gene names from our ATTED results
		#ids = _.pluck @allgenes, "primaryIdentifier"
		#ids = @allgenes[i][0]
		ids = []
		for key of @scoredict
			ids.push key
		console.log "plucked ids: ", ids

		# Build our POST data
		payload =
			identifiers: ids
			type: "ProteinDomain"
			caseSensitive: true
			wildCards: true

		url = @opts.service + "/ids"

		# Submit an ID Resolution Job
		request
			.post(url)
			.send(payload)
			.end (response) =>
				deferred.resolve response.body

		deferred.promise

	waitForResolutionJob: (resolutionJob, deferred) =>

		url = @opts.service + "/ids/#{resolutionJob.uid}/status"

		deferred ?= Q.defer()

		request
			.get(url)
			.end (response) =>
				if response.body.status is "RUNNING"
					setTimeout (=>
						@waitForResolutionJob(resolutionJob, deferred)
						return
					), 1000
				else if response.body.status is "SUCCESS"
					deferred.resolve resolutionJob

		deferred.promise


	fetchResolutionJob: (resolutionJob) =>

		# Get our resolution results
		deferred = Q.defer()

		url = @opts.service + "/ids/#{resolutionJob.uid}/results"
		request
			.get(url)
			.end (response) =>
				deferred.resolve response
				@deleteResolutionJob resolutionJob

		deferred.promise


	deleteResolutionJob: (resolutionJob) =>

		url = @opts.service +  "/ids/#{resolutionJob.uid}"
		request
			.del(url)
			# .end (response) =>
			# 	# console.log "Delete ID resolution response:", response

	# requery: (options, autocutoff) ->

	# 	# Execute our pre-query hook, if it exists.
	# 	if @queryhook? then do @queryhook

	# 	@loadingmessage.show()

	# 	@table = @wrapper.find(".atted-table")
	# 	@table.hide()
	# 	@opts.target.find(".statsmessage").html("Querying ATTED service...")

	# 	@lastoptions = options


	# 	Q.when(@call(options, null, autocutoff))
	# 		.then @getResolutionJob
	# 		.then @waitForResolutionJob
	# 		.then @fetchResolutionJob
	# 		.then (results) =>
	# 			console.log "final results", results
	# 			@resolvedgenes = results.body.results.matches.MATCH
	# 			@resolvedgenes = _.map @resolvedgenes, (gene) =>
	# 				gene.score = @scoredict[gene.summary.primaryIdentifier]
	# 				return gene
	# 			console.log "after mapping...", @resolvedgenes
	# 			do @renderapp

	call: (options, deferred, autocutoff) =>

		# @lastoptions = options
		@calculatedoptions = options

		options.guarantee ?= 1
		@currentcutoff = options.cutoff

		# Create our deferred object, later to be resolved
		deferred ?= Q.defer()

		console.log "first call", options.cutoff
		# The URL of our web service
		#url = "http://atted.jp/cgi-bin/API_coex.cgi?#{@opts.AGIcode}/#{options.method}/#{options.cutoff}"

		# url = "http://modalone:8080/thaleminebuild/service/query/results?columnheaders=none" +
  # 		      	"&format=json&query=%3Cquery%20name=%22%22%20model=%22genomic%22%20view=" +
  # 			  	"%22Protein.proteinDomains.primaryIdentifier%20Protein.proteinDomainRegions.start%22%20longDescription=" +
  # 			  	"%22%22%3E%3Cconstraint%20path=%22Protein.uniprotName%22%20op=%22=%22%20value=" +
  # 			  	"%22" + @opts.AGIcode + "%22" + 
  # 			  	"/%3E%3C/query%3E"

		url = "http://modalone:8080/thaleminebuild/service/query/results?query=" +
				"%3Cquery+name%3D%22%22+model%3D%22genomic%22+view%3D%22" +
				"Protein.proteinDomains.primaryIdentifier+Protein.proteinDomains.name+" +
				"Protein.proteinDomainRegions.originalDb+Protein.proteinDomainRegions.originalId+" +
				"Protein.proteinDomainRegions.start+Protein.proteinDomainRegions.end%22+" +
				"longDescription%3D%22%22+sortOrder%3D%22Protein.proteinDomains.primaryIdentifier+asc%22%3E%3C" +
				"constraint+path%3D%22Protein.uniprotName%22+op%3D%22%3D%22+value%3D%22" +
				@opts.AGIcode + "%22%2F%3E%3C%2Fquery%3E&format=json"


		console.log "URL", url

		# Make a request to the web service
		request.get url, (response) =>


			console.log "response ", response.text

			parsedData = JSON.parse(response.text)
			@allgenes = parsedData.results

			@scoredict = {}
			ids = []
			for i of parsedData.results
				id = parsedData.results[i][0]
				ids.push id

			_.each @allgenes, (geneObj) =>
				@scoredict[geneObj[0]] = geneObj[4]
			console.log "map", @scoredict

			# for key, value of @scoredict
			# 	console.log "AA", key, value

			deferred.resolve true

		# Return our promise
		deferred.promise

	talkValues: (extent, values, total) ->

		opts =
			lowest: if values.length < 1 then 0 else values[0].score
			highest: if values.length < 1 then 0 else values[values.length - 1].score

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


		@wrapper.find(".atted-table").show()
		@loadingmessage.hide()

		@rendertable @resolvedgenes

		# that = @
		# $("#fader").on("input", () -> that.filter this.value);

		# if @graph? then @graph.newdata(@allgenes, @) else @graph = new Graph @allgenes, @
		# if @graph? then @graph.newdata(@allgenes, @) else @graph = new Graph @allgenes, @
		# @graph = new Graph @allgenes, @

		newarr = []

		_.each @resolvedgenes, (next) =>
			newarr.push next.summary.primaryIdentifier

		@callback(newarr)



	rendertable: (genes) =>

		if genes.length < 1

			template = require './templates/noresults.hbs'
			$("#{@opts.target.selector} > div.atted-table-wrapper").html template {}


		else
			# Check to see if the table needs to be added

			table = $("#{@opts.target.selector} > div.atted-table-wrapper > table.atted-table")

			if !table.length then $("#{@opts.target.selector} > div.atted-table-wrapper").html("<table class='atted-table collection-table'></table>")

			template = require './templates/table.hbs'

			min = _.min genes, (gene) ->
				gene.score


			genes = _.sortBy genes, (item) ->
				if min.score < 1
					-item.score
				else

					item.score

			$("#{@opts.target.selector} > div.atted-table-wrapper > table.atted-table").html template {genes: genes}

		# if @opts.cutoff isnt @opts.origcutoff
		# 	@opts.target.find(".statsmessage").html("<strong>#{genes.length}</strong> genes found with a score <strong>>= #{@currentcutoff} (Cutoff has been automatically reduced to guarantee results.)</strong>")
		# else
		# 	if @opts.method.toUpperCase() is "COR"
		# 		@opts.target.find(".statsmessage").html("<strong>#{genes.length}</strong> genes found with a score <strong>>= #{@currentcutoff}</strong>")
		# 	else
		# 		@opts.target.find(".statsmessage").html("<strong>#{genes.length}</strong> genes found with a score <strong><= #{@currentcutoff}</strong>")



module.exports = App
