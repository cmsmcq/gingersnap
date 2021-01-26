<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    default-mode="unroll-occurrences"
    version="3.0">

  <!--* unroll-occurrences.xsl: Read ixml.xml grammar G, write out
      * G', similar grammar without repeat0, repeat1, or option.
      *
      * This is a lossy change.
      * 
      *-->

  <!--* Revisions:
      * 2021-01-18 : CMSMcQ : draft transform
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->
  
  <xsl:mode name="unroll-occurrences" on-no-match="shallow-copy"/>
  <xsl:strip-space elements="*"/>
  <xsl:output method="xml"
	      indent="yes"/>

  <!--* n:  when repeat0 and repeat1 are unrolled, how many
      * occurrences of the factor should there be in the 'plural'
      * branch?  We'll get branches with 1, with n, and for repeat0
      * with 0.  More sophisticated control is not currently needed.
      *-->
  <xsl:param name="n" as="xs:integer" select="15"/>

  <!--* G:  short name for this grammar *-->
  <xsl:param name="G" as="xs:string?" select="()"/>

  <!--* uri:  URI to record for this grammar.
      * In practice, we want it relative, not absolute,
      * and having make pass in the file name is the easiest
      * way I have thought of so far.
      *-->
  <xsl:param name="uri" as="xs:string"
	     select=" 'unspecified.ixml.xml' "/>
  
  <!--****************************************************************
      * Main / starting template
      ****************************************************************
      *-->
  <!--* With a default identity transform, we don't actually need a
      * main starting template.  But we do want one for ixml, to
      * inject a comment to identify the stylesheet.
      *-->
  <xsl:template match="ixml">
    
    <xsl:copy>
      <xsl:sequence select="@*"/>
      <xsl:attribute name="gt:date" select="current-dateTime()"/>
      <xsl:attribute name="gt:base-grammar"
		     select="(@gt:base-grammar,
			     $G,
			     base-uri(),
			     'unidentified grammar'
			     )[1]"/>
      <xsl:attribute name="gt:base-grammar-uri"
		     select="($uri,
			     @gt:base-grammar-uri,
			     base-uri()
			     )[1]"/>
      <xsl:element name="comment">
	<xsl:value-of select="current-dateTime()"/>
	<xsl:text>: unroll-occurrences.xsl.</xsl:text>
      </xsl:element>
      <xsl:element name="comment">
	<xsl:text>    Input: </xsl:text>
	<xsl:value-of select="base-uri(/)"/>
      </xsl:element>
      <xsl:element name="comment">
	<xsl:text>    Output:  modified grammar with ? * + unrolled. </xsl:text>
      </xsl:element>
      
      <xsl:text>&#xA;</xsl:text>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="text()[not(parent::comment)]"/>

  <xsl:template match="option">
    <xsl:element name="alts">
      <xsl:attribute name="gt:trace" select="'option'"/>
      <xsl:element name="alt">
	<xsl:element name="comment">
	  <xsl:text>empty</xsl:text>
	</xsl:element>
      </xsl:element>
      <xsl:element name="alt">
	<xsl:apply-templates/>
      </xsl:element>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="repeat0 | repeat1">
    <xsl:param name="n" as="xs:integer" tunnel="yes" select="$n"/>

    <!--* identify the pieces we need to work with *-->
    <xsl:variable name="leChildren" as="element()*"
		  select="* except comment"/>
    <xsl:variable name="factor0" as="element()"
		  select="$leChildren[1]"/>
    <xsl:variable name="sep0" as="element()?"
		  select="$leChildren[2]"/>

    <!--* pre-process the factor and separator. No point having
	* to do it multiple times *-->
    <xsl:variable name="factor" as="element()">
      <xsl:apply-templates select="$factor0"/>
    </xsl:variable>
    <xsl:variable name="sep" as="element()?">
      <xsl:apply-templates select="$sep0/*"/>
    </xsl:variable>

    <!--* Write out a choice of 0, 1, and n occurences of the
	* factor *-->
    <xsl:element name="alts">
      <xsl:attribute name="gt:trace" select="name()"/>

      <!--* 0 occurrences *-->
      <xsl:if test="self::repeat0">
	<xsl:element name="alt">	
	  <xsl:element name="comment">
	    <xsl:text>empty</xsl:text>
	  </xsl:element>
	</xsl:element>
      </xsl:if>
      
      <!--* 1 occurrence *-->
      <xsl:element name="alt">
	<xsl:sequence select="$factor"/>
      </xsl:element>

      <!--* n occurrences *-->
      <xsl:choose>
	<xsl:when test="$n gt 1">
	  <xsl:element name="alt">
	    <xsl:sequence select="$factor"/>
	    <xsl:for-each select="1 to ($n - 1)">
	      <xsl:sequence select="$sep, $factor"/>
	    </xsl:for-each>
	  </xsl:element>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:message>
	    <xsl:text>Warning:  unroll factor (</xsl:text>
	    <xsl:value-of select="$n"/>
	    <xsl:text>) less than 2.</xsl:text>
	    <xsl:text>  Wise?</xsl:text>
	  </xsl:message>
	</xsl:otherwise>
      </xsl:choose>
      
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
