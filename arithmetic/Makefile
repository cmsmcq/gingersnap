# Makefile for building test cases
# This has no business being in the test-suite directory but
# for the moment it's here.

XSLT=~/bin/saxon-he-wrapper.sh

# GS is the Gingersnap src directory. 
GS=../src

# WIDTH is unroll width
WIDTH=3

# K is parameter for O_K superset
K=3

# SYBMOL is the recursive symbol(s) needing O0 rules
SYMBOL=N

# COVERAGE is the coverage style for negative test cases
COVERAGE=all

all:
	@echo You want make G.test-catalog.xml
	@echo Then temp.G.u3.raw.xml and follow the instructions.


### Before you start:  XML from the ixml
%.ixml.xml:  %.ixml
	$(XSLT) ../toys/dummy.xml ~/2020/recursive-descent-parsing/ixml-to-xml.manual.xsl $@ input=file inputfile=`pwd`/$<

### First:  the unroll | dnf | parsetrees | testcases pipeline

temp.%.unroll3.xml: %.ixml.xml
	$(XSLT) $< $(GS)/unroll-occurrences.xsl $@ n=3 G=$< uri=$<

%.dnf3.xml: %.unroll3.xml
	$(XSLT) $< $(GS)/dnf-from-andor.xsl $@ 

%.ptm3.partial.xml: %.dnf3.xml
	$(XSLT) $< $(GS)/parsetrees-from-dnf.xsl $@ maxdepth=12
	@echo If there are unfinished trees, run ln-from-parsetrees,
	@echo    edit manually if need be, and run parsetree-pointing.
	@echo Otherwise cp $@ ...complete.xml

%.ptm3.complete.xml: %.dnf3.xml
	$(XSLT) $< $(GS)/parsetrees-from-dnf.xsl $@ maxdepth=20
	@echo If there are unfinished trees, then $@ is not complete.
	@echo    You will need to run make ...ptm3.bis.xml, and
	@echo    edit manually if need be.
	@echo Otherwise proceed.

%.ln3.xml: %.ptm3.partial.xml
	$(XSLT) $< $(GS)/ln-from-parsetrees.xsl $@
	cp $@ temp.noname.ln2.xml

%.ptm3.bis.xml: %.ptm3.partial.xml %.ln3.xml
	$(XSLT) $< $(GS)/parsetree-pointing.xsl $@ ln=`pwd`/temp.noname.ln2.xml
	@echo If that worked, then cp $< G.ptm3.complete.xml

# possible complications here ...
# Use grep to control whether we get complete or partial?

%.ptm3.nt.xml: %.ptm3.complete.xml
	$(XSLT) $< $(GS)/normalize-terminals.xsl $@

%.test-catalog.xml: temp.%.ptm3.nt.xml
	$(XSLT) $< $(GS)/testcases-from-parsetrees.xsl $@




### Second:  the O_k pipeline

# 2a make u3 subset

temp.%.u3.raw.xml: %.ixml.xml
	$(XSLT) $< $(GS)/rk-subset.xsl $@ k=3
	@echo Hand work needed:  O0 grammars are needed for the following identifiers:
	-grep '<nonterminal name="max' $@
	@echo For each such N, run make temp.G.N.O0.rg.xml start=N
	@echo and then develop a pipeline to create temp.G.N.O0.rrp.xml
	@echo and then run make temp.N.O0.rrp.xml

# 2b make O0 superset FSAs, simplified rules.

temp.%.$(SYMBOL).O0.rg.xml: %.ixml.xml
	$(XSLT) $< $(GS)/R0-superset.xsl $@ start=$(SYMBOL)
	@echo Now make a pipeline.  Call it $@.simpipe.xml
	@echo Start with a.S.O0.simplification pipeline if you have nothing better.
	@echo To run the pipeline, make temp.G.N.rrp.xml SYMBOL=N

temp.%.$(SYMBOL).O0.rrp.xml: temp.%.$(SYMBOL).O0.rg.xml temp.%.$(SYMBOL).O0.rg.xml.simpipe.xml
	$(XSLT) $< $(GS)/grammar-pipeline-handler.xsl $@ stepsfile=`pwd`/$<.simpipe.xml
	@echo When you have $@ and the other rrp files, knit them into the O_k superset grammar.
	@echo Name it GRAMMAR.O$(K).ixml.xml and run make temp.GRAMMAR.O$(K).fsa.xml

# 2c knit the O0.rrp rules into the u_k subset to make the O_k superset


# 2d make O_k fsa

temp.%.O$(K).fsa.xml: %.O$(K).ixml.xml
	$(XSLT) $< $(GS)/R0-superset.xsl $@ start='#inherit'
	@echo Next run make temp.G.O$(K).tclego.xml

# 2e make O_k test0case lego pieces

temp.%.O$(K).tclego.xml: temp.%.O$(K).fsa.xml
	$(XSLT) $< $(GS)/tclego-from-rg.xsl $@
	@echo Next run make temp.G.O$(K).tcrecipes.$(COVERAGE).neg.xml

# 2f make O_k negative recipes
temp.%.O$(K).tcrecipes.$(COVERAGE).neg.xml: temp.%.O$(K).tclego.xml
	$(XSLT) $< $(GS)/tclego-to-tcrecipes.xsl $@ coverage=$(COVERAGE) polarity=negative
	@echo Next run make G.O$(K).test-catalog.$(COVERAGE).neg.xml


# 2g make O_k negative test catalogs
%.O$(K).test-catalog.$(COVERAGE).neg.xml: temp.%.O$(K).tcrecipes.$(COVERAGE).neg.xml
	$(XSLT) $< $(GS)/tcrecipes-to-testcases.xsl $@
	@echo Now knit the test catalogs together.  Would it not be nice to automate that?

