### ------- User Configurable Options ------- ###
## ------------- Latex executables ------------- ##
LATEX       = xelatex
BIBTEX      = bibtex
LATEX_FLAGS = -interaction=batchmode
## ------- Project directories and files ------- ##
# Source Directory: where all your latex files are located
SRCDIR   = src/
# Build Directory: where the build files should be written
BUILDIR  = build/
## NOTE: EVERYTHING BELOW IS RELATIVE TO SOURCE DIRECTORY NOTE ##
# Subfiles Directory: where files compiled as subfiles are located
# NOTE: these files should be compilable as independant latex files
SUBDIR   = sections/
# TEX Directory: where you want make to search for your helper scripts
TEXDIR   = tex/
# Image Directory: where you want make to search for your images
IMGDIR   = images/
# The main tex file for the project
MAINFILE = article.tex
# How you want the output pdf file to be called
OUTPUT   = article.pdf
## ---------------------------------------------- ##
# The Shell interpreter
SHELL    = bash
## ---------------------------------------------- ##

##### ----------------------------------------------------------- #####
# NOTE:Everything Below this line is *not* to be edited by the User!! #
##### ----------------------------------------------------------- #####

##### ----------------------------------------------------------- #####
## Helper functions
##### ----------------------------------------------------------- #####
# filename(s): extract the basename(s) - name without extension
override filename  = $(strip $(basename $(notdir $(firstword $(1)))))
override filenames = $(strip $(basename $(notdir $(1))))
## dirfix: fix a directory name
# - remove leading slash '/'
# - remove all occurances of .
# - remove repeated occurances of '/'
# - add one trailing slash '/'
override dirfix      = $(strip $(patsubst /%,%,$(subst .,,$(_dir_helper))))
override _dir_helper =\
$(subst $(_not_defined_) ,/,$(strip $(subst /, ,$(firstword $(1)))))/
## parent: remove the last entry in a path and obtain the parent dir
override parent          = $(subst $(_not_defined_) ,/,$(_parent_helper_))
override _parent_helper_ =\
$(strip $(filter-out $(lastword $(subst /, ,$(1))),$(subst /, ,$(1))))/
## remove_trail_slash: remove a trailing slash
override remove_trail_slash = $(strip $(patsubst %/,%,$(1)))
##### ----------------------------------------------------------- #####
## Project files and directories
##### ----------------------------------------------------------- #####
# Project Directories
override srcdir  := $(call dirfix,$(SRCDIR))
override buildir := $(call dirfix,$(BUILDIR))
override texdir  := $(subst $(srcdir),,$(call dirfix,$(TEXDIR)))
override subdir  := $(subst $(srcdir),,$(call dirfix,$(SUBDIR)))
override imgdir  := $(subst $(srcdir),,$(call dirfix,$(IMGDIR)))
# Project Files
override mainfile   := $(call filename,$(MAINFILE))
override bibfiles   := $(call filenames,$(wildcard $(srcdir)*.bib))
override subfiles   := $(call filenames,$(wildcard $(srcdir)$(subdir)*.tex))
override texfiles   := $(call filenames,$(wildcard $(srcdir)$(texdir)*.tex))
override imgfiles   := $(notdir $(wildcard $(srcdir)$(imgdir)*))
override pkgfiles   := $(call filenames,$(wildcard $(srcdir)*.sty))
# Main output
ifneq ( $(strip $(firstword $(OUTPUT))),)
override outputfile := $(call filename,$(OUTPUT))
else
override outputfile := $(call filename,$(MAINFILE))
endif
## filter mainfile from texfiles if texdir is empty
ifeq ($(strip $(texdir)),)
$(warning Warning 'TEXDIR' is the same as that of '$(mainfile).tex')
override texfiles   := $(filter-out $(mainfile),$(texfiles))
endif
##### ----------------------------------------------------------- #####
## Reconstruction of project file names from the base names above
##### ----------------------------------------------------------- #####
# The main file and it's targets
override _main_texfile    := $(srcdir)$(mainfile).tex
override _main_outputfile := $(buildir)$(outputfile).pdf
override _main_phonypdf   := $(outputfile).pdf
override _main_phony      := $(outputfile)
# The subfiles and their targets
override _sub_texfiles    := $(addsuffix .tex,$(addprefix $(srcdir)$(subdir),$(subfiles)))
override _sub_outputfiles := $(addsuffix .pdf,$(addprefix $(buildir)$(subdir),$(subfiles)))
override _sub_phonypdfs   := $(addsuffix .pdf,$(addprefix $(subdir),$(subfiles)))
override _sub_phonys      := $(addprefix $(subdir),$(subfiles))
# The bibliography '.bib' files
override _bib_files       := $(addsuffix .bib,$(addprefix $(srcdir),$(bibfiles)))
# Main auxillary build files
override _main_auxfile    := $(buildir)$(outputfile).aux
override _main_bblfile    := $(buildir)$(outputfile).bbl
# Sub auxillary build files
override _sub_auxfiles    := $(addsuffix .aux,$(addprefix $(buildir)$(subdir),$(subfiles)))
override _sub_bblfiles    := $(addsuffix .bbl,$(addprefix $(buildir)$(subdir),$(subfiles)))
# Image files
override _img_files       := $(addprefix $(srcdir)$(imgdir),$(imgfiles))
# Helper Tex files
override _tex_files       := $(addprefix $(srcdir)$(texdir),$(addsuffix .tex,$(texfiles)))
# Package Files
override _pkg_files       := $(addprefix $(srcdir),$(addsuffix .sty,$(pkgfiles)))
##### ----------------------------------------------------------- #####
## Other miscellaneous helper variables
##### ----------------------------------------------------------- #####
override base_build_dir   := $(strip $(firstword $(subst /, ,$(buildir))))

