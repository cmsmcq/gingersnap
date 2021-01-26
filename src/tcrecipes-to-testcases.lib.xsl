<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    xmlns:d2x="http://www.blackmesatech.com/2014/lib/d2x"
    default-mode="make-test-cases"
    exclude-result-prefixes="gt xs gl rtn follow d2x"
    version="3.0">

  <!--* trecipes-to-testcases.xsl  Read test-case recipes grammar,
      * write out test cases, as XML.
      *
      *-->

  <!--* Revisions:
      * 2021-01-26 : CMSMcQ : change output to agree with draft schema
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


  <!--****************************************************************
      * Main / starting template
      ****************************************************************
      *-->
  <!--* With a default identity transform, we don't actually need a
      * main starting template.  But we do want one for ixml, to
      * inject a comment to identify the stylesheet.
      *-->
  <xsl:template match="ixml">

    <xsl:element name="test-catalog">
      <xsl:attribute name="gt:date" select="current-dateTime()"/>
      <xsl:call-template name="catalog-header"/>
      
      <xsl:element name="test-set">
	<xsl:call-template name="test-set-header"/>
	<xsl:call-template name="insert-grammar"/>
	<xsl:apply-templates/>
      </xsl:element>
    </xsl:element>

  </xsl:template>

  <xsl:template match="rule[@gt:polarity]/alt">
    <test-case>
      <xsl:attribute name="xml:id" select="../@name"/>
      <xsl:sequence select="../@gt:polarity, @gt:trace"/>
      <created by="{$who}" on="{$when}" />

      <xsl:variable name="s" as="xs:string"
		    select="gt:serialize(*)"/>
      <xsl:choose>
	<xsl:when test="gt:inlineable-string($s)">
	  <test-string
	      gt:hex="{for $cp in string-to-codepoints($s) 
		   return concat('#', d2x:d2x($cp)) }"
	      >
	    <xsl:value-of select="$s"/>
	  </test-string>
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
	  <test-string-ref href="{$filename}"/>
	</xsl:otherwise>
      </xsl:choose>
      <result>
	<xsl:choose>
	  <xsl:when test="../@gt:polarity = 'negative'">
	    <assert-not-a-sentence/>
	  </xsl:when>
	  <xsl:when test="../@gt:polarity = 'positive'">
	    <assert-is-a-sentence/>
	  </xsl:when>
	  <xsl:otherwise>
	    <assert-test-case-serializer-is-buggy/>
	  </xsl:otherwise>
	</xsl:choose>
      </result>
    </test-case>    
  </xsl:template>

  <!--****************************************************************
      * Named templates
      ****************************************************************
      *-->
  <xsl:template name="catalog-header">
    <description>
      <xsl:element name="p">
	<xsl:text>This test catalog describes tests for </xsl:text>
	<xsl:text>the language defined by </xsl:text>
	<xsl:value-of select="($G,
			      @gt:base-grammar,
			      '[grammar short-name]')[1]"/>
	<xsl:text>.</xsl:text>
      </xsl:element>
      <p>Test polarity:  <xsl:value-of select="@gt:test-polarity"/>.</p>
      <p>Test selection:  <xsl:value-of select="@gt:test-selection"/>.</p>
    </description>
  </xsl:template>
  
  <xsl:template name="test-set-header">
    <created by="{$who}" on="{$when}"/>
    <description>
      <p>This test set was generated by Gingersnap.</p>
      <p>Test polarity: see the indivicual tests.</p>
      <p>Test selection: see the individual tests.</p>
      <p>Test pipeline: approximation + FSA + tests.</p>
    </description>
  </xsl:template>
  

  <!--****************************************************************
      * Functions
      ****************************************************************
      *-->
 

  <!--****************************************************************
      * Predicates 
      *-->    

</xsl:stylesheet>
