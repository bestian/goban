toIndex = ->
	(list)->
		[to list.length-1]

myHash = ->
	data: location.hash
	asArray: ->
		@.data.replace \# '' .split \&
	upDateFromArray: (list) !->
		location.hash = \# + list.join \&

myGobanAnimate = ->
	GobanAnimate = new Object;
	angular.extend(GobanAnimate, {
		#params
		delay : 0
	})
	GobanAnimate

myGoban = ($http, $sce, $hash, $GobanAnimate, $timeout, $window) ->
	goban = new Object;
# mOdles
	angular.extend(goban, {
	#	yAxis
		data:[],
	#	xAxis
		icons: [],
	#	zAxis
		related: [],


	#loaDer
		path : 'https://ethercalc.org/',
		title : $hash.asArray![0] or '',
	
	#conTrols
		myI : $hash.asArray![1] or 0,
		myJ : $hash.asArray![2] or 0,
		myK : 0,
		colMax : 3,
		myColumnIndex : [0,1,2,3],

	#sWitchs
		webConfig: false,

	#staTus
		pageLoading : false,

	#roBot
		animate : $GobanAnimate,

	})

# methOds
	angular.extend(goban,{

	# moves
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


	# loads
		loadPage : !->
			@.pageLoading = true
			if goban.animate.delay	
				$timeout (!-> goban.pageLoading = false),goban.animate.delay
			else 
				@.pageLoading = false
	

		load : (num) !->
			num = num or 0

			if @.related and @.related[0]
				@.title = @.related[@.myK]

			folderName = @.title + num
			if typeof @.folderNames == \array
				folderName = @.folderNames[num]

			if @.webConfig
				@.loadConfig!

			$http {method: "GET",url: this.path + folderName + '.csv',dataType: "text"}
					.success (data) !->
						goban.data = goban.parseFromCSV data
						goban.updateHash!
					.error !->
						goban.sectionTitle = null
						goban.data = []

		loadConfig : !->
			folderName = @.title + 'Config'
			$http {method: "GET",url: this.path + folderName + '.csv',dataType: "text"}
				.success (data) !->
					config = goban.parseConfigFromCSV data
				
					if config.colMax
						goban.colMax = config.colMax
					if config.icons and config.icons.length
						goban.icons = config.icons
					if config.related and config.related.length
						goban.related = config.related
							.filter (o)->
								o and o.n and o.t
						goban.myName = config.myName
						goban.myK = (goban.related.map (o,index) -> [o.name, index]
												.filter (t) -> t.name == goban.myName
												.map (t) -> t.index)[0]

				.error !->
					goban.sectionTitle = null
					goban.data = []
					console.log 'error:connot load webConfig'


		parseConfigFromCSV : (csv) ->
			ans  = {
				myName: \Goban,
				colMax: 3,
				icons: [], # [{n: 'haha', url: 'bar.jpg'}, 
							# {n: 'hoho'm url: 'foo.csv'}]
				related: [],  # [{n: 'BT前端', t:'bt_frontend'},
								# {n:'BT數學', t:'bt_math'}]
			}

			allTextLines = csv.split(/\r\n|\n/)

			xAlts = (allTextLines[1] or "").split(',').slice(2)
			xIcons = (allTextLines[2] or "").split(',').slice(2)


			ans.myName = allTextLines[1].split(',')[1]
			ans.icons = xIcons
							.map (u,index)->
								{u: u,
								n: xAlts[index]}

			zLines = allTextLines.slice(1)
			

			ans.related = zLines.map (l)->
							{t: l.split(',')[0],
							n: l.split(',')[1]}


			ans


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
			@.load(@.myI)	
			
	#parSers

		parseFromCSV : (csv) ->
			allTextLines = csv.split(/\r\n|\n/)
			maybeRedirect = allTextLines[0].split(',')[0]
			if maybeRedirect and (maybeRedirect.substr(0,1) != \#)
				goban.redirect(maybeRedirect)
				return

			@.sectionTitle = allTextLines[1].split(',')[1]
			bodyLines = allTextLines.slice(2)
			goodList = bodyLines
						.map (text) -> 
							text = text.replace(/(html|css|js|output),/g, '$1COMMA')
							text.split \,
								.map (str)->
									str.replace(/COMMA/g,',')
						.filter (list) -> list[1]

			lastFolderIndex = 0

			bestList = goodList.map (list,index) ->
							isClosed = false
							if not list[0]
								lastFolderIndex := index
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
							and {url: list[0].replace(/["\s]/g, ''), name: list[1].replace(/["\s]/g, ''), isFolder: false, pIndex: lastFolderIndex, isBlank: isBlank, isIsolate: isIsolate})
								or { name: list[1], isFolder: true, isClosed: isClosed}

							obj
			bestList




		keyDown : (e) !->
			e.preventDefault()
			code = e.keyCode
			if code == 40
				if event.shiftKey
					@.dz 1
				else
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
			goZ = (o,n) !-> 
				o.myK += n
				o.load!

			if @.animate.delay
				$timeout (goZ @ n),@.animate.delay
			else 
				goZ n

		trust : (url)->
			$sce.trustAsResourceUrl(url)

		getCurrentURL : ->
			if @.data[@.myJ] && @.data[@.myJ].isBlank
				$window.open(@.data[@.myJ].url)
				@.data[@.myJ].isBlank = false
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
			for i in [to @.colMax]
				downloadURL(@.path + @.title + i + \.csv, i)
			if @.webConfig
				downloadURL(@.path + @.title + \Config.csv, \Config)
					  

		$default : (obj)->
			angular.extend(this,obj)
			@.title = $hash.asArray![0] or @.title
			angular.extend(this,{myColumnIndex : [to goban.colMax]})
			if location.hash.split('&')[0].replace('#','')
				goban.title = location.hash.split('&')[0].replace('#','')
			this

	})
   
	goban

angular.module 'goban' []
	.factory '$hash' myHash
	.factory '$goban' [\$http, \$sce, \$hash, \$timeout, \$window myGoban]
	.filter 'toIndex' toIndex
