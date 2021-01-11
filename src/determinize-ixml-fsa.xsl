<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:gt="http://blackmesatech.com/2020/grammartools"
		xmlns:xs="http://www.w3.org/2001/XMLSchema"
		default-mode="determinize"
		version="3.0">

  <!--* determinize-ixml-fsa.xsl:  Read ixml.xml (pseudo-)regular
      * grammar, rewrite it to be deterministic.
      *-->

  <!--* Revisions:
      * 2020-12-30 : CMSMcQ : split into main and library modules
      *                       to make Saxon hush
      * 2020-12-28 : CMSMcQ : propagate gt:ranges further up the tree: 
      *                       onto alt, and then onto rule.  The value
      *                       on rule is easy to complement to get
      *                       error transitions when they are needed.
      * 2020-12-26 : CMSMcQ : passes Andrews test 
      * 2020-12-25 : CMSMcQ : runs without crashing; output not right 
      * 2020-12-24 : CMSMcQ : still thinking 
      * 2020-12-23 : CMSMcQ : re-factor the plan; separate out 
      *                       prepatory steps and terminal normalization
      * 2020-12-21 : CMSMcQ : begin making first version.  Did not 
      *                       finish; there seems to be a lot of
      *                       bookkeeping
      *-->
  <!--****************************************************************
      * Setup, parameters 
      ****************************************************************
      *-->

  <!--* d2x module for hex/decimal conversions *-->
  <!--* <xsl:import href="../../../lib/xslt/d2x.xsl"/> *-->
  <xsl:import href="range-operations.lib.xsl"/>
  <xsl:import href="eliminate-arc-overlap.lib.xsl"/>
  
  <xsl:output method="xml"
	      indent="yes"/>


</xsl:stylesheet>
