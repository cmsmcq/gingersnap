<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    default-mode="parsetrees-cooked"
    exclude-result-prefixes="gt xs gl rtn follow"
    version="3.0">

  <!--* testcases-from-parsetrees-cooked.xsl:  a mode for serializing
      * the 'cooked' parse tree or abstract syntax tree from a 
      * parse tree matrix.  The 'cooked' parse tree elides some
      * element nodes present in the parse tree matrix and represents
      * some as attributes.
      *-->

  <!--* Revisions:
      * 2021-01-24 : CMSMcQ : make this file
      *-->

  <!--* We are given as input a parse-tree matrix and wish to produce
      * from it the output expected of an ixml parser for the case
      * represented.
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->
  
  <xsl:mode name="parsetrees-cooked" on-no-match="shallow-skip"/>

  <xsl:variable name="fDebugging" as="xs:boolean"
		select="false()"/>

  <!--****************************************************************
      * gt:element nodes
      ****************************************************************
      *-->

  <!--* if gt:element is marked ^ or is unmarked, emit an element node,
      * find the attributes, and find the children. *-->
  <xsl:template match="gt:element[not(@mark) or @mark='^']">
    <xsl:element name="{@name}">
      <xsl:apply-templates mode="attributes"/>
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <!--* In attributes mode, finding a serialized elements means
      * recursion can stop. *-->
  <xsl:template match="gt:element[not(@mark) or @mark='^']" mode="attributes"/>
  
  <!--* if gt:element is marked -, do not emit an element node, 
      * but recur to children. Do this for both the default
      * mode and for the attributes mode. *-->
  <xsl:template match="gt:element[@mark='-']"
		mode="#default attributes">
    <xsl:if test="$fDebugging">
      <xsl:comment>
	<xsl:text>* Node for nonterminal </xsl:text>
	<xsl:value-of select="@name"/>
	<xsl:text> elided. *</xsl:text>
      </xsl:comment>
    </xsl:if>
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <!--* if gt:element is marked @, in parsetrees-cooked mode,
      * do nothing.  Attributes are emitted only in attributes mode.
      *-->  
  <xsl:template match="gt:element[@mark='@']"/>

  <!--* if gt:element is marked @, in attributes mode, then emit
      * the attribute.  This is our time to shine!
      *-->  
  <xsl:template match="gt:element[@mark='@']" mode="attributes">
    <xsl:element name="{@name}">
      <xsl:apply-templates mode="attributes"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="inclusion|exclusion|literal"
		mode="#default attributes">
    <!-- <xsl:sequence select="."/> -->
    <xsl:value-of select="gt:serialize(.)"/> 
  </xsl:template>

  <xsl:template match="comment" mode="#default attributes"/>

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
