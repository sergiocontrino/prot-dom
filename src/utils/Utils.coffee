mediator = require './Events'

Utils =

	responseToJSON: (raw) ->

		mediator.publish "wat", 7, "hi", {one: 1}

		raw.substring(2, raw.length - 2).split('],[').map (next) ->
			split = next.split(',')
			{name: split[0], score: parseFloat split[1]}

module.exports = Utils