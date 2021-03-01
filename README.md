# Eliza 🥂

**Eliza** is a modern incarnation of the [ELIZA program](https://en.wikipedia.org/wiki/ELIZA) first developed in the mid-1960's at MIT's AI lab, ported to pure [Ink](https://dotink.co/) and compiled to JavaScript with [September](https://github.com/thesephist/september) to also run in the browser, as well as as a command-line app.

![Eliza running in a browser](docs/screenshot.png)

ELIZA was one of the earliest programs designed to hold a natural language conversation with human users, and uses a simple algorithm with a predefined "script" to parse your messages and try to offer a related response. The most popular script, including the one included in this web app, is a "doctor" script that tries to ask rhetorical questions like a superficial therapist might.

## Usage

If you want to simply try Eliza, you can find try the [online chat interface](https://eliza.dotink.co/).

If you want to customize Eliza or run it locally:

1. Clone the repository.
2. Download an [Ink release binary](https://github.com/thesephist/ink/releases/) for your platform.
3. Run `ink main.ink` to start the command-line conversation repl.

You can modify the script in `script.txt` to change how Eliza responds to queries from the user. The format for the file is not formally specified, but should be self-explanatory.

## Implementation

This Ink implementation of Eliza is based on MIT-licensed open-source implementations at [jezhiggins/eliza.py](https://github.com/jezhiggins/eliza.py) and [wadetb/eliza](https://github.com/wadetb/eliza), with tweaks from the [original 1966 paper on ELIZA's design](https://cse.buffalo.edu/~rapaport/572/S02/weizenbaum.eliza.1966.pdf). Eliza references a script, kept in the repository as [`script.txt](script.txt), to generate responses. The script followes a well specified format that feels like a domain-specific regular expression, so other scripts may be added to Eliza to modify its behavior.

Eliza is implemented as both a command-line app running on the native Ink interpreter, and as a [web app](https://eliza.dotink.co/), by compiling the Eliza library down to JavaScript.

### Isomorphic Ink in the real world

Eliza's core algorithm is implemented in _isomorphic Ink_ code that can run both natively and in the browser, which makes Eliza the first real-world Ink application that runs on both environments with the same codebase.

On the client, the [`eliza.ink`](lib/eliza.ink) library is loaded by [`main.ink`](main.ink) and run in a simple read-print loop.

```
`` ...

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
```

In the browser, `eliza.ink` is compiled to JavaScript with the [September](https://github.com/thesephist/september) compiler, and called from UI code in [`lib/ui.js.ink`](lib/ui.js.ink) that renders the rest of the application by leveraging [Torus](https://github.com/thesephist/torus) as a rendering library. Using Torus's lower level APIs, the Ink code driving the UI can describe the application UI declaratively and depend on the framework for efficient rendering.

### Development

Most of the application logic, including the core Eliza algoritm, is in `lib/`. Ink programs meant to run in the browser is marked by a `*.js.ink` extension, like the Torus-Ink API wrapper or the UI code.

The web app lives entirely in `static/`, where you'll also find some vendored Ink dependencies as well as a copy of the script for web distribution. Ink code is compiled to the `static/ink/` folder for serving by a few Makefile scripts, which you can run if you have the September compiler installed.

`test/` specifies a small suite of unit tests for Eliza's internal implementation functions, built on Ink's unit testing library `suite`. You can run this test suite with `make check` or `make t`.

## License

All Ink code in the repository is licensed under the MIT open-source license included with the distribution of this repository. The Eliza script file is exempt from this and instead shared under the license provided in its original repository [github.com/wadetb/eliza](https://github.com/wadetb/eliza).
