<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:gt="http://blackmesatech.com/2020/grammartools"
		xmlns:xs="http://www.w3.org/2001/XMLSchema"
		version="3.0">

  <!--* Functions for writing dot files.
      *-->

  <!--* 2020-11-39 : CMSMcQ : made stylesheet, as alternative to
      *                       duplication of function definitions.
      *-->

  
  <!--****************************************************************
      * Functions
      ****************************************************************
      *-->

  <!--* Tricky names are those dot has trouble with.
      * This may change as more grammars uncover issues.
      * For now, we just get rid of hyphens.
      *-->
  <xsl:function name="gt:trickyname"
		as="xs:boolean">
    <xsl:param name="n" as="xs:string"/>
    <xsl:value-of select="contains($n,'-')"/>
  </xsl:function>

  <!--* The node name is how we refer to a nonterminal in dot. *-->
  <xsl:function name="gt:nodename"
		as="xs:string">
    <xsl:param name="n" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="gt:trickyname($n)">
	<xsl:value-of select="translate($n,'-','_')"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="$n"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <!--* The node declaration is how the nonterminal is first
      * introduced in dot, with its mark as part of its label.
      * (Experience shows it's handy to have, when looking at
      * this diagram.)
      *-->
  <!--* gt:nodedecl($name) *-->
  <xsl:function name="gt:nodedecl"
		as="xs:string">
    <xsl:param name="n" as="xs:string"/>
    <xsl:variable name="rule"
		  as="element(rule)?"
		  select="$G//rule[@name=$n]"/>
    <xsl:variable name="mark"
		  as="xs:string?"
		  select="($rule/@mark/string(), '^')[1]"/>
    <xsl:value-of select="gt:nodedecl($n, $mark)"/>
  </xsl:function>
  
  <!--* gt:nodedecl($name, $mark) *-->
  <xsl:function name="gt:nodedecl"
		as="xs:string">
    <xsl:param name="n" as="xs:string"/>
    <xsl:param name="mark" as="xs:string?"/>
    <xsl:value-of select="concat(			      
			  gt:nodename($n),
			  ' [label=&quot;',
			  ($mark, '^')[1],
			  $n,
			  '&quot;]'
			  )"/>
  </xsl:function>
  
</xsl:stylesheet>
