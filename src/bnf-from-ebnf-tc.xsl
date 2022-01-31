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
      * rule/alt[count(*) = 1]/repeat0:  empty or E, more_Es
      *   where more_Es = empty; SEP, E, more_Es.
      * rule/alt[count(*) = 1]/repeat1:  E or E, E, more_Es
      *   where more_Es = empty; SEP, E, more_Es.
      *
      * The last two create multiple copies of E, so they should 
      * be performed only after the choices in E have been sufficiently
      * reified or flattened.
      *
      * In order to inject the reifications and the more_Es rules, 
      * the rule element traverses its children twice.  
      *
      * In order to ensure that the flattening and rule-generation
      * work is done for the same nodes, we use the same templates
      * on both passes.  (Modes should work but I was getting rules
      * generated for choice elements which had been reified, because
      * a node was skipped in one mode but not in the other.  So I
      * have shifted to a tunnel parameter.)
      *-->

  <!--* Revisions:
      * 2022-01-30 : CMSMcQ : make the output more economical
      * 2022-01-29 : CMSMcQ : made transform after thinking about it
      *                       for quite a while.
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->
  <xsl:mode name="tc-flattening" on-no-match="shallow-copy"/>
  
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

    <xsl:message>
      <xsl:text>Pass number </xsl:text>
      <xsl:value-of select="1 + $max-passes - $passes-remaining"/>
    </xsl:message>    

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
	  <xsl:apply-templates select="$doc0" mode="tc-flattening">
	    <xsl:with-param name="kwHow" select="'tc-flattening'"
			    tunnel="yes"/>
	  </xsl:apply-templates>
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

  <!--* for every rule, first handle it in tc-flattening mode, then
      * process it again to produce any required new rules.
      *-->
  <xsl:template match="rule" priority="5">
    <xsl:copy>
      <xsl:sequence select="@*"/>
      <xsl:apply-templates>
	<xsl:with-param name="kwHow" select="'tc-flattening'"
			tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:copy>
    <xsl:apply-templates>
      <xsl:with-param name="kwHow" select="'rule-addition'"
		      tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:template>

  <!--* In the tc-flattening pass, replace choice with a reference
      * to a new nonterminal.  Note that if the choice element
      * is the sole child of a right-hand side, we do not want
      * this template to fire.
      *
      * In the rule-addition pass, generate a new rule for the 
      * newly generated nonterminal.
      *-->  
  <xsl:template match="*
		       [self::alts[count(alt) gt 1] 
		       or self::option 
		       or self::repeat0
		       or self::repeat1]
		       [ (count(../* except ../comment) gt 1)
		       or empty(parent::alt/parent::rule)]
		       "
		mode="tc-flattening"
		priority="2">
    <xsl:param name="kwHow" as="xs:string" tunnel="yes"/>

    <xsl:variable name="N" as="xs:string"
		  select="gt:generate-nonterminal(.)"/>

    <xsl:choose>
      <xsl:when test="$kwHow = 'tc-flattening'">
	<xsl:message>
	  <xsl:text>  Reifying </xsl:text>
	  <xsl:value-of select="name()"/>
	  <xsl:text>  element in </xsl:text>
	  <xsl:value-of select="ancestor::rule/@name"/>
	  <xsl:text> as </xsl:text>
	  <xsl:value-of select="$N"/>      
	</xsl:message>
    
	<xsl:element name="nonterminal">
	  <xsl:attribute name="name" select="$N"/>
	</xsl:element>
      </xsl:when>
      
      <xsl:when test="$kwHow = 'rule-addition'">
	
	<xsl:message>
	  <xsl:text>  Writing rule for </xsl:text>
	  <xsl:value-of select="name()"/>
	  <xsl:text> element in </xsl:text>
	  <xsl:value-of select="ancestor::rule/@name"/>
	  <xsl:text> as </xsl:text>
	  <xsl:value-of select="$N"/>      
	</xsl:message>
	
	<xsl:element name="rule">
	  <xsl:attribute name="name" select="$N"/>
	  <xsl:attribute name="mark" select="'-'"/>
	  <xsl:element name="alt">
	    <xsl:sequence select="."/>
	  </xsl:element>
	</xsl:element>
      </xsl:when>

      <xsl:otherwise>
	<xsl:message>All bets are off.</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  

  <!--****************************************************************
      * Rewriting
      ****************************************************************
      *-->

  <!--* alts:  Exp = (F | G) *-->
  <!--* rule/alt[count(* except comment) = 1]/alts:  promote 
      * grandchildren
      *-->
  
  <xsl:template match="rule/alt
		       [alts]
		       [count(* except comment) = 1]
		       ">
    <xsl:param name="kwHow" as="xs:string" tunnel="yes"/>
    <xsl:choose>
      <xsl:when test="$kwHow = 'tc-flattening'">
	<xsl:sequence select="alts/*"/>
      </xsl:when>
      <xsl:when test="$kwHow = 'rule-addition'">
	<!--* do nothing:  we don't need a new rule,
	    * and the flattening pass does not recur. *-->
      </xsl:when>
      <xsl:otherwise>
	<xsl:message>Thud.</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>

  
  <!--* option:  Exp = E? *-->
  <!--* rule/alt[count(*) = 1]/option:  empty or E                *-->
  
  <xsl:template match="rule/alt
		       [option]
		       [count(* except comment) = 1]
		       ">
    <xsl:param name="kwHow" as="xs:string" tunnel="yes"/>
    <xsl:choose>
      <xsl:when test="$kwHow = 'tc-flattening'">
	<xsl:element name="alt"/><!-- yes, empty -->
	<xsl:element name="alt">
	  <xsl:sequence select="option/*"/>
	</xsl:element>
      </xsl:when>
      <xsl:when test="$kwHow = 'rule-addition'">
	<!--* do nothing:  we don't need a new rule,
	    * and the flattening pass does not recur. *-->
      </xsl:when>
      <xsl:otherwise>
	<xsl:message>Not with a bang, but a whisper.</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>

  
  <!--* repetitions:  Exp = E*SEP, Exp = E+SEP *-->
  <!--* rule/alt[count(*) = 1]/repeat0:  empty or E, more_Es
      *   where more_Es = empty; SEP, E, more_Es.                 *-->
  <!--* rule/alt[count(*) = 1]/repeat1:  E or E, E, more_Es
      *   where more_Es = empty; SEP, E, more_Es.                 *-->
  
  <xsl:template match="rule/alt
		       [repeat0 or repeat1]
		       [count(* except comment) = 1]
		       [empty(*/descendant::alts[count(alt) gt 1])]
		       [empty(*/descendant::option)]
		       [empty(*/descendant::repeat0)]
		       [empty(*/descendant::repeat1)]
		       ">
    <xsl:param name="kwHow" as="xs:string" tunnel="yes"/>    
    
    <xsl:variable name="N" as="xs:string"
		  select="gt:generate-nonterminal((repeat0, repeat1)[1])"/>
    <!--* that argument to generate-nonterminal is an experiment.
	* It may blow up. *-->
    <xsl:variable name="R" as="element()"
		  select="repeat0 | repeat1"/>
    <xsl:variable name="E" as="element()+"
		  select="$R/(* except (sep|comment))"/>
    <xsl:variable name="SEP" as="element()?"
		  select="$R/sep"/>

    
    <xsl:choose>
      
      <xsl:when test="($kwHow = 'tc-flattening')
		      and exists($R/self::repeat0)">
	<!--* For a repeat0, write (empty | E, _more_E) *-->
	<xsl:element name="alt"/>
	<xsl:element name="alt">
	  <xsl:sequence select="$E"/>
	  <xsl:element name="nonterminal">
	    <xsl:attribute name="name" select="concat('_more_', $N)"/>
	    <xsl:attribute name="mark" select="'-'"/>
	  </xsl:element>
	</xsl:element>
      </xsl:when>
      
      <xsl:when test="($kwHow = 'tc-flattening')
		      and exists($R/self::repeat1)">
	<!--* For a repeat1, write (E | E, SEP, E, _more_E) *-->      
	<xsl:element name="alt">
	  <xsl:sequence select="$E"/>
	</xsl:element>
	<xsl:element name="alt">
	  <xsl:sequence select="$E, $SEP/*, $E"/>
	  <xsl:element name="nonterminal">
	    <xsl:attribute name="name" select="concat('_more_', $N)"/>
	    <xsl:attribute name="mark" select="'-'"/>
	  </xsl:element>
	</xsl:element>
      </xsl:when>
      
      <xsl:when test="$kwHow = 'rule-addition'">
	<!--* In rule-addition pass, generate the rule for _more_E:
	    * _more_E: empty; SEP, E, _more_E. 
	    *-->
	<xsl:element name="rule">
	  <xsl:attribute name="name" select="concat('_more_', $N)"/>
	  <xsl:element name="alt"/>
	  <xsl:element name="alt">      
	    <xsl:sequence select="$SEP/*, $E"/>
	    <xsl:element name="nonterminal">
	      <xsl:attribute name="name" select="concat('_more_', $N)"/>
	      <xsl:attribute name="mark" select="'-'"/>
	    </xsl:element>
	  </xsl:element>
	</xsl:element>
      </xsl:when>
      <xsl:otherwise>
	<xsl:message>
	  <xsl:text>Catastrophic failure of program logic.  </xsl:text>
	  <xsl:text>It was thought that this could never happen.</xsl:text>
	</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--* Default template.  Since we are not using modes, the double
      * pass over rule elements produces double results, unless we
      * do this.  (The design for this stylesheet was so clean, once
      * upon a time.  Why is it so gnarly now?)
      *-->
  <xsl:template match="*[ancestor-or-self::rule]" priority="0">
    <xsl:param name="kwHow" as="xs:string" tunnel="yes"
	       select="'tc-flattening'"/>

    <xsl:choose>
      <xsl:when test="$kwHow = 'tc-flattening'">
	<xsl:copy>
	  <xsl:apply-templates select="@*, node()"/>
	</xsl:copy>
      </xsl:when>
      <xsl:when test="$kwHow = 'rule-addition'">
	<xsl:apply-templates select="node()"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:message>Moriturus te salutat.</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="text()[ancestor-or-self::rule]" priority="0">
    <xsl:param name="kwHow" as="xs:string" tunnel="yes"
	       select="'tc-flattening'"/>

    <xsl:choose>
      <xsl:when test="$kwHow = 'tc-flattening'">
	<xsl:sequence select="."/>
      </xsl:when>
      <xsl:when test="$kwHow = 'rule-addition'">
      </xsl:when>
      <xsl:otherwise>
	<xsl:message>Wow, this is a surprise.</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
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
		      select="count($E/preceding::*)
			      + count($E/ancestor-or-self::*)"/>
	<xsl:value-of select="concat('_', $g, $n)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <!--****************************************************************
      * Predicates 
      *-->
      
</xsl:stylesheet>
