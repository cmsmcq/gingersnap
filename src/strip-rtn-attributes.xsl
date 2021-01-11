<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    default-mode="strip-rtn-attributes"
    version="3.0">

  <!--* strip-rtn-attributes.xsl
      * Read ixml.xml grammar, write it out again, without any 
      * attributes in the rtn namespace.
      *
      * These patterns arise in simplifying the R_0 FSA and
      * we simplify them in order to reduce clutter.
      *
      *-->

  <!--* Revisions:
      * 2020-12-21 : CMSMcQ : despite the name, also remove gl and follow
      * 2020-12-19 : CMSMcQ : made stylesheet, for simplifying regular 
      *                       grammars and their FSAs
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->

  <xsl:output method="xml"
	      indent="yes"/>

  <xsl:mode name="strip-rtn-attributes"
	    on-no-match="shallow-copy"/>

  <xsl:param name="rules"
	     as="xs:string*"
	     select="'#all'"/>

  <!--****************************************************************
      * Templates
      ****************************************************************
      *-->
  <!--* A sequence containing only a choice of sequences.  Lost the
      * wrapper.
      *-->
  <xsl:template match="attribute::*">
    <xsl:choose>
      <xsl:when
	  test="namespace-uri(.)
		=
		('http://blackmesatech.com/2020/iXML/recursive-transition-networks',
		'http://blackmesatech.com/2019/iXML/Gluschkov',
		'http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset'
		)		
		"/>
      <xsl:otherwise>
	<xsl:copy-of select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  
</xsl:stylesheet>
