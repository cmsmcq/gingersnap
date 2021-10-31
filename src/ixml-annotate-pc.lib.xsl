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
      * 2021-01-26 : CMSMcQ : inject gt:base-grammar and ...-uri
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

  <xsl:mode name="annotate-pc" on-no-match="shallow-copy"/>

  <!--* fListdesc:  List descendants?  true or false *-->
  <xsl:param name="fListdesc" as="xs:boolean" select="false()"/>

  <!--* G:  short name for this grammar *-->
  <xsl:param name="G" as="xs:string?" select="()"/>
  
  <!--****************************************************************
      * Main / starting template
      ****************************************************************
      *-->
  
  <!--* With a default identity transform, we don't actually need a
      * main starting template.  But we do want one for ixml, to
      * inject a comment to identify the stylesheet.
      *-->
  <xsl:template match="ixml">
    
    <xsl:variable name="lnDef"
		  as="xs:string*"
		  select="distinct-values(
			  /descendant::rule/@name/string()
			  )"/>
    <xsl:variable name="lnRef"
		  as="xs:string*"
		  select="distinct-values(
			  /descendant::rule/descendant::nonterminal/@name/string()
			  )"/>
    <xsl:variable name="lnUndef"
		  as="xs:string*"
		  select="$lnRef[not(. = $lnDef)]"/>
    
    <xsl:if test="exists($lnUndef)">
      <xsl:message>Undefined nonterminals found: <xsl:value-of select="$lnUndef"/></xsl:message>
    </xsl:if>

    <xsl:variable name="idStart"
		  as="xs:string"
		  select="child::rule[1]/@name/string()"/>    

    <xsl:if test="root()[not(child::processing-instruction
		  [name() = 'xml-stylesheet'])]">
      <xsl:processing-instruction name="xml-stylesheet">
	<xsl:text>type="text/xsl"</xsl:text>
	<xsl:text> href="../../../gingersnap/src/ixml-html.xsl"</xsl:text>
      </xsl:processing-instruction>
    </xsl:if>
    <xsl:copy>
      <xsl:sequence select="@* except @gt:*"/>
      <xsl:attribute name="gt:date" select="current-dateTime()"/>
      <xsl:attribute name="gt:base-grammar"
		     select="(@gt:base-grammar,
			     $G,
			     base-uri(),
			     'unidentified grammar'
			     )[1]"/>
      <xsl:attribute name="gt:base-grammar-uri"
		     select="(@gt:base-grammar-uri,
			     base-uri()
			     )[1]"/>
      <xsl:element name="comment">
	<xsl:value-of select="current-dateTime()"/>
	<xsl:text>: ixml-annotate-pc.xsl.</xsl:text>
      </xsl:element>
      <xsl:element name="comment">
	<xsl:text>    Input: </xsl:text>
	<xsl:value-of select="base-uri(/)"/>
      </xsl:element>
      <xsl:element name="comment">
	<xsl:text>    Grammar augmented with @gt:recursive etc.</xsl:text>
      </xsl:element>
      <xsl:apply-templates>
	<xsl:with-param name="lnReachable" tunnel="yes" as="xs:string*"
			select="$idStart, gt:lnDescXGN(., $idStart)"/>
	<xsl:with-param name="lnRef" tunnel="yes" as="xs:string*"
			select="$lnRef"/>
	<xsl:with-param name="lnUndef" tunnel="yes" as="xs:string*"
			select="$lnUndef"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="rule">
    <xsl:param name="lnRef" as="xs:string*" tunnel="yes"/>
    <xsl:param name="lnReachable" as="xs:string*" tunnel="yes"/>
    <xsl:variable name="n"
		  as="xs:string"
		  select="string(@name)"/>
    <xsl:variable name="lnChildren"
		  as="xs:string*"
		  select="gt:lnChildrenXGN(.., $n)"/>
    <xsl:variable name="lnDescendants"
		  as="xs:string*"
		  select="gt:lnDescXGN(.., $n)"/>

    <xsl:copy>
      <xsl:sequence select="@* except @gt:*"/>
      <xsl:attribute name="gt:recursive"
		     select="($n = $lnDescendants)"/>
      <xsl:if test="not($n = $lnRef)">
	<xsl:attribute name="gt:referenced"
		       select="false()"/>
      </xsl:if>
      <xsl:if test="not($n = $lnReachable)">
	<xsl:attribute name="gt:reachable"
		       select="false()"/>
      </xsl:if>
      <xsl:if test="$fListdesc">
	<xsl:attribute name="gt:descendants"
		       select="$lnDescendants"/>
      </xsl:if>
      <xsl:apply-templates/>
    </xsl:copy>    
  </xsl:template>

  <xsl:template match="nonterminal">
    <xsl:param name="lnUndef" as="xs:string*" tunnel="yes"/>
    <xsl:copy>
      <xsl:sequence select="@* except @gt:*"/>
      <xsl:if test="string(@name) = $lnUndef">
	<xsl:attribute name="gt:defined" select="false()"/>
      </xsl:if>
      <xsl:sequence select="node()"/>
    </xsl:copy>
  </xsl:template>

  
</xsl:stylesheet>
