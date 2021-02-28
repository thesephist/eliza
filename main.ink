` ELIZA command-line repl `

std := load('vendor/std')

log := std.log
scan := std.scan
readFile := std.readFile

eliza := load('lib/eliza')

runEliza := eliza.runWithScript

readFile('script.txt', file => file :: {
	() -> log('Could not find script file')
	_ -> runEliza(
		file
		scan
		response => out(response + char(10) + '?> ')
	)
})