override LATEX_OUTPUT_OPT      := -output-directory=$(buildir)

ifeq ($(outputfile),$(mainfile))
override LATEX_MAIN_OUTPUT_OPT := $(LATEX_OUTPUT_OPT)
else
override LATEX_MAIN_OUTPUT_OPT := $(LATEX_OUTPUT_OPT) -jobname=$(outputfile)
endif

override define _makelink   =
[ -d $(call parent,$(<D)/$(buildir)) ] || mkdir -p $(call parent,$(<D)/$(buildir)); \
[ -d $(call remove_trail_slash,$(<D)/$(buildir)) ] \
|| ln -sr $(call remove_trail_slash,$(@D) $(<D)/$(buildir));
endef

override define _sub_deps_default =
override _sub_$(sub)_tex_depends := $$(_tex_files)
override _sub_$(sub)_img_depends := $$(_img_files)
endef

override define _sub_deps_costom =
ifneq ($$(strip $$(SUB_$(sub)_DEPENDS_TEX)),)
override _sub_$(sub)_tex_depends :=\
$$(filter $$(addsuffix .tex,$$(addprefix %,$$(call filenames,$$(SUB_$(sub)_DEPENDS_TEX)))),$$(_tex_files))
endif
ifneq ($$(strip $$(SUB_$(sub)_DEPENDS_IMG)),)
override _sub_$(sub)_img_depends :=\
$$(filter $$(addprefix %,$$(notdir $$(SUB_$(sub)_DEPENDS_IMG))),$$(_img_files))
endif
endef
##### ----------------------------------------------------------- #####
## Checks and tests
##### ----------------------------------------------------------- #####
# Search if mainfile actually exixst
ifeq ($(filter $(mainfile),$(call filenames,$(wildcard $(srcdir)*.tex))),)
$(error '$(mainfile).tex' not found please specify a valid '.tex' file as mainfile)
endif
# Ensure 'buildir' is not empty
ifeq ($(strip $(buildir)),)
$(error please specify a value for 'BUILDIR' directory; the current directory cannot be used)
endif
# Ensure 'subdir' is non empty
ifeq ($(strip $(subdir)),)
$(error please specify a value for 'SUBDIR' directory; subfiles cannot be in the same directory as '$(mainfile).tex')
endif
## Check that 'base_build_dir' is not empty, so source files won't be removed
# these two checks are the result of a disaster during development!!
ifeq ($(strip $(srcdir)),$(strip $(srcdir)$(base_build_dir)))
$(error Fatal Error; '$$base_build_dir' empty)
endif
ifeq ($(strip $(srcdir)$(subdir)),$(strip $(srcdir)$(subdir)$(base_build_dir)))
$(error Fatal Error; '$$base_build_dir' empty)
endif
##### ----------------------------------------------------------- #####
## Compile options and dependancy configuration
##### ----------------------------------------------------------- #####
override _clean_targets               :=\
clean-all clean clean-build clean-links clean-src-link clean-sub-link remove-configfile
override _exclude_config_with_targets :=\
config.mk generate-configfile $(_clean_targets) help
ifneq ($(strip $(filter-out $(_exclude_config_with_targets),$(MAKECMDGOALS))),)
ifneq ($(strip $(wildcard config.mk)),)
$(info Reading configuration.mk...)
endif
-include config.mk
endif
##### ----------------------------------------------------------- #####
## default configuration
##### ----------------------------------------------------------- #####
# By default build the table of contents, can be changed by user
TOC_REQUIRED = true
# Package dependanies (to exclude in dev packages)
override _pack_depends     := $(_pkg_files)
# Main output dependanies
override _main_sub_depends := $(_sub_texfiles)
override _main_tex_depends := $(_tex_files)
override _main_img_depends := $(_img_files)
# Subfile dependanies
$(foreach sub,$(subfiles),$(eval $(_sub_deps_default)))
##### ----------------------------------------------------------- #####
## More configuration processing
##### ----------------------------------------------------------- #####
# Table of contents
ifeq ($(strip $(filter-out false False FALSE NO No no,$(firstword $(TOC_REQUIRED)))),)
override TOC_REQUIRED = false
else
override TOC_REQUIRED = true
endif
# Main dependancy
ifneq ($(strip $(MAIN_SUBFILE_DEPS)),)
override _main_sub_depends :=\
$(filter $(addsuffix .tex,$(addprefix %,$(call filenames,$(MAIN_SUBFILE_DEPS)))),$(_sub_texfiles))
endif
ifneq ($(strip $(MAIN_TEX_DEPS)),)
override _main_tex_depends :=\
$(filter $(addsuffix .tex,$(addprefix %,$(call filenames,$(MAIN_TEX_DEPS)))),$(_tex_files))
endif
ifneq ($(strip $(MAIN_IMAGE_DEPS)),)
override _main_img_depends :=\
$(filter $(addprefix %,$(notdir $(MAIN_IMAGE_DEPS))),$(_img_files))
endif
# Package dependancy
ifneq ($(strip $(PACK_DEPENDS)),)
override _pack_depends     :=\
$(filter $(addsuffix .sty,$(addprefix %,$(call filenames,$(PACK_DEPENDS)))),$(_pkg_files))
endif
# Subfile dependancy
$(foreach sub,$(subfiles),$(eval $(_sub_deps_costom)))
##### ----------------------------------------------------------- #####
.NOTPARALLEL:
.SUFFIXES:

