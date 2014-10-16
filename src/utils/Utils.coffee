mediator = require './Events'
$ = require 'jquery'

Utils =

	responseToJSON: (raw) ->

		if raw is "{}"
			return []

		raw.substring(2, raw.length - 2).split('],[').map (next) ->
			split = next.split(',')
			{name: split[0].toUpperCase(), score: parseFloat split[1]}

module.exports = Utils