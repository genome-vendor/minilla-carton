#!/usr/bin/make -f

THIS := $(lastword $(MAKEFILE_LIST))

# Variables for installing into the debian packaging/staging directory
deb_staging_dir ?= /usr
carton_staging_dir ?= local
prefix ?= /usr

datarootdir ?= $(prefix)/share/minilla
datadir ?= $(datarootdir)

bindir ?= $(prefix)/bin

libdir ?= $(datadir)/lib
libexecdir ?= $(datadir)/libexec

# Directories as they appear when the package is installed
exec_prefix ?= $(prefix)
exec_datarootdir ?= $(exec_prefix)/share/minilla
exec_datadir ?= $(exec_datarootdir)
exec_bindir ?= $(exec_prefix)/bin
exec_libdir ?= $(exec_datadir)/lib
exec_libexecdir ?= $(exec_datadir)/libexec

define \n


endef
INSTALL_DIRS = $(foreach dir,$(shell cd $(1); find . -type d),install --directory $(DESTDIR)$(2)/$(dir)$(\n))
INSTALL_FILES = $(foreach file,$(shell cd $(1); find . -type f),install $(1)/$(file) $(DESTDIR)$(2)/$(file)$(\n))
INSTALL = $(foreach func,INSTALL_DIRS INSTALL_FILES,$(call $(func),$(1),$(2)))

BIN_WRAPPER=\
'\#!/bin/sh\n'\
'export PERL5LIB=$(exec_libdir)/perl5\n'\
'export PATH=$(exec_libexecdir):$$PATH\n'\
'exec $(exec_libexecdir)/$(1)' '"$$@"'
INSTALL_WRAPPER = install --directory $(2); echo $(BIN_WRAPPER) | sed 's/^ *//' > $(2)/$(1)

build: validate
	HOME=`pwd`/local carton install --deployment

validate:
ifneq ($(THIS), Makefile)
		$(error This needs to be run without specifying this Makefile manually)
endif

install: validate
	@$(call INSTALL,local/bin,$(libexecdir))
	@$(call INSTALL,local/lib,$(libdir))
	@$(call INSTALL_WRAPPER,minil,$(bindir))

clean:
	rm --recursive --force local/

update: validate
	git rm -r --force --quiet --ignore-unmatch vendor/
	carton install
	carton bundle
	git add cpanfile cpanfile.snapshot vendor
	git status
	@echo ""
	@echo "Staged changes ready for you to review and commit!"
	@echo ""

.PHONY : validate build install clean update