.DEFUALT_GOAL:build

build: build-main
.PHONY: build

build-all: build-main build-subfiles
.PHONY: build-all

build-main: $(_main_phonypdf)
.PHONY: build-main

build-subfiles: $(_sub_phonypdfs)
.PHONY: build-subfiles

override help: list_subfiles = echo -e "\e[32m...$(1)[.pdf]\e[0m";
override help: list_subfiles_indent = echo -e "......$(1)[.pdf]";
help:
	@echo -e "\e[35mBuild Targets:\e[0m"
	@echo -e "\e[32m...build*\e[0m"
	@echo -e "......build-main"
	@echo -e "\e[32m...build-all\e[0m"
	@echo -e "......build-main"
	@echo -e "......build-subfiles"
	@echo -e "\e[32m...build-main\e[0m"
	@echo -e "......$(_main_phony)[.pdf]"
	@echo -e "\e[32m...build-subfiles\e[0m"
	@$(foreach subfile,$(addprefix $(subdir),$(subfiles)),$(call list_subfiles_indent,$(subfile)))
	@echo -e "\e[35m'Raw' Build Targets:\e[0m"
	@echo -e "\e[32m...$(_main_phony)[.pdf]\e[0m"
	@$(foreach subfile,$(addprefix $(subdir),$(subfiles)),$(call list_subfiles,$(subfile)))
	@echo -e "\e[35mClean Targets:\e[0m"
	@echo -e "\e[32m...clean\e[0m"
	@echo -e "......clean-build"
	@echo -e "......clean-links"
	@echo -e "\e[32m...clean-all\e[0m"
	@echo -e "......clean"
	@echo -e "......remove-configfile"
	@echo -e "\e[32m...clean-build\e[0m"
	@echo -e "\e[32m...clean-links\e[0m"
	@echo -e "......clean-src-link"
	@echo -e "......clean-sub-link"
	@echo -e "\e[32m...clean-src-link\e[0m"
	@echo -e "\e[32m...clean-sub-link\e[0m"
	@echo -e "\e[35mOther Targets:\e[0m"
	@echo -e "\e[32m...help\e[0m"
	@echo -e "\e[32m...debug\e[0m"
	@echo -e "\e[32m...generate-configfile\e[0m"
	@echo -e "......config.mk"
	@echo -e "\e[32m...remove-configfile\e[0m"
	@echo -e "\e[32m...config.mk\e[0m"
