<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    default-mode="parsetree-pointing"
    version="3.0">

  <!--* parsetree-pointing.xsl: Read (a) collection of parse trees of 
      * the form produced by parsetrees-from-dnf.xsl, as main input,
      * and (b) a collection of complete parse trees for various
      * nonterminals N (as produced by ln-from-parsetrees.xsl), and
      * use the trees in (b) to complete the partial trees in (a).
      * 
      * The name is from the technique for repairing brickwork by
      * removing aging or cracked mortar and injecting new mortar into
      * the gaps.
      *-->

  <!--* Revisions:
      * 2021-01-24 : CMSMcQ : modify to ensure we pick up any @mark
      *                       from the nonterminal reference we are
      *                       expanding.
      * 2021-01-22 : CMSMcQ : write this to supply terminated subtrees 
      *                       for incomplete parse trees in the output
      *                       of parsetrees-from-dnf.
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->
  <xsl:mode name="parsetree-pointing" on-no-match="shallow-copy"/>
  
  <xsl:strip-space elements="*"/>
  <xsl:output method="xml" indent="yes"/>

  <xsl:param name="ln" as="xs:string" required="yes"/>
  
  <xsl:variable name="ln-trees" as="document-node()"
		select="doc($ln)"/>
  
  <!--****************************************************************
      * Main / starting template
      ****************************************************************
      *-->
  <xsl:template match="parse-tree-collection">
    
    <xsl:element name="parse-tree-collection">
      <xsl:sequence select="@*"/>
      <xsl:attribute name="gt:date" select="current-dateTime()"/>
      <xsl:element name="comment">
	<xsl:value-of select="current-dateTime()"/>
	<xsl:text>: parsetree-pointing.xsl.</xsl:text>
      </xsl:element>
      <xsl:element name="comment">
	<xsl:text>    Input: </xsl:text>
	<xsl:value-of select="base-uri(/)"/>
      </xsl:element>
      <xsl:element name="comment">
	<xsl:text>    Output:  trees rooted in start symbol </xsl:text>
	<xsl:text>and terminated with terminals.</xsl:text>
      </xsl:element>
      
      <xsl:apply-templates/>

    </xsl:element>
  </xsl:template>

  <xsl:template match="nonterminal">
    <xsl:variable name="name" as="xs:string" select="@name"/>
    <xsl:variable name="tree" as="element(gt:element)?"
		  select="$ln-trees/parse-tree-collection
			  /gt:element[@name = $name]"/>

    <!--* If this nonterminal reference has a mark, we need
	* to inject that mark into the gt:element we expand it
	* to.  Otherwise, we can just use $tree. Assuming it
	* exists.  *-->
    <xsl:choose>
      <xsl:when test="empty($tree) or empty(@mark)">
	<xsl:sequence select="($tree, .)[1]"/>
      </xsl:when>
      <xsl:when test="exists(@mark)">
	<!--* Assert:  exists($tree) and exists(@mark) *-->
	<xsl:element name="gt:element">
	  <xsl:sequence select="$tree/@*, @*, $tree/*"/>
	</xsl:element>
      </xsl:when>
      <xsl:otherwise>
	<xsl:message>
	  <xsl:text>Attention, travelers!  The laws of logic </xsl:text>
	  <xsl:text>appear to have been repealed.</xsl:text>
	  <xsl:text>&#xA;(Or else there is a bug in this code.</xsl:text>
	  <xsl:text>  You decide.)</xsl:text>
	</xsl:message>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>


  <!--****************************************************************
      * Functions
      ****************************************************************
      *-->
  
  <!--****************************************************************
      * Predicates 
      *-->
      
</xsl:stylesheet>
