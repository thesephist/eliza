` Port of ELIZA to Ink `

std := load('../vendor/std')
str := load('../vendor/str')
quicksort := load('../vendor/quicksort')

log := std.log
cat := std.cat
map := std.map
filter := std.filter
reduce := std.reduce
append := std.append
each := std.each
slice := std.slice
some := std.some
every := std.every
flatten := std.flatten
f := std.format

digit? := str.digit?
lower := str.lower
index := str.index
split := str.split
trim := str.trim
replace := str.replace

sortBy := quicksort.sortBy

Newline := char(10)
Punctuations := ['.', ',', '?', ';']

` reports whether item is in list `
contains := (list, item) => some(map(list, it => it = item))

` picks a choice at random from list `
choose := list => list.(floor(len(list) * rand()))

parseScriptFile := scriptFile => (
	maybeEmptyLines := split(scriptFile, Newline)
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
			_ -> log(f('Unknown script file command: {{0}}', line))
		}
	))

	` return parsed script state `
	S
)

new := scriptFile => (
	Script := parseScriptFile(scriptFile)

	initial := () => choose(Script.initials)
	final := () => choose(Script.finals)

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
						results := map(results, word => substitute(word, Script.posts))
						`` log(f('Decomp after post: {{0}}', [(std.stringList)(results)]))

						reasmb := nextReasmb(decomp)
						`` log(f('Reassembly: {{0}}', [(std.stringList)(reasmb)]))

						reasmb.0 :: {
							'goto' -> (
								gotoKey := reasmb.1
								Script.keys.(gotoKey) :: {
									() -> (log('Invalid goto key in script file: {{0}}', gotoKey), ())
									_ -> matchKey(words, Script.keys.(gotoKey))
								}
							)
							_ -> (
								output := reassemble(reasmb, results)
								decomp.save :: {
									true -> (
										Script.memory.len(Script.memory) := output
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
		matchDecompR(parts, words, results := [[]]) :: {
			true -> results.0
			_ -> ()
		}
	)
	matchDecompR := (parts, words, results) => (
		true :: {
			(parts = [] & words = []) -> true
			(parts = [] | (words = [] & ~(parts = ['*']))) -> false
			(parts.0 = '*') -> (
				` loop starts with len(words) and increments down to zero `
				(sub := i => (
					results.(0).len(results.0) := slice(words, 0, i)
					matchDecompR(slice(parts, 1, len(parts)), slice(words, i, len(words)), results) :: {
						true -> true
						_ -> (
							results.0 := slice(results.0, 0, len(results.0) - 1)
							i :: {
								~1 -> false
								_ -> sub(i - 1)
							}
						)
					}
				))(len(words))
			)
			(parts.(0).(0) = '@') -> (
				root := slice(parts.0, 1, len(parts.0))
				true :: {
					(Script.synons.(root) = ()) -> log(f('Unknown synonym root {{0}}', [root]))
					~contains(Script.synons.(root), lower(words.0)) -> false
					_ -> (
						results.(0).len(results.0) := [words.0]
						matchDecompR(
							slice(parts, 1, len(parts))
							slice(words, 1, len(words))
							results
						)
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
					true -> sub(reasmb, i + 1)
					_ -> ()
				}
				(reword.0 = '(' & reword.(len(reword) - 1) = ')') -> (
					num := slice(reword, 1, len(reword) - 1)
					every(map(num, digit?)) :: {
						false -> log('Invalid result index {{0}}', [num])
						_ -> (
							num := number(num)
							insert := results.(num - 1)
							insert := reduce(Punctuations, (ins, punct) => (
								punctIdx := index(ins, punct) :: {
									~1 -> ins
									_ -> slice(ins, 0, punctIdx)
								}
							), insert)
							append(output, insert)
							sub(reasmb, i + 1)
						)
					}
				)
				_ -> (
					append(output, [reword])
					sub(reasmb, i + 1)
				)
			}
		))(reasmb, 0)
		output
	)
	respond := request => contains(Script.quits, lower(request)) :: {
		true -> ''
		_ -> (
			` punctuation cleanup `
			request := reduce(Punctuations, (req, punct) => (
				replace(req, punct, ' ' + punct + ' ')
			), request)
			` collapse whitespace `
			request := cat(filter(split(request, ' '), s => len(s) > 0), ' ')

			words := split(request, ' ')
			` pre-substitution `
			words := substitute(words, Script.pres)
			`` log(f('substituted: {{0}}', [cat(words, ' ')]))

			keys := filter(map(words, word => Script.keys.(lower(word))), w => ~(w = ()))
			keys := sortBy(keys, key => ~(key.weight))
			`` log(f('sorted keys: {{0}}', [keys]))

			Output := [()]
			(sub := i => i :: {
				len(keys) -> ()
				_ -> (
					key := keys.(i)
					Output.0 := matchKey(words, key) :: {
						() -> ()
						_ -> sub(i + 1)
					}
				)
			})(0)
			Output.0 :: {
				() -> Script.memory :: {
					[] -> (
						Output.0 := nextReasmb(Script.keys.xnone.decomps.0)
					)
					_ -> (
						Output.0 := choose(Script.memory)
						` remove just-used output from memory `
						Script.memory := filter(Script.memory, x => ~(x = Output.0))
					)
				}
				_ -> Output.0
			}
			Output.0 :: {
				() -> Output.0 := ['<no response>']
			}

			response := cat(Output.0, ' ')
			response := reduce(Punctuations, (res, punct) => (
				replace(res, ' ' + punct, punct)
			), response)
		)
	}

	{
		initial: initial
		final: final
		respond: respond

		` exposed for unit testing `
		testing: {
			substitute: substitute
			matchKey: matchKey
			matchDecomp: matchDecomp
			matchDecompR: matchDecompR
			nextReasmb: nextReasmb
			reassemble: reassemble
		}
	}
)

runWithScript := (scriptFile, prompter, responder) => (
	Eliza := new(scriptFile)

	initial := Eliza.initial
	final := Eliza.final
	respond := Eliza.respond

	` main chat loop `
	(sub := response => (
		responder(response)
		prompter(request => trim(request, ' ') :: {
			'' -> responder(final())
			_ -> (
				resp := respond(request) :: {
					'' -> responder(final())
					_ -> sub(resp)
				}
			)
		})
	))(initial())
)

