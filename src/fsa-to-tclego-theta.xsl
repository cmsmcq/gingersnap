<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    default-mode="fsa-to-tclego"
    version="3.0">

  <!--* fsa-to-tclego.xsl:  Read ixml.grammar G, write out an ixml
      * grammar G' which is a copy of the original grammar, plus a set
      * of test-case lego pieces.  The lego pieces are all unreachable,
      * unless the user has constructed adversarial names, in which
      * case all bets are off.
      *
      * Note on why the lego pieces are unreachable and discussion of
      * alternate original design, at bottom of stylesheet.
      *
      * For each state q in G, we create three lego pieces (nonterminals
      * with special names.  Each lego piece has one or more right-hand
      * sides, each describing a path as described below.
      *      
      * . alpha_q has paths from the start state to q.
      *
      * . omega_q has paths from q to some other final state, if any
      *   such path exists.  If no such path exists, omega_q is not 
      *   defined.
      *
      * . theta_q has a single RHS containing a single terminal symbol
      *   whose character ranges include all XML characters which
      *   appear on no arc beginning in q_0 (if there are any such
      *   characters).  Theta is for thanatos; this terminal symbol
      *   is a poison character, for use in creating negative tests.
      *
      * U+03B1 is alpha, U+03C9 is omega, U_03B8 is theta.  Uppercase
      * versions are U+0391, U+03A9, U+0308, if needed.  Or just
      * spell the thing in latin characters.
      *
      * Each path takes the form of an alt element containing a
      * sequence of steps followed by a nonterminal.  (I am unclear
      * about whether the nonterminal should be kept or dropped, so
      * this may change.)
      *
      * Each step is a terminal symbol followed by a comment containing 
      * a nonterminal/state name and the number of an arc leaving that
      * state, separated by a dot as in Lisp dotted-pair notation.
      * The comment element carries the same information in gt:state and
      * gt:arc attributes.
      *
      * For example:
      * alpha_m-247: {program . 1}
      *              '{' {m-1 . 4}, 
      *              'e' {m-239˅249 . 4}, 
      *              '=' {m-242 . 4}, 
      *              '3',
      *              m-247.
      * <rule name="alpha_247">
      *   <alt>
      *     <comment gt:state="program" gt:arc="1">program . 1</comment>
      *     <literal dstring="{"/>
      *     <comment gt:state="m-1" gt:arc="4">m-1 . 4</comment>
      *     <literal dstring="e"/>
      *     <comment gt:state="m-239˅249" gt:arc="4">m-239˅249 . 4</comment>
      *     <literal dstring="="/>
      *     <comment gt:state="m-242" gt:arc="4">m-242 . 4</comment>
      *     <literal dstring="3"/>
      *     <nonterminal name="m-247"/>
      *   </alt>
      * </rule>
      *
      * In addition, we retain the original productions.  Since the
      * new nonterminals should all have distinct names, there should
      * be no interference.
      *
      * For an explanation of how to use these lego pieces to construct
      * collections of test cases with different coverage levels, see
      * tclego-to-tcrecipes.xsl (or the original make-start-rule
      * template at the bottom of this stylesheet).
      *-->

  <!--* Revisions:
      * 2020-12-27 : CMSMcQ : refactor, rewrite the planning comment
      * 2020-12-26 : CMSMcQ : begin writing this, with long comment 
      *                       to clear my mind.
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->

  <xsl:import href="fsa-to-tclego-alpha.xsl"/>
  <xsl:import href="fsa-to-tclego-omega.xsl"/>
  <xsl:import href="fsa-to-tclego-theta.xsl"/>

  <xsl:output method="xml"
	      indent="yes"/>

  <xsl:mode name="fsa-to-tclego" on-no-match="shallow-copy"/>


  <!--****************************************************************
      * Main / starting template
      ****************************************************************
      *-->
  <!--* With a default identity transform, we don't actually need a
      * main starting template.  But we do want one for ixml, to
      * inject a comment to identify the stylesheet.
      *-->
  <xsl:template match="ixml">

    <!--* Input grammar (not sure we need this as a variable) *-->
    <xsl:variable name="G" as="element(ixml)" select="."/>
    
    <!--* lsFinal:  what states in the input exist?  We are 
	* going to need this; let's do it once and be done. 
	*-->
    <xsl:variable name="lsStates" as="xs:string*"
		  select="rule/@name/string()"/>
    
    <!--* lsFinal:  what states in the input are final?  We are 
	* going to need this; let's do it once and be done. 
	*-->
    <xsl:variable name="lsFinal" as="xs:string*"
		  select="rule[
			  alt[empty(* except comment)]
			  ]/@name/string()"/>

    <xsl:copy>
      <xsl:sequence select="@*"/>
      <xsl:attribute name="gt:date" select="current-dateTime()"/>
      <xsl:attribute name="gl:gluschkov" select="'dummy value'"/>
      <xsl:attribute name="rtn:rtn" select="'Recursive transition network'"/>
      <xsl:attribute name="follow:followsets" select="'dummy value'"/>
      <xsl:element name="comment">
	<xsl:text> </xsl:text>
	<xsl:value-of select="current-dateTime()"/>
	<xsl:text> fsa-to-tclego.xsl. </xsl:text>
      </xsl:element>
      <xsl:element name="comment">
	<xsl:text> Input grammar G: </xsl:text>
	<xsl:value-of select="base-uri(.)"/>
	<xsl:text> </xsl:text>	
      </xsl:element>
      <xsl:element name="comment">
	<xsl:text> Output grammar G&#x2032;: </xsl:text>
	<xsl:text> this grammar.  G plus pieces for test suite.</xsl:text>	
      </xsl:element>
      <xsl:text>&#xA;</xsl:text>

      <!--* copy the input (we need the arcs) *-->
      <xsl:apply-templates/>

      <!--* alpha:  paths from start state to q *-->
      <comment> Alpha rules:  path(s) from q0 to q </comment>
      <xsl:apply-templates mode="alpha">
	<xsl:with-param name="G" tunnel="yes" select="$G"/>
	<xsl:with-param name="lsFinal" tunnel="yes" select="$lsFinal"/>
	<xsl:with-param name="lsStates" tunnel="yes" select="$lsStates"/>
      </xsl:apply-templates>
      
      <!--* omega:  paths from q to some final state *-->
      <comment> Omega rules:  path(s) from q to a final state </comment>
      <xsl:apply-templates mode="omega">
	<xsl:with-param name="G" tunnel="yes" select="$G"/>
	<xsl:with-param name="lsFinal" tunnel="yes" select="$lsFinal"/>
	<xsl:with-param name="lsStates" tunnel="yes" select="$lsStates"/>
      </xsl:apply-templates>
      
      <!--* theta:  poison terminal for q *-->
      <comment> Theta rules:  poison terminal for q </comment>
      <xsl:apply-templates mode="theta"/>
      
    </xsl:copy>
  </xsl:template>



  <!--****************************************************************
      * Named templates
      ****************************************************************
      *-->
 

  <!--****************************************************************
      * Functions
      ****************************************************************
      *-->

  <!--****************************************************************
      * Predicates 
      *-->    

  <!--****************************************************************
      * Note on original design
      ****************************************************************
      *
      * I liked the original design a lot, but its output was too big.
      *
      * The idea was to make a grammar which generated the test cases
      * in a nice, clear way.  (The 'tcrecipes' stage of the pipeline
      * does have a grammar that generates test cases, but the patterns
      * of construction are not visible.)
      *
      * Start symbol was to be 'testcases_' + start symbol of original
      * grammar, with a RHS of 'positive; negative'.  The nonterminals
      * 'positive', in turn, would list all positive and negative test
      * cases in the collection, respectively.
      *
      * The template for the construction template should make the
      * pattern clear.  But the output for the r_0 subset grammar of
      * Program.ixml was 250,000 lines (10 MB) long, and I changed my
      * plan.
      *-->
  
  <xsl:template name="original-make-start-rule" as="element(rule)+"
		use-when="false()">
    
    <xsl:param name="G" as="element(ixml)" tunnel="yes"/>
    <xsl:param name="lsFinal" as="xs:string*" tunnel="yes"/>

    <xsl:variable name="lsStates" as="xs:string*"
		  select="$G/rule/@name/string()"/>
    
    <rule name="testcases-{$G/rule[1]/@nme/string()}">
      <alt><nonterminal name="positive"/></alt>
      <alt><nonterminal name="negative"/></alt>
    </rule>
    
    <rule name="positive">
      <alt><nonterminal name="pos-state-final"/></alt>
      <alt><nonterminal name="pos-state-internal"/></alt>
      <alt><nonterminal name="pos-arc-final"/></alt>
      <alt><nonterminal name="pos-arc-internal"/></alt>
    </rule>
    
    <rule name="negative">
      <alt><nonterminal name="neg-state-final"/></alt>
      <alt><nonterminal name="neg-state-internal"/></alt>
      <alt><nonterminal name="neg-arc-final"/></alt>
      <alt><nonterminal name="neg-arc-internal"/></alt>
    </rule>
    
    <rule name="pos-state-final">
      <xsl:for-each select="$lsFinal">
	<alt><nonterminal name="alpha-{.}"/></alt>
      </xsl:for-each>
    </rule>
    
    <rule name="pos-state-internal">
      <xsl:for-each select="$lsStates">
	<alt>
	  <nonterminal name="alpha-{.}"/>
	  <nonterminal name="omega-{.}"/>
	</alt>
      </xsl:for-each>
    </rule>
    
    <rule name="pos-arc-final">
      <xsl:for-each select="$lsStates">
	<xsl:variable name="name" as="xs:string"
		      select="."/>
	<xsl:variable name="rule" as="element(rule)"
		      select="$G/rule[@name = $name]"/>
	<xsl:variable name="lePositive-arcs" as="element(alt)*"
		      select="$rule/alt
			      [(nonterminal/@name = $lsFinal)]"/>
	<xsl:for-each select="$lePositive-arcs">
	  <alt>
	    <nonterminal name="alpha-{$name}"/>
	    <xsl:sequence select="*"/>
	    <!--* Question:  include nonterminal or not? *-->
	  </alt>
	</xsl:for-each>	
      </xsl:for-each>
    </rule>
    
    <rule name="pos-arc-internal">
      <xsl:for-each select="$lsStates">
	<xsl:variable name="name" as="xs:string"
		      select="."/>
	<xsl:variable name="rule" as="element(rule)"
		      select="$G/rule[@name = $name]"/>
	<xsl:variable name="leAll-arcs" as="element(alt)*"
		      select="$rule/alt"/>
	<xsl:for-each select="$leAll-arcs">
	  <xsl:variable name="nmFollow" as="xs:string?"
			select="nonterminal/@name/string()"/>
	  <xsl:if test="exists($nmFollow)">
	    <alt>
	      <nonterminal name="alpha-{$name}"/>
	      <xsl:sequence select="* except nonterminal"/>
	      <nonterminal name="omega-{$nmFollow}"/>
	    </alt>
	  </xsl:if>
	</xsl:for-each>	
      </xsl:for-each>
    </rule>
    
    <rule name="neg-state-final">
      <xsl:for-each select="$lsStates[not(. = $lsFinal)]">
	<alt><nonterminal name="alpha-{.}"/></alt>
      </xsl:for-each>
    </rule>
    
    <rule name="neg-state-internal">
      <!--* Yes, there are other ways to make a negative test
	  * case.  Come back and do them sometime. *-->
      <xsl:for-each select="$lsStates">
	<alt>
	  <nonterminal name="alpha-{.}"/>
	  <nonterminal name="theta-{.}"/>
	  <nonterminal name="omega-{.}"/>
	</alt>
      </xsl:for-each>
    </rule>
    
    <rule name="neg-arc-final">
      <xsl:for-each select="$lsStates">
	<xsl:variable name="name" as="xs:string"
		      select="."/>
	<xsl:variable name="rule" as="element(rule)"
		      select="$G/rule[@name = $name]"/>
	<xsl:variable name="leNegative-arcs" as="element(alt)*"
		      select="$rule/alt
			      [nonterminal[not(@name = $lsFinal)]]"/>
	<!--* leNegative-arcs is not the complement of
	    * lePositive-arcs, above.  Neither matches an empty RHS
	    * (because those aren't arcs). *-->
	<xsl:for-each select="$leNegative-arcs">
	  <alt>
	    <nonterminal name="alpha-{$name}"/>
	    <xsl:sequence select="*"/>
	    <!--* Question:  include nonterminal or not? *-->
	  </alt>
	</xsl:for-each>	
      </xsl:for-each>
    </rule>
    
    <rule name="neg-arc-internal">
      <!--* Yes.  There are other ways to make negative
	  * test cases.  Come back and do more sometime.
	  * But not now. *-->
      <xsl:for-each select="$lsStates">
	<xsl:variable name="name" as="xs:string"
		      select="."/>
	<xsl:variable name="rule" as="element(rule)"
		      select="$G/rule[@name = $name]"/>
	<xsl:variable name="leAll-arcs" as="element(alt)*"
		      select="$rule/alt"/>
	<xsl:for-each select="$leAll-arcs">
	  <xsl:variable name="nmFollow" as="xs:string?"
			select="nonterminal/@name/string()"/>
	  <xsl:if test="exists($nmFollow)">
	    <alt>
	      <nonterminal name="alpha-{$name}"/>
	      <xsl:sequence select="* except nonterminal"/>
	      <nonterminal name="theta-{$nmFollow}"/>
	      <nonterminal name="omega-{$nmFollow}"/>
	    </alt>
	  </xsl:if>
	</xsl:for-each>	
      </xsl:for-each>
    </rule>
    
  </xsl:template>  
      
</xsl:stylesheet>
