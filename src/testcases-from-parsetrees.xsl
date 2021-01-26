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

  <!--****************************************************************
      * Main / starting template
      ****************************************************************
      *-->
  <!--* With a default identity transform, we don't actually need a
      * main starting template.  But we do want one for ixml, to
      * inject a comment to identify the stylesheet.
      *-->
  <xsl:template match="parse-tree-collection">

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


    <test-case xml:id="{$id}">
      <created by="{$who}" on="{$when}" />
      
      <xsl:variable name="lv" as="item()*">
	<xsl:apply-templates mode="serialization"/>
      </xsl:variable>
      <xsl:variable name="s" as="xs:string"
		    select="string-join($lv,'')"/>

      <xsl:choose>
	<xsl:when test="gt:inlineable-string($s)">
	  <test-string>
	    <xsl:value-of select="$s"/>
	  </test-string>
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
	  <test-string-ref href="{$filename}"/>
	</xsl:otherwise>
      </xsl:choose>

      <xsl:variable name="eAST" as="element()">
	<xsl:apply-templates select="." mode="parsetrees-cooked"/>
      </xsl:variable>      

      <xsl:choose>
	<xsl:when test="gt:inlineable-xml($eAST)">
	  <result>
	    <assert-xml>
	      <xsl:sequence select="$eAST"/>
	    </assert-xml>
	  </result>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:variable name="filename" as="xs:string"
			select="concat($result-dir, '/',
				$id, '.ast.xml')"/>
	  <xsl:result-document method="text"
			       href="{$filename}"
			       indent="no">
	    <xsl:sequence select="$eAST"/>
	  </xsl:result-document>
	  <assert-xml-ref href="{$filename}"/>
	</xsl:otherwise>
      </xsl:choose>

      <xsl:element name="app-info">
	<xsl:variable name="ePT" as="element()">
	  <xsl:apply-templates select="." mode="parsetrees-raw"/>
	</xsl:variable>      
	
	<xsl:choose>
	  <xsl:when test="gt:inlineable-xml($ePT)">
	    <raw-parse-tree>
		<xsl:sequence select="$ePT"/>
	    </raw-parse-tree>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:variable name="filename" as="xs:string"
			  select="concat($result-dir, '/',
				  $id, '.raw-parse-tree.xml')"/>
	    <xsl:result-document method="text"
				 href="{$filename}"
				 indent="no">
	      <xsl:sequence select="$ePT"/>
	    </xsl:result-document>
	    <raw-parse-tree-ref href="{$filename}"/>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:element>
      
    </test-case>
      
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
    <xsl:element name="description">
      <xsl:element name="p">
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
    <created by="{$who}" on="{$when}"/>
    <description>
      <p>This test set was generated by Gingersnap.</p>
      <p>Test polarity: positive.</p>
      <p>Test selection: unroll + dnf + parsetree-generation.</p>
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
