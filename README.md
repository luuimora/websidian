Hey. Half vibe-coded, half have written myself. This is a CLI-utility to convert your Obsidian vault to a bunch of static html files.
**WARNING**:
- I'm not claiming compatability with any Markdown standart
- My goal is first of all make a utility I use myself for my own vault
- Development is still going on, though it may suddenly be finished (when my vault will be converted to HTML properly)
- I'm open to code review and contribution

**TODO**:
- Checkbox lists
- Various edge cases
- Something I definitely forgot about
- Nesting for lists
- Footnotes

***

To compile, download the code and run:
```sh
sbcl (or your implementation)
(asdf:make :hostsidian)
```

You have to get the Deploy library into your local-projects of [Quicklisp](https://www.quicklisp.org/beta/) and install some dependecies before compilation (i think it's patchelf on Linux and libwinpthread-1.dll on Windows. Deploy will tell you what to install).

To use it, open your shell and run:
```
./hostsidian "name-of-note.md" "THE-SAME-NAME-AS-NOTE.html" "style.css" 
```

Last one is optional, the utility bakes css into html. I personally recommend [Sakura CSS](https://github.com/oxalorg/sakura).

It's more useful in script, something like:

```sh
#!/bin/bash

find . -maxdepth 1 -name "*.md" -print0 | while read -d $'\0' file; do
    clean_file=${file#./}
    output_file="${clean_file%.md}.html"
    
    echo "Processing: $clean_file -> $output_file"
    ./hostsidian "$clean_file" "$output_file" "style.css"
done
```

Script will work as intendent if you put all your files into one directory (also the pics).

If you somehow found this helpful, enjoy.

***

**Project structure**:

1. _predicates.lisp_ contains predicates used in project
2. _inline-walker.lisp_ contains a huge walker function that converts elements that are not blocks
3. _block-walker.lisp_ contains a huge walker function that converts elements that are blocks into AST
4. _renderer-ast.lisp_ contains a huge walker function that converts AST into HTML
5. _functions.lisp_ contains functions that are hanging in the air (mostly block proccessing stuff)
6. _main.lisp_ contains a main function
7. _package.lisp_ declares a package :websidian
8. _hostsidian.asd_ contains an asdf system definition
