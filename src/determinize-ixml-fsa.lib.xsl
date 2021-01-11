<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:gt="http://blackmesatech.com/2020/grammartools"
		xmlns:xs="http://www.w3.org/2001/XMLSchema"
		default-mode="determinize"
		version="3.0">

  <!--* determinize-ixml-fsa.xsl:  Read ixml.xml (pseudo-)regular
      * grammar, rewrite it to be deterministic.
      *-->

  <!--* Revisions:
      * 2021-01-01 : CMSMcQ : back out short-name hack
      * 2020-12-30 : CMSMcQ : split into main and library modules
      *                       to make Saxon hush
      * 2020-12-28 : CMSMcQ : propagate gt:ranges further up the tree:
      *                       onto alt, and then onto rule.  The value
      *                       on rule is easy to complement to get
      *                       error transitions when they are needed.
      * 2020-12-26 : CMSMcQ : passes Andrews test 
      * 2020-12-25 : CMSMcQ : runs without crashing; output not right 
      * 2020-12-24 : CMSMcQ : still thinking 
      * 2020-12-23 : CMSMcQ : re-factor the plan; separate out 
      *                       prepatory steps and terminal normalization
      * 2020-12-21 : CMSMcQ : begin making first version.  Did not 
      *                       finish; there seems to be a lot of
      *                       bookkeeping
      *-->

  <!--****************************************************************
      * Plan / overview 
      ****************************************************************
      *
      * We assume the input is a regular grammar.  We should probably
      * check.
      *
      * We start with a queue, which may be user-specified or (in the
      * usual case) just be the starting rule of the grammar.  We
      * also start with a list of completed states.
      *
      * For each item in the queue, we
      *   . detect partial overlap between arc labels (identity
      *     and complete difference are fine)
      *   . eliminate partial overlap by splitting ranges and
      *     providing new arcs as needed 
      *   . eliminate non-determinism by making one rule for
      *     each label, and merging all follow states into a single
      *     multi-state with a deterministic name (sort state names,
      *     join with .. or something)
      *   . add new states to the queue
      *   . move the state just finished from the queue to the 
      *     completed list 
      * 
      * The result should be a deterministic regular grammar for the
      * language recognized by the input.
      *
      *-->

  <!--* Limitations:
      * If character classes overlap with literals, the overlap
      * will be detected but is not repaired.  (Maybe not impossible,
      * but more than I can manage right now.)
      *
      * Overlap of character classes with ranges will not be
      * detected and will not be repaired.  Sufficient unto the day
      * is the evil thereof.  I don't need to borrow trouble.
      *-->

  <!--* Construction steps:
      *
      * An initial attempt to build this all in one go failed, because
      * there was too much bookkeeping and too many complications.  I
      * lost track and began to lose heart.
      *
      * Building by stages should allow more confidence in the code,
      * and should provide more victories (albeit smaller ones).
      *
      * Red. No modifications to rules, just verify that the queue
      * management (including detection of new states) works.
      *
      * Orange. Sigma-normalization, eq-or-disjoint property.  Rewrite the
      * grammar to ensure that any two arcs leaving a state are
      * either visibly the same or totally disjoint.  Eliminate all
      * partial overlap by rewriting rules.  This gets complicated, so
      * it has several sub-steps.
      *
      * Orange-yellow. Terminal normalization.  (This has been factored
      * out into normalize-terminals; the input should have gt:ranges
      * attributes on all terminals.)
      *
      * Orange-green Detection of overlap in isolation. Detection of
      * occurrences of overlap, in context of alt. Repair of overlap
      * in input.
      *
      * Orange-green steps are all handled in eliminate-arc-overlap;
      * to apply the process, apply templates to a rule in mode
      * arc-overlap.
      * 
      * Yellow. Determinization.  There is no guarantee that any state 
      * of the input grammar except the start state will be reachable in
      * the output grammar, so we don't process rules in push mode.
      * Instead we put the start-state on a queue and then work from
      * the queue.  Each item on the queue has the form
      *
      *   <gt:new-state name="..." old-states="..."/>
      *
      * where name is the name of the new state (may be the same as an 
      * old one) and old-states is a space-delimited list of names of
      * old states to be combined.
      *
      * Each state we pull from the queue goes through several
      * generations.  
      * . Generation 1. Make a new rule element with the given name 
      *   and arcs from each of the old states.  
      * . Generation 2. Rewrite the rule to eliminate all overlaps
      *   among arcs. I.e. apply templates in arc-overlap mode.
      * . Generation 3. Rewrite the rule to eliminate non-determinism.  
      *   - For each distinct value of @gt:ranges among the rule's RHS,
      *     collect the names of the follow non-terminals, sort them,
      *     and construct a composite name; give it a gt:old-states
      *     attribute.
      *   - Construct a RHS (alt element) with the given ranges and
      *     (possibly new) nonterminal.
      * 
      * If any of follow states of the 3d-generation state are new, the
      * queue manager is responsible for putting them on the queue.
      *
      *-->
  
  <!--****************************************************************
      * Setup, parameters 
      ****************************************************************
      *-->

  <xsl:mode name="determinize" on-no-match="shallow-copy"/>

  <!--* starters:  rules to start from.  Defaults to nothing
      * (which later is taken to mean the first state).
      *-->
  <xsl:param name="starters" as="xs:string*" select="()"/>

  
  <!--****************************************************************
      * Main / starting template
      ****************************************************************
      *-->
  <!--* With a default identity transform, we don't actually need a
      * main starting template.  But we do want one for ixml, to
      * inject a comment to identify the stylesheet.
      *-->
  <xsl:template match="ixml">
    <xsl:param name="starters" tunnel="yes" as="xs:string*"
	       select="$starters"/>
    
    <xsl:copy>
      <xsl:sequence select="@*"/>
      <xsl:attribute name="gt:date" select="current-dateTime()"/>

      <xsl:element name="comment">
	<xsl:value-of select="current-dateTime()"/>
	<xsl:text>: determinize.xsl.</xsl:text>
      </xsl:element>
      <xsl:element name="comment">
	<xsl:text>    Input: </xsl:text>
	<xsl:value-of select="base-uri(/)"/>
      </xsl:element>
      <xsl:element name="comment">
	<xsl:text>    Output:  deterministic regular grammar for the same language. </xsl:text>
      </xsl:element>
      <xsl:text>&#xA;</xsl:text>
      
      <!--* Prepare Get ready *-->
      <xsl:variable name="starting-names"
		    as="xs:string*"
		    select="if ($starters)
			    then $starters
			    else rule[1]/@name/string()"/>
      <xsl:variable name="queue"
		    as="element(gt:new-state)*">
	<xsl:for-each select="$starting-names">
	  <xsl:element name="gt:new-state">
	    <xsl:attribute name="name" select="."/>
	    <xsl:attribute name="old-states" select="."/>
	  </xsl:element>
	</xsl:for-each>
      </xsl:variable>      

      <!--* (d2) Go *-->
      
      <xsl:call-template name="queue-manager">
	<xsl:with-param name="queue" select="$queue"/>
	<xsl:with-param name="input-grammar" tunnel="yes" select="."/>
      </xsl:call-template>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="text()[not(parent::comment)]"/>

  <!--****************************************************************
      * Named templates
      * queue-manager (manages queue)
      * state-definer (does the actual work)
      ****************************************************************
      *-->
  <!--* queue-manager:  work through the items in the queue,
      * one by one.
      * Stop when you're done.
      *-->

  <xsl:template name="queue-manager">
    <xsl:param name="queue" as="element(gt:new-state)*" required="yes"/>
    <xsl:param name="lsDone" as="xs:string*" select="()"/>
    <xsl:param name="input-grammar" as="element(ixml)" tunnel="yes"/>
    
    <xsl:if test="false()">
      <xsl:message>
	<xsl:text>queue manager:  </xsl:text>
	<xsl:value-of select="concat(
			      count($queue),
			      ' items in queue, ',
			      count($lsDone),
			      ' items done.')"/>
      </xsl:message>
    </xsl:if>   
    <xsl:if test="false()">
      <xsl:message>
	<xsl:text>queue manager:  queue is:&#xA;</xsl:text>
	<xsl:sequence select="for $e in $queue return string($e/@name)"/>
      </xsl:message>
    </xsl:if>
    
    <xsl:choose>
      <!--* base case: empty queue, done *-->
      <xsl:when test="empty($queue)">
	<xsl:if test="false()">
	  <xsl:message>
	    <xsl:text>Deterministic FSA has ca. </xsl:text>
	    <xsl:value-of select="count($lsDone)"/>
	    <xsl:text> states.</xsl:text>
	  </xsl:message>
	</xsl:if>
	<xsl:element name="comment">
	  <xsl:text> bye </xsl:text>
	</xsl:element>
      </xsl:when>

      <!--* recursive case:  do first item in queue,
	  * add new items to queue as needed,
	  * recur. *-->
      <xsl:otherwise>
	<xsl:variable name="this-task"
		      as="element(gt:new-state)"
		      select="head($queue)"/>

	<!--* (1) Make new rule / new state. *-->
	<xsl:variable name="new-rule" as="element(rule)">
	  <xsl:call-template name="state-definer">
	    <xsl:with-param name="task" select="$this-task"/>
	    <xsl:with-param name="input-grammar" tunnel="yes"
			    select="$input-grammar" />
	  </xsl:call-template>
	</xsl:variable>

	<!--* (2) Extract non-terminal references from it,
	    * so we can add them to the queue if they are new.
	    *-->
	<xsl:variable name="leCandidates"
		      as="element(nonterminal)*"
		      select="$new-rule/descendant::nonterminal
			      [not(@name = ($lsDone, $queue/@name))]"/>
	<xsl:variable name="leNewtasks"
		      as="element(gt:new-state)*">
	  <xsl:for-each
	      select="$leCandidates
		      [index-of($leCandidates/@name,@name)[1]]">
	    <!--* Thank you, Dimitre, for the index-of() way
		* of eliminating duplicates here *-->
	    <xsl:element name="gt:new-state">
	      <xsl:sequence select="@name"/>
	      <xsl:attribute name="old-states"
			     select="(@gt:old-states, @name)[1]"/>
	    </xsl:element>
	  </xsl:for-each>
	</xsl:variable>

	<!--* (3) Write out the new rule, recur with new queue. *-->
	<xsl:sequence select="$new-rule"/>
	
	<xsl:call-template name="queue-manager">
	  <xsl:with-param name="queue"
			  select="(tail($queue), $leNewtasks)"/>
	  <xsl:with-param name="lsDone"
			  select="($this-task/@name, $lsDone)"/>
	</xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--* state-definer: given a new-state request, with @old-states,
      * make a state which is (a) a combination of the old states,
      * and (b) deterministic.
      *-->
  <xsl:template name="state-definer">
    <xsl:param name="task" as="element(gt:new-state)" required="yes"/>
    <xsl:param name="input-grammar" as="element(ixml)" tunnel="yes"
	       required="yes"/>
    
    <xsl:variable name="lsOld-states" as="xs:string*"
		  select="tokenize($task/@old-states, '\s+')
			  [normalize-space()]"/>

    <!--* First, make the first-generation state: name from the
	* task, arcs / RHS from the old states listed in the task. *-->
    <xsl:variable name="ruleGen1" as="element(rule)">
      <xsl:element name="rule">
	<!--* name of state from task *-->
	<xsl:attribute name="name" select="$task/@name"/>
	<xsl:attribute name="gt:old-states"
		       select="$task/@old-states"/>
	
	<!--* arcs beginning in state from states of input grammar
	    * listed in @old-states on task. *-->
	<xsl:sequence select="$input-grammar
			      /rule[@name = $lsOld-states]
			      /alt"/>
      </xsl:element>
    </xsl:variable>
        
    <!--* Second, modify the state to satisfy eliminate partial 
	* overlap of states:  any two arc labels should be either 
	* equal or disjoint. *-->
    <xsl:variable name="ruleGen2" as="element(rule)">
      <xsl:apply-templates select="$ruleGen1" mode="arc-overlap"/>
    </xsl:variable>
    
    <!--* Third, make a deterministic state out of it. *-->
    <xsl:variable name="ruleGen3" as="element(rule)">
      <xsl:element name="rule">
	<!--* name of state from task *-->
	<xsl:attribute name="name" select="$task/@name"/>
	<xsl:attribute name="gt:old-states"
		       select="$task/@old-states"/>
	<!--* range information from ruleGen2 *-->
	<xsl:sequence select="$ruleGen2/@gt:ranges"/>
	<xsl:sequence select="$ruleGen2/@gt:theta"/>

	<xsl:if test="false()">
	  <xsl:message>
	    <xsl:text>Gen 3: rule = </xsl:text>
	    <xsl:sequence select="$ruleGen2"/>
	  </xsl:message>
	</xsl:if>

	<!--* arcs from ruleGen2, but merged *-->
	<xsl:for-each
	    select="distinct-values($ruleGen2/alt/*/@gt:ranges)">
	  <xsl:variable name="sRanges" as="xs:string"
			select="string(.)"/>
	  <!--* lsFS:  list of strings naming follow states *-->
	  <xsl:variable name="lsFS" as="xs:string*"
			select="sort(
				distinct-values(
				$ruleGen2
				/alt[*/@gt:ranges = $sRanges]
				/nonterminal
				/@name/string()
				)
				)"/>
	  
	  <xsl:if test="false()">
	    <xsl:message>
	      <xsl:text>Gen 3: ranges value = </xsl:text>
	      <xsl:sequence select="$sRanges"/>
	      <xsl:text>&#xA; lsFS = </xsl:text>
	      <xsl:sequence select="$lsFS"/>
	    </xsl:message>
	  </xsl:if>
	  <xsl:element name="alt">
	    <xsl:attribute name="gt:ranges"
			   select="$sRanges"/>
	    <xsl:sequence select="gt:serialize-range-list(
				  for $t in tokenize($sRanges,'\s+')
				  [normalize-space()]
				  return xs:integer($t)
				  )"/>
	    
	    <xsl:variable name="new-follow-state"
			  as="element(nonterminal)">
	      <xsl:element name="nonterminal">
		<!--* N.B. it would be nice to have shorter names.
		    *-->
		<xsl:attribute name="name" use-when="true()"
			       select="concat(
				       'm-',
				       string-join(
				       for $state in $lsFS
				       return $state
				       ,
				       '&#x02C5;')
				       )"/>
		<!--* N.B. the old method used to shorten the names will
		    * produce regrettable results if the portion of
		    * the old state names after _ is ever non-unique.
		    * This was suppressed the day I ran determinize on
		    * an FSA that had been built from a full r_k
		    * grammar and not from a single rule.
		    *-->
		<xsl:attribute name="name" use-when="false()"
			       select="concat(
				       'm-',
				       string-join(
				       for $state in $lsFS
				       return tokenize($state,'_')
				       [last()]
				       ,
				       '&#x02C5;')
				       )"/>
		<xsl:attribute name="gt:old-states"
			       select="$lsFS"/>
	      </xsl:element>
	    </xsl:variable>
	    <xsl:choose>
	      <!--* Check for special case:  if the range set we are
		  * working on has any arc with just a terminal and
		  * no nonterminal (so: a rule of the form q: 'x'.), 
		  * then the nonterminal must be optional. *-->
	      <xsl:when test="$ruleGen2
			      /alt
			      [*[@gt:ranges = $sRanges]]
			      [not(nonterminal)]">
		<xsl:element name="option">
		  <xsl:sequence select="$new-follow-state"/>
		</xsl:element>
	      </xsl:when>
	      <xsl:otherwise>
		<xsl:sequence select="$new-follow-state"/>
	      </xsl:otherwise>
	    </xsl:choose>
	  </xsl:element>

	</xsl:for-each>

	<!--* Another boundary case we have to cover.  If the 
	    * original state was final, the output state should
	    * be final, too.
	    *-->
	<xsl:if test="$ruleGen2/alt
		      [empty(* except comment)]">
	  <xsl:element name="alt">
	    <xsl:comment> final state </xsl:comment>
	  </xsl:element>
	</xsl:if>
	
	<!--* A third boundary case cannot be ignored after all:
	    * if the input grammar has a lot of epsilon transitions,
	    * we are in trouble, because there is really no point in trying 
	    * to determinize such an FSA.  The user will already 
	    * have been warned by the arc-overlap template for rule.
	    *
	    * But the RTN linkage rules do take the form of empty
	    * transitions.
	    *-->
	<xsl:variable name="epsilon-transition" as="element(alt)?"
		      select="$ruleGen2/alt 
			      [exists(nonterminal) 
			      and not(exists(literal) 
  		              or exists(inclusion) 
			      or exists(exclusion)) ]"/>
	<xsl:if test="exists($epsilon-transition)">
	  <xsl:sequence select="$epsilon-transition"/>
	</xsl:if>
	    

      </xsl:element>
    </xsl:variable>
    
    <!--* Return the deterministic state. *-->
    <xsl:sequence select="$ruleGen3"/>
    
  </xsl:template>


 
	  
  <!--****************************************************************
      * Functions
      ****************************************************************
      *-->
  
  
 

</xsl:stylesheet>
