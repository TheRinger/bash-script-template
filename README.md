bash-script-template
====================

***A best practices Bash script template with many useful functions.***

## Motivation

I write ***Bash*** scripts not infrequently and realised that I often copied a recent script whenever I started writing a new one. This provided me with a basic scaffold and several useful helper functions I'd otherwise likely end up duplicating.

So rather than continually copying old scripts and flensing the irrelevant code I'm publishing a more formalised template to ease the process for my own usage and anyone else who may find it helpful! Suggestions for improvements are most welcome.

## Files

| File        | Description                                                                                      |
| ----------- |------------------------------------------------------------------------------------------------- |
| template.sh | A fully self-contained script which combines `source.sh` & `script.sh`.                          |
| source.sh   | Designed for sourcing into scripts; contains only those functions unlikely to need modification. |
| script.sh   | Sample script which sources in `source.sh` and contains those functions likely to be modified.   |
| build.sh    | Generates `template.sh` by combining `source.sh` & `template.sh`. Just a helper script for me.   |
