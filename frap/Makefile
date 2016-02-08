PACKAGE = $(shell grep "^Name: " DESCRIPTION | cut -f2 -d" ")
VERSION = $(shell grep "^Version: " DESCRIPTION | cut -f2 -d" ")

TARGET_DIR      = target/
RELEASE_DIR     = $(TARGET_DIR)$(PACKAGE)-$(VERSION)
RELEASE_TARBALL = $(TARGET_DIR)$(PACKAGE)-$(VERSION).tar.gz
HTML_DIR        = $(TARGET_DIR)$(PACKAGE)-html
HTML_TARBALL    = $(TARGET_DIR)$(PACKAGE)-html.tar.gz

M_SOURCES   = $(wildcard inst/*.m)
PKG_ADD     = $(shell grep -Pho '(?<=// PKG_ADD: ).*' $(M_SOURCES))

OCTAVE ?= octave --no-window-system --silent

.PHONY: help dist html release install check run clean

help:
	@echo "Targets:"
	@echo "   dist    - Create $(RELEASE_TARBALL) for release"
	@echo "   html    - Create $(HTML_TARBALL) for release"
	@echo "   release - Create both of the above and show md5sums"
	@echo
	@echo "   install - Install the package in GNU Octave"
	@echo "   check   - Execute package tests (w/o install)"
	@echo "   run     - Run Octave with development in PATH (no install)"
	@echo
	@echo "   clean   - Remove releases, html documentation, and oct files"

%.tar.gz: %
	tar -c -f - --posix -C "$(TARGET_DIR)" "$(notdir $<)" | gzip -9n > "$@"

$(RELEASE_DIR): .hg/dirstate
	@echo "Creating package version $(VERSION) release ..."
	-rm -rf "$@"
	hg archive --exclude ".hg*" --exclude "Makefile" --type files "$@"
	chmod -R a+rX,u+w,go-w "$@"

$(HTML_DIR): install
	@echo "Generating HTML documentation. This may take a while ..."
	-rm -rf "$@"
	$(OCTAVE) \
	  --eval "pkg load generate_html; " \
	  --eval "pkg load $(PACKAGE);" \
	  --eval 'generate_package_html ("${PACKAGE}", "$@", "octave-forge");'
	chmod -R a+rX,u+w,go-w $@

dist: $(RELEASE_TARBALL)
html: $(HTML_TARBALL)

release: dist html
	md5sum $(RELEASE_TARBALL) $(HTML_TARBALL)
	@echo "Upload @ https://sourceforge.net/p/octave/package-releases/new/"
	@echo 'Execute: hg tag "release-${VERSION}"'

install: $(RELEASE_TARBALL)
	@echo "Installing package locally ..."
	$(OCTAVE) --eval 'pkg ("install", "${RELEASE_TARBALL}")'

check: all
	$(OCTAVE) --path "inst/" --eval '${PKG_ADD}' --eval 'runtests ("inst");'

run: all
	$(OCTAVE) --persist  --path "inst/" --eval '${PKG_ADD}'

clean:
	rm -rf $(TARGET_DIR)
