<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:gt="http://blackmesatech.com/2020/grammartools"
		xmlns:xs="http://www.w3.org/2001/XMLSchema"
		default-mode="annotate-pc"
		version="3.0">

  <!--* Read ixml.xml grammar, write it out again with some
      * annotations:  rule/@gt:recursive, nonterminal/@gt:defined,
      * rule/@gt:referenced, rule/@gt:reachable (false only?),
      * optionally rule/@gt:descendants
      *-->

  <!--* Revisions:
      * 2020-12-28 : CMSMcQ : split into main and module
      * 2020-12-01 : CMSMcQ : add rule/@gt:reachable,
      *                       restore nonterminal/@gt:defined
      *                       (both for value=false, omit if true)
      * 2020-11-28 : CMSMcQ : made stylesheet, as alternative to 
      *                       ixml-to-nonterminalslist.xsl
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->
  
  <xsl:import href="ixml-grammar-tools.lib.xsl"/>
  <xsl:include href="ixml-annotate-pc.lib.xsl"/>

  <xsl:output method="xml"
	      indent="yes"/>

  
</xsl:stylesheet>
