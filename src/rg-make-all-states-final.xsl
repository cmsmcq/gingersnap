<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    default-mode="accept-anything"
    version="3.0">

  <!--* rg-make-all-states-final.xsl: read a regular grammar
      * in ixml, make every state final.  Also strip all marks.
      *
      * Intended purpose: make it easier to measure positive and
      * negative coverage in a test suite.  
      *
      * Assume grammars G (a context-free grammar used in the test
      * suite) and R (a regular approximation of G), we want to make a
      * third grammar R' structurally similar to R but which will
      * accept any string and will thus accept both positive and
      * negative test cases for G.  The task of this stylesheet is
      * to make R' from R.
      *
      * Assumptions (and consequent limitations):
      * - Input is a regular (not pseudo-regular) grammar.
      *   If pseudo-regular, will probably still work.
      *   If non-regular, behavior is unknown and unlikely to be
      *   useful.
      * - 
      *-->

  <!--* Revisions:
      * 2022-05-29 : CMSMcQ : made first cut
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->
  <xsl:mode name="accept-anything" on-no-match="shallow-copy"/>
  
  <xsl:strip-space elements="*"/>
  <xsl:output method="xml" indent="yes"/>

  <!--****************************************************************
      * Main / starting template
      ****************************************************************
      *-->
  <!--* None needed.
      *-->  

  <!--****************************************************************
      * Rules 
      ****************************************************************
      *-->

  <!--* if a nonterminal is already marked final (has an empty alt),
      * we can leave it alone.
      *-->
  <xsl:template match="rule[alt[empty(* except comment)]]">
    <xsl:copy>
      <xsl:sequence select="@* except (@mark, @tmark)"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>
  
  <!--* otherwise, add an empty alt to make it an accept state.
      *-->
  <xsl:template match="rule[not(alt[empty(* except comment)])]">
    <xsl:copy>
      <xsl:sequence select="@* except (@mark, @tmark)"/>
      <xsl:element name="alt">
	<xsl:element name="comment">
	  <xsl:text> In this regular approximation all states are accept states </xsl:text>
	</xsl:element>	
      </xsl:element>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

<xsl:template match="@mark"/>
  <xsl:template match="@tmark"/>
  
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

  <!--* In the tc-flattening pass, let's do one simplification:
      * an alts with a single alt child, with alt as parent, can
      * be simplified by promoting the children.
      *
      * No rule-addition pass is needed for this case.
      *-->  
  <xsl:template match="alt/alts[count(alt) eq 1]"
		mode="tc-flattening"
		priority="3">
    <xsl:param name="kwHow" as="xs:string" tunnel="yes"/>

    <xsl:variable name="N" as="xs:string"
		  select="gt:generate-nonterminal(.)"/>

    <xsl:choose>
      <xsl:when test="$kwHow = 'tc-flattening'">
	<xsl:message>
	  <xsl:text>  Flattening alt/alts[count(alt) eq 1]/alt</xsl:text>
	  <xsl:text>  in </xsl:text>
	  <xsl:value-of select="ancestor::rule/@name"/>
	  <xsl:text>. </xsl:text>      
	</xsl:message>
    
	<xsl:sequence select="alt/child::node()"/>
      </xsl:when>
      
      <xsl:when test="$kwHow = 'rule-addition'">
	<!-- nop -->
      </xsl:when>

      <xsl:otherwise>
	<xsl:message>Say what?  I don't know about this.</xsl:message>
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
	  <xsl:apply-templates select="@* except (@mark, @tmark), node()"/>
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
	<xsl:variable name="n" as="xs:integer">
	  <xsl:number count="*" level="any" select="$E"/>
	</xsl:variable>
	<!--
	<xsl:variable name="n" as="xs:integer"
		      select="count($E/preceding::*)
			      + count($E/ancestor-or-self::*)"/>
	-->
	<xsl:value-of select="concat('_', $g, $n)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <!--****************************************************************
      * Predicates 
      *-->
      
</xsl:stylesheet>
