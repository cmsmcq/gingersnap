<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    default-mode="make-rtn"
    version="3.0">

  <!--* ixml-to-saprg.xsl
      * Read ixml.xml grammar G which recognizes L(G).  G must be
      * Gluschkov-annotated.  Write out a related grammar G' as an
      * SAPRG: a stack-augmented pseudo-regular grammar in which each
      * 'expanded' nonterminal is replaced by a set of new nonterminals,
      * one for each basic token in its right-hand side plus one
      * start state and one final state.
      *-->

  <!--* Revisions:
      * 2020-12-28 : CMSMcQ : split into main and module to make Saxon 
      *                       stop complaining about multiple import 
      * 2020-12-27 : CMSMcQ : suppress hi-mom message, becoming tedious
      * 2020-12-23 : CMSMcQ : stop suppressing @gt:*, we need to keep
      *                       @gt:ranges
      * 2020-12-20 : CMSMcQ : define default mode, so I can integrate 
      *                       this into the pipeline handler
      * 2020-12-06 : CMSMcQ : made stylesheet, trying to automate what 
      *                       I have been doing by hand.
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->
  
  <xsl:import href="ixml-grammar-tools.lib.xsl"/>
  <xsl:include href="ixml-to-saprg.lib.xsl"/>

  <xsl:output method="xml"
	      indent="yes"/>
  
</xsl:stylesheet>
