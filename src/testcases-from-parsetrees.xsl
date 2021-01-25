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
  <xsl:import href="codepoint-serialization.lib.xsl"/>
  
  <xsl:output method="xml"
	      indent="yes"/>
  <xsl:strip-space elements="*"/>
  <xsl:mode name="testcases-from-trees" on-no-match="shallow-skip"/>
  <xsl:mode name="serialization" on-no-match="shallow-skip"/>

  <!--****************************************************************
      * Main / starting template
      ****************************************************************
      *-->
  <!--* With a default identity transform, we don't actually need a
      * main starting template.  But we do want one for ixml, to
      * inject a comment to identify the stylesheet.
      *-->
  <xsl:template match="parse-tree-collection">

    <xsl:element name="test-set">
      <xsl:attribute name="gt:date" select="current-dateTime()"/>
      <xsl:call-template name="test-set-header"/>
      <xsl:apply-templates/>
    </xsl:element>

  </xsl:template>

  <xsl:template match="parse-tree-collection/gt:element
		       | parse-tree-collection
		       /gt:failure
		       [not(descendant::nonterminal)]
		       /gt:element">
    <testcase gt:polarity="positive">
      <input-string>
	<xsl:variable name="lv" as="item()*">
	  <xsl:apply-templates mode="serialization"/>
	</xsl:variable>
	<xsl:value-of select="string-join($lv,'')"/>
      </input-string>
      <raw-parse-tree>
	<xsl:apply-templates select="." mode="parsetrees-raw"/>
      </raw-parse-tree>
      <marked-up-tree>
	<xsl:apply-templates select="." mode="parsetrees-cooked"/>
      </marked-up-tree>
    </testcase>    
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
  <xsl:template name="test-set-header">
    <desc>
      <p>This document contains tests for the language defined
      by [what grammar?], generated by Gingersnap.</p>
      <p>Test polarity: positive.</p>
      <p>Test selection: unroll + dnf + parsetree-generation.</p>
    </desc>    
  </xsl:template>
  

  <!--****************************************************************
      * Functions
      ****************************************************************
      *-->
 

  <!--****************************************************************
      * Predicates 
      *-->    

</xsl:stylesheet>
