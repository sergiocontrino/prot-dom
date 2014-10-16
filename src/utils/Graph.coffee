d3 = require 'd3'
_ = require 'underscore'
$ = require 'jquery'
mediator = require './Events'

class Graph

	lineData = []

	allmargin = 35

	bisectScore = d3.bisector((d) -> d.score ).left

	if !width then width = 0
	if !height? then height = 0

	xScale = d3.scale.linear().range [0,width]
	yScale = d3.scale.linear().range [0,height]

	line = d3.svg.line().x (d) -> xScale d.index
	.y (d) -> yScale d.score

	xAxis = d3.svg.axis().scale(xScale).orient("bottom").tickFormat(d3.format('.0f'))
	yAxis = d3.svg.axis().scale(yScale).orient("left")

	brush = d3.svg.brush()


	constructor: (data, @parent) ->

		$('.viz').empty();

		@lineData = @transform data

		# Get the width and height of our SVG container
		width = parseInt(d3.select(".viz").style("width")) - allmargin*2
		height = parseInt(d3.select(".viz").style("height")) - allmargin*1.5

		# Append an SVG element for rendering
		# @svg = d3.select(".viz").remove();
		@svg = d3.select(".viz").append("svg").attr("width", width + allmargin*2).attr("height", height + allmargin*2).append("g").attr("transform", "translate(" + allmargin + "," + allmargin + ")")

		@rescale()
		
		# Create a filter for our SVG
		filter = @svg.append("defs")
			.append("filter")
			.attr("id", "blurry")
			.append("feGaussianBlur")
			.attr("stdDeviation", 0.8)

		# Create a clipping paths to highlight selections 
		selectedClipPath = @svg.select("defs")
			.append("clipPath")
			.attr('id', 'clip-selected')
			.append("rect")
			.attr("id", "clipping-selected-rect")
			.style("stroke", "none")
			.attr('width', 0)
			.attr('height', height)
			.attr('x', 0)
			.attr('y', 0)

		unselectedMask = @svg.select("defs")
			.append("mask")
			.attr('id', 'mask-unselected')
			.append("rect")
			.attr("id", "mask-unselected-rect")
			.attr('width', 100)
			.attr('height', height)
			.attr('x', 0)
			.attr('y', 0)
			.attr("fill", "white")

		# Background fillter
		@svg.append("rect")
			.attr("class", "background")
			.attr("width", width)
			.attr("height", height)
			.attr("fill", "#428bca")
			.attr("fill-opacity", "1")


		# X Axis
		@svg.append("g")
			.attr("class", "x axis")
			.attr("transform", "translate(0," + height + ")")
			.call xAxis
			.append("text")
			.attr("x", width / 2)
			.attr("y", -12)
			.attr("dy", "1em")
			.attr("class", "x axis label")
			.style("text-anchor", "middle")
			.text "Count"

		@svg.append("g").attr("class", "y axis")
			.call(yAxis)
			.append("text")
			.attr("transform", "translate(0, " + height/2 + ") rotate(-90)")
			.attr("dy", "1em")
			.style("text-anchor", "middle")
			.attr("class", "y axis label")
			.text "Score"

		@svg.append("path")
			.datum(@lineData)
			.attr("class", "line unselected")
			.attr "d", line
			# .attr("mask", "url(#mask-unselected)")
			# .style("filter", "url(#blurry)")

		@svg.append("path")
			.datum(@lineData)
			.attr("class", "line selected")
			.attr "d", line
			.attr('clip-path', 'url(#clip-selected)')

		if @lineData.length < 100

			@svg.selectAll('circle')
				.data(@lineData)
				.enter().append('circle')
				.attr('fill', '#fff')
				.attr('cx', (d) -> xScale(d.index))
				.attr('cy', (d) -> yScale(d.score))
				.attr('r', 2); 

		@svg.append("g").attr("class", "x brush").call(@brush).selectAll("rect").attr("y", 0).attr "height", height

		@parent.talkValues(0, @lineData, @lineData.length);

		# If the window updates then resize the graph
		d3.select(window).on('resize', @resize)



	rescale: () ->

		xScale.domain d3.extent @lineData, (d) -> d.index
		yScale.domain d3.extent @lineData, (d) -> d.score
		xScale.range [0,width]
		min = d3.min @lineData, (d) -> d.score
		if min < 1 then yScale.range [height,0] else yScale.range [0,height]
		d3.select(".x.brush").remove()
		@brush = d3.svg.brush().x(xScale).on("brush", @brushed)


	transform: (values) ->
		_.map values, (next, index) ->
			{name: next.name, x: index, y: next.score, index: index + 1, score: next.score}

	brushed: () =>

		extent = @brush.extent();

		@svg.select("#clipping-selected-rect")
			.attr("x", xScale extent[0])
			.attr("width", xScale(extent[1]) - xScale(extent[0]))

		@svg.select("#mask-unselected-rect")
			.attr("x", xScale extent[0])
			.attr("width", xScale(extent[1]) - xScale(extent[0]))

		if extent[0] is extent[1]
			sliced = @lineData
		else
			sliced = @lineData.slice Math.ceil(extent[0] - 1), Math.floor(extent[1])



		beginning = @lineData[bisectScore(@lineData, extent[0])];
		end = @lineData[bisectScore(@lineData, extent[1])];

		# console.log "beginning", beginning
		# console.log "end", end

		# Send the sliced data to our parent so it can render the table
		@parent.talkValues(extent, sliced, @lineData.length);

	resize: =>



		width = parseInt(d3.select(".viz").style("width")) - allmargin*2
		height = parseInt(d3.select(".viz").style("height")) - allmargin*1.5;

		d3.select(".background").attr("width", width)


		xScale.range [0,width]

		d3.select(".line.unselected").datum(@lineData.slice @lastcutoffindex, @lineData.length).attr("d", line)
		d3.select(".line.selected").datum(@lineData.slice 0, @lastcutoffindex).attr("d", line)


		d3.select(".x.axis.label").attr("x", width/2)
		@svg.select(".y.axis").call(yAxis)
		@svg.select('.x.axis').attr("transform", "translate(0," + height + ")").call(xAxis);

		@svg.selectAll('circle').data(@lineData).attr('cx', (d) -> xScale(d.index)).attr('cy', (d) -> yScale(d.score))

		@brushed()

		# TODO: Fix the following selection
		d3.select('svg').attr("width", width + allmargin*2)
		@

module.exports = Graph