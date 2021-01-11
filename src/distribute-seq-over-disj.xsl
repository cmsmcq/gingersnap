<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    default-mode="distribute-sequence-over-disjunction"
    version="3.0">

  <!--* distribute-seq-over-disj.xsl
      * Read ixml.xml grammar, write it out again, replacing every
      * alt of the form (alpha, (beta; gamma)) with a flattened
      * (alpha, beta); (alpha, gamma), i.e. two alt elements.
      *
      * These patterns arise in simplifying the R_0 FSA and
      * we flatten in order to get the rule back into pseudo-regular
      * form.
      *
      * To keep things simple, we do this only for the first 'alts'
      * encountered in any 'alt'.  If we ever develop more than one,
      * we'll need to run this more than once to simplify them all.
      *-->

  <!--* Revisions:
      * 2020-12-13 : CMSMcQ : made stylesheet, for simplifying regular
      *                       grammars and their FSAs
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->

  <xsl:output method="xml"
	      indent="yes"/>

  <xsl:mode name="distribute-sequence-over-disjunction"
	    on-no-match="shallow-copy"/>


  <!--****************************************************************
      * Templates
      ****************************************************************
      *-->
  <xsl:template match="alt[alts]">
    <xsl:param name="which" as="xs:string" tunnel="yes"
	       select=" 'first' "/>
    
    <xsl:variable name="choice" as="element(alts)"		  
		  select="if ($which eq 'first')
			  then alts[1]
			  else if ($which eq 'last')
			  then alts[last()]
			  else alts[$which]"/>
    
    <xsl:variable name="left" as="node()*"
		  select="$choice/preceding-sibling::*"/>
    <xsl:variable name="right" as="node()*"
		  select="$choice/following-sibling::*"/>

    <xsl:for-each select="$choice/alt">
      <xsl:element name="alt">
	<xsl:sequence select="$left, *, $right"/>
      </xsl:element>
    </xsl:for-each>
  </xsl:template>
  
  
</xsl:stylesheet>
