Utils =

	responseToJSON: (raw) ->

		raw.substring(2, raw.length - 2).split('],[').map (next) ->
			split = next.split(',')
			{name: split[0], score: parseFloat split[1]}

module.exports = Utils