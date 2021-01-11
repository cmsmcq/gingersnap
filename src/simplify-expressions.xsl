<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    default-mode="simplify-expressions"
    version="3.0">

  <!--* simplify-expressions.xsl
      * Read ixml.xml grammar, write it out again, simplifying
      * expressions, especially getting rid of unsatisfiable
      * sub-expressions
      *
      * These patterns arise in simplifying the R_0 FSA and
      * we simplify them in order to reduce clutter.
      *
      *-->

  <!--* Revisions:
      * 2020-12-20 : CMSMcQ : made stylesheet, for simplifying regular
      *                       grammars and their FSAs
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->

  <xsl:output method="xml"
	      indent="yes"/>

  <xsl:mode name="simplify-expressions"
	    on-no-match="shallow-copy"/>


  <!--****************************************************************
      * Templates
      ****************************************************************
      *-->
  <!--* A nonterminal with an unsatisfiable rule is unsatisfiable *-->
  <xsl:template match="nonterminal">
    <xsl:variable name="n" select="string(@name)"/>
    <xsl:variable name="rule" select="//rule[@name = $n]"/>
    <xsl:choose>
      <xsl:when test="$rule/@gt:satisfiable='false'">
	<xsl:element name="gt:empty-set"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:copy-of select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!--* An undefined nonterminal is unsatisfiable *-->
  <xsl:template match="nonterminal[@gt:defined=('false', 'no', 0)]">
    <xsl:element name="gt:empty-set"/>
  </xsl:template>

  <!--* A sequence with an unsatisfiable term is unsatisfiable *-->  
  <xsl:template match="alt[gt:empty-set]
		       | sep[gt:empty-set]
		       | repeat0[gt:empty-set]">
    <xsl:element name="gt:empty-set"/>
  </xsl:template>

  <!--* An optional unsatisfiable term is the empty sequence *-->  
  <xsl:template match="option[gt:empty-set]
		       | repeat0[gt:empty-set]">
    <xsl:element name="comment">nil</xsl:element>
  </xsl:template>

  <!--* A unsatisfiable choice can be dropped *-->  
  <xsl:template match="alt/gt:empty-set"/>

  <!--* A unsatisfiable RHS can be dropped, if it's not the only one *-->  
  <xsl:template match="rule[alt]/gt:empty-set"/>  

  <!--* An empty choice is unsatisfiable *-->  
  <xsl:template match="alts[gt:empty-set and not(alt)]">
    <xsl:element name="gt:empty-set"/>
  </xsl:template>

  <!--* A rule whose only RHS is the empty choice is unsatisfiable *-->  
  <xsl:template match="rule[gt:empty-set and not(alt)]">
    <rule name="{@name}" gt:satisfiable="false">
      <gt:empty-set/>
    </rule>
  </xsl:template>
  
  
</xsl:stylesheet>
