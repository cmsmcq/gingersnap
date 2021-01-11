<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    default-mode="annotate-gl"
    version="3.0">

  <!--* ixml-annotate-gluschkov.xsl
      * Read ixml.xml grammar, write it out again with some
      * annotations and additions.  Each right-hand side (and
      * each subexpression of a right-hand side) gets attributes
      * specifying the Gluschkov automaton for the expression.
      *
      * Every expression gets an ID to make this work.
      * @gl:first specifies the tokens for possible initial symbols.
      * @gl:last specifies the final tokens (states). 
      * @gl:nullable specifies whether L(E) include the empty string.
      * @follow:X specifies (for each token X) what states (tokens)
      * can follow X.
      *
      * Algorithm is from ABK, "Regular expressions into finite
      * automata", as elaborated for more complicated expressions
      * in Gluschkov.xqm.
      *
      * See ixml-to-rtndot.xsl for a translation to dot to draw the
      * recursive transition network.
      *-->

  <!--* Revisions:
      * 2020-12-28 : CMSMcQ : split into main and module
      * 2020-12-04 : CMSMcQ : found error in handling of sequences. 
      *                       Fixed (typo in handling option).
      *
      * 2020-11-29 : CMSMcQ : made stylesheet, as XSLT successor to 
      *                       Gluschkov.xqm
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->

  <xsl:import href="ixml-grammar-tools.lib.xsl"/>
  <xsl:include href="ixml-annotate-gluschkov.lib.xsl"/>

  <xsl:output method="xml"
	      indent="yes"/>

  
</xsl:stylesheet>
