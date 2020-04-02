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
				filePathFromImport = importStr.replace(/@import\s*/ig, '').replace(/"/g, '')
				fileNameFromImport = filePathFromImport.split("/")
				fileNameFromImport = fileNameFromImport[fileNameFromImport.length - 1]
				relativePath = filePathFromImport
				if fileNameFromImport.charAt(0) != '_'
					arRelative = relativePath.split '/'
					arRelative[arRelative.length - 1] = "_#{arRelative[arRelative.length - 1]}"
					relativePath = arRelative.join '/'
				relativePathWrong = filePathFromImport
				fullPath = path.resolve dir, relativePath
				fullPathWrong = path.resolve dir, relativePathWrong
				shouldCheckForWrongName = false
				shouldReturn = false
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
						shouldCheckForWrongName = true
				else
					shouldCheckForWrongName = true

				if shouldCheckForWrongName
					isWrongFileName = false
					fileName = fileNameFromImport
					fileExt = undefined
					if @options.baseDir
						fullPathWrong = path.resolve @options.baseDir, relativePathWrong
					if fs.existsSync "#{fullPathWrong}.scss"
						isWrongFileName = true
						fileExt = "scss"
					if fs.existsSync "#{fullPathWrong}.sass"
						isWrongFileName = true
						fileExt = "sass"
					if isWrongFileName
						fullPathWrong += ".#{fileExt}"
						fileName += ".#{fileExt}"

						wrongFileContents = fs.readFileSync(fullPathWrong)
						disableWarningsRegExp = new RegExp("/\\*\\s*scss-dependency\\s+disable-filename-warning\\s*\\*/", "gm")
						if not disableWarningsRegExp.test(wrongFileContents)
							console.log "\x1b[31m", "[scss-dependency] rename file #{fileName} to _#{fileName} (full path: #{fullPathWrong})"
							shouldReturn = true
						else
							fullPath = fullPathWrong

				return if shouldReturn

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
