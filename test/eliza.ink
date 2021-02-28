` Eliza unit and e2e tests `

s := (load('../vendor/suite').suite)('Eliza')
m := s.mark
t := s.test

std := load('../vendor/std')
map := std.map
some := std.some
readFile := std.readFile

eliza := load('../lib/eliza')
newEliza := eliza.new

` reports whether item is in list `
contains := (list, item) => some(map(list, it => it = item))

readFile('script.txt', file => file :: {
	() -> log('Could not find script file')
	_ -> (
		Eliza := newEliza(file)

		m('matchDecomp')
		(
			matchDecomp := Eliza.testing.matchDecomp
			t('x', matchDecomp(['a'], ['a']), [])
			t('x', matchDecomp(['a', 'b'], ['a', 'b']), [])

			t('x', matchDecomp(['a'], ['b']), ())
			t('x', matchDecomp(['a'], ['a', 'b']), ())
			t('x', matchDecomp(['a', 'b'], ['a']), ())
			t('x', matchDecomp(['a', 'b'], ['b', 'a']), ())

			t('x', matchDecomp(['*'], ['a']), [['a']])
			t('x', matchDecomp(['*'], ['a', 'b']), [['a', 'b']])
			t('x', matchDecomp(['*'], ['a', 'b', 'c']), [['a', 'b', 'c']])

			t('x', matchDecomp([], []), [])
			t('x', matchDecomp(['*'], []), [[]])

			t('x', matchDecomp(['a'], []), ())
			t('x', matchDecomp([], ['a']), ())

			t('x', matchDecomp(['*', 'a'], ['0', 'a']), [['0']])
			t('x', matchDecomp(['*', 'a'], ['0', 'a', 'a']), [['0', 'a']])
			t('x', matchDecomp(['*', 'a'], ['0', 'a', 'b', 'a']), [['0', 'a', 'b']])
			t('x', matchDecomp(['*', 'a'], ['0', '1', 'a']), [['0', '1']])

			t('x', matchDecomp(['*', 'a'], ['a']), [[]])

			t('x', matchDecomp(['*', 'a'], ['a', 'b']), ())
			t('x', matchDecomp(['*', 'a'], ['0', 'a', 'b']), ())
			t('x', matchDecomp(['*', 'a'], ['0', '1', 'a', 'b']), ())

			t('x', matchDecomp(['*', 'a', '*'], ['0', 'a', 'b']), [['0'], ['b']])
			t('x', matchDecomp(['*', 'a', '*'], ['0', 'a', 'b', 'c']), [['0'], ['b', 'c']])

			t('x', matchDecomp(['*', 'a', '*'], ['0', 'a']), [['0'], []])
			t('x', matchDecomp(['*', 'a', '*'], ['a']), [[], []])
			t('x', matchDecomp(['*', 'a', '*'], ['a', 'b']), [[], ['b']])
		)

		m('synonym processing')
		(
			matchDecomp := Eliza.testing.matchDecomp

			t('x', matchDecomp(['@be'], ['am']), [['am']])
			t('x', matchDecomp(['@be', 'a'], ['am', 'a']), [['am']])
			t('x', matchDecomp(['a', '@be', 'b'], ['a', 'am', 'b']), [['am']])

			t('x', matchDecomp(['@be'], ['a']), ())

			t('x', matchDecomp(['*', 'i', 'am', '@sad', '*'], ['its', 'true', 'i', 'am', 'unhappy']), [['its', 'true'], ['unhappy'], []])
		)

		m('basic responses')
		(
			initial := Eliza.initial
			respond := Eliza.respond
			final := Eliza.final

			t('initial response', initial(), 'How do you do.  Please tell me your problem.')
			t('default response', contains([
				'How do you do. Please state your problem.'
				'Hi. What seems to be your problem?'
			], respond('Hello.')), true)
			t('final response', final(), 'Goodbye.  Thank you for talking to me.')
		)

		m('advanced responses')
		(
			respond := Eliza.respond

			t('x', respond('Men are all alike.'), 'Did you think they might not be all alike?')
			t('x', respond('They\'re always bugging us about something or other.')
				'Can you think of a specific example?')
			t('x', respond('Well, my boyfriend made me come here.')
				'Your boyfriend made you come here?')
			t('x', respond('He says I\'m depressed much of the time.')
				'I am sorry to hear that you are depressed.')
		)

		(s.end)()
	)
})

