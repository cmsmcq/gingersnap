<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    xmlns:d2x="http://www.blackmesatech.com/2014/lib/d2x"
    default-mode="parsetrees-raw"
    exclude-result-prefixes="gt xs gl rtn follow d2x"
    version="3.0">

  <!--* testcases-from-parsetrees.xsl  Read parse trees as produced
      * by parsetrees-from-dnf and parsetree-pointing, and write out
      * test cases, as XML.
      *-->

  <!--* Revisions:
      * 2021-01-23 : CMSMcQ : make this file
      *-->

  <!--* We are given as input a parse-tree-collection element
      * containing a sequence of gt:element and gt:failure elements.
      *
      * Each gt:element, and probably each gt:failure element should
      * turn into one positive test case.  (The gt:failure label is
      * potentially inaccurate.)
      *
      * Each test case needs metadata, the input string, the
      * expected raw parse tree, and the expected abstract syntax tree.
      * The metadata is tbd, but obvious needs are:
      *
      * - identifier
      * - identity of the governing grammar
      * - polarity
      * - provenance
      * 
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->
  
  <xsl:mode name="parsetrees-raw" on-no-match="shallow-skip"/>


  <!--****************************************************************
      * Main / starting template
      ****************************************************************
      *-->

  <xsl:template match="gt:element">
    <xsl:element name="{@name}">
      <xsl:sequence select="@* except @name"/>
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="inclusion|exclusion|literal">
    <!-- <xsl:sequence select="."/> -->
    <xsl:variable name="s" as="xs:string"
		  select="gt:serialize(.)"/>
    <gt:character>
      <xsl:sequence select="@* except @gt:ranges"/>
      <xsl:attribute name="hex"
		     select="d2x:d2x(
			     string-to-codepoints($s)
			     )"/>
      <xsl:value-of select="$s"/>
    </gt:character>
  </xsl:template>

  <xsl:template match="comment"/>

  <!--****************************************************************
      * Named templates 
      ****************************************************************
      *-->

  

  <!--****************************************************************
      * Functions
      ****************************************************************
      *-->
 

  <!--****************************************************************
      * Predicates 
      *-->    

</xsl:stylesheet>
