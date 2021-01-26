# Makefile for building test cases
# This should become general over time, but the initial rules
# are intended to save time in the very short term and may be
# a bit parochial.

XSLT=~/bin/saxon-he-wrapper.sh

temp.ixml.testcases.xml:  temp.ixml.parsetrees.ranged.xml
	$(XSLT) $< ../src/testcases-from-parsetrees.xsl $@

temp.ixml.parsetrees.ranged.xml:  temp.ixml.parsetrees.completed.xml
	$(XSLT) $< ../src/normalize-terminals.xsl $@

temp.ixml.parsetrees.completed.xml:  temp.ixml.parsetrees.partial.xml temp.ixml.ln.xml
	$(XSLT) $< ../src/parsetree-pointing.xsl $@ ln=`pwd`/temp.ixml.ln.xml

temp.ixml.ln.xml: temp.ixml.parsetrees.partial.xml
	$(XSLT) $< ../src/ln-from-parsetrees.xsl $@

temp.ixml.parsetrees.partial.xml: ixml.unrolled.3.dnf.hand-edited.xml
	$(XSLT) $< ../src/parsetrees-from-dnf.xsl $@ maxfail=10 maxdepth=20

## OK, let's try patterns

temp.%.unroll3.xml: %.ixml.xml
	$(XSLT) $< ../src/unroll-occurrences.xsl $@ n=3 G=$<

%.dnf3.xml: %.unroll3.xml
	$(XSLT) $< ../src/dnf-from-andor.xsl $@ 

%.ptm3.partial.xml: %.dnf3.xml
	$(XSLT) $< ../src/parsetrees-from-dnf.xsl $@
	@echo If there are unfinished trees, run ln-from-parsetrees,
	@echo    edit manually if need be, and run parsetree-pointing.
	@echo Otherwise cp $@ ...complete.xml

# possible complications here ...

%.ptm3.nt.xml: %.ptm3.complete.xml
	$(XSLT) $< ../src/normalize-terminals.xsl $@

%.test-catalog.xml: temp.%.ptm3.nt.xml
	$(XSLT) $< ../src/testcases-from-parsetrees.xsl $@