.PHONY: help

override debug: sub_msg_tex = echo -e "\e[35mSubfile: $(1).tex Texfile dependancies\e[0m";\
echo -e "\t$(_sub_$(1)_tex_depends)";
override debug: sub_msg_img = echo -e "\e[35mSubfile: $(1).tex Image dependancies\e[0m";\
echo -e "\t$(_sub_$(1)_img_depends)";
debug:
	@echo -e "Files:"
	@echo -e "\e[35mMain File:\e[0m"
	@echo -e "\t$(_main_texfile)"
	@echo -e "\e[35mPackage Files:\e[0m"
	@echo -e "\t$(_pack_depends)"
	@echo -e "\e[35mSubfiles:\e[0m"
	@echo -e "\t$(_sub_texfiles)"
	@echo -e "\e[35mTexfiles:\e[0m"
	@echo -e "\t$(_tex_files)"
	@echo -e "\e[35mImages:\e[0m"
	@echo -e "\t$(_img_files)"
	@echo -e "Configurations:"
	@echo -e "\e[35mMain outputfile:\e[0m"
	@echo -e "\t$(_main_texfile)"
	@echo -e "\e[35mMain Subfile dependancies:\e[0m"
	@echo -e "\t$(_main_sub_depends)"
	@echo -e "\e[35mMain Texfile dependancies:\e[0m"
	@echo -e "\t$(_main_tex_depends)"
	@echo -e "\e[35mMain Image dependancies:\e[0m"
	@echo -e "\t$(_main_img_depends)"
	@$(foreach subfile,$(subfiles),$(call sub_msg_tex,$(subfile)))
	@$(foreach subfile,$(subfiles),$(call sub_msg_img,$(subfile)))
.PHONY: debug

$(_main_phony): $(_main_outputfile)
.PHONY: $(_main_phony)

$(_main_phonypdf): $(_main_outputfile)
.PHONY: $(_main_phonypdf)


ifneq ($(strip $(bibfiles)),)
$(_main_outputfile): $(_main_bblfile)

$(_main_bblfile): $(_main_texfile) $(_bib_files) \
  $(_main_sub_depends) \
  $(_main_tex_depends) \
  $(_main_img_depends) \
  $(_pack_depends)
	@+[ -d $(@D) ] || mkdir -p $(@D)
	@+$(_makelink)
	cd $(<D);\
	$(LATEX) $(LATEX_FLAGS) $(LATEX_MAIN_OUTPUT_OPT) $(<F)
	-cd $(<D);\
	$(BIBTEX) $(buildir)$(basename $(@F)).aux
endif

$(_main_outputfile): $(_main_texfile) \
  $(_main_sub_depends) \
  $(_main_tex_depends) \
  $(_main_img_depends) \
  $(_pack_depends)
	@+[ -d $(@D) ] || mkdir -p $(@D)
	@+$(_makelink)
	cd $(<D);\
	$(LATEX) $(LATEX_FLAGS) $(LATEX_MAIN_OUTPUT_OPT) $(<F);
ifeq ($(strip $(TOC_REQUIRED)),true)
	cd $(<D);\
	$(LATEX) $(LATEX_FLAGS) $(LATEX_MAIN_OUTPUT_OPT) $(<F);
endif

##### ----------------------------------------------------------- #####
## Macros For Subfile rules
##### ----------------------------------------------------------- #####

override _subfile_outfile_  = $$(buildir)$$(subdir)$(1).pdf
override _subfile_bblfile_  = $$(buildir)$$(subdir)$(1).bbl
override _subfile_texfile_  = $$(srcdir)$$(subdir)$(1).tex

override _subfile_phonypdf  = $$(subdir)$(1)
override _subfile_phony     = $$(subdir)$(1).pdf

override define _subfile_rule =
$(_subfile_phony): $(_subfile_outfile_)
.PHONY: $(_subfile_phony)

$(_subfile_phonypdf): $(_subfile_outfile_)
.PHONY: $(_subfile_phonypdf)

ifneq ($$(strip $$(bibfiles)),)
$(_subfile_outfile_): $(_subfile_bblfile_)

$(_subfile_bblfile_): $(_subfile_texfile_) $$(_bib_files) \
  $$(_sub_$(1)_tex_depends) \
  $$(_sub_$(1)_img_depends) \
  $$(_pack_depends)
	@+[ -d $$(@D) ] || mkdir -p $$(@D)
	@+$$(_makelink)
	cd $$(<D);\
	$$(LATEX) $$(LATEX_FLAGS) $$(LATEX_OUTPUT_OPT) $$(<F)
	-cd $$(<D);\
	$$(BIBTEX) $$(buildir)$$(basename $$(@F)).aux
