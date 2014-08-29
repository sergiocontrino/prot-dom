d3 = require 'd3'
# c3 = require '../../bower_components/c3/c3'
css = require '../../bower_components/c3/c3.css'
_ = require 'underscore'
$ = require 'jquery'

class Graph



	constructor: (@data) ->



		$container = $('')


		@lineData = _.map @data, (next, index) ->
		  {x: index, y: next.score}

		margin =
		  top: 20
		  right: 20
		  bottom: 30
		  left: 50

		bisectDate = d3.bisector((d) -> d.x).left

		width = 960 - margin.left - margin.right
		height = 100 - margin.top - margin.bottom

		@width = width
		@height = height
		x = d3.scale.linear().range([
		  0
		  width
		])
		y = d3.scale.linear().range([
		  0
		  height
		])
		xAxis = d3.svg.axis().scale(x).orient("bottom")
		yAxis = d3.svg.axis().scale(y).orient("left")
		line = d3.svg.line().x((d) ->
		  x d.x
		).y((d) ->
		  y d.y
		)
		@svg = d3.select("#vis").append("svg").attr("width", width + margin.left + margin.right).attr("height", height + margin.top + margin.bottom).append("g").attr("transform", "translate(" + margin.left + "," + margin.top + ")").attr("viewBox",'0,0,100,100')
		x.domain d3.extent(@lineData, (d) ->
		  d.x
		)
		y.domain d3.extent(@lineData, (d) ->
		  d.y
		)


		that = @
		@x = x

		d3.select(window).on('resize', @resize)

		mousemove = () ->

		  x0 = x.invert(d3.mouse(this)[0])
		  i = bisectDate(that.lineData, x0, 1)
		  console.log "i", i
		  d0 = that.lineData[i - 1]
		  d1 = that.lineData[i]
		  d = (if x0 - d0.x > d1.x - x0 then d1 else d0)
		  d3.select(".brush").attr("width", x(d.x) )

		@svg.append("g").attr("class", "xaxis").attr("transform", "translate(0," + height + ")").call xAxis
		@svg.append("g").attr("class", "yaxis").call(yAxis).append("text").attr("transform", "rotate(-90)").attr("y", 6).attr("dy", ".71em").style("text-anchor", "end").text "Score"
		@svg.append("path").datum(@lineData).attr("class", "line").attr "d", line
		@svg.append("rect").attr("class", "brush").attr("width", width).attr("height", height).attr("fill", "blue").attr("opacity", "0.3");
		@svg.append("rect").attr("class", "overlay").attr("width", width).attr("height", height).attr("fill", "red").attr("fill-opacity", "0") #.on("mousemove", mousemove);


	update: (value) ->

	  cutoffindex = @lineData.length - 1

	  for gene, index in @lineData
	  	if gene.y > value
	  		cutoffindex = index
	  		break
	  d = @lineData[cutoffindex]
	  d3.select(".brush").attr("width", @x(d.x) )

	resize: ->
	  console.log "resizing..."
	  width = parseInt(d3.select("#vis").style("width"))
	  height = parseInt(d3.select("#vis").style("height"))
	  console.log "width", width
	  console.log "height", height
	  x = d3.scale.linear().range([
	    0
	    width
	  ])
	  y = d3.scale.linear().range([
	    0
	    height
	  ])
	  x.domain d3.extent(@lineData, (d) ->
	    d.x
	  )
	  y.domain d3.extent(@lineData, (d) ->
	    d.y
	  )
	  @svg.select('.xaxis').attr("transform", "translate(0," + height + ")").call(x)
	  @

	

module.exports = Graph