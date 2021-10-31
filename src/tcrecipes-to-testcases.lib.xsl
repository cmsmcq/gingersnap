<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    xmlns:d2x="http://www.blackmesatech.com/2014/lib/d2x"
    xmlns:testcat="https://github.com/cmsmcq/ixml-tests"
    default-mode="make-test-cases"
    exclude-result-prefixes="gt xs gl rtn follow d2x testcat"
    version="3.0">

  <!--* trecipes-to-testcases.xsl  Read test-case recipes grammar,
      * write out test cases, as XML.
      *
      *-->

  <!--* Revisions:
      * 2021-01-26 : CMSMcQ : change output to agree with draft
      *                       schema; insert xml-stylesheet PI      
      * 2021-01-23 : CMSMcQ : split codepoint-serialization functions 
      *                       out into library. 
      * 2020-12-28 : CMSMcQ : split into main and module 
      * 2020-12-26 : CMSMcQ : begin writing this, with long comment
      *                       to clear my mind.
      *-->

  <!--* Immediate plan of attack:
      * Generate test-set container, documentation, and test cases.
      * In test-case generation, push choice of characters for
      * inclusions and exclusions to a function.
      * First version of the function is trivial and mechanical.
      * Later versions are better (e.g. allow config file with
      * strings to try).
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->
  
  <xsl:mode name="make-test-cases" on-no-match="shallow-skip"/>

  <!--* who:  what to put in the 'by' attribute of 'created' *-->
  <xsl:param name="who" as="xs:string"
	     select=" 'Gingersnap (CMSMcQ)' "/>

  <!--* when:  what to put in the 'on' attribute of 'created' *-->
  <xsl:param name="when" as="xs:string"
	     select="string(
		     adjust-date-to-timezone(
		     current-date(), ()))"/>

  <!--* G:  short name for the grammar (overrides @gt:base-grammar) *-->
  <xsl:param name="G" as="xs:string?" select="()"/>

  <!--* result-dir:  where do external files go? *-->
  <xsl:param name="result-dir" as="xs:string"
	     select="resolve-uri('external', base-uri(/))"/>

  <!--* ns-tc:  test-catalog namespace *-->
  <xsl:variable name="ns-tc" as="xs:string"
		select=" 'https://github.com/cmsmcq/ixml-tests' " />


  <!--****************************************************************
      * Main / starting template
      ****************************************************************
      *-->
  <!--* With a default identity transform, we don't actually need a
      * main starting template.  But we do want one for ixml, to
      * inject a comment to identify the stylesheet.
      *-->
  <xsl:template match="ixml">

    <xsl:processing-instruction name="xml-stylesheet">
      <xsl:text>type="text/xsl" </xsl:text>
      <xsl:text>href="../../lib/testcat-html.xsl"</xsl:text>
    </xsl:processing-instruction>

    <xsl:element name="test-catalog" namespace="{$ns-tc}">
      <xsl:attribute name="name"
		     select="(@gt:base-grammar,
			     'Test catalog')[1]"/>
      <xsl:attribute name="release-date" select="$when"/>
      <xsl:attribute name="gt:date" select="current-dateTime()"/>
      
      <xsl:call-template name="catalog-header"/>
      
      <xsl:element name="test-set" namespace="{$ns-tc}">
	<xsl:call-template name="test-set-header"/>
	<xsl:call-template name="insert-grammar"/>
	<xsl:apply-templates/>
      </xsl:element>
    </xsl:element>

  </xsl:template>

  <xsl:template match="rule[@gt:polarity]/alt">
    <xsl:element name="test-case" namespace="{$ns-tc}">
      <xsl:attribute name="xml:id" select="../@name"/>
      <xsl:sequence select="../@gt:polarity, @gt:trace"/>
      <xsl:element name="created" namespace="{$ns-tc}">
	<xsl:attribute name="by" select="$who"/>
	<xsl:attribute name="on" select="$when" />
      </xsl:element>
      
      <xsl:variable name="s" as="xs:string" 
		    select="gt:serialize(*)"/>
      <xsl:choose>
	<xsl:when test="gt:inlineable-string($s)">
	  <xsl:element name="test-string" namespace="{$ns-tc}">
	    <xsl:attribute name="gt:hex"
			   select="for $cp in string-to-codepoints($s) 
				   return concat('#', d2x:d2x($cp))"/>
	    <xsl:value-of select="$s"/>
	  </xsl:element>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:variable name="filename" as="xs:string"
			select="concat($result-dir, '/',
				@name, '.ixml')"/>
	  <xsl:result-document method="text"
			       href="{$filename}"
			       indent="no">
	    <xsl:sequence select="$s"/>
	  </xsl:result-document>
	  <xsl:element name="test-string-ref" namespace="{$ns-tc}">
	    <xsl:attribute name="href" select="$filename"/>
	  </xsl:element>
	</xsl:otherwise>
      </xsl:choose>
      <xsl:element name="result" namespace="{$ns-tc}">
	<xsl:choose>
	  <xsl:when test="../@gt:polarity = 'negative'">
	    <xsl:element name="assert-not-a-sentence" namespace="{$ns-tc}"/>
	  </xsl:when>
	  <xsl:when test="../@gt:polarity = 'positive'">
	    <xsl:element name="assert-is-a-sentence" namespace="{$ns-tc}"/>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:element name="assert-test-case-serializer-is-buggy" namespace="{$ns-tc}"/>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:element>
    </xsl:element>
  </xsl:template>

  <!--****************************************************************
      * Named templates
      ****************************************************************
      *-->
  <xsl:template name="catalog-header">
    <xsl:element name="description" namespace="{$ns-tc}">
      <xsl:element name="p" namespace="{$ns-tc}">
	<xsl:text>This test catalog describes tests for </xsl:text>
	<xsl:text>the language defined by </xsl:text>
	<xsl:value-of select="($G,
			      @gt:base-grammar,
			      '[grammar short-name]')[1]"/>
	<xsl:text>.</xsl:text>
      </xsl:element>
      <xsl:element name="p" namespace="{$ns-tc}">
	<xsl:text>Test polarity:  </xsl:text>
	<xsl:value-of select="@gt:test-polarity"/>
	<xsl:text>.</xsl:text>
      </xsl:element>
      <xsl:element name="p" namespace="{$ns-tc}">
	<xsl:text>Test selection:  </xsl:text>
	<xsl:value-of select="@gt:test-selection"/>
	<xsl:text>.</xsl:text>
      </xsl:element>
    </xsl:element>
  </xsl:template>
  
  <xsl:template name="test-set-header">
    <xsl:element name="created" namespace="{$ns-tc}">
      <xsl:attribute name="by" select="$who"/>
      <xsl:attribute name="on" select="$when"/>
    </xsl:element>
    <xsl:element name="description" namespace="{$ns-tc}">
      <xsl:element name="p" namespace="{$ns-tc}">
	<xsl:text>This test set was generated by Gingersnap.</xsl:text>
      </xsl:element>
      <xsl:element name="p" namespace="{$ns-tc}">
	<xsl:text>Test polarity: see the individual tests.</xsl:text>
      </xsl:element>
      <xsl:element name="p" namespace="{$ns-tc}">
	<xsl:text>Test selection: see the individual tests.</xsl:text>
      </xsl:element>
      <xsl:element name="p" namespace="{$ns-tc}">
	<xsl:text>Test pipeline: approximation + FSA + tests.</xsl:text>
      </xsl:element>
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
