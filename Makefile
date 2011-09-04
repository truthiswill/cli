SHELL = bash

docs = $(shell find doc -name '*.md' \
				|sed 's|.md|.1|g' \
				|sed 's|doc/|man1/|g' )

htmldocs = $(shell find doc -name '*.md' \
						|sed 's|.md|.html|g' \
						|sed 's|doc/|html/doc/|g' ) html/doc/index.html

doc_subfolders = $(shell find doc -type d \
									|sed 's|doc/|man1/|g' )

# This is the default make target.
# Since 'make' typically does non-installation build stuff,
# it seems appropriate.
submodules:
	! [ -d .git ] || git submodule update --init --recursive

latest: submodules
	@echo "Installing latest published npm"
	@echo "Use 'make install' or 'make link' to install the code"
	@echo "in this folder that you're looking at right now."
	node cli.js install -g -f npm

install: submodules
	node cli.js install -g -f

# backwards compat
dev: install

link: uninstall
	node cli.js link -f

clean: uninstall
	node cli.js cache clean

uninstall: submodules
	node cli.js rm npm -g -f

man: man1

man1: $(doc_subfolders)
	[ -d man1 ] || mkdir -p man1

html/doc: $(doc_subfolders)
	[ -d html/doc ] || mkdir -p html/doc

doc: $(docs) $(htmldocs)

# use `npm install ronn` for this to work.
man1/%.1: doc/%.md man1
	@[ -x ./node_modules/.bin/ronn ] || node cli.js install ronn
	./node_modules/.bin/ronn --roff $< > $@

man1/%/: doc/%/ man1
	@[ -d $@ ] || mkdir -p $@

# use `npm install ronn` for this to work.
html/doc/%.html: doc/%.md html/dochead.html html/docfoot.html html/doc
	@[ -x ./node_modules/.bin/ronn ] || node cli.js install ronn
	(cat html/dochead.html && \
	 ./node_modules/.bin/ronn -f $< && \
	 cat html/docfoot.html )\
	| sed 's|@NAME@|$*|g' \
	| sed 's|@DATE@|$(shell date -u +'%Y-%M-%d %H:%m:%S')|g' \
	| perl -pi -e 's/npm-([^\)]+)\(1\)/<a href="\1.html">npm-\1(1)<\/a>/g' \
	| perl -pi -e 's/npm\(1\)/<a href="index.html">npm(1)<\/a>/g' \
	> $@

html/doc/index.html: html/doc/npm.html
	cp $< $@

html/doc/%/: doc/%/ html/doc
	@[ -d $@ ] || mkdir -p $@

test: submodules
	node cli.js test

version: link
	git add package.json &&\
	git ci -m v$(shell npm -v)

publish: link
	git tag -s -m v$(shell npm -v) v$(shell npm -v) &&\
	git push origin master &&\
	npm publish

.PHONY: latest install dev link doc clean uninstall test man
