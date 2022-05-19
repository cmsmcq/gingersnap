<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    
    xmlns:rng="http://relaxng.org/ns/structure/1.0"
    
    default-mode="inlining-hiddens"
    version="3.0">

  <!--* ixml-inline-hidden-nonterminals.xsl: read an invisible-XML 
      * grammar, write an equivalent ixml grammar in which all
      * hidden nonterminals are inlined.  The inlined rules are not
      * eliminated, because in principle they might be recursive.
      * 
      * To eliminate the inlined rules that are not in fact recursive
      * and could in fact be eliminated, the simplest way is probably
      * run ixml-annotate-pc.xsl and remove-unreachables.xsl on the
      * output of this stylesheet.
      *
      * Initial use case is for the ixml specification grammar, so 
      * any dark corners or complications not arising there may be
      * blithely ignored.  Be forewarned.
      *-->

  <!--* Current status:
      * 2022-05-15:  appears to run correctly on ixml.ixml.
      *-->

  <!--* Known limits:
      * Watch this space.
      *-->

  <!--* Revisions:
      * 2022-04-18 : CMSMcQ : made first draft
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->
  <xsl:mode name="inlining-hiddens" on-no-match="shallow-copy"/>
  
  <xsl:strip-space elements="*"/>
  <xsl:output method="xml" indent="yes"/>
  
  <!--****************************************************************
      * Main / starting template
      ****************************************************************
      *-->
  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>
  
  <xsl:template match="ixml">
    <xsl:copy>
      <xsl:sequence select="@*"/>
      <xsl:element name="comment">
	<xsl:text>* </xsl:text>
	<xsl:value-of select="adjust-date-to-timezone(
			      current-date(),
			      ())"/>
	<xsl:text>: hidden nonterminal inlined by </xsl:text>
	<xsl:text>ixml-inline-hidden-nonterminals.xsl *</xsl:text>
      </xsl:element>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>


  <!--****************************************************************
      * Rules
      ****************************************************************
      *-->
  
  <!--****************************************************************
      * Nonterminals patterns
      ****************************************************************
      *-->
  
  <xsl:template match="nonterminal[@mark='-']
		       | nonterminal[not(@mark)]">
    <xsl:param name="lnm-stack" as="xs:string*"
	       tunnel="yes"/>
    
    <xsl:variable name="nt" as="xs:string"
		  select="@name/string()"/>
    <xsl:variable name="rule"
		  as="element(rule)"
		  select="/ixml/rule[@name = $nt]"/>

    <xsl:choose>
      
      <xsl:when test="$nt = $lnm-stack">
	<!-- If we are already inlining a reference to this nonterminal,
	     stop:  it's recursive and we will be caught in a loop.
	-->
	<xsl:sequence select="."/>
      </xsl:when>
      
      <xsl:when test="(@mark, $rule/@mark)[1] eq '-'">
	<!-- If the reference is marked '-' or the reference is unmarked
	     and the rule is marked '-', the nonterminal is hidden in
	     this reference.  So hide it.
	-->
	<xsl:comment>
	  <xsl:value-of select="@name"/>
	</xsl:comment>
	<xsl:element name="alts">
	  <xsl:apply-templates select="$rule/alt">
	    <xsl:with-param name="lnm-stack"
			    tunnel="yes"
			    select="$nt, $lnm-stack"/>
	  </xsl:apply-templates>
	</xsl:element>

      </xsl:when>
      
      <xsl:otherwise>
	<!-- If the rule is not marked '-', it's not hidden.  Leave
	     unhidden references alone.
	-->
	<xsl:sequence select="."/>
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

