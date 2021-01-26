<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:gt="http://blackmesatech.com/2020/grammartools"
		xmlns:xs="http://www.w3.org/2001/XMLSchema"
		version="3.0">

  <!--* Read ixml.xml grammar for FSA, write out the tclego grammar.
      *-->

  <!--* Revisions:
      * 2021-01-26 : CMSMcQ : make stylesheet for convenience.
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->
  
  <xsl:import href="grammar-pipeline-handler.xsl"/>

  <xsl:output method="xml"
	      indent="yes"/>

  <xsl:variable name="pipeline"
		as="element(grammar-pipeline)">
    
    <grammar-pipeline>
      <desc>
	<p>Generic pipeline for converting a regular approximation
	(whether an r_k subset or an R_k superset) to a
	deterministic FSA from which test cases can be generated.</p>
	<p>At least, it's mostly generic.</p>
	<p>The make-rtn/@fissile attribute is grammar-specific.</p>
	<p>The expand-references/@nonterminals attribute is currently
	grammar-specific. If we add a way to tell make-rtn not to add
	linkage rules, this could be dispensed with.</p>
      </desc>
      <desc>
	<p>Revisions:</p>
	<p>2021-01-26 : CMSMcQ : wrap old a.regular-approx-to-dfsa.pipeline.xml
	pipeline in a stylesheet to simplify invocation.</p>
	<p>2021-01-13 : CMSMcQ : normalize-terminals is required, 
	not optional, even for a.ixml.</p>
	<p>2021-01-12 : CMSMcQ : revise for a.ixml u5 and O2 
	approximations.</p>
	<p>2020-12-31 : CMSMcQ : made file (but apparently did not
	get it to a working state)</p>
      </desc>

      <normalize-terminals>
	<desc>
	  <p>Normalization of terminals is required for
	  the determinization step to work, even when
	  the grammar appears not to need it: the
	  annotations are used in checking determinism.
	  </p>
	</desc>
      </normalize-terminals>

      <eliminate-unit-rules>
	<desc>
	  <p>The FSAs I'm working with have epsilon transitions,
	  which of course take the form of unit rules.
	  We need to lose them before determinizing.
	  </p>
	</desc>
      </eliminate-unit-rules>

      <annotate-pc>
	<desc>
	  <p>Epsilon elimination does make some states unreachable,
	  so let's clear them out.  First re-annotate.  Then
	  do the deed.</p>
	</desc>
      </annotate-pc>
      <remove-unreachables>
	<desc>
	  <p>I said, then do the deed.  Get moving!</p>
	</desc>
      </remove-unreachables>
      
      <simplify-epsilon-expressions save="temp.nfsa.xml">
	<desc><p>Not always needed, but not harmful.</p></desc>
      </simplify-epsilon-expressions>  

      <determinize>
	<desc>
	  <p>Now make the FSA deterministic.</p>
	</desc>
      </determinize>      
      
      <simplify-epsilon-expressions save="temp.dfsa.xml"/>

      <fsa-to-tclego save="temp.tclego.xml"/>
  
    </grammar-pipeline>
  </xsl:variable>
  
  <xsl:template match="/">
    <xsl:call-template name="gt:pipeline-handler">
      <xsl:with-param name="grammar" select="."/>
      <xsl:with-param name="steps" select="$pipeline/(* except desc)"/>
    </xsl:call-template>
  </xsl:template>
  
</xsl:stylesheet>
