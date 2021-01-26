<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    default-mode="make-test-cases"
    version="3.0">

  <!--* trecipes-to-testcases.xsl  Read test-case recipes grammar,
      * write out test cases, as XML.
      *
      * We should start with a little metadata describing the
      * contents, includilng whether they are positive or negative
      * and so on.
      *
      * Then what we want is essentially a test catalogue, with inline
      * input rather than separate files.  For the moment, we assume
      * that one run of this stylesheet will produce one set of tests
      * (part of a test suite).
      *
      * 
      *-->

  <!--* Revisions:
      * 2021-01-26 : CMSMcQ : import inlineability functions
      * 2021-01-23 : CMSMcQ : split codepoint-serialization functions 
      *                       out into library. 
      * 2020-12-28 : CMSMcQ : split into main and module 
      * 2020-12-26 : CMSMcQ : begin writing this, with long comment 
      *                       to clear my mind.
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->
  
  <xsl:include href="tcrecipes-to-testcases.lib.xsl"/>
  <xsl:include href="codepoint-serialization.lib.xsl"/>
  <xsl:include href="inlineability-tests.lib.xsl"/>
  <xsl:import href="../../../lib/xslt/d2x.xsl"/>
  
  <xsl:output method="xml"
	      indent="yes"/>  

</xsl:stylesheet>
