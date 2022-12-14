toIndex = ->
	(list)->
		if (!list)
			list = []
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

myGoban = ($rootScope, $http, $sce, $hash, $GobanAnimate, $timeout) ->
	goban = new Object;
# modles
	angular.extend(goban, {
	#	yAxis
		data:[],
	#	xAxis
		icons: [],
	#	zAxis
		related: [],
	#	x-y
		matrix:[[]],


	#loader
		path : 'https://ethercalc.org/',
		title : $hash.asArray![0] or '',
	
	#conTrols
		myI : $hash.asArray![1] or 0,
		myJ : $hash.asArray![2] or 0,
		myK : 0,
		colMax : 3,
		myColumnIndex : [0,1,2,3],
		webConfig: false,
		useJSON: '.json',
		pageLoading : false,
		animate : $GobanAnimate,

	})

# methods
	angular.extend(goban,{

	# moves
		setI : (n) !->
			if @.myI != n
				@.maybeDelay! 
				@.myI = n
				@.updateHash!
				@.load @.myI
				goban.cast \dx {d: 0, p: goban.myI}
	
		setJ : (n) !->	
			if @.myJ != n
				@.maybeDelay!
				@.myJ = n
				@.updateHash!
				goban.cast \dy {d: 0, p: goban.myJ}
	
		updateHash : !->
			$hash.upDateFromArray [@.title, @.myI, @.myJ]


		updateIndex : !->
			@.myColumnIndex = [to @.colMax]

	# get
		getSectionTitle : (i)->
			console.log(@.matrix)
			@.matrix and @.matrix[i] and @.matrix[i].sectionTitle
	
	# broadcasts
		cast : (eventName, arg)!->
			broadcastName = 'goban.' + eventName
			$rootScope.$broadcast(broadcastName, arg)


	# loads
		maybeDelay : !->
			@.pageLoading = true
			if goban.animate.delay	
				$timeout (!-> goban.pageLoading = false),goban.animate.delay
			else 
				@.pageLoading = false

		loadMatrix: !->
			for k in @.myColumnIndex
				url = @.path + @.title + k + '.csv' + @.useJSON
				$http {method: "GET",url: url, dataType: "text"}
					.success (data) !->
						if goban.useJSON == '.json'
							goban.matrix[k] = goban.parseDataFromJSON data
						else 
							goban.matrix[k] = goban.parseDataFromCSV data
							
						goban.cast \loaded {p:'matrix'}
					.error !->
						goban.cast \error {p:'matrix'}

	
		loadCore:(num) !->
			url = @.path + @.title + num + '.csv' + @.useJSON
			$http {method: "GET",url: url, dataType: "text"}
					.success (data) !->
						if goban.useJSON == '.json'
							goban.data = goban.parseDataFromJSON data
						else 
							goban.data = goban.parseDataFromCSV data
						
						goban.matrix[goban.myI] = angular.copy(goban.data)
						goban.updateHash!
						goban.cast \loaded {p:'data'}
					#	goban.loadMatrix!
					.error !->
						goban.sectionTitle = null
						goban.data = []
						goban.cast \error {p:'data'}
			

		load : (num) !->
			num = num or 0

			if @.webConfig
				@.loadConfig num

			goban.loadCore num
	#		goban.loadMatrix!

		loadDataOnly:(num) ->
			num = num or 0
			@.loadCore num

		loadConfig : !->
			folderName = @.title + 'Config'
			$http {method: "GET",url: goban.path + goban.title + 'Config.csv' + goban.useJSON, dataType: "text"}
				.success (data) !->
					config = {}
					if goban.useJSON == '.json'
						config := goban.parseConfigFromJSON data
					else 
						config := goban.parseConfigFromCSV data
				
					if config.related and config.related.length
						goban.related = config.related
							.filter (o)->
								o and o.n and o.t
						goban.myName = config.myName
						goban.myK = (goban.related.map (o,index) -> {name:o.n, index: index}
												.filter (t) -> t.name == goban.myName
												.map (t) -> t.index)[0]

					goban.cast \loaded {p:'config'}
				.error !->
					goban.cast \error {p:'config'}
					console.log 'error:connot load webConfig'

		parseConfigFromJSON : (data) ->
			ans  = {
				myName: \Goban,
				related: [],  
			}

			if data and data[1]
				ans.myName := data.[1][1] or data.[1][0]

			myD = data.slice(1)
			myC = ''
			myR = []

			for s in myD
				if s[1] and (not s[0])
					myC := s[1]
				else if s[0]
					myR.push(
						t: s[0],
						n: s[1] or s[0],
						c: myC)

			ans.related = myR
			ans

		parseConfigFromCSV : (csv) ->
			ans  = {
				myName: \Goban,
			#	icons: [], # [{n: 'haha', url: 'bar.jpg'}, 
			#				# {n: 'hoho'm url: 'foo.csv'}]
				related: [],  # [{n: 'BT??????', t:'bt_frontend'},
								# {n:'BT??????', t:'bt_math'}]
			}

			allTextLines = csv.split(/\r\n|\n/)

			xAlts = (allTextLines[1] or "").split(',').slice(2)
		

			ans.myName = allTextLines[1].split(',')[1]
			zLines = allTextLines.slice(1)
			

			ans.related = zLines.map (l)->
							{t: l.split(',')[0],
							n: l.split(',')[1]}


			ans


		redirect : (url) !->
			if url.indexOf(".csv") == -1
				url += '.csv' + goban.useJSON
			$http {method: "GET",url: url, dataType: "text"}
					.success (data) !->
						goban.data = goban.parseDataFromJSON data
						goban.cast \loaded {p:'data', isRedirected: true}
					.error !->
						goban.sectionTitle = null
						goban.data = []
						goban.cast \error {p:'data', isRedirected: true, isBroken: true}

		init : !->
			@.load(@.myI)
			goban.cast \initialized {i: @.myI}
		
	#Parsers
		parseDataFromJSON : (d) ->
			# TODO: ???sectionTitle??????????????????????????????
			@.sectionTitle = ((d or [])[1] or [])[1]
			maybeRedirect = ((d or [])[0] || [])[0]
			if !@.sectionTitle and !maybeRedirect
				maybeRedirect = @.path + @.title
			if maybeRedirect and (maybeRedirect.substr(0,1) != \#)
				goban.redirect(maybeRedirect)
				return

			bodyArrays = d.slice(2)
			goodList = bodyArrays
						.filter (list) -> list[1]

			lastFolderIndex = 0

			bestList = goodList.map (list,index) ->
							isClosed = false
							if not list[0]
								lastFolderIndex := index
								if list[2] and (list[2].search(/exp[ea]nd(.+)true/) > -1 
										or list[2].search(/open/) > -1)
									isClosed = false
								if list[2] and (list[2].search /exp[ea]nd(.+)false/ > -1
										or list[2].search(/close/) > -1)
									isClosed = true
							else
								if list[2] && list[2].search(/blank/) > -1
									isBlank = true
								if list[2] && list[2].search(/iso/) > -1  # isolated
									isIsolated = true


							obj = (list[0]
							and {
							url: list[0].replace(/["\s]/g, ''),
							name: list[1].replace(/["\s]/g, ''),
							labels: (list[3] or "").replace(/["\s]/g, '').split(\+),
							isFolder: false,
							pIndex: lastFolderIndex,
							isBlank: isBlank,
							isIsolated: isIsolated})
								or { name: list[1], isFolder: true, isClosed: isClosed}

							obj
			bestList
	
			
		# backup function
		parseDataFromCSV : (csv) ->
			# TODO: ???sectionTitle??????????????????????????????
			allTextLines = csv.split(/\r\n|\n/)

			@.sectionTitle = allTextLines[1].split(',')[1]
			maybeRedirect = allTextLines[0].split(',')[0]

			if !@.sectionTitle and !maybeRedirect
				maybeRedirect = @.path + @.title

			if maybeRedirect and (maybeRedirect.substr(0,1) != \#)
				goban.redirect(maybeRedirect)
				return

			bodyLines = allTextLines.slice(2)
			goodList = bodyLines
						.map (text) -> 
							text = text.replace(/(html|css|js|output),/g, '$1COMMA')
							text.split(/COMMA|,/)
						.filter (list) -> list[1]

			lastFolderIndex = 0

			bestList = goodList.map (list,index) ->
							isClosed = false
							if not list[0]
								lastFolderIndex := index
								if list[2] and (list[2].search /exp[ea]nd(.+)true/ > -1 
										or list[2].search /open/ > -1)
									isClosed = false
								if list[2] and (list[2].search /exp[ea]nd(.+)false/ > -1
										or list[2].search /close/ > -1)
									isClosed = true
							else
								if list[2] && list[2].search(/blank/ > -1)
									isBlank = true
								if list[2] && list[2].search(/iso/ > -1)  # isolated
									isIsolated = true


							obj = (list[0]
							and {
							url: list[0].replace(/["\s]/g, ''),
							name: list[1].replace(/["\s]/g, ''),
							labels: (list[3] or "").replace(/["\s]/g, '').split(\+),
							isFolder: false,
							pIndex: lastFolderIndex,
							isBlank: isBlank,
							isIsolated: isIsolated})
								or { name: list[1], isFolder: true, isClosed: isClosed}

							obj
			bestList




		keyDown : (e) !->
			e.preventDefault()
			code = e.keyCode
			switch code
			case 40 then 
				if event.shiftKey
					@.dz 1
				else
					@.dy 1
			case 38 then
				if event.shiftKey
					@.dz -1
				else
					@.dy -1
			case 37 then @.dx -1
			case 39 then @.dx 1
			case 32 then @.data[@.myJ].isClosed = !@.data[@.myJ].isClosed

		dx : (myN,isLoop) !->
			goX = (n) !-> 
				goban.myI = parseInt(goban.myI)
				goban.myI += n
				if goban.myI == -1
					goban.myI = goban.colMax
					myN := 0
				if goban.myI == goban.colMax
					if not goban.hasLimit
						goban.colMax++
						goban.updateIndex!

				if goban.myI == goban.colMax + 1
					goban.myI = 0
					myN := 0
					if not goban.isLoop
						goban.dz(1)
				goban.updateHash!
				goban.maybeDelay!
				goban.load goban.myI
			if @.animate.delay
				$timeout (goX myN), @.animate.delay
			else
				goX myN
			goban.cast \dx {d: myN, p: goban.myI}

		dy : (myN, isLoop) !->
			goY = (n) !-> 
				goban.myJ = parseInt(goban.myJ)
				goban.myJ += n
				if goban.myJ == -1
					goban.myJ = (goban.data.length or 1)-1
					if not isLoop
						goban.dx(-1)
				else if goban.myJ >= goban.data.length
					goban.myJ = 0
					if not isLoop
						goban.dx(1)
				goban.updateHash!
			@.maybeDelay!
			if @.animate.delay
				$timeout (goY myN), @.animate.delay
			else 
				goY n

			goban.cast \dy {d: myN, p: goban.myJ}


		dz : (n) !->
			goZ = (o,n) !-> 
				o.myK += n
				if @.related and @.related[0]
					@.title = @.related[@.myK].t
				o.load!

			if @.animate.delay
				$timeout (goZ @ n),@.animate.delay
			else 
				goZ n
			goban.cast \dz {d: n, p: goban.title}

		trust : (url)->
			$sce.trustAsResourceUrl(url)

		getCurrentURL : ->
			@.data = @.data or []
			if @.data[@.myJ] && @.data[@.myJ].isBlank
				window.open(@.data[@.myJ].url)
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
			goban.updateIndex!

			if location.hash.split('&')[0].replace('#','')
				goban.title = location.hash.split('&')[0].replace('#','')
			this

	})
   
	goban

angular.module 'goban' []
	.factory '$hash' myHash
	.factory '$goban' [\$rootScope, \$http, \$sce, \$hash, \$timeout, myGoban]
	.filter 'toIndex' toIndex
