Hey. Half vibe-coded, half have written myself. This is a CLI-utility to convert your Obsdidian vault to a bunch of static html files.

To compile, download the code and run:
```sh
sbcl (or your implementation)
(asdf:make :websidian)
```

You have to get the Deploy library into your local-projects of Quicklisp and install some dependecies before compilation (i think it's patchelf on Linux and some random .dll on Windows. Deploy will tell you what to install).

To use it, open your shell and run:
```
./websidian "name-of-note.md" "THE-SAME-NAME-AS-NOTE.html" "style.css" 
```

Last one is optional, the utility bakes css into html. I personally recommend [Sakura CSS](https://github.com/oxalorg/sakura).

It's more useful in script, something like:

```sh
#!/bin/bash

find . -maxdepth 1 -name "*.md" -print0 | while read -d $'\0' file; do
    clean_file=${file#./}
    output_file="${clean_file%.md}.html"
    
    echo "Processing: $clean_file -> $output_file"
    ./websidian "$clean_file" "$output_file" "style.css"
done
```

It'll work if you put all your files into one directory (also the pics).

If you somehow found this helpful, enjoy.
