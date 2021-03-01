`renderer Ink program running the web UI `

f := format

Speaker := {
	Eliza: 0
	User: 1
}

` App-with-state rendering logic `

Messages := state => (
	messages := state.messages

	map(messages, msg => h(
		'div'
		['eliza-message', msg.speaker :: {
			(Speaker.Eliza) -> 'from-eliza'
			_ -> 'from-user'
		}]
		[str(msg.message)]
	))
)

App := state => (
	` Initialize Torus renderer `
	r := Renderer(document.body)
	update := r.update

	addMessage := state.addMessage

	` Load script and start app `
	req := fetch('/data/script.txt')
	reqDecoded := bind(req, 'then')(resp => bind(resp, 'text')())
	bind(reqDecoded, 'then')(scriptFile => (
		state.Eliza := new(scriptFile)
		initial := state.Eliza.initial
		addMessage(initial(), Speaker.Eliza)
		render()

		requestAnimationFrame(() => (
			inputField := bind(document, 'querySelector')('.eliza-input')
			bind(inputField, 'focus')()
		))
	))

	render := () => update(h(
		'div'
		['app']
		[
			h('header', [], [
				h('h1', [], ['Eliza'])
				h('nav', [], [
					ha('a', [], {
						href: 'https://github.com/thesephist/eliza'
						target: '_blank'
					}, ['about'])
				])
			])
			state.Eliza :: {
				() -> h('div', [], [str('Loading Eliza...')])
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

									` It feels nicer to the human if the computer
									waits before responding, to make it feel more
									organic. `
									wait(1, () => (
										response := (state.Eliza.respond)(request)
										addMessage(response, Speaker.Eliza)
										render()
									))
								)
							}
						}
						[]
					)
				])
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
}

app := App(State)
(app.render)()

