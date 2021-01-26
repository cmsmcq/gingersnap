<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    default-mode="testcases-from-trees"
    exclude-result-prefixes="gt xs gl rtn follow"
    version="3.0">

  <!--* inlineability-tests.lib.xsl  Functions for use when writing
      * out test cases.
      *-->

  <!--* Revisions:
      * 2021-01-26 : CMSMcQ : split out from testcases-from-parsetrees
      *-->

  <!--****************************************************************
      * Functions 
      ****************************************************************
      *-->
  <!--* gt:inlineable-string(), inlineable-xml():  is it OK
      * to put this test case or test result in the catalog?
      *-->
      
  <xsl:function name="gt:inlineable-string" as="xs:boolean">
    <xsl:param name="s" as="xs:string"/>
    <xsl:sequence
	select="if (string-length($s) gt 1500)
		then false()
		else if (contains($s, '&#xD;'))
		then false()
		else true()"/>
  </xsl:function>
  
  <xsl:function name="gt:inlineable-xml" as="xs:boolean">
    <xsl:param name="e" as="element()"/>
    <xsl:sequence
	select="if (count($e/descendant-or-self::*) gt 50)
		then false()
		else if (contains(string($e), '&#xD;'))
		then false()
		else true()"/>
  </xsl:function>



  <!--****************************************************************
      * Named templates
      ****************************************************************
      *-->
  
  <xsl:template name="insert-grammar">
    <!--* Ideally, if the ixml is short we should
	* insert it.  Say, up to ten rules.
	* For now, though, we do the quickest thing that
	* could work.
	*
	* Also, let's change the schema to allow multiple
	* specifications of the grammar.  If we have it
	* in multiple forms, we might as well do it.
	*-->
    
    <!--* ixml, if we have it *-->
    <xsl:if test="exists(/*/comment[@gt:type='ixml'])">
      <xsl:element name="ixml-grammar">
	<xsl:value-of select="/*/comment[@gt:type='ixml']"/>
      </xsl:element>
    </xsl:if>

    <!--* reference to ixml, if we have it *-->
    <xsl:if test="exists(/*/@gt:ixml-grammar-uri)">
      <xsl:element name="ixml-grammar-ref">
	<xsl:attribute name="href" select="/*/@gt:ixml-grammar-ref"/>
      </xsl:element>
    </xsl:if>

    <!--* XML, if we have it and it's small enough *-->
    <xsl:variable name="uriG" as="xs:anyURI?"
		  select="if (exists(/*/@gt:base-grammar-uri))
			  then resolve-uri(/*/@gt:base-grammar-uri,
			  base-uri(.))
			  else ()
			  "/>
    <xsl:variable name="eG" as="element(ixml)?"
		  select="if (exists($uriG))
			  then doc(string($uriG))/ixml
			  else ()"/>
    <xsl:if test="exists($eG) and gt:inlineable-xml($eG)">
      <xsl:element name="vxml-grammar">
	<xsl:sequence select="$eG"/>
      </xsl:element>
    </xsl:if>

    <!--* XML reference, if we have it. *-->
    <xsl:if test="exists(/*/@gt:base-grammar-uri)">
      <xsl:element name="vxml-grammar-ref">
	<xsl:attribute name="href" select="/*/@gt:base-grammar-uri"/>
      </xsl:element>
    </xsl:if>
    
    <!--* Fake it, if we have to. *-->
    <xsl:if test="not(exists(/*/comment[@gt:type='ixml']))
		  and not(exists(/*/@gt:ixml-grammar-uri)) 
		  and not(exists(/*/@gt:base-grammar-uri))">
      <xsl:element name="ixml-grammar">
	<xsl:text>{grammar not found, </xsl:text>
	<xsl:text>manual intervention needed}</xsl:text>
      </xsl:element>
    </xsl:if>
    
  </xsl:template>  

</xsl:stylesheet>
