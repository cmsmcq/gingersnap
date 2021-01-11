<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    exclude-result-prefixes="xs gl rtn follow"
    default-mode="alpha"
    version="3.0">

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
