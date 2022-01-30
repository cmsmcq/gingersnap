<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    default-mode="tc-flattening"
    version="3.0">

  <!--* bnf-from-ebnf.xsl: read an ixml grammar, produce an equivalent
      * BNF grammar with properties appropriate to test-case generation.
      *
      * By default, the BNF generated is non-minimal in ways that make
      * it simpler to generate a set of test cases that satisfy the
      * grammar-choice criterion with repetitions treated as three-way
      * branches (0, 1, 2 for repeat0 and 1, 2, 3 for repeat1).  If the
      * parameter minimal=true is specified, we make a slightly smaller
      * BNF.
      *
      * Elements involving a choice (alts, option, repeat0, repeat1)
      * are rewritten; other constructs are left alone.  Choice elements
      * alone at the top of a RHS are rewritten as a set of RHS in BNF 
      * form; choice elements elsewhere are reified (or at least named):
      * a new nonterminal is generated, the choice element is replaced
      * by a reference to that nonterminal, and the new nonterminal
      * has the choice element (and eventually its rewritten form) as
      * its definition.  Repetitions are rewritten using a 
      * auxiliary nonterminal.
      *
      * The main work is done by five templates which perform two basic
      * actions:  reification and rewriting.  In the following 
      * descriptions, E is the base expression of the option or 
      * repetition and SEP any separator in the repetition.
      *
      * Reification:
      * alts or option or repeat0 or repeat1:  generate new nonterminal,
      *   insert reference to it, write new rule with (expansion of)
      *   the choice element.
      *
      * Rewriting:
      * rule/alt[count(*) = 1]/alts:  promote grandchildren
      * rule/alt[count(*) = 1]/option:  empty or E
      * rule/alt[count(*) = 1]/repeat0:  empty or E, E, more_Es
      *   where more_Es = empty; SEP, E, more_Es.
      * rule/alt[count(*) = 1]/repeat1:  E or E, E, more_Es
      *   where more_Es = empty; SEP, E, more_Es.
      *
      * In order to inject the reifications and the more_Es rules, 
      * the rule element traverses its children twice.
      *-->

  <!--* Revisions:
      * 2022-01-29 : CMSMcQ : made transform after thinking about it
      *                       for quite a while.
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->
  <xsl:mode name="tc-flattening" on-no-match="shallow-copy"/>
  <xsl:mode name="rule-addition" on-no-match="shallow-skip"/>
  
  <xsl:strip-space elements="*"/>
  <xsl:output method="xml" indent="yes"/>

  <!--* Parameters allowed, but they do nothing yet. *-->
  <xsl:param name="minimal" as="xs:boolean" select="false()"/>
  <xsl:param name="rep-count" as="xs:integer" select="3"/>
  <xsl:param name="max-passes" as="xs:integer" select="20"/>

  
  <!--****************************************************************
      * Main / starting template
      ****************************************************************
      *-->
  <!--* We process the document handling one level of choices at a time,
      * leaving nested choices alone to simplify our thinking.
      * We stop when we reach a fixed point or when we have maxed 
      * out on the number of passes.
      *-->
  <xsl:template match="/" name="main">
    <xsl:param name="doc0" as="element(ixml)" select="/ixml"/>
    <xsl:param name="passes-remaining" as="xs:integer"
	       select="$max-passes"/>

    <xsl:variable name="stylesheet" as="processing-instruction()">
      <xsl:processing-instruction name="xml-stylesheet">
	<xsl:text>type="text/xsl" href="ixml-html.xsl"</xsl:text>
      </xsl:processing-instruction>
    </xsl:variable>
    
    <xsl:choose>
      <xsl:when test="$passes-remaining eq 0">
	<xsl:sequence select="$stylesheet, $doc0"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:variable name="doc1" as="element(ixml)">
	  <xsl:apply-templates select="$doc0" mode="tc-flattening"/>
	</xsl:variable>
	<xsl:choose>
	  <xsl:when test="deep-equal($doc0, $doc1)">
	    <xsl:sequence select="$stylesheet, $doc0"/>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:call-template name="main">
	      <xsl:with-param name="doc0" select="$doc1"/>
	      <xsl:with-param name="passes-remaining"
			      select="$passes-remaining - 1"/>
	    </xsl:call-template>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>  

  <!--****************************************************************
      * Reification 
      ****************************************************************
      *-->

  <!--* for every rule, first copy it in tc-flattening mode, then
      * process it again in rule-addition mode, in case we need to
      * add new rules to reify a choice within the original rule.
      *-->
  <xsl:template match="rule">
    <xsl:copy>
      <xsl:sequence select="@*"/>
      <xsl:apply-templates mode="tc-flattening"/>
    </xsl:copy>
    <xsl:apply-templates mode="rule-addition"/>
  </xsl:template>

  <!--* In tc-flattening mode, replace choice with a reference
      * to a new nonterminal.  (Note that if the choice element
      * is the sole child of a right-hand side, this template
      * won't fire because the template for alt will fire first.
      *-->
  <xsl:template match="alts | option | repeat0 | repeat1"
		mode="tc-flattening">
    <xsl:variable name="N" as="xs:string"
		  select="gt:generate-nonterminal(.)"/>
    <xsl:element name="nonterminal">
      <xsl:attribute name="name" select="$N"/>
    </xsl:element>
  </xsl:template>
  
  <!--* In rule-addition mode, generate a new rule for the 
      * newly generated nonterminal.
      *-->
  <xsl:template match="alts | option | repeat0 | repeat1"
		mode="rule-addition">
    <xsl:variable name="N" as="xs:string"
		  select="gt:generate-nonterminal(.)"/>
    <xsl:if test="(count(../* except ../comment) gt 1)
		  or empty(parent::alt/parent::rule)">
      <xsl:element name="rule">
	<xsl:attribute name="name" select="$N"/>
	<xsl:attribute name="mark" select="'-'"/>
	<xsl:element name="alt">
	  <xsl:sequence select="."/>
	</xsl:element>
      </xsl:element>
    </xsl:if>
  </xsl:template>

  <!--****************************************************************
      * Rewriting
      ****************************************************************
      *-->

  <!--* rule/alt[count(* except comment) = 1]/alts:  promote grandchildren       *-->
  
  <xsl:template match="rule/alt[count(* except comment) = 1][alts]">
    <xsl:sequence select="alts/*"/>
  </xsl:template>

  
  <!--* rule/alt[count(*) = 1]/option:  empty or E                *-->
  
  <xsl:template match="rule/alt[count(* except comment) = 1][option]">
    <xsl:element name="alt">
      <xsl:element name="comment">
	<xsl:text>* empty *</xsl:text>
      </xsl:element>
    </xsl:element>
    <xsl:element name="alt">
      <xsl:sequence select="option/*"/>
    </xsl:element>
  </xsl:template>

  
  <!--* rule/alt[count(*) = 1]/repeat0:  empty or E, E, more_Es
      *   where more_Es = empty; SEP, E, more_Es.                 *-->
  
  <xsl:template match="rule/alt[count(* except comment) = 1][repeat0]">
    <xsl:variable name="N" as="xs:string"
		  select="gt:generate-nonterminal(.)"/>
    <xsl:variable name="E" as="element()+"
		  select="repeat0/(* except (sep|comment))"/>
    <xsl:variable name="SEP" as="element()?"
		  select="repeat0/sep"/>
    <xsl:element name="alt">
      <xsl:element name="comment">
	<xsl:text>* empty *</xsl:text>
      </xsl:element>
    </xsl:element>
    <xsl:element name="alt">
      <xsl:sequence select="$E"/>
      <xsl:element name="nonterminal">
	<xsl:attribute name="name" select="concat('_more_', $N)"/>
	<xsl:attribute name="mark" select="'-'"/>
      </xsl:element>
    </xsl:element>
  </xsl:template>
  
  <!--* rule/alt[count(*) = 1]/repeat1:  E or E, E, more_Es
      *   where more_Es = empty; SEP, E, more_Es.                 *-->
  
  <xsl:template match="rule/alt[count(* except comment) = 1][repeat1]">
    <xsl:variable name="N" as="xs:string"
		  select="gt:generate-nonterminal(.)"/>
    <xsl:variable name="E" as="element()+"
		  select="repeat1/(* except (sep|comment))"/>
    <xsl:variable name="SEP" as="element()?"
		  select="repeat1/sep"/>
    <xsl:element name="alt">
      <xsl:sequence select="$E"/>
    </xsl:element>
    <xsl:element name="alt">
      <xsl:sequence select="$E, $SEP, $E"/>
      <xsl:element name="nonterminal">
	<xsl:attribute name="name" select="concat('_more_', $N)"/>
	<xsl:attribute name="mark" select="'-'"/>
      </xsl:element>
    </xsl:element>
  </xsl:template>

  
  <xsl:template match="rule/alt[count(* except comment) = 1][repeat1 or repeat0]"
		mode="rule-addition">
    <xsl:variable name="N" as="xs:string"
		  select="gt:generate-nonterminal(.)"/>
    <xsl:variable name="E" as="element()+"
		  select="*/(* except (sep|comment))"/>
    <xsl:variable name="SEP" as="element()?"
		  select="*/sep"/>
    
    <xsl:element name="rule">
      <xsl:attribute name="name" select="concat('_more_', $N)"/>
      <xsl:element name="alt">
	<xsl:element name="comment">
	  <xsl:text>* empty *</xsl:text>
	</xsl:element>
      </xsl:element>
      <xsl:element name="alt">      
	<xsl:sequence select="$SEP, $E"/>
	<xsl:element name="nonterminal">
	  <xsl:attribute name="name" select="concat('_more_', $N)"/>
	  <xsl:attribute name="mark" select="'-'"/>
	</xsl:element>
      </xsl:element>
    </xsl:element>
  </xsl:template>
  

  <!--****************************************************************
      * Functions
      ****************************************************************
      *-->
  <xsl:function name="gt:generate-nonterminal"
		as="xs:string">
    <xsl:param name="E" as="element()"/>

    <xsl:variable name="easy-solution" as="xs:string?"
		  select="($E/@gt:expname/string(),
			  $E/@xml:id/string())[1]"/>
    <xsl:choose>
      <xsl:when test="exists($easy-solution)">
	<xsl:value-of select="$easy-solution"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:variable name="gi" as="xs:string"
		      select="local-name($E)"/>
	<xsl:variable name="g" as="xs:string"
		      select="if ($gi eq 'alts')
			      then 'or'
			      else if ($gi eq 'alt')
			      then 'xx'
			      else if ($gi eq 'repeat0')
			      then 'star'
			      else if ($gi eq 'repeat1')
			      then 'plus'
			      else if ($gi eq 'option')
			      then 'opt'
			      else $gi"/>
	<xsl:variable name="n" as="xs:integer"
		      select="count($E/preceding::*)"/>
	<xsl:value-of select="concat('_', $g, $n)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <!--****************************************************************
      * Predicates 
      *-->
      
</xsl:stylesheet>
