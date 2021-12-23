<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:gt="http://blackmesatech.com/2020/grammartools"
		xmlns:xs="http://www.w3.org/2001/XMLSchema"
		version="3.0">

  <!--* Read ixml.xml grammar, write out an r_k subset.
      *-->

  <!--* Revisions:
      * 2021-01-10 : CMSMcQ : make stylesheet for convenience.
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->
  
  <xsl:import href="grammar-pipeline-handler.xsl"/>

  <xsl:output method="xml"
	      indent="yes"/>

  <xsl:param name="k" as="xs:integer" required="yes"/>

  <xsl:variable name="pipeline"
		as="element(grammar-pipeline)">
    <grammar-pipeline>

      <desc>
        <p>This pipeline takes an ixml grammar and produces an r_k
        subset grammar.</p>
        <p>Two steps are required:  first, parent/child annotation,
        and then the generation of the subset.</p>
      </desc>

      <annotate-pc/>
      <rk-subset k="{$k}"/>

    </grammar-pipeline>
  </xsl:variable>
  
  <xsl:template match="/">
    <xsl:call-template name="gt:pipeline-handler">
      <xsl:with-param name="grammar" select="."/>
      <xsl:with-param name="steps" select="$pipeline/(* except desc)"/>
    </xsl:call-template>
  </xsl:template>
  
</xsl:stylesheet>
