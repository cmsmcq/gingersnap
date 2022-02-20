<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:gt="http://blackmesatech.com/2020/grammartools"
		xmlns:xs="http://www.w3.org/2001/XMLSchema"
		version="3.0">

  <!--* Read ixml.xml grammar, write out the R_0 superset.
      *-->

  <!--* Revisions:
      * 2021-01-26 : CMSMcQ : add pseudo-terminals parameter
      * 2021-01-10 : CMSMcQ : make stylesheet for convenience. 
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->
  
  <xsl:import href="grammar-pipeline-handler.xsl"/>

  <xsl:output method="xml"
	      indent="yes"/>

  <!-- <xsl:param name="start" as="xs:string" required="yes"/> -->
  <xsl:param name="start" as="xs:string"
	     select="/descendant::rule[1]/@name/string()"/>

  <!--* pseudo-terminals: list of nonterminals which should not
      * be expanded.
      *-->
  <xsl:param name="pseudo-terminals" as="xs:string*" select="()"/>  

  
  <xsl:variable name="pipeline"
		as="element(grammar-pipeline)">

    <grammar-pipeline>

      <desc>
	<p>This pipeline takes an ixml grammar and produces an R_0
	superset grammar, in the form of a stack-augmented
	pseudo-regular grammar showing the recursive transition
	network for the input grammar.</p>
	<p>I'm not completely sure I know what I'm doing; I know
	I did this before, but I need a better way to remember
	how to do it.  That's this pipeline, maybe.</p>
	
	<p>Revisions:
	2021-01-10 : CMSMcQ : incorporate in a stand-alone stylesheet
	2020-12-30 : CMSMcQ : began pipeline. 
	</p>
      </desc>

      <annotate-pc save="temp.r0.pc.xml">
	<desc>
	  <p>Parent/child annotation is a prerequisite for
	  Gluschkov annoation.</p>
	</desc>
      </annotate-pc>

      <annotate-gl save="temp.r0.gl.xml">
	<desc>
	  <p>Gluschkov annotation is a prerequisite for
	  making the RTN.</p>
	</desc>
      </annotate-gl>

      <item-labels>
	<desc>
	  <p>Label each symbol with a parse item, to make
	  the RTN easier to read and interpret.</p>
	</desc>
      </item-labels>

      <make-rtn non-fissile="{if (empty($pseudo-terminals))
			     then '#none'
			     else $pseudo-terminals}"
		start="{$start}"
		linkage="#none"
		keep-non-fissiles="#yes"
		save="temp.r0.rtn.xml"
		>
	<desc>
	  <p>Build the RTN, using all recursive nonterminals
	  and providing no external linkage.</p>
	</desc>
      </make-rtn>
      <!--
      <expand-references nonterminal="{$pseudo-terminals}"/>      
      -->
    </grammar-pipeline>    
  </xsl:variable>
  
  <xsl:template match="/">
    <xsl:call-template name="gt:pipeline-handler">
      <xsl:with-param name="grammar" select="."/>
      <xsl:with-param name="steps" select="$pipeline/(* except desc)"/>
    </xsl:call-template>
  </xsl:template>
  
</xsl:stylesheet>
