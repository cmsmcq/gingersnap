<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    
    xmlns:rng="http://relaxng.org/ns/structure/1.0"
    
    default-mode="ixml-to-rng"
    version="3.0">

  <!--* ixml-to-rng.xsl: read an invisible-XML grammar, write a
      * Relax NG schema that enforces the structural constraints of
      * the schema.  N.B. constraints on character data are NOT 
      * enforced; v.Next might add Schematron rules.
      *
      * Initial use case is for the ixml specification grammar, so 
      * any dark corners or complications not arising there may be
      * blithely ignored.  Be forewarned.
      *-->

  <!--* Known limits:
      * Assumes that nonterminals are legal XML names.
      *-->

  <!--* Revisions:
      * 2022-03-15 : CMSMcQ : made first draft
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->
  <xsl:mode name="ixml-to-rng" on-no-match="fail"/>
  
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
    <rng:grammar datatypeLibrary="http://www.w3.org/2001/XMLSchema-datatypes">
      <rng:start>
	<rng:ref name="{rule[1]/@name}"/>
      </rng:start>

      <xsl:apply-templates/>
      
    </rng:grammar>
  </xsl:template>


  <!--****************************************************************
      * Rules
      ****************************************************************
      *-->
  <xsl:template match="rule">
    
    <xsl:variable name="N" as="xs:string"
		  select="@name/string()"/>
    <xsl:variable name="mark" as="xs:string"
		  select="(@mark/string(), '^')[1]"/>
    
    <!--* 1. Define the default rule for this nonterminal, based
	* on the mark.
	*-->
    <rng:define name="{@name}">      
      <rng:ref name="{
		     if ($mark = '^') 
                     then 'e.'
                     else if ($mark = '@')
		     then 'a.'
		     else if ($mark = '-')
                     then 'h.'
                     else '!!!mark!!!.'
		     }{$N}"/>
    </rng:define>
    
    <!--* 2. Define the explicit rules we need for this nonterminal,
        * based on all the marks it carries anywhere.  *-->
    <xsl:variable name="reference-marks" as="xs:string*"
		  select="distinct-values(
			  ..//nonterminal[@name = $N]/@mark/string()
			  )"/>
    
    <xsl:if test="'^' = ($mark, $reference-marks)">
      <rng:define name="e.{$N}">
	<rng:element name="{$N}">
	  <rng:ref name="external-attributes"/>
	  <xsl:call-template name="content-pattern"/> 
	</rng:element>
      </rng:define>
    </xsl:if>
    
    <xsl:if test="'@' = ($mark, $reference-marks)">
      <rng:define name="a.{$N}">
	<rng:attribute name="{$N}">
	  <xsl:call-template name="content-pattern"/>
	</rng:attribute>
      </rng:define>
    </xsl:if>
    
    <xsl:if test="'-' = ($mark, $reference-marks)">
      <rng:define name="h.{$N}">
	<xsl:call-template name="content-pattern"/>
      </rng:define>
    </xsl:if>
  </xsl:template>
  
  <!--****************************************************************
      * Content patterns
      ****************************************************************
      *-->
  <xsl:template name="content-pattern">
    <xsl:choose>
      <xsl:when test="count(alt) gt 1">
	<rng:choice>
	  <xsl:apply-templates/>
	</rng:choice>
      </xsl:when>
      <xsl:otherwise>
	<xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="alts">
    <xsl:choose>
      <xsl:when test="count(alt) gt 1">
	<rng:choice>
	  <xsl:apply-templates/>
	</rng:choice>
      </xsl:when>
      <xsl:otherwise>
	<xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="alt">
    <xsl:variable name="children" as="item()*">
      <xsl:apply-templates/>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="exists($children)">
	<rng:group>
	  <xsl:sequence select="$children"/>
	</rng:group>
      </xsl:when>
      <xsl:otherwise>
	<xsl:comment> alt with no realized children </xsl:comment>
	<rng:empty/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="repeat0">
    <xsl:choose>
      <xsl:when test="count(* except comment) eq 1">
	<rng:zeroOrMore>
	  <xsl:apply-templates/>
	</rng:zeroOrMore>
      </xsl:when>
      <xsl:when test="count(* except comment) eq 2">
	<rng:optional>
	  <xsl:apply-templates select="(* except comment)[1]"/>
	  <rng:zeroOrMore>
	    <xsl:apply-templates select="(* except comment)[2]"/>
	    <xsl:apply-templates select="(* except comment)[1]"/>
	  </rng:zeroOrMore>
	</rng:optional>
      </xsl:when>
      <xsl:otherwise>
	<xsl:message terminate="yes">
	  <xsl:text>repetition with wrong number of arguments:</xsl:text>
	  <xsl:copy-of select="."/>
	</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="repeat1">
    <xsl:choose>
      <xsl:when test="count(* except comment) eq 1">
	<rng:oneOrMore>
	  <xsl:apply-templates/>
	</rng:oneOrMore>
      </xsl:when>
      <xsl:when test="count(* except comment) eq 2">
	<rng:group>
	  <xsl:apply-templates select="(* except comment)[1]"/>
	  <rng:zeroOrMore>
	    <xsl:apply-templates select="(* except comment)[2]"/>
	    <xsl:apply-templates select="(* except comment)[1]"/>
	  </rng:zeroOrMore>
	</rng:group>
      </xsl:when>
      <xsl:otherwise>
	<xsl:message terminate="yes">
	  <xsl:text>repetition with wrong number of arguments:</xsl:text>
	  <xsl:copy-of select="."/>
	</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="option">
    <rng:optional>
      <xsl:apply-templates/>
    </rng:optional>
  </xsl:template>

  <xsl:template match="sep">
    <xsl:apply-templates/>
  </xsl:template>
  
  <xsl:template match="nonterminal">
    <rng:ref
	name="{
	      if (@mark eq '^') 
	      then 'e.'
	      else if (@mark eq '@')
	      then 'a.'
	      else if (@mark eq '-')
	      then 'h.'
	      else ''
	      }{@name}"/>
  </xsl:template>

  <xsl:template match="inclusion">
    <xsl:if test="not(@tmark eq '-')">
      <xsl:comment> can a data element be used? </xsl:comment>
      <rng:text/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="exclusion">
    <xsl:if test="not(@tmark eq '-')">
      <xsl:comment> can a data element be used? </xsl:comment>
      <rng:text/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="literal">
    <xsl:if test="not(@tmark eq '-')">
      <xsl:comment> can a data element be used? </xsl:comment>
      <rng:text/>
    </xsl:if>
  </xsl:template>
  
  <!--****************************************************************
      * Attribute value patterns
      ****************************************************************
      *-->
  <!--* Does this need to be distinct? *-->
  <xsl:template name="attribute-value-pattern">
  </xsl:template>
  
  <!--****************************************************************
      * Misc
      ****************************************************************
      *-->
  <xsl:template match="comment"/>


  <!--****************************************************************
      * Functions
      ****************************************************************
      *-->
  
  <!--****************************************************************
      * Predicates 
      *-->
      
</xsl:stylesheet>
