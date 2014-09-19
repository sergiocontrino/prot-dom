d3 = require 'd3'
_ = require 'underscore'
$ = require 'jquery'
mediator = require './Events'

class Graph

	lineData = []

	allmargin = 25

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

		@lineData = @transform data

		console.log("@lineData from constructor", @lineData);

		
		# Get the width and height of our SVG container
		width = parseInt(d3.select("#viz").style("width")) - allmargin*2
		height = parseInt(d3.select("#viz").style("height")) - allmargin*2;

		# Append an SVG element for rendering
		@svg = d3.select("#viz").append("svg").attr("width", width + allmargin*2).attr("height", height + allmargin*2).append("g").attr("transform", "translate(" + allmargin + "," + allmargin + ")")

		
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
			.attr('width', 0)
			.attr('height', height)
			.attr('x', 0)
			.attr('y', 0)

		unselectedClipPath = @svg.select("defs")
			.append("clipPath")
			.attr('id', 'clip-unselected')

		unselectedClipPath.append("rect")
			.attr("id", "clipping-unselected-rect1")
			.attr('width', 0)
			.attr('height', height)
			.attr('x', 0)
			.attr('y', 0)
		unselectedClipPath.append("rect")
			.attr("id", "clipping-unselected-rect2")
			.attr('width', 0)
			.attr('height', height)
			.attr('x', 0)
			.attr('y', 0)


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
			.append("text")
			# .attr("transform", "translate(" + (width / 2) + ",0") #.attr("transform", "rotate(-90) translate(-" + height + ", 0)")
			.attr("x", width / 2)
			.attr("y", height - 12)
			.attr("dy", "1em")
			.attr("class", "x axis label")
			.style("text-anchor", "middle")
			.text "Count"

		# Brush ON
		@svg.append("rect")
			.attr("class", "backgroundblue")
			.attr("width", width)
			.attr("height", height)
			.attr("fill", "#428BCA")
			.attr("opacity", "1")

		@svg.append("g").attr("class", "y axis")
			.call(yAxis)
			.append("text")
			# .attr("y", height/2)
			# .attr("x", 16)
			.attr("transform", "translate(0, " + height/2 + ") rotate(-90)")
			# .attr("transform", "rotate(-90)") #.attr("transform", "rotate(-90) translate(-" + height + ", 0)")
			.attr("dy", "1em")
			.style("text-anchor", "middle")
			.attr("class", "y axis label")
			.text "Score"

		@svg.append("path")
			.datum(@lineData)
			.attr("class", "line unselected")
			.attr "d", line

		@svg.append("path")
			.datum(@lineData)
			.attr("class", "line selected")
			.attr "d", line
			.attr('clip-path', 'url(#clip-selected)')
			

		@svg.append("g").attr("class", "x brush").call(@brush).selectAll("rect").attr("y", 0).attr "height", height

		# If the window updates then resize the graph
		d3.select(window).on('resize', @resize)

	rescale: () ->

		console.log "rescakubng="

		xScale.domain d3.extent @lineData, (d) -> d.index
		yScale.domain d3.extent @lineData, (d) -> d.score



		xScale.range [0,width]
		# yScale.range [0,height]

		min = d3.min @lineData, (d) -> d.score
		console.log "min", min
		if min < 1 then yScale.range [height,0] else yScale.range [0,height]

		yAxis.ticks(Math.max(height/50, 5));

		console.log "finished rendering"

		# brush.extent([0,0])

		console.log "BRUSH", brush

		# do @brushed
		d3.select(".x.brush").remove()

		@brush = d3.svg.brush().x(xScale).on("brush", @brushed)

		# @svg.select(".x.brush").call(@brush).selectAll("rect").attr("y", 0).attr "height", height


	transform: (values) ->
		_.map values, (next, index) ->
			{name: next.name, x: index, y: next.score, index: index + 1, score: next.score}

	newdata: (values) ->

		@lineData = @transform values
		do @rescale

		@svg.select('.x.axis').attr("transform", "translate(0," + height + ")").call(xAxis);
		@svg.select('.y.axis').call(yAxis);
		@svg.select('.line.selected').datum(@lineData).transition().attr("d", line)
		@svg.select('.line.unselected').datum(@lineData).transition().attr("d", line)



	brushed: () =>

		extent = @brush.extent();
		console.log "extent", extent
		
		

		@svg.select("#clipping-selected-rect")
			.attr("x", xScale extent[0])
			.attr("width", xScale(extent[1]) - xScale(extent[0]))

		@svg.select('#clipping-unselected-rect1')
			.attr("width", xScale extent[0])

		@svg.select('#clipping-unselected-rect2')
			.attr("x", xScale extent[1])
			.attr("width", width)

		sliced = @lineData.slice Math.ceil(extent[0] - 1), Math.floor(extent[1])


		# beginning = @lineData[bisectScore(@lineData, extent[0])];
		end = @lineData[bisectScore(@lineData, extent[1])];

		console.log "end", end

		# console.log "-----------"
		# console.log "EXTENT", extent
		# console.log "Slicked", sliced
		# console.log "beginning", beginning
		# console.log "end", end

		# Send the sliced data to our parent so it can render the table
		@parent.talkValues(extent, sliced);

	resize: =>

		width = parseInt(d3.select("#viz").style("width")) - allmargin*2
		height = parseInt(d3.select("#viz").style("height")) - allmargin*2;

		xScale.range [0,width]

		yAxis.ticks(Math.max(height/50, 5));

		# dpp = @lineData.length/width;

		# dataResampled = @lineData.filter () ->
		# 	(d, i) ->
		# 		i % Math.ceil(dpp) == 0

		d3.select(".line.unselected").datum(@lineData.slice @lastcutoffindex, @lineData.length).attr("d", line)
		d3.select(".line.selected").datum(@lineData.slice 0, @lastcutoffindex + 1).attr("d", line)

		d3.select(".x.axis.label").attr("x", width/2)
		@svg.select(".y.axis").call(yAxis)
		@svg.select('.x.axis').attr("transform", "translate(0," + height + ")").call(xAxis);

		# TODO: Fix the following selection
		d3.select('svg').attr("width", width + allmargin*2)
		# d3.select(".background").attr("width", xScale(@lastcutoff.index))
		d3.select(".backgroundblue").attr("width", width)
		@

module.exports = Graph