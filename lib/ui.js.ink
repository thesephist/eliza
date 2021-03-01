`renderer Ink program running the web UI `

f := format

Speaker := {
	Eliza: 0
	User: 1
}

querySelector := bind(document, 'querySelector')

scrollToMessageListEnd := () => (
	messageList := querySelector('.eliza-message-list')
	scrollTo := bind(messageList, 'scrollTo')
	scrollTo({
		top: messageList.scrollTop + 999999
		behavior: 'smooth'
	})

)

` App-with-state rendering logic `

Messages := state => (
	messages := state.messages

	map(messages, (msg, i) => h(
		'div'
		[
			'eliza-message'
			msg.speaker :: {
				(Speaker.Eliza) -> 'from-eliza'
				_ -> 'from-user'
			}
			next := messages.(i + 1) :: {
				() -> 'last-of-speaker'
				_ -> next.speaker = msg.speaker :: {
					true -> ''
					_ -> 'last-of-speaker'
				}
			}
		]
		[str(msg.message)]
	))
)

App := state => (
	` Initialize Torus renderer `
	r := Renderer(document.body)
	update := r.update

	addMessage := state.addMessage

	minLoadingTime := 2.7 ` seconds `
	goalLoadTime := time() + minLoadingTime

	` Load script and start app `
	req := fetch('/data/script.txt')
	reqDecoded := bind(req, 'then')(resp => bind(resp, 'text')())
	bind(reqDecoded, 'then')(scriptFile => (
		state.Eliza := new(scriptFile)

		` for a nice loading effect, wait at least 2 seconds to load `
		waitRemaining := (time() > goalLoadTime :: {
			true -> 0
			_ -> goalLoadTime - time()
		})
		bind(console, 'log')(goalLoadTime, time(), waitRemaining)
		wait(waitRemaining, () => (
			initial := state.Eliza.initial
			addMessage(initial(), Speaker.Eliza)
			render()

			` for testing and demos `
			addMessage('I\'m really tired today.', Speaker.User)
			addMessage('Is it because you are really tired today that you came to me?', Speaker.Eliza)
			addMessage('Yes. What should I do?', Speaker.User)
			addMessage('I\'m also bored.', Speaker.User)
			addMessage('Do you believe it is normal to be also bored?', Speaker.Eliza)
			addMessage('How long have you been bored?', Speaker.Eliza)
			addMessage('Only since the beginning of time.', Speaker.User)
			addMessage('I\'m not sure I understand you fully.', Speaker.Eliza)
			render()

			requestAnimationFrame(() => (
				inputField := bind(document, 'querySelector')('.eliza-input')
				inputField :: {
					() -> ()
					_ -> bind(inputField, 'focus')()
				}
			))
		))
	))

	renderEliza := () => state.Eliza :: {
		() -> h('div', ['eliza-loading'], [str('Loading Eliza...')])
		_ -> h('div', ['eliza-ui'], [
			h('ul', ['eliza-message-list'], Messages(state))
			hae(
				'input'
				['eliza-input']
				{
					value: state.input
					placeholder: 'Say something...'
				}
				{
					input: evt => (
						state.input := evt.target.value
						render()
					)
					keydown: evt => evt.key :: {
						'Enter' -> (
							request := trim(state.input, ' ')
							addMessage(request, Speaker.User)

							state.input := ''
							render()

							scrollToMessageListEnd()

							` It feels nicer to the human if the computer
									waits before responding, to make it feel more
									organic. `
							wait(1.2, () => (
								response := (state.Eliza.respond)(request)
								addMessage(response, Speaker.Eliza)
								render()

								scrollToMessageListEnd()
							))
						)
					}
				}
				[]
			)
		])
	}

	render := () => update(h(
		'div'
		['app']
		[
			h('header', [], [
				h('h1', [], ['Eliza'])
				h('div', ['header-waveform'], [])
				h('nav', [], [
					hae('a', [], {href: '#'}, {
						click: () => (
							state.showAbout? := true
							render()
						)
					}, ['about'])
				])
			])
			state.showAbout? :: {
				true -> h('div', ['about-page'], [
					hae('a', ['about-back'], {href: '#'}, {
						click: () => (
							state.showAbout? := false
							render()
						)
					}, ['← back'])
					h('div', ['about-title'], [str('About Eliza.')])
					h('p', [], [
						str('This app is a modern incarnation of the ')
						ha('a', [], {
							href: 'https://en.wikipedia.org/wiki/ELIZA'
							target: '_blank'
						}, [str('ELIZA')])
						str(' program first developed in the mid-1960\'s at
						MIT\'s AI lab. ELIZA was one of the earliest programs
						designed to hold a natural language conversation with
						human users, and uses a simple algorithm with a
						predefined "script" to parse your messages and try to
						offer a related response. The most popular script,
						including the one included in this web app, is a
						"doctor" script that tries to ask rhetorical questions
						like a superficial therapist might.')
					])
					h('p', [], [
						str('In general, ELIZA scripts specify a set of
						patterns that the program should try to find in the
						user\'s question, like "I am X" or "I want to Y", and
						offer a range of choices for the program to build a
						response that incorporates some elements of the user\'s
						question back in the generated response.')
					])
					h('p', [], [
						str('Eliza as you see here is open-source and written
						in the ')
						ha('a', [], {
							href: 'https://dotink.co/'
							target: '_blank'
						}, [str('Ink programming language')])
						str(' and compiled down to JavaScript to run in your
						browser by the ')
						ha('a', [], {
							href: 'https://dotink.co/posts/september/'
							target: '_blank'
						}, [str('September compiler')])
						str('. You can read the full source code and
						documentation on GitHub at ')
						ha('a', [], {
							href: 'https://github.com/thesephist/eliza'
							target: '_blank'
						}, [str('thesephist/eliza')])
						str('.')
					])
					h('p', [], [
						str('Eliza is a project by ')
						ha('a', [], {
							href: 'https://thesephist.com/'
							target: '_blank'
						}, [str('Linus')])
						str('. You can find me on Twitter at ')
						ha('a', [], {
							href: 'https://twitter.com/thesephist'
							target: '_blank'
						}, [str('@thesephist')])
						str('.')
					])
				])
				_ -> renderEliza()
			}
		]
	))

	self := {
		render: render
	}
)

` initialize app and render first pass `

State := {
	Eliza: ()
	input: ''
	messages: []
	addMessage: (msg, speaker) => State.messages.len(State.messages) := {
		message: msg
		speaker: speaker
	}
	showAbout?: false

	` TODO: testing `
	showAbout?: true
}

app := App(State)
(app.render)()

