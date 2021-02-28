` Port of ELIZA to Ink `

std := load('vendor/std')
str := load('vendor/str')
quicksort := load('vendor/quicksort')

log := std.log
scan := std.scan
cat := std.cat
map := std.map
filter := std.filter
reduce := std.reduce
append := std.append
each := std.each
slice := std.slice
some := std.some
flatten := std.flatten
f := std.format
readFile := std.readFile

lower := str.lower
split := str.split
trim := str.trim
replace := str.replace

sortBy := quicksort.sortBy
sort := quicksort.sort

Newline := char(10)

` reports whether item is in list `
contains := (list, item) => some(map(list, it => it = item))

` picks a choice at random from list `
choose := list => list.(floor(len(list) * rand()))

parseDoctorFile := doctorFile => (
	maybeEmptyLines := split(doctorFile, Newline)
	trimmedLines := map(maybeEmptyLines, line => trim(line, ' '))
	lines := filter(trimmedLines, line => len(line) > 0)

	S := {
		key: ()
		decomp: ()

		initials: []
		finals: []
		quits: []
		pres: {}
		posts: {}
		synons: {}
		keys: {}
		memory: []
	}

	each(lines, line => (
		` NOTE: we assume content does not contain extraneous :'s `
		parts := map(split(line, ':'), part => trim(part, ' '))
		tag := parts.0
		content := parts.1

		tag :: {
			'initial' -> S.initials.len(S.initials) := content
			'final' -> S.finals.len(S.finals) := content
			'quit' -> S.quits.len(S.quits) := content
			'pre' -> (
				parts := split(content, ' ')
				S.pres.(parts.0) := slice(parts, 1, len(parts))
			)
			'post' -> (
				parts := split(content, ' ')
				S.posts.(parts.0) := slice(parts, 1, len(parts))
			)
			'synon' -> (
				parts := split(content, ' ')
				S.synons.(parts.0) := parts
			)
			'key' -> (
				parts := split(content, ' ')
				word := parts.0
				weight := (len(parts) > 1 :: {
					true -> number(parts.1)
					_ -> 1
				})
				key := {
					word: word
					weight: weight
					decomps: []
				}
				S.keys.(word) := key
				S.key := key
			)
			'decomp' -> (
				parts := split(content, ' ')
				save := (parts.0 :: {
					'$' -> true
					_ -> false
				})
				parts := (parts.0 :: {
					'$' -> slice(parts, 1, len(parts))
					_ -> parts
				})
				decomp := {
					parts: parts
					save: save
					reasmbs: []
					nextReasmbIdx: 0
				}
				S.key.decomps.len(S.key.decomps) := decomp
				S.decomp := decomp
			)
			'reasmb' -> (
				parts := split(content, ' ')
				S.decomp.reasmbs.len(S.decomp.reasmbs) := parts
			)
			_ -> log(f('Unknown doctor file command: {{0}}', line))
		}
	))

	` return parsed Eliza state `
	S
)

run := doctorFile => (
	Eliza := parseDoctorFile(doctorFile)

	initial := () => choose(Eliza.initials)
	final := () => choose(Eliza.finals)

	substitute := (words, pres) => reduce(words, (out, word) => (
		word := lower(word)
		pres.(word) :: {
			() -> append(out, [word])
			_ -> append(out, pres.(word))
		}
	), [])
	matchKey := (words, key) => (
		(sub := (decomps, i) => decomps.(i) :: {
			() -> ()
			_ -> (
				decomp := decomps.(i)
				results := matchDecomp(decomp.parts, words)
				results :: {
					() -> sub(decomps, i + 1)
					_ -> (
						log(f('Decomp matched: {{0}} | {{1}}', [decomp.parts, results]))

						` post-substitution `
						results := map(results, word => substitute(word, Eliza.posts))

						reasmb := nextReasmb(decomp)

						reasmb.0 :: {
							'goto' -> (
								gotoKey := reasmb.1
								Eliza.keys.(gotoKey) :: {
									() -> (log('Invalid goto key in doctor file: {{0}}', gotoKey), ())
									_ -> matchKey(words, Eliza.keys.(gotoKey))
								}
							)
							_ -> (
								output := reassemble(reasmb, results)
								decomp.save :: {
									true -> (
										Eliza.memory.len(Eliza.memory) := output
										sub(decomps, i + 1)
									)
									_ -> output
								}
							)
						}
					)
				}
			)
		})(key.decomps, 0)
	)
	matchDecomp := (parts, words) => (
		matchDecompR(parts, words, results := []) :: {
			true -> results
			_ -> ()
		}
	)
	matchDecompR := (parts, words, results) => (
		[parts, words] :: {
			[[], []] -> true
			[[], _] -> false
			_ -> (
				` TODO: rip`
			)
		}
	)
	nextReasmb := () => (
		` TODO: _next_reasmb`
	)
	reassemble := (reasmb, result) => (
		` TODO: _reassemble `
	)
	respond := request => contains(Eliza.quits, lower(request)) :: {
		true -> ''
		_ -> (
			` punctuation cleanup `
			request := replace(request, '.', ' . ')
			request := replace(request, ',', ' , ')
			request := replace(request, ';', ' ; ')
			` collapse whitespace `
			request := cat(filter(split(request, ' '), s => len(s) > 0), ' ')

			words := split(request, ' ')
			` pre-substitution `
			words := substitute(words, Eliza.pres)
			`` log(f('substituted: {{0}}', [cat(words, ' ')]))

			keys := filter(map(words, word => Eliza.keys.(lower(word))), w => ~(w = ()))
			keys := sortBy(keys, key => ~(key.weight))
			`` log(f('sorted keys: {{0}}', [keys]))

			Output := [()]
			(sub := keys => (
				Output.0 := matchKey(words, keys.0)
				(Output.0 = ()) & (len(keys) > 0) :: {
					true -> sub(slice(keys, 1, len(keys)))
				}
			))(keys)
			Output.0 :: {
				() -> Eliza.memory :: {
					[] -> (
						Output.0 := nextReasmb(Eliza.keys.xnone.decomps.0)
					)
					_ -> (
						Output.0 := choose(Eliza.memory)
						` remove just-used output from memory `
						Eliza.memory := filter(Eliza.memory, x => ~(x = Output.0))
					)
				}
				_ -> Output.0
			}
			Output.0 :: {
				() -> Output.0 := ['<no response>']
			}

			cat(Output.0, ' ')
		)
	}

	(sub := response => (
		log(response)
		out('?> ')
		scan(request => trim(request, ' ') :: {
			'' -> log(final())
			_ -> sub(respond(request))
		})
	))(initial())
)

readFile('doctor.txt', data => data :: {
	() -> log('Could not find doctor file')
	_ -> run(data)
})

