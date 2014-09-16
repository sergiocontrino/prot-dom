d3 = require 'd3'
_ = require 'underscore'
$ = require 'jquery'

class Graph

	allmargin = 25

	bisectDate = d3.bisector((d) -> d.index).left

	if !width then width = 0
	if !height? then height = 0

	xScale = d3.scale.linear().range [0,width]
	yScale = d3.scale.linear().range [0,height]

	line = d3.svg.line().x (d) -> xScale d.index
	.y (d) -> yScale d.score

	xAxis = d3.svg.axis().scale(xScale).orient("bottom").tickFormat(d3.format('.0f'))
	yAxis = d3.svg.axis().scale(yScale).orient("left")

	constructor: (@data) ->

		@lineData = _.map @data, (next, index) ->
			{x: index, y: next.score, index: index, score: next.score}

		console.log("@lineData", @lineData);

		xScale.domain d3.extent @lineData, (d) -> d.index
		yScale.domain d3.extent @lineData, (d) -> d.score

		width = parseInt(d3.select("#vis").style("width")) - allmargin*2
		height = parseInt(d3.select("#vis").style("height")) - allmargin*2;

		xScale.range [0,width]
		yScale.range [0,height]

		yAxis.ticks(Math.max(height/50, 5));

		@svg = d3.select("#vis").append("svg").attr("width", width + allmargin*2).attr("height", height + allmargin*2).append("g").attr("transform", "translate(" + allmargin + "," + allmargin + ")")
		
		# Filter!
		filter = @svg.append("defs")
			.append("filter")
			.attr("id", "blurry")
			.append("feGaussianBlur")
			.attr("stdDeviation", 0.8)

		# Background fillter
		@svg.append("rect")
			.attr("class", "background")
			.attr("width", width)
			.attr("height", height)
			.attr("fill", "#272822")
			.attr("fill-opacity", "1")

		# X Axis
		@svg.append("g")
			.attr("class", "x axis")
			.attr("transform", "translate(0," + height + ")")
			.call xAxis

		# Brush ON
		@svg.append("rect")
			.attr("class", "brush")
			.attr("width", width)
			.attr("height", height)
			.attr("fill", "#428BCA")
			.attr("opacity", "1")
			# .attr("filter", "url(#blurry)")

		@svg.append("g").attr("class", "y axis")
			.call(yAxis)
			.append("text")
			.attr("transform", "rotate(-90) translate(-5,0)") #.attr("transform", "rotate(-90) translate(-" + height + ", 0)")
			.attr("y", 6)
			.attr("dy", ".71em")
			.style("text-anchor", "end")
			.text "Score"

		@svg.append("path")
			.datum(@lineData)
			.attr("class", "line selected")
			.attr "d", line

		@svg.append("path")
			.datum(@lineData)
			.attr("class", "line unselected")
			.attr "d", line
			# .attr("filter", "url(#blurry)")

		# @svg.append("rect").attr("class", "clickable").attr("width", width).attr("height", height).attr("fill", "red").attr("fill-opacity", "0") #.on("mousemove", mousemove);

		# Assume that the user wants all numbers, so set the brush to the maximum value
		@update d3.max @lineData, (d) ->
			d.score

		# If the window updates then resize the graph
		d3.select(window).on('resize', @resize)

	update: (value) ->

		cutoffindex = @lineData.length - 1

		for gene, index in @lineData
			if gene.score > value
				cutoffindex = index
				break
		d = @lineData[cutoffindex]

		# Store the last cut off of the brush so that we can use it when the graph resizes.
		@lastcutoff = d
		@lastcutoffindex = cutoffindex

		# Resize our brush accordingly
		d3.select(".brush").attr("width", xScale(d.index))

		sliced = @lineData.slice(cutoffindex, @lineData.length)

		d3.select(".line.unselected").datum(@lineData.slice cutoffindex, @lineData.length).attr("d", line)
		d3.select(".line.selected").datum(@lineData.slice 0, cutoffindex + 1).attr("d", line)

		# Return the index for statistical purposes
		cutoffindex

	resize: =>

		

		width = parseInt(d3.select("#vis").style("width")) - allmargin*2
		height = parseInt(d3.select("#vis").style("height")) - allmargin*2;

		xScale.range [0,width]

		yAxis.ticks(Math.max(height/50, 5));

		dpp = @lineData.length/width;

		dataResampled = @lineData.filter () ->
			(d, i) ->
				i % Math.ceil(dpp) == 0

		# @svg.select(".line").datum(dataResampled).attr("d", line)
		# @svg.select(".line").datum(dataResampled).attr("d", line)
		d3.select(".line.unselected").datum(@lineData.slice @lastcutoffindex, @lineData.length).attr("d", line)
		d3.select(".line.selected").datum(@lineData.slice 0, @lastcutoffindex + 1).attr("d", line)

		@svg.select(".y.axis").call(yAxis)
		@svg.select('.x.axis').attr("transform", "translate(0," + height + ")").call(xAxis);

		# TODO: Fix the following selection
		d3.select('svg').attr("width", width + allmargin*2)
		d3.select(".brush").attr("width", xScale(@lastcutoff.index))
		d3.select(".background").attr("width", width)
		@

module.exports = Graph