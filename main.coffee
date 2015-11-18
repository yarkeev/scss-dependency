fs = require 'fs'
_ = require 'underscore'
path = require 'path'
Deferred = require 'when'

class ScssFile

	importReg: new RegExp /@import\s*"(.*?)"/g

	constructor: (pathToFile, options) ->
		@options = _.extend
			encoding: 'utf-8',
			baseDir: null
		,options
		dir = path.dirname pathToFile
		@deps = []
		promises = []

		if !fs.existsSync pathToFile
			@options.callback?()
			return

		fs.readFile pathToFile, @options.encoding, (err, content) =>
			if err || !content
				console.log err
				@options.callback?()
				return

			imports = content.match @importReg
			if !Array.isArray imports
				@options.callback?()
				return

			imports.forEach (importStr) =>
				dfd = Deferred.defer()
				relativePath = importStr.replace(/@import\s*/ig, '').replace(/"/g, '')
				arRelative = relativePath.split '/'
				arRelative[arRelative.length - 1] = "_#{arRelative[arRelative.length - 1]}"
				relativePath = arRelative.join '/'
				fullPath = path.resolve dir, relativePath
				if fs.existsSync "#{fullPath}.scss"
					fullPath = "#{fullPath}.scss"
				else if fs.existsSync "#{fullPath}.sass"
					fullPath = "#{fullPath}.sass"
				else if @options.baseDir
					fullPath = path.resolve @options.baseDir, relativePath
					if fs.existsSync "#{fullPath}.scss"
						fullPath = "#{fullPath}.scss"
					else if fs.existsSync "#{fullPath}.sass"
						fullPath = "#{fullPath}.sass"
					else
						return
				else
					return

				@deps.push fullPath
				new ScssFile fullPath, _.extend {}, @options,
					callback: (list = []) =>
						@deps = @deps.concat list
						dfd.resolve()
				promises.push dfd.promise

			Deferred.all(promises).then =>
				@options.callback? @deps


module.exports = (file, options, callback) ->
	if _.isFunction options
		callback = options
		options = {}

	new ScssFile file, _.extend(options, {
		callback: callback
	})
