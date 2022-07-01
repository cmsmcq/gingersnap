<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    xmlns:d2x="http://www.blackmesatech.com/2014/lib/d2x"
    default-mode="regex"
    version="3.0">

  <!--* ixml-inject-regex.xsl: read an ixml grammar, write out the same
      * grammar with @gt:regex attributes on inclusions and exclusions.
      *
      * Initial use case: simplify coverage measurements
      *-->

  <!--* Revisions:
      * 2022-05-30 : CMSMcQ : first cut
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->

  <xsl:import href="d2x.xsl"/>
  
  <xsl:mode name="regex" on-no-match="shallow-copy"/>
  
  <xsl:strip-space elements="*"/>
  <xsl:output method="xml" indent="yes"/>

  
  <!--****************************************************************
      * Main / starting template
      ****************************************************************
      *-->
  <xsl:template match="ixml">    
    <xsl:copy>
      <xsl:sequence select="@* except @gt:info"/>
      <xsl:attribute name="gt:info"
		     select=" 'regex annotation' "/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <!--****************************************************************
      * Inclusion, exclusion
      ****************************************************************
      *-->

  <xsl:template match="inclusion|exclusion">
    <xsl:variable name="pos-char-groups-0" as="xs:string*">
      <xsl:apply-templates/>
    </xsl:variable>
    <xsl:variable name="pos-char-groups" as="xs:string">
      <xsl:value-of select="string-join($pos-char-groups-0)"/>
    </xsl:variable>
    
    <xsl:copy>
      <xsl:sequence select="@* except @gt:regex"/>
      <xsl:attribute name="gt:regex"
		     select="if (self::exclusion)
			     then concat('[^', $pos-char-groups, ']')
			     else concat('[',  $pos-char-groups, ']')
			     "/>      
      <xsl:sequence select="child::node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="member[@from]">
    <xsl:variable name="f" as="xs:string"
		  select="gt:escape(gt:string-from-point(@from))"/>
    <xsl:variable name="t" as="xs:string"
		  select="gt:escape(gt:string-from-point(@to))"/>
    
    <xsl:value-of select="concat($f, '-', $t)"/>
  </xsl:template>

  <xsl:template match="member[@string]">    
    <xsl:value-of select="gt:escape(@string)"/>
  </xsl:template>
  
  <xsl:template match="member[@hex]">    
    <xsl:value-of select="gt:escape(codepoints-to-string(d2x:x2d(@hex)))"/>
  </xsl:template>

  <xsl:template match="member[@code]">
    
    <xsl:value-of select="concat('\p{', @code, '}')"/>
  </xsl:template>
 
  <!--****************************************************************
      * Functions
      ****************************************************************
      *-->
  <xsl:function name="gt:escape" as="xs:string">
    <xsl:param name="s0" as="xs:string"/>
    <xsl:value-of select="replace($s0, '([\\\[\]\-\^])', '\\$1')"/>
  </xsl:function>
  
  <xsl:function name="gt:string-from-point" as="xs:string">
    <xsl:param name="s0" as="xs:string"/>

    <xsl:choose>
      <xsl:when test="string-length($s0) eq 1">
	<xsl:value-of select="$s0"/>
      </xsl:when>
      <xsl:when test="starts-with($s0, '#')">
	<xsl:value-of select="string(d2x:x2d(substring($s0, 2)))"/>
      </xsl:when>
    </xsl:choose>
  </xsl:function>
  
  <!--****************************************************************
      * Predicates 
      *-->
      
</xsl:stylesheet>
