` ELIZA command-line repl `

std := load('vendor/std')

log := std.log
scan := std.scan
readFile := std.readFile

eliza := load('lib/eliza')

runEliza := eliza.runWithScript

readFile('doctor.txt', file => file :: {
	() -> log('Could not find doctor file')
	_ -> runEliza(
		file
		scan
		response => out(response + char(10) + '?> ')
	)
})

