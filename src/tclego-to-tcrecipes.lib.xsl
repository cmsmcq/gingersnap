<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    default-mode="tclego-to-tcrecipes"
    exclude-result-prefixes="xs gt gl rtn follow"
    version="3.0">

  <!--* tclego-to-tcrecipes.xsl:  Read test-case lego grammar (as
      * produced by fsa-to-tclego.xsl), write out test case recipes
      * with metadata, with user control of coverage criterion.
      *-->

  <!--* Revisions:
      * 2020-12-29 : CMSMcQ : time to implement this.
      * 2020-12-28 : CMSMcQ : split into main and module 
      * 2020-12-26 : CMSMcQ : begin writing this, with long comment 
      *                       to clear my mind.
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->


  <xsl:mode name="tclego-to-tcrecipes" on-no-match="shallow-copy"/>

  <!--* $coverage = 'state'; 'arc'; 'state-final'; 'arc-final'.
      * In the current implementation, no effort is made to avoid
      * redundancy: each state gets a recipe of the expectd kind,
      * if possible.  Not clear right now whether redundancy checks
      * are better implemented here or in a separate pass.
      *-->
  <xsl:param name="coverage" as="xs:string"
	     select="('state', 'arc',
		     'state-final', 'arc-final',
		     'all')[1]"/>

  <!--* Positive or negative test cases? *-->
  <xsl:param name="polarity" as="xs:string"
	     select="('positive', 'negative', 'all')[1]"/>

  <!--****************************************************************
      * Main / starting template
      ****************************************************************
      *-->
  <!--* With a default identity transform, we don't actually need a
      * main starting template.  But we do want one for ixml, to
      * inject a comment to identify the stylesheet.
      *-->
  <xsl:template match="ixml">
    <xsl:param name="coverage" as="xs:string" tunnel="yes"
	       select="$coverage"/>
    <xsl:param name="polarity" as="xs:string" tunnel="yes"
	       select="$polarity"/>

    <xsl:message use-when="false()">
      <xsl:text>tclego-to-tcrecipes got coverage = </xsl:text>
      <xsl:value-of select="$coverage"/>
      <xsl:text>, polarity = </xsl:text>
      <xsl:value-of select="$polarity"/>
    </xsl:message>    

    <xsl:variable name="lnmPolarity" as="xs:string+"
		  select="if ($polarity eq 'all')
			  then ('positive', 'negative')
			  else $polarity"/>
    
    <xsl:variable name="lnmCoverage" as="xs:string+"
		  select="if ($coverage eq 'all')
			  then ('state', 'state-final',
			  'arc', 'arc-final')
			  else $coverage"/>

    <!--* Input grammar (not sure we need this as a variable) *-->
    <xsl:variable name="G" as="element(ixml)" select="."/>    
    
    <!--* lqFinal:  what states in the input are final?  We are 
	* going to need this; let's do it once and be done. 
	*-->
    <xsl:variable name="lsFinal" as="xs:string*"
		  select="rule[
			  alt[empty(* except comment)]
			  ]/@name/string()"/>
    <xsl:message use-when="false()">
      <xsl:text>tclego-to-tcrecipes: </xsl:text>
      <xsl:text>final states found are: </xsl:text>
      <xsl:sequence select="$lsFinal"/>
    </xsl:message>
    <xsl:variable name="lsEpsilon" as="xs:string*"
		  select="rule[
			  alt
			  [nonterminal]
			  [empty(*
			  except (comment | nonterminal))]
			  ]/@name/string()"/>
    <xsl:if test="exists($lsEpsilon)" use-when="true()">
      <xsl:message use-when="true()">
	<xsl:text>tclego-to-tcrecipes: </xsl:text>
	<xsl:text>Epsilon transitions found for: </xsl:text>
	<xsl:sequence select="$lsEpsilon"/>
      </xsl:message>
    </xsl:if>
    
    <xsl:copy>
      <xsl:sequence select="@*"/>
      <xsl:attribute name="gt:dg-type" select="'testcase grammar'"/>
      <xsl:attribute name="gt:test-polarity" select="$lnmPolarity"/>
      <xsl:attribute name="gt:test-selection" select="$lnmCoverage"/>
      <xsl:attribute name="gt:date" select="current-dateTime()"/>
      <xsl:attribute name="gl:gluschkov" select="'dummy value'"/>
      <xsl:attribute name="rtn:rtn" select="'Recursive transition network'"/>
      <xsl:attribute name="follow:followsets" select="'dummy value'"/>

      <!--* Add whodunnit messages to output. *-->
      <xsl:element name="comment">
	<xsl:text> </xsl:text>
	<xsl:value-of select="current-dateTime()"/>
	<xsl:text> tclego-to-tcrecipes.xsl. </xsl:text>
      </xsl:element>
      <xsl:element name="comment">
	<xsl:text> Input grammar G: </xsl:text>
	<xsl:value-of select="base-uri(.)"/>
	<xsl:text> </xsl:text>	
      </xsl:element>
      <xsl:element name="comment">
	<xsl:text> Output grammar G&#x2032;: </xsl:text>
	<xsl:text> Test case recipes (</xsl:text>
	<xsl:value-of select="$polarity"/>
	<xsl:text>, </xsl:text>	
	<xsl:value-of select="$coverage"/>	
	<xsl:text>) for L(G).</xsl:text>	
      </xsl:element>
      <xsl:text>&#xA;</xsl:text>

      <!--* Make a start rule *-->      
      <xsl:call-template name="make-recipe-start-rule">
	<xsl:with-param name="G" tunnel="yes" select="$G"/>
	<xsl:with-param name="lsFinal" tunnel="yes"
			select="$lsFinal"/>
	<xsl:with-param name="lnmPolarity" select="$lnmPolarity"/>
	<xsl:with-param name="lnmCoverage" select="$lnmCoverage"/>
      </xsl:call-template>
			 
      <!--* Do the actual work *-->      
      <xsl:apply-templates select="rule">
	<xsl:with-param name="G" tunnel="yes" select="$G"/>
	<xsl:with-param name="lsFinal" tunnel="yes" select="$lsFinal"/>
	<xsl:with-param name="lnmPolarity" select="$lnmPolarity"/>
	<xsl:with-param name="lnmCoverage" select="$lnmCoverage"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>


  <!--* Alpha-, omega-, and theta-rules are building blocks; they
      * don't need any processing. *-->
  <xsl:template match="rule[starts-with(@name, 'alpha-')]"
		priority="10"/>
  <xsl:template match="rule[starts-with(@name, 'omega-')]"
		priority="10"/>
  <xsl:template match="rule[starts-with(@name, 'theta-')]"
		priority="10"/>

  <!--* Normal rules will normally generate one state-final and
      * two state-internal test cases. *-->
  <xsl:template match="rule">
    <xsl:param name="lnmCoverage" as="xs:string*" required="yes"/>
    <xsl:param name="lnmPolarity" as="xs:string*" required="yes"/>
    
    <!--* Information about this state *-->
    <xsl:variable name="nmQ" as="xs:string"
		  select="string(@name)"/>
    <xsl:variable name="fFinal" as="xs:boolean"
		  select="exists(alt[empty(* except comment)])"/>
    
    <!--* Related information: the alpha, omega, theta paths *-->
    <xsl:variable name="alpha" as="element(rule)?"
		  select="../rule[@name = concat('alpha-', $nmQ)]"/>
    <xsl:variable name="omega" as="element(rule)?"
		  select="../rule[@name = concat('omega-', $nmQ)]"/>
    <xsl:variable name="theta" as="element()?"
		  select="gt:serialize-range-list(
			  for $t
			  in tokenize(@gt:theta,'\s+')
			  [normalize-space()]
			  return xs:integer($t)
			  )"/>

    <!--* Create the test recipes. *-->
    
    <!--* 1. State-final test (pos/neg): the alpha path. *-->
    <xsl:if test="$lnmCoverage = 'state-final'
		  and exists($alpha)
		  and
		  (
		  (($lnmPolarity = 'positive') and $fFinal)
		  or
		  (($lnmPolarity = 'negative') and not($fFinal))
		  )">
      <xsl:element name="rule">
	<xsl:attribute name="name"
		       select="concat('state-final-', $nmQ)"/>
	<xsl:attribute name="gt:polarity"
		       select="if ($fFinal)
			       then 'positive'
			       else 'negative'"/>	
	<xsl:sequence select="$alpha/alt"/>
      </xsl:element> 
    </xsl:if>

    <!--* 2. State-internal positive:  alpha plus omega. *-->
    <xsl:if test="$lnmCoverage = 'state'
		  and $lnmPolarity = 'positive'
		  and exists($alpha)
		  and exists($omega)
		  ">
      <xsl:element name="rule">
	<xsl:attribute name="name"
		       select="concat('state-pos-', $nmQ)"/>
	<xsl:attribute name="gt:polarity"
		       select="'positive'"/>
	<xsl:for-each select="$alpha/alt">
	  <xsl:variable name="left" as="element()*" select="."/>
	  <xsl:for-each select="$omega/alt">
	    <xsl:variable name="right" as="element()*" select="."/>
	    <xsl:element name="alt">
	      <xsl:attribute name="gt:trace"
			     select="concat($left/@gt:trace,
				     ' + ',
				     $right/@gt:trace)"/>
	      <xsl:sequence select="$left/*, $right/*"/>
	    </xsl:element>
	  </xsl:for-each>
	</xsl:for-each>
      </xsl:element>      
    </xsl:if>
    
    <!--* 3. State-internal negative:  alpha + theta + omega. *-->
    <xsl:if test="$lnmCoverage = 'state'
		  and $lnmPolarity = 'negative'
		  and exists($alpha)
		  and exists($omega)
		  ">
      <xsl:element name="rule">
	<xsl:attribute name="name"
		       select="concat('state-neg-', $nmQ)"/>
	<xsl:attribute name="gt:polarity"
		       select="'negative'"/>
	<xsl:for-each select="$alpha/alt">
	  <xsl:variable name="left" as="element()*" select="."/>
	  <xsl:for-each select="$omega/alt">
	    <xsl:variable name="right" as="element()*" select="."/>
	    <!--* Insertion of bogon *-->
	    <xsl:element name="alt">
	      <xsl:attribute name="gt:trace"
			     select="concat($left/@gt:trace,
				     ' + error')"/>
	      <xsl:sequence select="$left/*, $theta, $right/*"/>
	    </xsl:element>
	    <!--* Substitution of bogon for head($right) *-->
	    <xsl:element name="alt">
	      <xsl:attribute name="gt:trace"
			     select="concat($left/@gt:trace,
				     ' + error ')"/>
	      <xsl:sequence select="$left/*, $theta, tail($right/*)"/>
	    </xsl:element>
	    <!--* Deletion of arc would be nice, for symmetry,
		* but requires more work. Maybe later.
		*-->
	  </xsl:for-each>
	</xsl:for-each>
      </xsl:element>      
    </xsl:if>

    <!--* Descend to arcs to generate arc-oriented test cases *-->
    <xsl:if test="$lnmCoverage = ('arc', 'arc-final')">
      <xsl:apply-templates>
	<xsl:with-param name="lnmCoverage" select="$lnmCoverage"/>
	<xsl:with-param name="lnmPolarity" select="$lnmPolarity"/>
	<xsl:with-param name="alpha" select="$alpha"/>
      </xsl:apply-templates>
    </xsl:if>
  </xsl:template>

  <!--* rule/alt elements without nonterminals don't get
      * arc tests.  In the FSAs we are expecting, they
      * will only ever be empty, and present to signal
      * that the state is final. *-->
  <xsl:template match="rule/alt[empty(* except comment)]"/>

  <!--* Paranoid check that this is actually true. *-->
  <xsl:template match="rule/alt[not(nonterminal)]
		       [exists(* except comment)]">
    <xsl:message>
      <xsl:text>Unexpected rule/alt structure! &#xA;</xsl:text>
      <xsl:text>If they don't have a next state, arcs </xsl:text>
      <xsl:text>should be empty.  But this was found:&#xA;</xsl:text>
      <xsl:sequence select="."/>
      <xsl:text>&#xA;This arc is being ignored.  So there.</xsl:text>
    </xsl:message>
  </xsl:template>

  <!--* Normal arcs *-->
  <xsl:template match="rule/alt[nonterminal]">
    <xsl:param name="lnmCoverage" as="xs:string+" required="yes"/>
    <xsl:param name="lnmPolarity" as="xs:string+" required="yes"/>
    <xsl:param name="alpha" as="element(rule)?"/>

    <!--* Information about source state *-->
    <xsl:variable name="nmSource" as="xs:string"
		  select="string(../@name)"/>

    <!--* Information about this arc *-->
    <xsl:variable name="pos" 
		  select="1 + count(preceding-sibling::alt)"/>
    <xsl:variable name="nmArc" as="xs:string" 
		  select="concat($nmSource, '&#x02C3;', $pos)"/>
    <xsl:variable name="leTerminals" as="element()*" 
		  select="* except nonterminal"/>

    <!--* Information about destination state *-->
    <xsl:variable name="nmDest" as="xs:string"
		  select="nonterminal/@name/string()"/>    

    <xsl:variable name="eRule-dest" as="element(rule)?"
		  select="../../rule[@name = $nmDest]"/>

    <xsl:variable name="fDest-final" as="xs:boolean"
		  select="exists($eRule-dest/alt
			  [empty(* except comment)])"/>

    <!--* Related information for dest: omega and theta paths *-->
    <xsl:variable name="omega-dest" as="element(rule)?"
		  select="../../rule
			  [@name = concat('omega-', $nmDest)]
			  "/>
    <xsl:variable name="theta-dest" as="element()?"
		  select="gt:serialize-range-list(
			  for $t
			  in tokenize($eRule-dest/@gt:theta,'\s+')
			  [normalize-space()]
			  return xs:integer($t)
			  )"/>    
    
    <!--* Create the test recipes. *-->
    
    <!--* 4. Arc-final (pos/neg):  alpha + arc. *-->
    <xsl:if test="$lnmCoverage = 'arc-final'
		  and exists($alpha)
		  and
		  (
		  (($lnmPolarity = 'positive') and $fDest-final)
		  or
		  (($lnmPolarity = 'negative') and not($fDest-final))
		  )">
      <xsl:element name="rule">
	<xsl:attribute name="name"
		       select="concat('arc-final-', $nmArc)"/>
	<xsl:attribute name="gt:polarity"
		       select="if ($fDest-final)
			       then 'positive'
			       else 'negative'"/>
	<xsl:for-each select="$alpha/alt">
	  <xsl:variable name="left" select="."/>
	  <xsl:element name="alt">
	    <xsl:attribute name="gt:trace"
			   select="concat($left/@gt:trace,
				   ' + ', 
				   $nmArc)"/>
	    <xsl:sequence select="$left/*, $leTerminals"/>
	  </xsl:element>
	</xsl:for-each>
      </xsl:element>      
    </xsl:if>

    <!--* 5. Arc-internal positive:  alpha + arc + dest omega. *-->
    <xsl:if test="$lnmCoverage = 'arc'
		  and $lnmPolarity = 'positive'
		  and exists($alpha)
		  and exists($omega-dest)
		  ">
      <xsl:element name="rule">
	<xsl:attribute name="name"
		       select="concat('arc-pos-', $nmArc)"/>
	<xsl:attribute name="gt:polarity"
		       select="'positive'"/>
	<xsl:for-each select="$alpha/alt">
	  <xsl:variable name="left" as="element()*" select="."/>
	  <xsl:for-each select="$omega-dest/alt">
	    <xsl:variable name="right" as="element()*" select="."/>
	    <xsl:element name="alt">
	      <xsl:attribute name="gt:trace"
			     select="concat($left/@gt:trace,
				     ' + ',
				     $nmArc,
				     ' + ',
				     $right/@gt:trace)"/>
	      <xsl:sequence select="$left/*, $leTerminals, $right/*"/>
	    </xsl:element>
	  </xsl:for-each>
	</xsl:for-each>
      </xsl:element>      
    </xsl:if>
    
    <!--* 6. Arc-internal negative: 
	*    alpha + arc + dest theta + dest omega. *-->
    <xsl:if test="$lnmCoverage = 'arc'
		  and $lnmPolarity = 'negative'
		  and exists($alpha)
		  and exists($omega-dest)
		  ">
      <xsl:element name="rule">
	<xsl:attribute name="name"
		       select="concat('arc-neg-', $nmArc)"/>
	<xsl:attribute name="gt:polarity"
		       select="'negative'"/>
	<xsl:for-each select="$alpha/alt">
	  <xsl:variable name="left" as="element()*" select="."/>
	  <xsl:for-each select="$omega-dest/alt">
	    <xsl:variable name="right" as="element()*" select="."/>
	    <!--* Insertion of bogon *-->
	    <xsl:element name="alt">
	      <xsl:attribute name="gt:trace"
			     select="concat($left/@gt:trace,
				     ' + ',
				     $nmArc,
				     ' + error')"/>
	      <xsl:sequence select="$left/*, $theta-dest, $right/*"/>
	    </xsl:element>
	    <!--* Substitution of bogon for head($right) *-->
	    <xsl:element name="alt">
	      <xsl:attribute name="gt:trace"
			     select="concat($left/@gt:trace,
				     ' + ',
				     $nmArc,
				     ' + error')"/>
	      <xsl:sequence select="$left/*, $theta-dest, tail($right/*)"/>
	    </xsl:element>
	    <!--* Deletion of an arc would be nice, for symmetry,
		* but requires more work. Maybe later.
		*-->
	  </xsl:for-each>
	</xsl:for-each>
      </xsl:element>      
    </xsl:if>
    
  </xsl:template>

  <xsl:template match="text()[not(parent::comment)]"/>  

  <!--****************************************************************
      * Named templates
      ****************************************************************
      *-->
      
  <xsl:template name="make-recipe-start-rule" as="element(rule)+">
    <xsl:param name="lnmPolarity" as="xs:string+"/>
    <xsl:param name="lnmCoverage" as="xs:string+"/>
    <xsl:param name="G" as="element(ixml)" tunnel="yes"/>
    <xsl:param name="lsFinal" as="xs:string*" tunnel="yes"/>

    <xsl:variable name="lsStates" as="xs:string*"
		  select="$G/rule/@name/string()
			  [not(starts-with(., 'alpha-'))]
			  [not(starts-with(., 'omega-'))]
			  [not(starts-with(., 'theta-'))]
			  "/>

    <!--* Top rule:
	* testcases-Q0:  positive; negative. { or similar } *-->
    <rule name="testcases-{$G/rule[1]/@nme/string()}">
      <xsl:for-each select="$lnmPolarity">
	<alt><nonterminal name="{.}"/></alt>
      </xsl:for-each>	    
    </rule>

    <!--* Second-level rules: positive, negative.
	* positive:  positive-state; positive-state-final; ...
	* negative:  negative-state; negative-state-final; ...
	*-->
    <xsl:for-each select="$lnmPolarity">
      <xsl:variable name="nmPol" as="xs:string" select="."/>
      <rule name="{.}">
	<xsl:for-each select="$lnmCoverage">
	  <alt><nonterminal name="{$nmPol}-{.}"/></alt>
	</xsl:for-each>
      </rule>
    </xsl:for-each>

    <!--* Third-level rules:  polarity + coverage combinations *-->
    <xsl:if test="$lnmPolarity = 'positive' 
		  and $lnmCoverage = 'state-final'">
      <rule name="positive-state-final">
	<xsl:for-each select="$lsFinal">
	  <alt><nonterminal name="state-final-{.}"/></alt>
	</xsl:for-each>
      </rule>
    </xsl:if>
    
    <xsl:if test="$lnmPolarity = 'positive' 
		  and $lnmCoverage = 'state'">
      <rule name="positive-state">
	<xsl:for-each select="$lsStates">
	  <alt>
	    <nonterminal name="state-pos-{.}"/>
	  </alt>
	</xsl:for-each>
      </rule>
    </xsl:if>

    <xsl:if test="$lnmPolarity = 'positive' 
		  and $lnmCoverage = 'arc-final'">
    
      <rule name="positive-arc-final">
	<xsl:apply-templates select="/ixml/rule/alt[nonterminal]" mode="toc">
	  <xsl:with-param name="coverage" select="'arc-final'"/>
	  <xsl:with-param name="polarity" select="'positive'"/>
	  <xsl:with-param name="lsFinal" select="$lsFinal"/>
	</xsl:apply-templates>
      </rule>
    </xsl:if>
    
    <xsl:if test="$lnmPolarity = 'positive' 
		  and $lnmCoverage = 'arc'">
      <rule name="positive-arc">
	<xsl:apply-templates select="/ixml/rule/alt[nonterminal]" mode="toc">
	  <xsl:with-param name="coverage" select="'arc'"/>
	  <xsl:with-param name="polarity" select="'positive'"/>
	  <xsl:with-param name="lsFinal" select="$lsFinal"/>
	</xsl:apply-templates>
    </rule>
    </xsl:if>
    
    <xsl:if test="$lnmPolarity = 'negative' 
		  and $lnmCoverage = 'state-final'">
    <rule name="negative-state-final">
      <xsl:for-each select="$lsStates[not(. = $lsFinal)]">
	<alt><nonterminal name="state-final-{.}"/></alt>
      </xsl:for-each>
    </rule>
    </xsl:if>
    
    <xsl:if test="$lnmPolarity = 'negative' 
		  and $lnmCoverage = 'state'">
      <rule name="negative-state">
	<xsl:for-each select="$lsStates">
	  <alt>
	    <nonterminal name="state-neg-{.}"/>
	  </alt>
	</xsl:for-each>
      </rule>
    </xsl:if>
    
    <xsl:if test="$lnmPolarity = 'negative' 
		  and $lnmCoverage = 'arc-final'">
      <rule name="negative-arc-final">
	<xsl:apply-templates select="/ixml/rule/alt[nonterminal]" mode="toc">
	  <xsl:with-param name="coverage" select="'arc-final'"/>
	  <xsl:with-param name="polarity" select="'negative'"/>
	  <xsl:with-param name="lsFinal" select="$lsFinal"/>
	</xsl:apply-templates>
      </rule>
    </xsl:if>
    
    <xsl:if test="$lnmPolarity = 'negative' 
		  and $lnmCoverage = 'arc'">
      <rule name="negative-arc">
	<xsl:apply-templates select="/ixml/rule/alt[nonterminal]" mode="toc">
	  <xsl:with-param name="coverage" select="'arc'"/>
	  <xsl:with-param name="polarity" select="'negative'"/>
	  <xsl:with-param name="lsFinal" select="$lsFinal"/>
	</xsl:apply-templates>
      </rule>
    </xsl:if>
    
  </xsl:template>


  <!--****************************************************************
      * toc mode
      ****************************************************************
      *-->
  <xsl:template match="rule/alt" mode="toc">
    <xsl:param name="coverage" as="xs:string" required="yes"/>
    <xsl:param name="polarity" as="xs:string" required="yes"/>
    <xsl:param name="lsFinal" as="xs:string*" required="yes"/>

    <xsl:variable name="nmDest" as="xs:string"
		  select="nonterminal/@name/string()"/>
    <xsl:variable name="nmArc" as="xs:string"
		  select="concat(
			  ../@name,
			  '&#x02C3;',
			  1 + count(preceding-sibling::alt)
			  )"/>
    <xsl:choose>
      <xsl:when test="$coverage = 'arc-final'
		      and $polarity = 'positive'
		      and ($nmDest = $lsFinal)">
	<alt><nonterminal name="arc-final-{$nmArc}"/></alt>
      </xsl:when>
      <xsl:when test="$coverage = 'arc-final'
		      and $polarity = 'negative'
		      and not($nmDest = $lsFinal)">
	<alt><nonterminal name="arc-final-{$nmArc}"/></alt>
      </xsl:when>
      <xsl:when test="$coverage = 'arc'
		      and $polarity = 'positive'">
	<alt><nonterminal name="arc-pos-{$nmArc}"/></alt>
      </xsl:when>
      <xsl:when test="$coverage = 'arc'
		      and $polarity = 'negative'">
	<alt><nonterminal name="arc-neg-{$nmArc}"/></alt>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <!--****************************************************************
      * Functions 
      ****************************************************************
      *-->

  <!--****************************************************************
      * Predicates 
      *-->    

</xsl:stylesheet>
