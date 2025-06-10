


tags:
# I don't like --extras=+q b/c it duplicates most functions as M.foo when they're already foo on another line
#   but, it does get functions that are nested in another func, so maybe keep it on
#     i.e. iter.sort/iter.tolist (on my superiter type... htought
#   can always filter records that start with M\. and exclude those from prompt
		# ctags -R --extras=+q --languages=lua
		# for now try --extras w/o +q and only add if needed.. the private/hidden state is gonna be very rarely needed
		#    could always do a FIM toggle that switches to new run of ctags w/ diff arg
		# FYI not including markdown and various other config files that are not that important
		ctags -R
		# TODO! consider making a special tags file for consumers of this package to load with minimal (public only) symbols

tests:
		fd "\.tests\." | xargs -I_ nvim --headless -c 'PlenaryBustedFile _'

clean:
		rm -f tags


# TODO build a special tags file for ask-openai? or let it cache what it needs?
# ask.tags:
# 		ctags -R

