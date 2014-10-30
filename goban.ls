toIndex = ->
	(list)->
		[to list.length-1]

myHash = ->
	data: location.hash
	asArray: ->
		@.data.replace \# '' .split \&
	upDateFromArray: (list) !->
		location.hash = \# + list.join \&

myGoban = ($http, $sce, $gobanPath, $gobanTitle, $hash, $gobanMax, $timeout, $window)->
	goban = new Object;

	

# models

	angular.extend(goban, {
		data:[],
		z:[],
		path : $gobanPath or '',
		title : $hash.asArray![0] or $gobanTitle,
		myI : $hash.asArray![1] or 0,
		myJ : $hash.asArray![2] or 0,
		myK : 0,
		pageLoading : false,
		animate : new Object,
		colMax : $gobanMax or 3,
		myColumnIndex : [to $gobanMax]

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
	
		loadPage : !->
			@.pageLoading = true
			if goban.animate.delay	
				$timeout (!-> goban.pageLoading = false),goban.animate.delay
			else 
				@.pageLoading = false
	
		updateHash : !->
			$hash.upDateFromArray [@.title, @.myI, @.myJ]


		load : (num) !->
			folderName = @.title + num
			if typeof @.folderNames == \array
				folderName = @.folderNames[num]

			$http {method: "GET",url: $gobanPath + folderName + '.csv',dataType: "text"}
					.success (data) !->
						goban.data = goban.parseFromCSV data
					.error !->
						goban.sectionTitle = null
						goban.data = []

		parseFromCSV : (csv) ->
			allTextLines = csv.split(/\r\n|\n/)
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
			@.loadPage!
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
			for i in [to $gobanMax]
				downloadURL(goban.path + goban.title + i + \.csv, i)	  

		$default : (obj)->
			angular.extend(this,obj)
			this

	})
    

	goban

angular.module 'goban' []
	.factory '$hash' myHash
	.factory '$goban' [\$http, \$sce, \$gobanPath, \$gobanTitle, \$hash, \$gobanMax, \$timeout, \$window myGoban]
	.filter 'toIndex' toIndex
