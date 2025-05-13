## lua like repl for NVIM runtime env

What if the messages window were a REPL:
- type and submit commands (with completion)
  - basically just embed cmdline into messages window
  - could imagine a separate buffer at bottom of messages to type the commands
- features:
  - multiline
  - pull back command history
  - completion like cmdline
    - including current runtime variables

Or, think of the lua REPL, and now imagine that hooked into the lua env/runtime running in neovim

What if I stop using messages as a terinal buffer? I'd lose ansi colors (I could replace those with extmark highglighting)
- then it would be easier to type into it, more intuitive (not re-inventing the typing wheel)
- DO THE colors later, for now how about testing it as a regular (non-terminal) buffer?
- OR I need to better understand what a terminal buffer represents (the buffer part thats in-memory, vs how previous inputs are piped to STDOUT... which is how ansi colors become possible)

OR, what if had a small buffer below that took a multi line command line?
  this is basically what cmdline does... just want it to feel more like a REPL experience...
  or how about a float window with cmdline, that might be wisest way to input and then messages is never an input surface
FOR NOW cmdline is fine!

minimum implementation:
- set filetype to lua to get lua LS completions (static completions)?
- messages might be best suited as just for messages
  - that said, making it interactive would add a new degree of utility
- on_input when creating terminal buffer 
  - but, terminal buffer contents can't be changed like traditional buffer, or I need to think more about it... it's more like what shows is what was previously output (STDOUT)
    - would need to clear the buffer to change anything pre-existing?
  - allow typing into buffer (its already modifiable so I can clear it)
- use normal mode and insert mode keymaps to execute:
  - current line (isl like => send line, icl => clear then send line)
  - basically mirror most of the iron.nvim keymaps
- could also support sending code to the buffer (like iron.nvim does) from another lua file
