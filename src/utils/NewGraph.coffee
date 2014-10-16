d3 = require 'd3'
nv = require 'nvd3'
_ = require 'underscore'
$ = require 'jquery'
mediator = require './Events'

class NV

	console.log "nv", nv

	#These lines are all chart setup.  Pick and choose which chart features you want to utilize. 
	#Adjust chart margins to give the x-axis some breathing room.
	#We want nice looking tooltips and a guideline!
	#how fast do you want the lines to transition?
	#Show the legend, allowing users to turn on/off line series.
	#Show the y-axis
	#Show the x-axis
	#Chart x-axis settings
	#Chart y-axis settings

	# Done setting the chart up? Time to render it!
	#You need data...
	#Select the <svg> element you want to render the chart in.   
	#Populate the <svg> element with chart data...
	#Finally, render the chart!

	#Update the chart when window resizes.

	###*
	Simple test data generator
	###
	# sinAndCos = ->
	#   sin = []
	#   sin2 = []
	#   cos = []
	  
	#   #Data is represented as an array of {x,y} pairs.
	#   i = 0

	#   while i < 100
	#     sin.push
	#       x: i
	#       y: Math.sin(i / 10)

	#     sin2.push
	#       x: i
	#       y: Math.sin(i / 10) * 0.25 + 0.5

	#     cos.push
	#       x: i
	#       y: .5 * Math.cos(i / 10)

	#     i++
	  
	#   #Line chart data should be sent as an array of series objects.
	#   [
	#     {
	#       values: sin #values - represents the array of {x,y} data points
	#       key: "Sine Wave" #key  - the name of the series.
	#       color: "#ff7f0e" #color - optional: choose your own line color.
	#     }
	#     {
	#       values: cos
	#       key: "Cosine Wave"
	#       color: "#2ca02c"
	#     }
	#     {
	#       values: sin2
	#       key: "Another sine wave"
	#       color: "#7777ff"
	#       area: true #area - set to true if you want this line to turn into a filled area chart.
	#     }
	#   ]
	# nv.addGraph ->
	#   chart = nv.models.lineChart().margin(left: 100).useInteractiveGuideline(true).transitionDuration(350).showLegend(true).showYAxis(true).showXAxis(true)
	#   chart.xAxis.axisLabel("Time (ms)").tickFormat d3.format(",r")
	#   chart.yAxis.axisLabel("Voltage (v)").tickFormat d3.format(".02f")
	#   myData = sinAndCos()
	#   d3.select("#chart svg").datum(myData).call chart
	#   nv.utils.windowResize ->
	#     chart.update()
	#     return

	#   chart

module.exports = NV