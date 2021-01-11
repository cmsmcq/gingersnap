<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:d2x="http://www.blackmesatech.com/2014/lib/d2x"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    default-mode="normalize-terminals"
    version="3.0">

  <!--* normalize-terminals.xsl
      * Read ixml.xml grammar, write it out again, normalizing
      * terminals to make determinization easier.
      * . Replace multi-character literals with a sequence of
      *   one-character literals.  Exact markup of result depends on
      *   context (literal+ or alts/alt/literal+).
      * . In every range, literal, or class, add gt:ranges attribute
      *   with a sequence of ranges.  Value to be an even number
      *   of natural numbers in ascending order, with the obvious
      *   meaning.
      * . In every inclusion, take the union of the ranges (and
      *   get them into the right order).
      * . In every exclusion, first take the union of the ranges
      *   and then subtract that from the ranges in $xmlchar.
      *-->

  <!--* Revisions:
      * 2020-12-28 : CMSMcQ : split into main and module to quiet Saxon
      * 2020-12-28 : CMSMcQ : move merge-elements function into 
      *                       range-operations, needed elsewhere
      * 2020-12-25 : CMSMcQ : bug fix
      * 2020-12-24 : CMSMcQ : move most functions to range-operations 
      * 2020-12-23 : CMSMcQ : add test cases, union operation, ... 
      * 2020-12-22 : CMSMcQ : broaden focus from just splitting 
      *                       literals to general terminal 
      *                       normalization.
      * 2020-12-21 : CMSMcQ : made stylesheet, as preparatory step 
      *                       for making regular grammars / FSAs
      *                       deterministic.
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->
  <xsl:import href="range-operations.lib.xsl"/>
  <xsl:include href="normalize-terminals.lib.xsl"/>

  <xsl:output method="xml"
	      indent="yes"/>


</xsl:stylesheet>

