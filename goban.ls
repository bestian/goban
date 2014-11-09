toIndex = ->
	(list)->
		[to list.length-1]

myHash = ->
	data: location.hash
	asArray: ->
		@.data.replace \# '' .split \&
	upDateFromArray: (list) !->
		location.hash = \# + list.join \&

myGoban = ($http, $sce, $hash, $timeout, $window)->
	goban = new Object;

	

# models

	angular.extend(goban, {
		data:[],
		xAxis:{
			icons: [],
		},
		zAxis:{
			related: [],
		},
		path : 'https://ethercalc.org/',
		title : $hash.asArray![0] or '',
		myI : $hash.asArray![1] or 0,
		myJ : $hash.asArray![2] or 0,
		myK : 0,
		pageLoading : false,
		animate : new Object,
		colMax : 3,
		myColumnIndex : [0,1,2,3]

	})

# methods

	angular.extend(goban,{
		setI : (n) !->
			if @.myI != n
				@.loadPage!
				$timeout (!-> 
					goban.myI = n
					goban.updateHash!
					goban.load goban.myI),1000
	
		setJ : (n) !->	
			if @.myJ != n
				@.loadPage!
				$timeout (!-> 
					goban.myJ = n
					goban.updateHash!),1000
	
		updateHash : !->
			$hash.upDateFromArray [@.title, @.myI, @.myJ]


		loadPage : !->
			@.pageLoading = true
			if goban.animate.delay	
				$timeout (!-> goban.pageLoading = false),goban.animate.delay
			else 
				@.pageLoading = false
	

		load : (num) !->
			folderName = @.title + num
			if typeof @.folderNames == \array
				folderName = @.folderNames[num]

			$http {method: "GET",url: this.path + folderName + '.csv',dataType: "text"}
					.success (data) !->
						goban.data = goban.parseFromCSV data
					.error !->
						goban.sectionTitle = null
						goban.data = []

		loadConfig : !->
			folderName = @.title + 'Config'
			$http {method: "GET",url: this.path + folderName + '.csv',dataType: "text"}
					.success (data) !->
						config = goban.parseConfigFromCSV data
						goban.colMax = config.colMax
						goban.xAxis.icons = config.icons
						goban.zAxis.related = config.related


					.error !->
						goban.sectionTitle = null
						goban.data = []


		redirect : (url) !->
			if url.indexOf(".csv") == -1
				url += '.csv'
			$http {method: "GET",url: url, dataType: "text"}
					.success (data) !->
						goban.data = goban.parseFromCSV data
					.error !->
						goban.sectionTitle = null
						goban.data = []

		init : !->
			this.load(this.myI)
			

		parseFromCSV : (csv) ->
			allTextLines = csv.split(/\r\n|\n/)

				#REDIRECT
		
			maybeRedirect = allTextLines[0].split(',')[0]
			if maybeRedirect and (maybeRedirect.substr(0,1) != \#)
				goban.redirect(maybeRedirect)
				return

		#TITLE
			@.sectionTitle = allTextLines[1].split(',')[1]

			bodyLines = allTextLines.slice(2)

			goodList = bodyLines
						.map (text) -> 
							text = text.replace(/(html|css|js|output),/g, '$1COMMA')
							text.split \,
								.map (str)->
									str.replace(/COMMA/g,',')
						.filter (list) -> list[1]

			lastFolder = {id:0 , set: (n)!-> this.id = n}
			
			bestList = goodList.map (list,index) ->
							isClosed = false
							if not list[0]
								lastFolder.set(index)
								if list[2] and list[2].search /expand(.+)true/ > -1
									isClosed = false
								if list[2] and list[2].search /expand(.+)false/ > -1
									isClosed = true
							else
								if list[2] && list[2].search(/target(.+)_blank/ > -1)
									isBlank = true
								if list[2] && list[2].search(/isolate(.+)true/ > -1)
									isIsolate = true

							obj = (list[0]
							and {url: list[0].replace(/["\s]/g, ''), name: list[1].replace(/["\s]/g, ''), isFolder: false, pIndex: lastFolder.id, isBlank: isBlank, isIsolate: isIsolate})
								or { name: list[1], isFolder: true, isClosed: isClosed}

							obj
			bestList

		parseConfigFromCSV : (url) !->
			allTextLines = csv.split(/\r\n|\n/)

			xIconLines = allTextLines[1].split(',').slice(2)
			xAltLines = allTextLines[2].split(',').slice(2)

			zTitle = allTextLines[1].split(',')[1]
			zLines = allTextLines.slice(2)


			iconObjs = []			#TODO
			relatedObjs = []		#TODO

			config = {
				icons : iconObjs,
				related : relatedObjs,
			}

			config



		keyDown : ($event) !->
			console.log $event
			$event.preventDefault()
			code = $event.keyCode
			if code == 40
				@.dy 1
			if code == 38
				@.dy -1
			if code == 37
				@.dx -1
			if code == 39
				@.dx 1
			if code == 32
				@.data[@.myJ].isClosed = !@.data[@.myJ].isClosed

		dx : (n) !->
			goX = (n) !-> 
				goban.myI = parseInt(goban.myI)
				goban.myI += n
				if goban.myI == -1
					goban.myI = goban.colMax
				if goban.myI == goban.colMax + 1
					goban.myI = 0
				goban.updateHash!
			@.loadPage!
			@.load parseInt(@.myI) + n
			if @.animate.delay
				$timeout (goX n), @.animate.delay
			else
				goX n

		dy : (n) !->
			goY = (n) !-> 
				goban.myJ = parseInt(goban.myJ)
				goban.myJ += n
				if goban.myJ == -1
					goban.myJ = goban.data.length-1
				if goban.myJ == goban.data.length
					goban.myJ = 0
				goban.updateHash!
			@.loadPage!
			if @.animate.delay
				$timeout (goY n), @.animate.delay
			else 
				goY n


		dz : (n) !->
			goZ = (n) !-> 
				goban.myK += n
				goban.loadConfig!
				goban.load!

			if @.animate.delay
				$timeout (goZ n),@.animate.delay
			else 
				goZ n

		trust : (url)->
			$sce.trustAsResourceUrl(url)

		getCurrentURL : ->
			if @.data[@.myJ] && @.data[@.myJ].isBlank
				$window.open(@.data[@.myJ].url)
				return
			@.trust((@.data[@.myJ] && @.data[@.myJ].url) or (@.data[@.myJ+1] && @.data[@.myJ+1].url))

		backupAll : !->
			downloadURL = (url,k) ->
				hiddenIFrameID = 'hiddenDownloader' + k
				iframe = document.getElementById(hiddenIFrameID)
				if iframe === null
					iframe = document.createElement('iframe')
					iframe.id = hiddenIFrameID
					iframe.name = url
					iframe.style.display = 'none'
					document.body.appendChild(iframe)
				iframe.src = url
			for i in [to goban.colMax]
				downloadURL(goban.path + goban.title + i + \.csv, i)	  

		$default : (obj)->
			console.log location.hash.split('&')[0].replace('#','')

			angular.extend(this,obj)
			angular.extend(this,{myColumnIndex : [to goban.colMax]})
			if location.hash.split('&')[0].replace('#','')
				console.log location.hash.split('&')[0].replace('#','')
				goban.title = location.hash.split('&')[0].replace('#','')
			this

	})
   
	goban

angular.module 'goban' []
	.factory '$hash' myHash
	.factory '$goban' [\$http, \$sce, \$hash, \$timeout, \$window myGoban]
	.filter 'toIndex' toIndex
