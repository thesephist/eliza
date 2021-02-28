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
						`` log(f('Decomp matched: {{0}} | {{1}}', [(std.stringList)(decomp.parts), results]))
						`` log(f('Decomp results: {{0}}', [(std.stringList)(results)]))

						` post-substitution `
						results := map(results, word => substitute(word, Eliza.posts))
						`` log(f('Decomp after post: {{0}}', [(std.stringList)(results)]))

						reasmb := nextReasmb(decomp)
						`` log(f('Reassembly: {{0}}', [(std.stringList)(reasmb)]))

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
		true :: {
			(parts = [] & words = []) -> true
			(parts = [] | (words = [] & ~(parts = ['*']))) -> false
			(parts.0 = '*') -> (
				` loop starts with len(words) and increments down to zero `
				(sub := (results, i) => (
					results.len(results) := slice(words, 0, i)
					matchDecompR(slice(parts, 1, len(parts)), slice(words, i, len(words)), results) :: {
						true -> true
						_ -> i :: {
							~1 -> false
							_ -> (
								results = slice(results, 0, len(results) - 1)
								sub(results, i - 1)
							)
						}
					}
				))(results, len(words))
			)
			(parts.(0).(0) = '@') -> (
				root := slice(parts.0, 1, len(parts.0))
				true :: {
					(Eliza.synons.(root) = ()) -> (
						log(f('Unknown synonym root {{0}}', [root]))
					)
					~contains(Eliza.synons.(root), lower(words.0)) -> false
					_ -> matchDecompR(
						slice(parts, 1, len(parts))
						slice(words, 1, len(words))
						results
					)
				}
			)
			~(lower(parts.0) = lower(words.0)) -> false
			_ -> matchDecompR(
				slice(parts, 1, len(parts))
				slice(words, 1, len(words))
				results
			)
		}
	)
	nextReasmb := decomp => (
		index := decomp.nextReasmbIdx
		result := decomp.reasmbs.(index % len(decomp.reasmbs))
		decomp.nextReasmbIdx := index + 1
		result
	)
	reassemble := (reasmb, results) => (
		output := []
		(sub := (reasmb, i) => (
			reword := reasmb.(i)
			true :: {
				(reword = () | reword = '') -> i < len(reasmb) :: {
					true -> rsub(reasmb, i + 1)
					_ -> ()
				}
				(reword.0 = '(' & reword.(len(reword) - 1) = ')') -> (
					` TODO: process error when digit inside reword is invalid `
					index := number(slice(reword, 1, len(reword) - 1))
					insert := results.(index - 1)
					` TODO: 
					for punct in [',', '.', ';', '?']:
						if punct in insert:
							insert = insert[:insert.index(punct)]`
					append(output, insert)
					sub(reasmb, i + 1)
				)
				_ -> (
					append(output, [reword])
					sub(reasmb, i + 1)
				)
			}
		))(reasmb, 0)
		output
	)
	respond := request => contains(Eliza.quits, lower(request)) :: {
		true -> ''
		_ -> (
			` punctuation cleanup `
			request := replace(request, '.', ' . ')
			request := replace(request, ',', ' , ')
			request := replace(request, ';', ' ; ')
			request := replace(request, '?', ' ? ')
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
			(sub := keys => keys :: {
				[] -> ()
				_ -> (
					Output.0 := matchKey(words, keys.0)
					(Output.0 = ()) & (len(keys) > 0) :: {
						true -> sub(slice(keys, 1, len(keys)))
					}
				)
			}
			)(keys)
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
		out(response + Newline)
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