endif

$(_subfile_outfile_): $(_subfile_texfile_) \
  $$(_sub_$(1)_tex_depends) \
  $$(_sub_$(1)_img_depends) \
  $$(_pack_depends)
	@+[ -d $$(@D) ] || mkdir -p $$(@D)
	@+$$(_makelink)
	cd $$(<D);\
	$$(LATEX) $$(LATEX_FLAGS) $$(LATEX_OUTPUT_OPT) $$(<F);
ifeq ($$(strip $$(TOC_REQUIRED)),true)
	cd $$(<D);\
	$$(LATEX) $$(LATEX_FLAGS) $$(LATEX_OUTPUT_OPT) $$(<F);
endif
endef

$(foreach sub,$(subfiles),$(eval $(call _subfile_rule,$(sub))))

##### ----------------------------------------------------------- #####
## clean commands
##### ----------------------------------------------------------- #####
generate-configfile: config.mk
.PHONY: generate-configfile

clean-all: clean remove-configfile
.PHONY: clean-all

clean: clean-links clean-build
.PHONY: clean

clean-build:
	rm -rf $(buildir)
.PHONY: clean-build

clean-links: clean-src-link clean-sub-link
.PHONY: clean-links

clean-src-link:
	rm -rf $(srcdir)$(base_build_dir)
.PHONY: clean-src-link

clean-sub-link:
	rm -rf $(srcdir)$(subdir)$(base_build_dir)
.PHONY: clean-sub-link

remove-configfile:
	rm -f config.mk
.PHONY: remove-configfile
##### ----------------------------------------------------------- #####
## Generate configuration file	@echo "$(backslash)"
##### ----------------------------------------------------------- #####
override _config_rule_with_targets_ := config.mk generate-configfile
ifneq ($(strip $(filter $(_config_rule_with_targets_),$(MAKECMDGOALS))),)
override config.mk: hash := $(strip #$(_not_defined_))
override config.mk: _subfile_config_text_ =\
echo -e "\n$(hash) SUBFILE CONFIGURATION:\
$(1).tex\n$(hash) Select helper 'tex' files required by subfile,\
$(1).tex.\n$(hash) Detected files: $(notdir $(_tex_files))\nSUB_$(1)_DEPENDS_TEX\
= $(notdir $(_tex_files))\n$(hash) Select the images subfile $(1).tex depends\
on.\n$(hash) Detected files: $(notdir $(_img_files))\nSUB_$(1)_DEPENDS_IMG\
= $(notdir $(_img_files))" >> config.mk;

config.mk:
	@echo -e "$(hash) Set This variable if you need a Table of contents"\
	"\n$(hash) you can use true or false (FALSE, False, false, NO, no, No)"\
	"\nTOC_REQUIRED = true"\
	"\n"\
	"\n$(hash) NOTICE: The below sections will require you to select files :NOTICE"\
	"\n$(hash) Existing files are detected and placed in a comment above the option"\
	"\n$(hash) please select among them only. If you specify random non existant files"\
	"\n$(hash) the build will likely fail."\
	"\n$(hash) You can leave out extensions if you choose."\
	"\n$(hash) Further, The directories are not needed here, they are anyway striped before"\
	"\n$(hash) processing."\
	"\n"\
	"\n$(hash) Specify the package files to include."\
	"\n$(hash) Detected files: $(notdir $(_pkg_files))"\
	"\nPACK_DEPENDS = $(notdir $(_pkg_files))"\
	"\n"\
	"\n$(hash) Select the subfiles $(notdir $(_main_texfile)) depends on."\
	"\n$(hash) Detected files: $(notdir $(_sub_texfiles))"\
	"\nMAIN_SUBFILE_DEPS = $(notdir $(_sub_texfiles))"\
	"\n$(hash) Select the helper 'tex' $(notdir $(_main_texfile)) depends on."\
	"\n$(hash) Detected files: $(notdir $(_tex_files))"\
	"\nMAIN_TEX_DEPS     = $(notdir $(_tex_files))"\
	"\n$(hash) Select the images $(notdir $(_main_texfile)) depends on."\
	"\n$(hash) Detected files: $(notdir $(_img_files))"\
	"\nMAIN_IMAGE_DEPS   = $(notdir $(_img_files))"\
	> config.mk
	@$(foreach sub,$(subfiles),$(call _subfile_config_text_,$(sub)))
endif
