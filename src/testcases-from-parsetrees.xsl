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

  <!--* testcases-from-parsetrees.xsl  Read parse tree matrices as 
      * produced by parsetrees-from-dnf and parsetree-pointing, and 
      * write out test cases, as XML.
      *
      * We distinguish:
      * . parse tree matrices are trees containing gt:element elements 
      *   and ixml terminals.
      * . 'raw' parse trees are trees containing elements whose names 
      *   are those of nonterminals in the grammar and whose leaves are
      *   (sequences of) literal characters (or, in the case of XML
      *   output, sometimes numeric character references).
      * . 'cooked' parse trees or 'abstract syntax trees' are XDM trees
      *   in which some internal nodes of the raw parse tree have been
      *   changed from elements to attributes (if marked @) or elided
      *   (if marked -), and some leaf characters have been elided
      *   (when the terminal is marked -).
      * 
      * All three are here represented as XDM trees.  Note that although
      * the cooked parse tree is described as a modification of the raw
      * parse tree, both are in practice derived from the matrix.
      *-->

  <!--* Revisions:
      * 2021-11-17 : CMSMcQ : adjustments to match test-catalog.rnc
      * 2021-01-25 : CMSMcQ : modify to match draft schema for test 
      *                       catalogs
      * 2021-01-24 : CMSMcQ : continue working, writing cooked mode
      * 2021-01-23 : CMSMcQ : make this file 
      *-->

  <!--* We are given as input a parse-tree-collection element
      * containing a sequence of gt:element and gt:failure elements
      * (i.e. parse tree matrices).
      *
      * Each gt:element, and probably each gt:failure element should
      * turn into one positive test case.  (The gt:failure label is
      * potentially inaccurate and should be mistrusted.)
      *
      * Each test case needs metadata, the input string, the
      * expected raw parse tree, and the expected abstract syntax tree.
      * The metadata is tbd, but obvious needs are:
      *
      * - identifier
      * - identity of the governing grammar
      * - polarity
      * - provenance
      * 
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->

  <xsl:include href="testcases-from-parsetrees-raw.xsl"/>
  <xsl:include href="testcases-from-parsetrees-cooked.xsl"/>
  <xsl:include href="inlineability-tests.lib.xsl"/>
  <xsl:import href="codepoint-serialization.lib.xsl"/>
  <xsl:import href="../../../lib/xslt/d2x.xsl"/>
  
  <xsl:output method="xml"
	      indent="yes"/>
  <xsl:strip-space elements="*"/>
  <xsl:mode name="testcases-from-trees" on-no-match="shallow-skip"/>
  <xsl:mode name="serialization" on-no-match="shallow-skip"/>

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
  <xsl:template match="parse-tree-collection">

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

  <xsl:template match="parse-tree-collection
		       /gt:element
		       |
		       parse-tree-collection
		       /gt:failure
		       [not(descendant::nonterminal)]
		       /gt:element">

    <xsl:variable name="n" as="xs:integer"
		  select="1 + count(
			  ancestor::*
			  [parent::parse-tree-collection]
			  /preceding-sibling::*
			  [self::gt:node
			  or self::gt:element
			  or self::gt:failure])"/>

    <xsl:variable name="id" as="xs:string"
		  select="concat(@name, '-', $n)"/>


    <xsl:element name="test-case" namespace="{$ns-tc}">
      <xsl:attribute name="xml:id" select="$id"/>
      <xsl:element name="created" namespace="{$ns-tc}">
	<xsl:attribute name="by" select="$who"/>
	<xsl:attribute name="on" select="$when"/>
      </xsl:element>
      
      <xsl:variable name="lv" as="item()*">
	<xsl:apply-templates mode="serialization"/>
      </xsl:variable>
      <xsl:variable name="s" as="xs:string"
		    select="string-join($lv,'')"/>

      <xsl:choose>
	<xsl:when test="gt:inlineable-string($s)">
	  <xsl:element name="test-string" namespace="{$ns-tc}">
	    <xsl:value-of select="$s"/>
	  </xsl:element>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:variable name="filename" as="xs:string"
			select="concat($result-dir, '/',
				$id, '.ixml')"/>
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

      <xsl:variable name="eAST" as="element()">
	<xsl:apply-templates select="." mode="parsetrees-cooked"/>
      </xsl:variable>      

      <xsl:choose>
	<xsl:when test="gt:inlineable-xml($eAST)">
	  <xsl:element name="result" namespace="{$ns-tc}">
	    <xsl:element name="assert-xml" namespace="{$ns-tc}">
	      <xsl:sequence select="$eAST"/>
	    </xsl:element>
	  </xsl:element>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:variable name="filename" as="xs:string"
			select="concat($result-dir, '/',
				$id, '.ast.xml')"/>
	  <xsl:result-document method="xml"
			       href="{$filename}"
			       indent="no">
	    <xsl:sequence select="$eAST"/>
	  </xsl:result-document>
	  <xsl:element name="assert-xml-ref" namespace="{$ns-tc}">
	    <xsl:attribute name="href" select="$filename"/>
	  </xsl:element>
	</xsl:otherwise>
      </xsl:choose>

      <xsl:element name="app-info" namespace="{$ns-tc}">
	<xsl:variable name="ePT" as="element()">
	  <xsl:apply-templates select="." mode="parsetrees-raw"/>
	</xsl:variable>      
	
	<xsl:choose>
	  <xsl:when test="gt:inlineable-xml($ePT)">
	    <xsl:element name="raw-parse-tree" namespace="{$ns-tc}">
		<xsl:sequence select="$ePT"/>
	    </xsl:element>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:variable name="filename" as="xs:string"
			  select="concat($result-dir, '/',
				  $id, '.raw-parse-tree.xml')"/>
	    <xsl:result-document method="xml"
				 href="{$filename}"
				 indent="no">
	      <xsl:sequence select="$ePT"/>
	    </xsl:result-document>
	    <xsl:element name="raw-parse-tree-ref" namespace="{$ns-tc}">
	      <xsl:attribute name="href" select="$filename"/>
	    </xsl:element>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:element>
      
    </xsl:element>
      
  </xsl:template>

  <xsl:template match="parse-tree-collection/gt:failure
		       [not(descendant::nonterminal)]">
    <xsl:apply-templates/>
  </xsl:template>
  
  <xsl:template match="parse-tree-collection/gt:failure
		       [(descendant::nonterminal)]">
    <xsl:message>
      <xsl:text>Incomplete tree found.</xsl:text>
    </xsl:message>
  </xsl:template>

  <xsl:template match="literal | inclusion | exclusion"
		mode="serialization">
    <xsl:sequence select="gt:serialize(.)"/>
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
    </xsl:element>
  </xsl:template>
  
  <xsl:template name="test-set-header">
    <xsl:attribute name="name" select="test-set-nnn"/>
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
	<xsl:text>Test pipeline: unroll + dnf + parsetree matrices + tests.</xsl:text>
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
