<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:gt="http://blackmesatech.com/2020/grammartools"
		xmlns:xs="http://www.w3.org/2001/XMLSchema"
		default-mode="rk-subset"
		version="3.0">

  <!--* ixml-to-rk-subset.xsl:  Read annotated ixml.xml grammar,
      * write it out again as grammar for r_k subset of original
      * language.
      *-->

  <!--* Revisions:
      * 2021-01-12 : CMSMcQ : be more cautious about stylesheet PI
      * 2020-12-30 : CMSMcQ : add some simple metadata attributes
      *                       to ixml element to say that this is
      *                       the r_k subset
      * 2020-12-20 : CMSMcQ : make this pipelineable by adding 
      *                       default-mode
      * 2020-12-12 : CMSMcQ : minimal first version 
      *-->

  <!--****************************************************************
      * Plan / overview 
      ****************************************************************
      *
      * We replace all rules for recursive nonterminals with a set
      * of rules in whose names an affix tracks the stack depth;
      * when the affix exceeds our limits, we stop the recursion.
      * The result:  a regular language approximating the language of
      * the input grammar, as a subset.
      *
      * Rules for non-recursive nonterminals are copied through without
      * change.
      *
      * Some points of detail:
      * (1) If the affix is too long, the rule is defined with a
      * right-hand side of the empty set (U+2205, ∅).  This nonterminal
      * being undefined, it cannot be matched (so the set of matching
      * strings is the empty set, hence the name).  When we knit the
      * r_k subset grammar generated here together with the R_0 grammar
      * to make the R_k superset grammar, we'll replace those RHS with
      * the appropriate R_0 definition of the nonterminal.  If we want
      * to parse strings against the r_k subset, the grammar produced
      * here can be used, but we will probably want to clean the grammar,
      * simplifying RHS to eliminate unsatisfiable subexpressions.
      * 
      * (2) We define a predicate fAffixok($affix, $n), to simplify
      * customization.  (We could choose to allow different levels of
      * nesting for different recursive nonterminals.)  Default:  no
      * affix containing more than k instances of $n gets a normal
      * definition.
      *
      * (3) A user-specified configuration document can provide codes
      * to use for each nonterminal (and can specify that a given
      * nonterminal should not be tracked in the affixes, even though
      * it's recursive:  this is helpful for keeping the affixes
      * shorter and fewer in number, and it's safe for left- and
      * right-embedded nonterminals which do not produce tag pairs.
      * 
      *-->

  <!--* Construction steps:
      * 1 Copy through without change (scaffolding).
      * 2 Suppress recursive nonterminals (and text nodes).
      * 3 Handle recursive nonterminals.
      *-->
  
  <!--****************************************************************
      * Setup, parameters 
      ****************************************************************
      *-->
  
  <xsl:output method="xml"
	      indent="yes"/>

  <xsl:mode name="rk-subset" on-no-match="shallow-copy"/>
  <xsl:mode name="affix" on-no-match="shallow-copy"/>

  <!--* k:  stack depth parameter; allow each recursive nonterminal
      * at most k ancestors of the same name.  k=0 for bracket-free
      * subset of language. *-->
  <xsl:param name="k" as="xs:integer" select="0"/>

  <!--* starters:  rules to rewrite with null left-hand affix.
      * If not specified, take all recursive nonterminals as starters
      * (there will be unreachable nonterminals in output).
      *-->
  <xsl:param name="starters" as="xs:string*" select="()"/>

  <!--* config:  filename of configuration file *-->
  <xsl:param name="config" as="xs:string" select="'no-config-file'"/>

  <!--* stkdel:  stack delimiter *-->
  <!--* 22EF looks good (midline horizontal ellipsis) but is not
      * a name character (? I thought they were all name
      * characters now?) and so causes problems for follow:*
      * attributes. Promising letters:
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
  <xsl:param name="stackdel" as="xs:string" select=" '&#xB7;' "/>

  <!--* empty-set:  name to use for empty-set nonterminal *-->
  <!--* U+2205 empty set is good, but not a name character.
      * U+3007 ideographic number zero is a fallback if name
      * character-hood is important.
      * U+0660 Arabic-Indic digit zero 
      * U+06F0 Extented Arabic-Indic digit zero 
      * U+FF10 Fullwidth digit zero
      * U+1F10C Dingbat negative circled sans-serif digit zero
      * (Lots of other zeroes are legal namestart characters, but
      * I don't see other empty-set symbols.)
      * U+1D34C Tetragram for stoppage 
      * U+1D350 Tetragram for failure 
      *-->
  <xsl:param name="empty-set" as="xs:string" select=" '&#x2205;' "/>

  <!--* msg-level: how chatty? *-->
  <xsl:param name="msg-level" as="xs:integer" select=" 10 "/>
  <!--* to do:  manage message levels systematically *-->
  
  <!--****************************************************************
      * Main / starting template
      ****************************************************************
      *-->
  <!--* With a default identity transform, we don't actually need a
      * main starting template.  But we do want one for ixml, to
      * inject a comment to identify the stylesheet.
      *-->
  <xsl:template match="ixml">
    <xsl:param name="k" tunnel="yes" as="xs:integer"
	       select="$k"/>
    <xsl:param name="starters" tunnel="yes" as="xs:string*"
	       select="$starters"/>
    <xsl:param name="config" tunnel="yes" as="xs:string"
	       select="$config"/>
    
    <xsl:variable name="configdoc"
		  as="document-node(element(gt:config))?"
		  select="if ($config eq 'no-config-file')
			  then ()
			  else doc($config)"/>

    <!--* (a) Check invocation, bail if it's pointless to proceed *-->
    <xsl:if test="empty(rule/@gt:recursive)">
      <xsl:message terminate="yes">
	<xsl:text>No recursive nonterminals found!&#xA;</xsl:text>
	<xsl:text>Either grammar is already regular &#xA;</xsl:text>
	<xsl:text>or ixml-annotate-pc.xsl needs to be run!</xsl:text>
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
      <xsl:attribute name="gt:ra-type" select="'rk-subset'"/>
      <xsl:attribute name="gt:k" select="$k"/>
      <xsl:attribute name="gt:date" select="current-dateTime()"/>

      <xsl:element name="comment">
	<xsl:value-of select="current-dateTime()"/>
	<xsl:text>: ixml-to-rk-subset.xsl.</xsl:text>
      </xsl:element>
      <xsl:element name="comment">
	<xsl:text>    Input: </xsl:text>
	<xsl:value-of select="base-uri(/)"/>
      </xsl:element>
      <xsl:element name="comment">
	<xsl:text>    This grammar accepts the r_</xsl:text>
	<xsl:value-of select="$k"/>
	<xsl:text> subset </xsl:text>
      </xsl:element>
      <xsl:element name="comment">
	<xsl:text>    of the language accepted by the input grammar.</xsl:text>
      </xsl:element>
      <xsl:text>&#xA;</xsl:text>

      <xsl:apply-templates select="comment[not(preceding-sibling::rule)]"/>
      
      <!--* (c) Handle non-recursive nonterminals. *-->
      <xsl:text>&#xA;</xsl:text>
      <xsl:element name="comment">
	<xsl:text> First, nonrecursive production rules </xsl:text>
      </xsl:element>
      <xsl:text>&#xA;</xsl:text>

      <xsl:apply-templates select="rule | comment[preceding-sibling::rule]"/>

      <!--* (d) Handle recursive nonterminals. *-->
      <xsl:text>&#xA;</xsl:text>
      <xsl:element name="comment">
	<xsl:text> Second, recursive production rules </xsl:text>
      </xsl:element>
      <xsl:text>&#xA;</xsl:text>

      <!--* (d1) Get ready *-->
      <xsl:variable name="starting-names"
		    as="xs:string*"
		    select="if ($starters)
			    then $starters
			    else rule[xs:boolean(@gt:recursive)]
			    /@name/string()"/>
      <xsl:variable name="queue"
		    as="element(gt:please-define)*">
	<xsl:for-each select="$starting-names">
	  <xsl:element name="gt:please-define">
	    <xsl:attribute name="name" select="."/>
	    <xsl:attribute name="basename" select="."/>
	    <xsl:attribute name="affix" select=" '' "/>
	  </xsl:element>
	</xsl:for-each>
      </xsl:variable>

      <!--* (d2) Go *-->

      <xsl:message use-when="false()">
	<xsl:text>Passing k = </xsl:text>
	<xsl:value-of select="$k"/>
	<xsl:text> and </xsl:text>
	<xsl:value-of select="count($configdoc)"/>
	<xsl:text> config doc(s).</xsl:text>
      </xsl:message>
      <xsl:message terminate="yes" use-when="false()">
	<xsl:text>Queue = </xsl:text>
	<xsl:sequence select="$queue"/>
      </xsl:message>
      
      <xsl:call-template name="one-by-one">
	<xsl:with-param name="queue" select="$queue"/>
	<xsl:with-param name="k" tunnel="yes" select="$k"/>
	<xsl:with-param name="configdoc" tunnel="yes" select="$configdoc"/>
      </xsl:call-template>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="rule[xs:boolean(@gt:recursive) = true()]"/>

  <xsl:template match="text()[not(parent::comment)]"/>

  <!--****************************************************************
      * Named templates
      * one-by-one (manages queue)
      * and copy-with-affix (does the actual work)
      ****************************************************************
      *-->
  <!--* one-by-one:  work through the items in the queue,
      * one by one.
      * Stop when you're done.
      *-->

  <xsl:template name="one-by-one">
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
      <xsl:text>one-by-one:  </xsl:text>
      <xsl:text>&#xA;  queue = </xsl:text>
      <xsl:sequence select="$queue/@name/string()"/>
      <xsl:text>&#xA;  done = </xsl:text>
      <xsl:sequence select="$leDone/@name/string()"/>
    </xsl:message>

    <xsl:choose>
      <!--* base case: empty queue, done *-->
      <xsl:when test="empty($queue)">
	<xsl:element name="comment">
	  <xsl:text> bye </xsl:text>
	</xsl:element>
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
	  <xsl:sequence select="$this-task"/>
	</xsl:message>
	
	
	<xsl:variable name="new-rule"
		      as="element(rule)">
	  <xsl:call-template name="copy-with-affix">
	    <xsl:with-param name="task"
			    select="$this-task"/>
	  </xsl:call-template>
	</xsl:variable>

	<!--* (2) Extract non-terminal references from it,
	    * so we can add them to the queue if they are new.
	    *-->
	<xsl:variable name="leCandidates"
		      as="element(nonterminal)*"
		      select="$new-rule/descendant::nonterminal
			      [@gt:affix]
			      [not(@name = ($leDone/@name, $queue/@name))]"/>
	<xsl:variable name="leNewtasks"
		      as="element(gt:please-define)*">
	  <xsl:for-each
	      select="$leCandidates
		      [index-of($leCandidates/@name,@name)[1]]">
	    <!--* Thank you, Dimitre, for the index-of() way
		* of eliminating duplicates here *-->
	    <xsl:element name="gt:please-define">
	      <xsl:sequence select="@name"/>
	      <xsl:attribute name="basename" select="@gt:basename"/>
	      <xsl:attribute name="affix" select="@gt:affix"/>
	    </xsl:element>
	  </xsl:for-each>
	</xsl:variable>

	<!--* (3) Write out the new rule, recur with new queue. *-->
	<xsl:sequence select="$new-rule"/>
	<xsl:call-template name="one-by-one">
	  <xsl:with-param name="queue"
			  select="($queue[position() gt 1],
				  $leNewtasks)"/>
	  <xsl:with-param name="leDone"
			  select="($this-task, $leDone)"/>
	</xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--* copy-with-affix
      *
      *-->
  
  <xsl:template name="copy-with-affix">
    <xsl:param name="task"
	       as="element(gt:please-define)"/>
    <xsl:param name="k" as="xs:integer" tunnel="yes"/>
    <xsl:param name="configdoc"
	       as="document-node(element(gt:config))?"
	       tunnel="yes"/>
    
    <xsl:message use-when="false()">
	<xsl:text>Copy-with-affix got task = </xsl:text>
	<xsl:sequence select="$task"/>
	<xsl:text>Copy-with-affix got k = </xsl:text>
	<xsl:value-of select="$k"/>
	<xsl:text> and </xsl:text>
	<xsl:value-of select="count($configdoc)"/>
	<xsl:text> config doc(s).</xsl:text>
    </xsl:message>
    
    <!--* We are to copy a rule, adding an affix to the left-hand side
	* and a different affix (one symbol longer) to items on the
	* right-hand side.  That's all.
	*-->
    <!--* Calculate the new affix. *-->
    <xsl:variable name="code" as="xs:string"
		  select="gt:codeXnt($task/@basename, $configdoc)"/>
    <xsl:variable name="new-affix" as="xs:string"
		  select="if (gt:ftraceXnt($task/@basename, $configdoc))
			  then concat($code, $task/@affix)
			  else $task/@affix"/>

    <xsl:message use-when="false()">
      <xsl:text>Debug:  basename </xsl:text>
      <xsl:value-of select="$task/@basename"/>
      <xsl:text>, code </xsl:text>
      <xsl:value-of select="$code"/>
      <xsl:text>, new affix </xsl:text>
      <xsl:value-of select="$new-affix"/>
    </xsl:message>

    <!--* If the affix is within our limits, find the
	* rule and copy it.  Otherwise, stub it out.
	*-->
    <xsl:choose>
      <xsl:when test="gt:fAffixok(
		      $task/@affix,
		      $task/@basename,
		      $k,
		      $configdoc)">	
	<!--* Find the rule. *-->
	<xsl:variable name="rule"
		      as="element(rule)"
		      select="/ixml/rule[@name=$task/@basename]"/>
	
	<xsl:if test="$msg-level gt 5">
	  <xsl:message>Making rule <xsl:value-of select="$task/@name"/></xsl:message>
	</xsl:if>
	
	<!--* Copy the rule *-->
	<xsl:element name="rule">
	  <xsl:sequence select="$task/@name,
				@mark"/>
	  <xsl:attribute name="gt:basename" select="$task/@basename"/>
	  <xsl:attribute name="gt:affix" select="$task/@affix"/>
	  <xsl:attribute name="gt:type" select=" 'stack-affixed' "/>
	  
	  <xsl:apply-templates mode="affix" select="$rule/*">
	    <xsl:with-param name="affix" select="$new-affix" tunnel="yes"/>
	  </xsl:apply-templates>
	</xsl:element>
      </xsl:when>
      <xsl:otherwise>
	<!--* stub it out *-->

	<xsl:if test="$msg-level gt 5">
	  <xsl:message>Stubbing out empty-set rule for <xsl:value-of select="$task/@name"/></xsl:message>
	</xsl:if>
	
	<xsl:element name="rule">
	  <xsl:sequence select="$task/@name,
				@mark"/>
	  <xsl:attribute name="gt:basename" select="$task/@basename"/>
	  <xsl:attribute name="gt:affix" select="$task/@affix "/>
	  <xsl:attribute name="gt:type" select=" 'stub' "/>
	  <xsl:element name="alt">
	    <xsl:element name="nonterminal">
	      <xsl:attribute name="name"
			     select="concat('max-', $task/@basename)"/>
	      <!--
		  <xsl:attribute name="name" select="$empty-set"/>
	      -->
	    </xsl:element>
	  </xsl:element>
	</xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--* When creating affigated copies, don't copy comments *-->
  <xsl:template match="comment" mode="affix"/>
   
  <!--* When creating affigated copies, add gt:basename and
      * gt:affix attributes to recursive nonterminals.
      * Leave non-recursive nonterminals alone.
      *-->
  <xsl:template match="nonterminal"
		mode="affix">
    <xsl:param name="affix" as="xs:string" tunnel="yes"/>

    <xsl:variable name="name" select="string(@name)"/>
    
    <xsl:variable name="attRecursive"
		  as="attribute()?"
		  select="/ixml/rule[@name = $name]/@gt:recursive"/>
    <xsl:variable name="fRecursive"
		  as="xs:boolean"
		  select="xs:boolean($attRecursive) = true()"/>
    <xsl:choose>
      <xsl:when test="$fRecursive">
	<xsl:copy>
	  <xsl:attribute name="name"
			 select="concat(@name, $stackdel, $affix)"/>
	  <xsl:attribute name="gt:basename" select="@name"/>
	  <xsl:attribute name="gt:affix" select="$affix"/>
	</xsl:copy>
      </xsl:when>
      <xsl:otherwise>
	<xsl:copy-of select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
	  
  <!--****************************************************************
      * Functions
      ****************************************************************
      *-->
  <!--* gt:codeXnt($n) return code for nonterminal $n *-->
  <xsl:function name="gt:codeXnt" as="xs:string">
    <xsl:param name="n" as="xs:string"/>
    <xsl:param name="configdoc" as="document-node(element(gt:config))?"/>

    <xsl:variable name="code" as="xs:string?"
		  select="$configdoc//nonterminal[@name=$n]
			  /@stack-code/string()"/>
    <xsl:choose>
      <xsl:when test="exists($configdoc)
		      and exists($code)">
	<xsl:value-of select="$code"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="concat($n, $stackdel)"/>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:function>
  
  <!--* gt:ftraceXnt($n) return flag to show whether
      * nonterminal $n should be traced or not *-->
  <xsl:function name="gt:ftraceXnt" as="xs:boolean">
    <xsl:param name="n" as="xs:string"/>
    <xsl:param name="configdoc" as="document-node(element(gt:config))?"/>
    
    <xsl:variable name="flag" as="xs:string?"
		  select="$configdoc//nonterminal[@name=$n]
			  /@stack-trace"/>
    <xsl:value-of select="if ($flag eq 'no')
			  then false()
			  else true()"/>    
  </xsl:function>

  <!--* gt:fAffixok($affix, $n):  return flag to show whether
      * this nonterminal + affix pair should be defined normally
      * or as empty set
      *-->
  <xsl:function name="gt:fAffixok" as="xs:boolean">
    <xsl:param name="affix" as="xs:string"/>
    <xsl:param name="n" as="xs:string"/>
    <xsl:param name="k" as="xs:integer"/>
    <xsl:param name="configdoc"
	       as="document-node(element(gt:config))?"/>

    <!--* Currently we support only one form of stack limitation:
	* a non-negative integer k.
	*
	* We will tokenize the stack, and then look to see whether any
	* item occurs more than k times.
	*
	* The pattern $stack[index-of($stack, .)] produces a list of
	* places where the current item occurs in the stack. So
	* $stack[index-of($stack, .)][1] returns the first occurrence
	* of each item, [2] returns the second occurrence of any value
	* (dropping the others), etc.
	* 
	* So if $stack[index-of($stack, .)][$k + 1]
	* is empty, all is well.
	*-->

    <!--* First, tokenize the affix to get a picture of the stack we
	* are trying to keep track of. If $affix contains $stackdel,
	* we have full names, not codes; tokenize on stackdel.
	* Otherwise, assume one-character codes.
	*-->
    <xsl:variable
	name="stack"
	as="item()*"
	select="if (contains($affix, $stackdel))
		then tokenize($affix, $stackdel)[normalize-space()]
		else for $s in string-to-codepoints($affix)
		     return codepoints-to-string($s)
		"/>

    <xsl:message use-when="false()">
      <xsl:text>fAffixok:  stack of </xsl:text>
      <xsl:value-of select="count($stack)"/>
      <xsl:text> items: </xsl:text>
      <xsl:sequence select="$stack"/>
    </xsl:message>
    
    <!--* the affix is 'ok' (to be defined) iff there are no more
	* than $k occurrences of $n in $stack.
	*-->
    <xsl:variable name="code" as="xs:string"
		  select="tokenize(
			  gt:codeXnt($n, $configdoc),
			  $stackdel
			  )
			  [normalize-space()]"/>
    
    <xsl:variable name="occurrences"
		  select="index-of($stack, $code)"/>

    <xsl:message use-when="false()">
      <xsl:text>fAffixok:  codeXnt = </xsl:text>
      <xsl:value-of select="gt:codeXnt($n, $configdoc)"/>
      <xsl:text>, occurrences = </xsl:text>
      <xsl:sequence select="$occurrences"/>
    </xsl:message>    

    <xsl:if test="$msg-level gt 8" use-when="false()">
      <xsl:message>
	<xsl:value-of
	    select="concat(
		    'gt:fAffixok(',
		    $affix, ', ', $n,
		    ') returns ',
		    count($occurrences) le $k,
		    ' with ',
		    count($occurrences), ' and k = ', $k
		    )"/></xsl:message>
    </xsl:if>
    
    <xsl:value-of select="count($occurrences) le $k"/>
    
  </xsl:function>
  
  <!--* old version of gt:fAffixok($affix):  return flag to show whether
      * this affix should be defined normally or as empty set
      *-->
  <xsl:function name="gt:fAffixok" as="xs:boolean">
    <xsl:param name="affix" as="xs:string"/>
    <xsl:param name="k" as="xs:integer"/>

    <!--* Currently we support only one form of stack limitation:
	* a non-negative integer k.
	*
	* We will tokenize the stack, and then look to see whether any
	* item occurs more than k times.
	*
	* The pattern $stack[index-of($stack, .)] produces a list of
	* places where the current item occurs in the stack. So
	* $stack[index-of($stack, .)][1] returns the first occurrence
	* of each item, [2] returns the second occurrence of any value
	* (dropping the others), etc.
	* 
	* So if $stack[index-of($stack, .)][$k + 1]
	* is empty, all is well.
	*-->

    <!--* First, tokenize the affix to get a picture of the stack we
	* are trying to keep track of. If $affix contains $stackdel,
	* we have full names, not codes; tokenize on stackdel.
	* Otherwise, assume one-character codes.
	*-->
    <xsl:variable
	name="stack"
	as="item()*"
	select="if (contains($affix, $stackdel))
		then tokenize($affix, $stackdel)[normalize-space()]
		else string-to-codepoints($affix)
		"/>
    
    <!--* Next, see which symbols are maxed out. *-->
    <xsl:variable
	name="ls-maxedout"
	as="item()*"
	select="$stack[index-of($stack, .)][$k + 1]"/>
    
    <!--* the affix is 'ok' (to be defined) iff the
	* list of maxed-out symbols is empty.
	*-->
    <xsl:value-of select="empty($ls-maxedout)"/>
    
  </xsl:function>
  
  
</xsl:stylesheet>
