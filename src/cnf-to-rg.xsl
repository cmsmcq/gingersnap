<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    default-mode="cnf-to-rg"
    exclude-result-prefixes="gt xs"
    version="3.0">

  <!--* cnf-to-rg.xsl:  read ixml grammar, confirm that it's in
      * Chomsky Normal Form, and produce (a reconstruction of) the
      * grammar G' described in section 6 of Chomsky 1959 "On certain
      * formal properties of grammars," Information and control 2
      * (1959): 137-167; rpt. in Handbook of mathematical psychology,
      * vol. II, ed. R. D. Luce, R. R. Bush, and E. Galanter (New York:
      * John Wiley and Sons, 1965), pp. 125-155.
      *
      * One challenge is that the paragraphs labeled "Construction"
      * in section 6 of the paper do not actually say how to contruct
      * grammar G' = (V, T, P, S):  they constrain the nonterminals in
      * V to take the form of rewrite chains of nonterminals in G plus
      * a two-valued subscript, and they constrain the production rules
      * P to contain rules of certain specified patterns, when V and
      * the production rules of G contain nonterminals and rules of
      * certain patterns, but they do not say how to construct,
      * generate, identify, or enumerate the members of V or P, and 
      * they say nothing abt all about T or S.
      *
      * I'm writing this in large part to try to put some guesses into
      * concrete form.
      *
      * Specifically, I guess that:
      * V(G') contains all rewrite chains of G which start with S(G)
      * and which have no repetitions;
      * T(G') is T(G);
      * P(G') is the smallest set that contains rules satisfying the
      * specified constraints for all members of V;
      * S(G') is i.S, where S is S(G), the start state of G.
      *
      * I should define terms:
      * 
      * A rewrite chain is a sequence of nonterminals from some grammar
      * such that each element in the chain appears on the right-hand
      * side of the nonterminal which precedes it.  In a typical grammar
      * there are an infinite number of rewrite chains, but only a
      * finite number with no repetitions.  It should be clear on
      * reflection that for a clean grammar (all nonterminals reachable
      * and productive) the set of non-repetitive rewrite chains is the
      * set of possible paths in a parse tree from the root to the
      * topmost occurrence of any nonterminal.
      *
      * Chomsky describes the nonterminals of G' as "represented in
      * the form [B_1 ... B_n]i(i=1,2), where the B_j's are in turn
      * nonterminal symbols of G".  He does not say how the sequence
      * (B_1, ..., B_n) is chosen beyond saying "Suppose that" it is a
      * rewrite chain of G.  
      *
      * In the grammar generated here, nonterminals will take the form
      * described by the following grammar.
      *
      *     NT: index, sep, base, affix.   { a nonterminal in G' }
      *     ntg: identifier.              { any nonterminal in G }
      *
      *     index: 'i'; 'f'.       {'i' = initial, 'f' = 'final' }
      *     sep: '·'.           { anything not used in G will do }
      *     base: ntg.
      *     affix:  ntg*sep.
      * 
      * What Chomsky represents as a sequence of nonterminals in
      * ancestor to descendant order is represented here by a
      * concatenation of the nonterminals in descendant to ancestor
      * order, with a separator for clarity.  And the index is moved
      * from the end to the beginning.  These changes place the base
      * nonterminal and the index at the beginning of the identifier
      * places the most meaningful variation at the beginning of the
      * identifier.
      *
      *-->

  <!--* Revisions:
      * 2021-01-15 : CMSMcQ : made stylesheet, while trying to 
      *                       understand Chomsky 1959.
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->

  <xsl:output method="xml"
	      indent="yes"/>

  <xsl:mode name="cnf-to-rg" on-no-match="shallow-copy"/>
  <xsl:mode name="trim-attributes" on-no-match="shallow-copy"/>

  <!--* k:  stack depth parameter; allow each recursive nonterminal
      * at most k ancestors of the same name.  k=0 for bracket-free
      * subset of language. *-->
  <xsl:param name="k" as="xs:integer" select="0"/>  

  <!--* sep:  separator to use as stack delimiter *-->
  <!--* 22EF looks good (midline horizontal ellipsis) but is not
      * a name character (? I thought they were all name
      * characters now?) and so causes problems sometimes.
      * Promising letters:
      * B7 Middle dot 
      * 1C0 Latin letter dental click (vertical line) 
      * 1C1 Latin letter lateral click (double vertical line) 
      * 1C3 Latin letter retroflex click (bang) 
      * 2C2 Modifier letter left arrowhead 
      * 2C3 Modifier letter right arrowhead 
      * 2C8 Modifier letter vertical line 
      * 2D0 Modifier letter triangular colon 
      * 387 Greek ano teleia 
      *-->
  <xsl:param name="sep" as="xs:string" select=" '&#x1C0;' "/>

  

  <!--****************************************************************
      * Templates
      ****************************************************************
      *-->
  <xsl:template match="ixml">
    <xsl:param name="k" tunnel="yes" as="xs:integer"
	       select="$k"/>

    <!--* (a) Check invocation, bail if it's pointless to proceed *-->
    <xsl:if test="not(gt:is-cnf(.))">
      <xsl:message terminate="yes">
	<xsl:text>Input is not in Chomsky Normal Form.&#xA;</xsl:text>
	<xsl:text>No good can come of running this transform </xsl:text>
	<xsl:text>on this grammar. &#xA;</xsl:text>
	<xsl:text>Bye.</xsl:text>
      </xsl:message>
    </xsl:if>

    <!--* (b) Check ixml element, add work log item *-->
    <xsl:if test="not(preceding-sibling::processing-instruction
		  [name() = 'xml-stylesheet']
		  [contains(., 'text/xsl')])">
      <xsl:processing-instruction name="xml-stylesheet">
	<xsl:text> type="text/xsl"</xsl:text>
	<xsl:text> href="../src/ixml-html.xsl"</xsl:text>
      </xsl:processing-instruction>
    </xsl:if>
    
    <xsl:copy>
      <xsl:sequence select="@*"/>
      <xsl:attribute name="gt:dg-type" select="'regular approximation'"/>
      <xsl:attribute name="gt:ra-type" select="'Chomsky-transform'"/>
      <xsl:attribute name="gt:k" select="$k"/>
      <xsl:attribute name="gt:date" select="current-dateTime()"/>

      <xsl:element name="comment">
	<xsl:value-of select="current-dateTime()"/>
	<xsl:text>: cnf-to-rg.xsl.</xsl:text>
      </xsl:element>
      <xsl:element name="comment">
	<xsl:text>    Input: </xsl:text>
	<xsl:value-of select="base-uri(/)"/>
      </xsl:element>
      <xsl:element name="comment">
	<xsl:text>    This grammar is (a reconstruction of) the </xsl:text>
	<xsl:text>grammar produced by</xsl:text>
      </xsl:element>
      <xsl:element name="comment">
	<xsl:text>    the rules in Sec. 6 of Chomsky 1959.</xsl:text>
      </xsl:element>
      <xsl:text>&#xA;</xsl:text>

      <xsl:apply-templates select="comment[not(preceding-sibling::rule)]"/>

      <xsl:text>&#xA;</xsl:text>

      <!--* (d1) Get ready to do the work *-->
      <xsl:variable name="starting-names"
		    as="xs:string*"
		    select="rule[1]
			    /@name/string()"/>
      <xsl:variable name="queue"
		    as="element(gt:please-define)*">
	<xsl:for-each select="$starting-names">
	  <xsl:element name="gt:please-define">
	    <xsl:attribute name="name" select="."/>
	    <xsl:attribute name="basename" select="."/>
	    <!-- <xsl:attribute name="affix" select=" '' "/> -->
	    <xsl:attribute name="index" select=" 'i' "/>
	  </xsl:element>
	</xsl:for-each>
      </xsl:variable>

      <!--* (d2) Make the rules (but not necessarily in order) *-->

      <xsl:message use-when="false()">
	<xsl:text>Passing k = </xsl:text>
	<xsl:value-of select="$k"/>
      </xsl:message>
      <xsl:message terminate="yes" use-when="false()">
	<xsl:text>Queue = </xsl:text>
	<xsl:sequence select="$queue"/>
      </xsl:message>

      <xsl:variable name="leRules" as="element(rule)*">
	<xsl:call-template name="one-by-one-cnfrg">
	  <xsl:with-param name="queue" select="$queue"/>
	  <xsl:with-param name="k" tunnel="yes" select="$k"/>
	</xsl:call-template>
      </xsl:variable>

      <xsl:for-each-group select="$leRules"
			  group-by="@name">
	<!-- <xsl:sort select="substring-after(@name, $sep)"/> -->
	<rule name="{current-grouping-key()}">
	  <xsl:apply-templates select="current-group()/alt"
			       mode="trim-attributes"/>
	</rule>
      </xsl:for-each-group>
      
    </xsl:copy>
  </xsl:template>

  <xsl:template match="text()[not(parent::comment)]"/>

  <xsl:template match="@gt:*" mode="trim-attributes"/>

  <!--****************************************************************
      * Named templates
      * one-by-one-cnfrg (manages queue)
      * and make-rules (does the actual work)
      ****************************************************************
      *-->
  <!--* one-by-one-cnfrg:  work through the items in the queue,
      * one by one.
      * Stop when you're done.
      *-->

  <xsl:template name="one-by-one-cnfrg">
    <xsl:param name="queue"
	       as="element(gt:please-define)*"
	       required="yes"/>
    <xsl:param name="leDone"
	       as="element(gt:please-define)*"
	       select="()"/>    

    <!--
    <xsl:element name="comment">
      <xsl:text> queue management template </xsl:text>
      <xsl:element name="queue">
	<xsl:sequence select="$queue"/>
      </xsl:element>
    </xsl:element>
    <xsl:element name="comment">
      <xsl:element name="leDone">
	<xsl:sequence select="$leDone"/>
      </xsl:element>
    </xsl:element>
    -->
    
    <xsl:message use-when="false()">
      <xsl:text>one-by-one-cnfrg:  </xsl:text>
      <xsl:text>&#xA;  queue = </xsl:text>
      <xsl:sequence select="$queue/@name/string()"/>
    </xsl:message>
    <xsl:message use-when="false()">
      <xsl:text>one-by-one-cnfrg:  </xsl:text>
      <xsl:text>&#xA;  queue = </xsl:text>
      <xsl:sequence select="$queue/@name/string()"/>
      <xsl:text>&#xA;  done = </xsl:text>
      <xsl:sequence select="$leDone/@name/string()"/>
    </xsl:message>

    <xsl:choose>
      <!--* base case: empty queue, done *-->
      <xsl:when test="empty($queue)">
	<!--* say goodnight *-->
      </xsl:when>

      <!--* recursive case:  do first item in queue,
	  * add new items to queue as needed,
	  * recur. *-->
      <xsl:otherwise>
	<!--* (1) make the new rule, but don't write 
	    * it out yet, we need to look at it. 
	    *-->
	<xsl:variable name="this-task"
		      as="element(gt:please-define)"
		      select="$queue[1]"/>

	<xsl:message use-when="false()">
	  <xsl:text>  this-task = </xsl:text>
	  <xsl:sequence select="$this-task/@name/string()"/>
	</xsl:message>
	
	<xsl:variable name="new-rules"
		      as="element(rule)+">
	  <xsl:call-template name="make-rules">
	    <xsl:with-param name="task"
			    select="$this-task"/>
	  </xsl:call-template>
	</xsl:variable>

	<!--* (2) Extract non-terminal references from it,
	    * so we can add them to the queue if they are new.
	    *-->
	<xsl:variable name="leCandidates"
		      as="element(nonterminal)*"
		      select="$new-rules/descendant::nonterminal
			      [not(@gt:name = ($leDone/@name, $queue/@name))]"/>
	<xsl:variable name="leNewtasks"
		      as="element(gt:please-define)*">
	  <xsl:for-each
	      select="$leCandidates
		      [index-of($leCandidates/@name,@name)[1]]">
	    <!--* Thank you, Dimitre, for the index-of() way
		* of eliminating duplicates here *-->
	    <xsl:element name="gt:please-define">
	      <!--* Note that the @name on please-define has
		  * no i/f prefix, it's just the rewrite chain.
		  * So we need to get it from @gt:name, not @name,
		  * on the nonterminal element.
		  *-->
	      <xsl:attribute name="name" select="@gt:name"/>
	      <xsl:attribute name="basename" select="@gt:basename"/>
	      <xsl:if test="normalize-space(@gt:affix) ne ''">
		<xsl:attribute name="affix" select="@gt:affix"/>
	      </xsl:if>
	      <xsl:attribute name="index" select="@gt:index"/>
	    </xsl:element>
	  </xsl:for-each>
	</xsl:variable>

	<!--* (3) Write out the new rule, recur with new queue. *-->
	<xsl:sequence select="$new-rules"/>
	<xsl:call-template name="one-by-one-cnfrg">
	  <xsl:with-param name="queue"
			  select="($queue[position() gt 1],
				  $leNewtasks)"/>
	  <xsl:with-param name="leDone"
			  select="($this-task, $leDone)"/>
	</xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--****************************************************************
      * make-rules
      ****************************************************************
      *-->
  <xsl:template name="make-rules" as="element(rule)+">
    <xsl:param name="task"
	       as="element(gt:please-define)"/>
    <xsl:param name="k" as="xs:integer" tunnel="yes"/>
    <xsl:param name="G" as="element(ixml)" select="/ixml"/>

    <!--* $basename:  right-hand sides in G *-->
    <xsl:variable name="basename" as="xs:string"
		  select="$task/@basename/string()"/>
    <!--* $baserule:  production rule for $basename in G *-->
    <xsl:variable name="baserule" as="element(rule)"
		  select="$G/rule[@name = $basename]"/>
    <!--* $leRHS-G:  right-hand sides in G *-->
    <xsl:variable name="leRHS-G" as="element(alt)+"
		  select="$baserule/alt"/>
    
    <!--* $affix:  the affix part of the new name *-->
    <xsl:variable name="affix" as="xs:string?"
		  select="$task/@affix/string()
			  [normalize-space()]"/>
    <!--* $tokens:  the tokens in the rewrite chain *-->
    <xsl:variable name="tokens" as="xs:string+"
		  select="($basename, tokenize($affix, $sep))
			  [normalize-space()]"/>

    <xsl:if test="contains($affix, $sep)" use-when="false()">
    <xsl:message use-when="true()">
      <xsl:text>&#xA; basename = </xsl:text>
      <xsl:value-of select="$basename"/>
      <xsl:text>&#xA; affix = </xsl:text>
      <xsl:value-of select="$affix"/>
      <xsl:text>&#xA; tokens = </xsl:text>
      <xsl:sequence select="$tokens"/>
    </xsl:message>
    </xsl:if>

    <!--* For the summaries of Chomsky's rules, Bn is $basename,
	* a is a terminal symbol, C, D are nonterminal symbols,
	* $affix is a string and $affixtokens is the tokenization
	* of $affix, plus Bn.
	*-->
    
    <!--* (i) if ({$Bn}: a) in G, then 
	* i.{$Bn}.{$affix}: t, f.{$Bn}.{$affix}. 
	*-->
    <xsl:for-each select="$leRHS-G[gt:is-terminal-RHS(.)]">
      <xsl:variable name="rhs" as="element(alt)" select="."/>
      <xsl:variable name="eT" as="element()"
		    select="$rhs/(* except comment)"/>
      
      <rule name="{string-join(('i', $basename, $affix), $sep)}"
	    gt:basename="{$basename}"
	    gt:trace="able">
	<alt>
	  <xsl:sequence select="$eT"/>
	  <nonterminal
	      name="{string-join(('f', $basename, $affix), $sep)}"
	      gt:name="{string-join(($basename, $affix), $sep)}"
	      gt:basename="{$basename}"
	      gt:affix="{$affix}"
	      gt:index="f"/>
	</alt>
      </rule>
      
      <xsl:element name="rule" use-when="false()">
	<xsl:attribute name="name"
		       select="string-join(('i', $basename, $affix),
			       $sep)"/>
	<xsl:sequence select="$eT"/>      
	<xsl:element name="nonterminal">
	  <xsl:attribute name="name"
			 select="string-join((
				 'f',
				 $basename,
				 $affix),
				 $sep)"/>
	  <xsl:attribute name="gt:name"
			 select="string-join(($basename, $affix), $sep)"/>
	  <xsl:attribute name="gt:basename" select="$basename"/>
	  <xsl:attribute name="gt:affix" select="$affix"/>
	  <xsl:attribute name="gt:index" select="'f'"/>
	</xsl:element>
      </xsl:element>
    </xsl:for-each>

    <xsl:for-each select="$leRHS-G[gt:is-NN-RHS(.)]">    
      <xsl:variable name="rhs" as="element(alt)" select="."/>
      <xsl:variable name="sN1" as="xs:string"
		    select="$rhs/nonterminal[1]/@name/string()"/>
      <xsl:variable name="sN2" as="xs:string"
		    select="$rhs/nonterminal[2]/@name/string()"/>

      <xsl:choose>
	<xsl:when test="not( ($sN1, $sN2) = ($tokens) )">
	  <!--* (ii) if ({$Bn}: C, D) where not (C, D) = $affixtokens,
	      * then 
	      * i.{$Bn}.{$affix}:   i.C.{$Bn}.{$affix}. 
	      * f.C.{$Bn}.{$affix}: i.D.{$Bn}.{$affix}. 
	      * f.D.{$Bn}.{$affix}: f.{$Bn}.{$affix}. 
	      *-->
	  <rule name="{string-join(('i', $basename, $affix), $sep)}"
		gt:basename="{$basename}"
		gt:trace="baker">
	    <alt>
	    <nonterminal
		name="{string-join(('i', $sN1, $basename, $affix), $sep)}"
		gt:name="{string-join( ($sN1, $basename, $affix), $sep)}"
		gt:basename="{$sN1}"
		gt:affix="{string-join(($basename, $affix), $sep)}"
		gt:index="i"/>
	    </alt>
	  </rule>
	  <rule name="{string-join(('f', $sN1, $basename, $affix), $sep)}"
		gt:basename="{$sN1}"
		gt:trace="charlie">
	    <alt>
	      <nonterminal
		name="{string-join(('i', $sN2, $basename, $affix), $sep)}"
		gt:name="{string-join(($sN2, $basename, $affix), $sep)}"
		gt:basename="{$sN2}"
		gt:affix="{string-join(($basename, $affix), $sep)}"
		gt:index="i"/>
	    </alt>
	  </rule>
	  <rule name="{string-join(('f', $sN2, $basename, $affix), $sep)}"
		gt:basename="{$sN2}"
		gt:trace="dog">
	    <alt>
	      <nonterminal
		  name="{string-join(('f', $basename, $affix), $sep)}"
		  gt:name="{string-join(($basename, $affix), $sep)}"
		  gt:basename="{$basename}"
		  gt:affix="{$affix}"
		  gt:index="f"/>
	    </alt>
	  </rule>
	</xsl:when>
	<xsl:when test="$sN2 = $tokens">	  
	  <!--* (iii) if ({$Bn}: C, D) where D = $affixtokens, then
	      * let $pos := index-of($affixtokens, D)[1],
	      * let $ancestor := subsequence($affixtokens, $pos)
	      *
	      * i.{$Bn}.{$affix}:   i.C.{$Bn}.{$affix}. 
	      * f.C.{$Bn}.{$affix}: i.{$ancestor}.
	      *-->
	  <xsl:variable name="pos" select="index-of($tokens, $sN2)[1]"/>
	  <xsl:variable name="ancestor" select="subsequence($tokens, $pos)"/>
	  <rule name="{string-join(('i', $basename, $affix), $sep)}"
		gt:basename="{$basename}"
		gt:trace="easy">
	    <alt>
	    <nonterminal
		name="{string-join(('i', $sN1, $basename, $affix), $sep)}"
		gt:name="{string-join( ($sN1, $basename, $affix), $sep)}"
		gt:basename="{$sN1}"
		gt:affix="{string-join(($basename, $affix), $sep)}"
		gt:index="i"/>
	    </alt>
	  </rule>
	  <rule name="{string-join(('f', $sN1, $basename, $affix), $sep)}"
		gt:basename="{$sN1}"
		gt:trace="fox">
	    <alt>
	    <nonterminal
		name="{string-join(('f', $ancestor), $sep)}"
		gt:name="{string-join($ancestor, $sep)}"
		gt:basename="{$sN2}"
		gt:affix="{string-join(tail($tokens), $sep)}"
		gt:index="f"/>
	    </alt>
	  </rule>
	</xsl:when>
	<xsl:when test="$sN1 = $tokens">
	  <!--* (iv) if ({$Bn}: C, D) where C = $affixtokens, then
	      * let $pos := index-of($affixtokens, C)[1],
	      * let $ancestor := subsequence($affixtokens, $pos)
	      *
	      * f.{$ancestor}: i.D.{$Bn}.{$affix}.
	      * f.D.{$Bn}.{$affix}: i.{$ancestor}.
	      *-->
	  <xsl:variable name="pos" select="index-of($tokens, $sN1)[1]"/>
	  <xsl:variable name="ancestor" select="subsequence($tokens, $pos)"/>
	  <xsl:message use-when="false()">
	    <xsl:text>left recursive nonterminal </xsl:text>
	    <xsl:value-of select="$sN1"/>
	    <xsl:text>&#xA; basename = </xsl:text>
	    <xsl:value-of select="$basename"/>
	    <xsl:text>&#xA; affix = </xsl:text>
	    <xsl:value-of select="$affix"/>
	    <xsl:text>&#xA; tokens = </xsl:text>
	    <xsl:sequence select="$tokens"/>
	    <xsl:text>&#xA; ancestor = </xsl:text>
	    <xsl:sequence select="$ancestor"/>
	  </xsl:message>
	  <rule name="{string-join(('f', $ancestor), $sep)}"
		gt:basename="{$sN1}"
		gt:trace="george">
	    <alt>
	    <nonterminal
		name="{string-join(('i', $sN2, $basename, $affix), $sep)}"
		gt:name="{string-join( ($sN2, $basename, $affix), $sep)}"
		gt:basename="{$sN2}"
		gt:affix="{string-join(($basename, $affix), $sep)}"
		gt:index="i"/>
	    </alt>
	  </rule>
	  <rule name="{string-join(('f', $sN2, $basename, $affix), $sep)}"
		gt:basename="{$sN2}"
		gt:trace="how">
	    <alt>
	    <nonterminal
		name="{string-join(('i', $ancestor), $sep)}"
		gt:name="{string-join($ancestor, $sep)}"
		gt:basename="{$sN1}"
		gt:affix="{string-join(tail($tokens), $sep)}"
		gt:index="f"/>
	    </alt>
	  </rule>
	</xsl:when>
      </xsl:choose>
    </xsl:for-each>
    
  </xsl:template>
  
  <!--****************************************************************
      * Functions: is-cnf() et al.
      ****************************************************************
      *-->
  <!--* Is the grammar CNF?  If all of the rules are CNF, yes, 
      * otherwise no. 
      *-->
  <xsl:function name="gt:is-cnf" as="xs:boolean">
    <xsl:param name="G" as="element(ixml)"/>

    <xsl:sequence select="every $r in $G/rule
			  satisfies gt:is-cnf-rule($r)"/>
    <!--         	  empty($G/rule[not(gt:is-cnf-rule(.))])"/> -->
  </xsl:function>

  <!--* Is the rule CNF?  If all of the RHS are CNF, yes, 
      * otherwise no. 
      *-->
  <xsl:function name="gt:is-cnf-rule" as="xs:boolean">
    <xsl:param name="r" as="element(rule)"/>
    
    <xsl:sequence select="exists($r/alt)
			  and
			  (every $rhs in $r/alt
			  satisfies gt:is-cnf-RHS($rhs))" />
    <!-- 		  empty($r/alt[not(gt:is-cnf-RHS(.))])"/> -->
  </xsl:function>

  <!--* Is the right-hand side CNF?  If it consists of one terminal 
      * or two nonterminals yes, otherwise no. 
      *-->
  <xsl:function name="gt:is-cnf-RHS" as="xs:boolean">
    <xsl:param name="rhs" as="element(alt)"/>

    <xsl:sequence select="gt:is-terminal-RHS($rhs)
			  or
			  gt:is-NN-RHS($rhs)"/>
  </xsl:function>

  <!--* Is the right-hand side a terminal rule?  It may be unnecessary
      * to factor this out, but it helps keep the make-rules simpler.
      *-->  
  <xsl:function name="gt:is-terminal-RHS" as="xs:boolean">
    <xsl:param name="rhs" as="element(alt)"/>

    <xsl:variable name="leChildren" as="element()*"
		  select="$rhs/(* except comment)"/>
    <xsl:variable name="leT" as="element()*"
		  select="$leChildren[self::literal
			  or self::inclusion
			  or self::exclusion]"/>
    <xsl:variable name="leN" as="element()*"
		  select="$leChildren[self::nonterminal]"/>

    <xsl:sequence select="count($leChildren) = 1
			  and count($leT) = 1
			  and count($leN) = 0
			  "/>
  </xsl:function>
  <xsl:function name="gt:is-NN-RHS" as="xs:boolean">
    <xsl:param name="rhs" as="element(alt)"/>

    <xsl:variable name="leChildren" as="element()*"
		  select="$rhs/(* except comment)"/>
    <xsl:variable name="leT" as="element()*"
		  select="$leChildren[self::literal
			  or self::inclusion
			  or self::exclusion]"/>
    <xsl:variable name="leN" as="element()*"
		  select="$leChildren[self::nonterminal]"/>

    <xsl:sequence select="count($leChildren) = 2
			  and count($leT) = 0
			  and count($leN) = 2
			  "/>
  </xsl:function>
  
</xsl:stylesheet>
