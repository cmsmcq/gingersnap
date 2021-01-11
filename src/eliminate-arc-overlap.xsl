<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:gt="http://blackmesatech.com/2020/grammartools"
		xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"		
		xmlns:xs="http://www.w3.org/2001/XMLSchema"
		default-mode="arc-overlap"
		version="3.0">

  <!--* eliminate-arc-overlap.xsl:  module for inclusion into
      * determinzie.xsl.  Templates to process rules so as to
      * eliminate partial overlap between arcs in an FSA.
      *-->

  <!--* Revisions:
      * 2020-12-28 : CMSMcQ : split into main and module to quiet Saxon 
      * 2020-12-28 : CMSMcQ : propagate gt:ranges further up the tree:
      *                       onto alt, and then onto rule.  The value
      *                       on rule is easy to complement to get
      *                       error transitions when they are needed.
      *                       Also factor sanity checks into template.
      * 2020-12-26 : CMSMcQ : make sanity checks fire correctly
      * 2020-12-25 : CMSMcQ : correct some errors; passes Andrews test.
      * 2020-12-24 : CMSMcQ : draft completed, ready to test.
      * 2020-12-23 : CMSMcQ : begin making first version. 
      *-->

  <!--****************************************************************
      * Plan / overview 
      ****************************************************************
      *
      * We assume the input is a regular grammar.  We should probably
      * check.
      *
      * We check the arcs leaving each state (the RHS of each rule) to
      * ensure that no two of them have a partial overlap.  Any two
      * rules have the same non-terminal, or disjoint non-terminals.
      * (This doesn't come up in automata theory because there arcs are
      * assumed to be labeled with single symbols - not much fun in
      * a Unicode world.)
      *
      * For each arc, we split the label whenever we find overlap
      * with another arc.  We then check each split again.
      *
      * More formally:
      * if for any arc $a there is sibling $s such that ($a \ $s) and
      * ($a intersect $s) are both non-empty (which means each will
      * be different from $a), then we create a new arc for each of
      * these, and call the routine recursively.  If there is no such
      * sibling, then the arc goes into the output without change.
      *
      * To say it explicitly, this approach is based on two premises:
      * (1) We can work on rules individually: we do NOT have to work
      * pairwise.
      * (2) We can split rules by considering just the original 
      * grammar:  it is not necessary to consult the modified rules.
      *
      *-->

  
  <!--****************************************************************
      * Setup, parameters 
      ****************************************************************
      *-->

  <xsl:import href="range-operations.lib.xsl"/>
  <xsl:include href="eliminate-arc-overlap.lib.xsl"/>
  
  <xsl:output method="xml"
	      indent="yes"/>

  <xsl:template match="/ixml">
    <xsl:copy>
      <xsl:sequence select="@*"/>
      <xsl:attribute name="gt:date" select="current-dateTime()"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>
