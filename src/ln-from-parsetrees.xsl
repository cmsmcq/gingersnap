<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    default-mode="ln-from-parsetrees"
    version="3.0">

  <!--* ln-from-parsetrees.xsl: Read collection of parse trees of the
      * form produced by parsetrees-from-dnf.xsl, and for each
      * nonterminal requested (default: all), extract one complete
      * subtree to represent L(N) for further processing.
      *-->

  <!--* Revisions:
      * 2021-01-22 : CMSMcQ : write this in haste
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->
  


  <xsl:mode name="ln-from-parsetrees" on-no-match="shallow-copy"/>
  
  <xsl:strip-space elements="*"/>
  <xsl:output method="xml" indent="yes"/>

  <!--* nonterminals: list of nonterminals which should be sought. 
      *-->
  <xsl:param name="nonterminals" as="xs:string*" select="()"/>

  
  <!--****************************************************************
      * Main / starting template
      ****************************************************************
      *-->
  <xsl:template match="parse-tree-collection">
    <xsl:param name="nonterminals" as="xs:string*" tunnel="yes"
	       select="$nonterminals"/>
    
    <xsl:element name="parse-tree-collection">
      <xsl:sequence select="@*"/>
      <xsl:attribute name="gt:date" select="current-dateTime()"/>
      <xsl:element name="comment">
	<xsl:value-of select="current-dateTime()"/>
	<xsl:text>: ln-from-parsetrees.xsl.</xsl:text>
      </xsl:element>
      <xsl:element name="comment">
	<xsl:text>    Input: </xsl:text>
	<xsl:value-of select="base-uri(/)"/>
      </xsl:element>
      <xsl:element name="comment">
	<xsl:text>    Output:  trees rooted in N </xsl:text>
	<xsl:text>for each N requested (if available).</xsl:text>
      </xsl:element>
      
      <xsl:text>&#xA;</xsl:text>

      <!--* source-trees: what are we looking at?  *-->
      <xsl:variable name="source-trees" as="element()"
		    select="."/>
      
      <!--* lsNames: what are we looking for?  *-->
      <xsl:variable name="lsNames" as="xs:string*"
		    select="if (empty($nonterminals))
			    then distinct-values(//gt:element/@name)
			    else $nonterminals"/>
      
      <!--* for each name, find complete trees; select the smallest. *-->
      <xsl:for-each select="$lsNames">
	<xsl:variable name="name" as="xs:string" select="."/>

	<xsl:variable name="tree" as="element(gt:element)?"
		      select="sort(
			      $source-trees/descendant::gt:element
			      [@name=$name]
			      [not(descendant::nonterminal)]
			      )[1]"/>

	<xsl:if test="empty($tree)">
	  <xsl:message>
	    <xsl:text>N.B. no tree found for nonterminal </xsl:text>
	    <xsl:value-of select="$name"/>
	  </xsl:message>
	</xsl:if>
	
	<xsl:sequence select="$tree"/>
	
      </xsl:for-each>
    </xsl:element>
  </xsl:template>


  <!--****************************************************************
      * Functions
      ****************************************************************
      *-->
  
  <!--****************************************************************
      * Predicates 
      *-->
      
</xsl:stylesheet>
