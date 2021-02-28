` Eliza unit and e2e tests `

s := (load('../vendor/suite').suite)('Eliza')
m := s.mark
t := s.test

std := load('../vendor/std')
readFile := std.readFile

eliza := load('../lib/eliza')
newEliza := eliza.new

readFile('script.txt', file => file :: {
	() -> log('Could not find script file')
	_ -> (
		m('matchDecomp')
		(
			matchDecomp := newEliza(file).testing.matchDecomp
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
		)

		(s.end)()
	)
})

