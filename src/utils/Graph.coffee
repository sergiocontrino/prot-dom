d3 = require 'd3'
_ = require 'underscore'
$ = require 'jquery'

class Graph

	lineData = []

	allmargin = 25

	bisectDate = d3.bisector((d) -> d.index).left

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

	constructor: (@data, @parent) ->

		console.log "created with parent", parent

		console.log "data", @data

		@lineData = _.map @data, (next, index) ->
			{name: next.name, x: index, y: next.score, index: index + 1, score: next.score}

		console.log("@lineData", @lineData);

		xScale.domain d3.extent @lineData, (d) -> d.index
		yScale.domain d3.extent @lineData, (d) -> d.score

		width = parseInt(d3.select("#viz").style("width")) - allmargin*2
		height = parseInt(d3.select("#viz").style("height")) - allmargin*2;

		xScale.range [0,width]
		yScale.range [0,height]

		yAxis.ticks(Math.max(height/50, 5));

		@brush = d3.svg.brush().x(xScale).on("brush", @brushed)

		@svg = d3.select("#viz").append("svg").attr("width", width + allmargin*2).attr("height", height + allmargin*2).append("g").attr("transform", "translate(" + allmargin + "," + allmargin + ")")
		
		# Filter!

		filter = @svg.append("defs")
			.append("filter")
			.attr("id", "blurry")
			.append("feGaussianBlur")
			.attr("stdDeviation", 0.8)

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

		# Brush ON
		@svg.append("rect")
			.attr("class", "brush")
			.attr("width", width)
			.attr("height", height)
			.attr("fill", "#428BCA")
			.attr("opacity", "1")
			.on("mousemove", () -> @mousemove)
			
			# .attr("filter", "url(#blurry)")

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

		@svg.append("g").attr("class", "x axis")
			.call(yAxis)
			.append("text")
			# .attr("transform", "translate(" + (width / 2) + ",0") #.attr("transform", "rotate(-90) translate(-" + height + ", 0)")
			.attr("x", width / 2)
			.attr("y", height - 12)
			.attr("dy", "1em")
			.attr("class", "x axis label")
			.style("text-anchor", "middle")
			.text "Count"

		@svg.append("path")
			.datum(@lineData)
			.attr("class", "line unselected")
			.attr "d", line
			# .attr('clip-path', 'url(#clip-unselected)')
			# .attr("filter", "url(#blurry)")



		@svg.append("path")
			.datum(@lineData)
			.attr("class", "line selected")
			.attr "d", line
			.attr('clip-path', 'url(#clip-selected)')
			

		@svg.append("g").attr("class", "x brush").call(@brush).selectAll("rect").attr("y", 0).attr "height", height

		@focus = @svg.append("g")
			.attr("class", "focus")
			.style("display", "none");

		@focus.append("circle")
			.attr("r", 4.5);

		@focus.append("text")
			.attr("x", 9)
			.attr("dy", ".35em");

			# .attr("filter", "url(#blurry)")

		# @svg.append("rect").attr("class", "clickable").attr("width", width).attr("height", height).attr("fill", "red").attr("fill-opacity", "0") #.on("mousemove", mousemove);

		# Assume that the user wants all numbers, so set the brush to the maximum value
		# @update d3.max @lineData, (d) ->
		# 	d.index

		# If the window updates then resize the graph
		d3.select(window).on('resize', @resize)

	newdata: (values) ->
		console.log "re rendering with values", values

	mousemove: (that) =>

		x0 = xScale.invert d3.mouse(@)[0]

		i = @lineData[bisectScore(@lineData, x0)];
	
		# d0 = @lineData[i - 1]
		# d1 = @lineData[i]
		# d = x0 - d0.score > d1.score - x0 ? d1 : d0
		# @focus.attr("transform", "translate(" + xScale(d.count) + "," + yScale(d.score) + ")")
		# @focus.select("text").text(d.score)


	brushed: () =>
		extent = @brush.extent();
		
		

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
		# d3.select(".brush").attr("width", xScale(@lastcutoff.index))
		d3.select(".background").attr("width", width)
		@

module.exports = Graph