<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    exclude-result-prefixes="gt xs gl rtn follow"
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
      *   [Change of plan:  @gt:theta on the rule q is all we need.]
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
      * template in fsa-to-tclego.geniza.xsl).
      *-->

  <!--* To do:
      * . 2021-01-17:  ensure that zero-length paths are included in 
      *   alpha and omega paths, if they are the only ones available.
      *
      *-->
  <!--* Revisions: 
      * 2020-12-28 : CMSMcQ : change plan w.r.t. theta rules:  use
      *                       rule/@gt:theta not new rule
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
  <!-- <xsl:import href="fsa-to-tclego-theta.xsl"/> -->

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
      <xsl:apply-templates mode="alpha" select=".">
	<xsl:with-param name="G" tunnel="yes" select="$G"/>
	<!--*
	    <xsl:with-param name="lsFinal" tunnel="yes" select="$lsFinal"/>
	    <xsl:with-param name="lsStates" tunnel="yes" select="$lsStates"/>
	    *-->
      </xsl:apply-templates>
      
      <!--* omega:  paths from q to some final state *-->
      <comment> Omega rules:  path(s) from q to a final state </comment>
      <xsl:apply-templates mode="omega" select="."/>
      
      <!--* theta:  poison terminal for q *-->
      <comment> Theta rules:  poison terminal for q </comment>
      <comment> These are implicit in the gt:theta attributes on rules </comment>
      <!-- <xsl:apply-templates mode="theta"/> -->
      
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
 
      
</xsl:stylesheet>
