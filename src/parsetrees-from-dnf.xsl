<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    default-mode="parsetrees-from-dnf"
    version="3.0">

  <!--* parsetrees-from-dnf.xsl: Read ixml.xml grammar G in disjunctive
      * normal form, write out a sequence of parse tree skeletons
      * rooted in the start symbol, whose leaves are terminals and
      * pseudo-terminals.
      *
      * When the parse tree produced by ixml should have an element
      * named S, the parse tree schema produced here will have an
      * element named gt:element with name="S". The gt:element elements
      * may also carry @mark attributes carried over from the relevant
      * rule or nonterminal elements in G, so they can be used to
      * guide construction of the expected ixml result tree (the AST).
      *
      * We use gt:element elements to distinguish them reliably from
      * ixml elements used as placeholders. (I tried making elements
      * named as they should be in the ixml output, but could not make
      * that work for building ixml test cases.)
      *-->

  <!--* Revisions:
      * 2021-01-19/21 : CMSMcQ : filling it in (went very slowly)
      * 2021-01-18 : CMSMcQ : try to make at least an outline. 
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->
  


  <xsl:mode name="parsetrees-from-dnf" on-no-match="shallow-copy"/>
  <xsl:mode name="leaf-expansion" on-no-match="fail"/>
  
  <xsl:strip-space elements="*"/>
  <xsl:output method="xml" indent="yes"/>

  <!--* maxdepth: what is maximum depth of a resulting tree?
      * When do we quit if we don't manage a complete xsl?
      *-->
  <xsl:param name="maxdepth" as="xs:integer" select="40"/>

  <!--* maxfail: what is maximum number of times we can try to
      * build a tree and fail, before giving up completely?
      *-->
  <xsl:param name="maxfail" as="xs:integer" select="10"/>

  <!--* pseudoterminals: list of nonterminals which should not
      * be expanded.
      *-->
  <xsl:param name="pseudoterminals" as="xs:string*" select="()"/>

  <!--* Define keys lhs and rhs to make it easier to find rule/alt
      * elements when we need them.
      * key('lhs', $n) finds the rules with $n on the left hand side.
      *    = /ixml/rule[@name=$n]/alt
      * key('rhs', $n) finds the rules which refer to $n.
      *    = //rule/alt[nonterminal[@name=$n]]
      *-->

  <xsl:key name="lhs" match="rule/alt" use="parent::rule/@name/string()"/>
  <xsl:key name="rhs" match="rule/alt" use="nonterminal/@name/string()" composite="no"/>

  
  <!--****************************************************************
      * Main / starting template
      ****************************************************************
      *-->
  <xsl:template match="ixml">
    <xsl:param name="maxdepth" as="xs:integer" tunnel="yes"
	       select="$maxdepth"/>
    <xsl:param name="maxfail" as="xs:integer" tunnel="yes"
	       select="$maxfail"/>
    <xsl:param name="pseudoterminals" as="xs:string*" tunnel="yes"
	       select="$pseudoterminals"/>

    <xsl:message use-when="false()">
      <xsl:text>maxfail = </xsl:text>
      <xsl:value-of select="$maxfail"/>
    </xsl:message>
    
    <xsl:element name="parse-tree-collection">
      <xsl:sequence select="@*"/>
      <xsl:attribute name="gt:date" select="current-dateTime()"/>
      <xsl:element name="comment">
	<xsl:value-of select="current-dateTime()"/>
	<xsl:text>: parsetrees-from-dnf.xsl.</xsl:text>
      </xsl:element>
      <xsl:element name="comment">
	<xsl:text>    Input: </xsl:text>
	<xsl:value-of select="base-uri(/)"/>
      </xsl:element>
      <xsl:element name="comment">
	<xsl:text>    Output:  trees rooted in start symbol </xsl:text>
	<xsl:text>with terminals and pseudoterminals as leaves.</xsl:text>
      </xsl:element>
      
      <xsl:text>&#xA;</xsl:text>

      <!--* make-trees($tree, $acc, $new, $used) *-->
      <xsl:sequence select="gt:make-trees((), (),
			    rule/alt, (),
			    0,
			    map{'maxdepth':  $maxdepth,
			    'maxfail':  $maxfail, 
			    'pseudoterminals':  $pseudoterminals, 
			    'start-symbol': rule[1]/@name/string()})"/>
    </xsl:element>
  </xsl:template>


  <!--****************************************************************
      * Functions
      ****************************************************************
      *-->
  <!--* Talked myself out of the function make-rhs-map():  it was to
      * produce a map to make it easy to find suitable RHS from the
      * top, or from the bottom, and know whether they were already
      * used or not.
      *
      * My tentative sketch said: top-level keys are nonterminals. 
      * Each value is a map with the keys 
      * 'parents' (list of parent nonterminals) 
      * 'new' (list of alt elements) 
      * 'used' (list of alt elements) 
      * 
      * After looking up the map functions and making a cheat sheet
      * I decided I don't need that at all.
      * . To find RHS for a given nonterminal $n,
      *   /ixml/rule[@name=$n]/alt does fine.  If it's slow,
      *   key('lhs', $n) may be faster. 
      * . To find RHS referring to $n, /ixml/rule/alt
      *   [nonterminal/@name = $n] will do, or key('rhs', $n).
      * . To find unused RHS for $n, intersect with $new
      * . To move $rhs from new to used, ($new except $rhs),
      *   ($used, $r) should do fine.
      * 
      *-->

  
  
  <xsl:function name="gt:make-trees" as="element()*">
    <xsl:param name="T" as="element()?"/>
    <xsl:param name="acc" as="element()*"/>
    <xsl:param name="new" as="element(alt)*"/>
    <xsl:param name="used" as="element(alt)*"/>
    <xsl:param name="cFails" as="xs:integer"/>
    <xsl:param name="options" as="map(*)?"/>
    
    <xsl:variable name="maxdepth" as="xs:integer"
		  select="($options('maxdepth'),$maxdepth)[1]"/>
    <xsl:variable name="maxfail" as="xs:integer"
		  select="($options('maxfail'),$maxfail)[1]"/>

    <xsl:message use-when="false()">
      <xsl:text>gt:make-trees() called with </xsl:text>
      <xsl:text>T = </xsl:text>
      <xsl:sequence select="($T)"/>
      <xsl:text>&#xA;     new = </xsl:text>
      <xsl:sequence select="(for $e in $new return $e/@id/string())"/>
      <xsl:text>&#xA;     used = </xsl:text>
      <xsl:sequence select="(for $e in $used return $e/@id/string())"/>
    </xsl:message>
    
    <xsl:message use-when="false()">
      <xsl:text>gt:make-trees() called with </xsl:text>
      <xsl:text>&#xA;     </xsl:text>
      <xsl:value-of select="count($T)"/>
      <xsl:text> partial tree(s),</xsl:text>
      <xsl:text>&#xA;     </xsl:text>
      <xsl:value-of select="count($acc)"/>
      <xsl:text> tree(s) in the accumulator,</xsl:text>
      <xsl:text>&#xA;     </xsl:text>
      <xsl:value-of select="count($new)"/>
      <xsl:text> RHS not yet used,</xsl:text>
      <xsl:text>&#xA;     </xsl:text>
      <xsl:value-of select="count($used)"/>
      <xsl:text> RHS already used at least once,</xsl:text>
      <xsl:text>&#xA;     cFails = </xsl:text>
      <xsl:value-of select="$cFails"/>
      <xsl:text>&#xA;     maxdepth = </xsl:text>
      <xsl:value-of select="$maxdepth"/>
      <xsl:text>&#xA;     maxfail = </xsl:text>
      <xsl:value-of select="$maxfail"/>
    </xsl:message>
    
    <xsl:message use-when="false()">
      <xsl:text>gt:make-trees() called with </xsl:text>
      <xsl:text>&#xA;     </xsl:text>
      <xsl:value-of select="count($T)"/>
      <xsl:text> partial tree(s) rooted in </xsl:text>
      <xsl:value-of select="$T/@name"/>
      <xsl:text> of depth </xsl:text>
      <xsl:value-of select="max(
		      for $D in $T/descendant::*
		      return count($D/ancestor::*)
		      )"/>
      <xsl:text>&#xA;     maxdepth = </xsl:text>
      <xsl:value-of select="$maxdepth"/>
    </xsl:message>

    <xsl:choose>
      <!--* if all pieces have been used, stop *-->
      <xsl:when test="count($new) eq 0 and empty($T)">
	<xsl:message use-when="true()">
	  <xsl:text>gt:make-trees() returning </xsl:text>
	  <xsl:value-of select="count($acc)"/>
	  <xsl:text> tree(s), including </xsl:text>
	  <xsl:value-of select="$cFails"/>
	  <xsl:text> failed attempts.</xsl:text>
	</xsl:message>
	
	<xsl:sequence select="$acc"/>
      </xsl:when>
      
      <!--* if we have failed too often, stop *-->
      <xsl:when test="$cFails ge $maxfail">
	<xsl:message use-when="true()">
	  <xsl:text>gt:make-trees() returning </xsl:text>
	  <xsl:value-of select="count($acc)"/>
	  <xsl:text> tree(s), having failed </xsl:text>
	  <xsl:value-of select="$cFails"/>
	  <xsl:text> times.  The limit is </xsl:text>
	  <xsl:value-of select="$maxfail"/>
	  <xsl:text> times.  Enough is enough.</xsl:text>
	</xsl:message>
	<xsl:sequence select="$acc"/>
      </xsl:when>
      
      <!--* if we have no tree, start one *-->
      <xsl:when test="empty($T)">
	<xsl:message use-when="false()">
	  <xsl:text>gt:make-trees() starting a new tree, with </xsl:text>
	  <xsl:text>&#xA;     </xsl:text>
	  <xsl:value-of select="count($acc)"/>
	  <xsl:text> tree(s) in the accumulator,</xsl:text>
	  <xsl:text>&#xA;     </xsl:text>
	  <xsl:value-of select="count($new)"/>
	  <xsl:text> RHS not yet used,</xsl:text>
	  <xsl:text>&#xA;     </xsl:text>
	  <xsl:value-of select="count($used)"/>
	  <xsl:text> RHS already used at least once,</xsl:text>
	  <xsl:text>&#xA;     cFails = </xsl:text>
	  <xsl:value-of select="$cFails"/>
	</xsl:message>
	
	<!--* pick a new lego piece *-->
	<xsl:variable name="rhs" as="element(alt)"
		      select="$new[1]"/>
	<xsl:variable name="T1" as="element()">
	  <xsl:element name="gt:element">
	    <xsl:sequence select="$rhs/parent::rule/@*,
				  $rhs/*"/>
	  </xsl:element>
	</xsl:variable>
	
	<!--* recur *-->
	<xsl:sequence select="gt:make-trees(
			      $T1, $acc,
			      ($new except $rhs),
			      ($used, $rhs),
			      $cFails, $options
			      )"/>
      </xsl:when>

      <!--* if the tree is too deep, fail and recur. *-->
      <xsl:when test="max(
		      for $D in $T/descendant::*
		      return count($D/ancestor::*)
		      ) gt $maxdepth">
	<!--* Confess *-->
	<xsl:message use-when="true()">
	  <xsl:text>gt:make-trees() giving up.  Tree </xsl:text>
	  <xsl:text>rooted in </xsl:text>
	  <xsl:value-of select="$T/@name"/>
	  <xsl:text> got too big:  </xsl:text>
	  <xsl:value-of select="count($T/descendant-or-self::*)"/>
	  <xsl:text> elements, height = </xsl:text>
	  <xsl:value-of select="max(
		      for $D in $T/descendant::*
		      return count($D/ancestor::*)
		      )"/>
	</xsl:message>
	<xsl:variable name="failure" as="element(gt:failure)">
	  <xsl:element name="gt:failure">
	    <xsl:sequence select="$T"/>
	  </xsl:element>
	</xsl:variable>
	<!--* Recur. *-->
	<xsl:sequence select="gt:make-trees(
			      (), ($acc, $failure),
			      $new, $used,
			      $cFails + 1, $options
			      )"/>
      </xsl:when>

      <!--* if we have a tree, grow it upwards to
	  * the start symbol. *-->
      <xsl:when test="$T/@name ne $options('start-symbol')">
	<xsl:message use-when="false()">
	  <xsl:text>gt:make-trees() growing upwards, </xsl:text>
	  <xsl:text>partial tree is rooted in </xsl:text>
	  <xsl:value-of select="$T/@name"/>
	  <xsl:text>, start symbol is </xsl:text>
	  <xsl:value-of select="$options('start-symbol')"/>
	</xsl:message>
	<xsl:message use-when="false()">	  
	  <xsl:text>     count($new): </xsl:text>
	  <xsl:value-of select="count($new)"/>
	  <xsl:text>.&#xA;     count($used): </xsl:text>
	  <xsl:value-of select="count($used)"/>	  
	</xsl:message>
	
	<!--* find a potential parent *-->
	<!--
	<xsl:variable name="leRHS0" as="element(alt)+"
		      select="key('rhs', $T/@name/string(), ($new, $used)[1]/root()/ixml)"/>
	<xsl:variable name="leRHS1" as="element(alt)*"
		      select="$leRHS0 intersect $new"/>
	<xsl:variable name="leRHS2" as="element(alt)*"
		      select="$leRHS0 except $leRHS1"/>
	<xsl:variable name="rhs" as="element(alt)"
                      select="($leRHS1, $leRHS2)[1]"/>
	-->

	<xsl:variable name="G" as="element(ixml)"
		      select="($new, $used)[1]/root()/ixml"/>
	<xsl:variable name="leNew0" as="element(alt)*"
		      select="$new intersect key('rhs', $T/@name, $G)"/>
	<xsl:variable name="leUsed0" as="element(alt)*"
		      select="$used[nonterminal/@name = $T/@name]"/>

	<!--* temporary paranoia *-->
	<xsl:variable name="leUsed666" as="element(alt)*"
		      select="for $e in $used
			      return if ($e/nonterminal/@name = $T/@name)
			      then $e else ()"/>
	<xsl:if test="not(deep-equal($leUsed0, $leUsed666))">
	  <xsl:message>
	    <xsl:text>Strange.  leUsed0 = </xsl:text>
	    <xsl:sequence select="$leUsed0"/>
	    <xsl:text>&#xA; while leUsed666 = </xsl:text>
	    <xsl:sequence select="$leUsed666"/>
	  </xsl:message>
	</xsl:if>
	<!--* end temporary paranoia *-->
	
	<xsl:variable name="rhs" as="element(alt)"
                      select="head(($leNew0, $leUsed0))"/>
	<xsl:variable name="target" as="element(nonterminal)"
		      select="$rhs/nonterminal[@name=$T/@name][1]"/>
	
	<!--* Build new T. *-->
	<xsl:variable name="T1" as="element()">
	  <xsl:element name="gt:element">
	    <xsl:sequence select="$rhs/parent::rule/@*,
				  $target/@mark (: may override @mark :),
				  $target/preceding-sibling::*,
				  $T,
				  $target/following-sibling::*"/>	    
	  </xsl:element>
	</xsl:variable>

	<xsl:variable name="height" as="xs:integer"
		      select="max(for $n in $T1/descendant::nonterminal
			      return count($n/ancestor::*))"/>
	<xsl:message use-when="false()">
	  <xsl:text>Height of new tree is </xsl:text>
	  <xsl:value-of select="$height"/>
	</xsl:message>
	
	<!--* Recur *-->
	<xsl:sequence select="gt:make-trees(
			      $T1, $acc,
			      ($new except $rhs),
			      (for $e in $used
			      return if (empty($e intersect $rhs))
			      then $e
			      else (),
			      $rhs),
			      $cFails, $options
			      )"/>
      </xsl:when>

      <!--* if the tree is complete, recur. *-->
      <xsl:when test="$T/@name eq $options('start-symbol')
		      and
		      empty($T/descendant::nonterminal
		      [not(@name=$options('pseudoterminals'))])">
	<xsl:message use-when="true()">
	  <xsl:text>gt:make-trees() has completed a tree </xsl:text>
	  <xsl:text>rooted in </xsl:text>
	  <xsl:value-of select="$T/@name"/>
	  <xsl:text> with </xsl:text>
	  <xsl:value-of select="count($T/descendant-or-self::*)"/>
	  <xsl:text> elements, height = </xsl:text>
	  <xsl:value-of select="max(
		      for $D in $T/descendant::*
		      return count($D/ancestor::*)
		      )"/>
	</xsl:message>

	<!--* Recur. *-->
	<xsl:sequence select="gt:make-trees(
			      (), ($acc, $T),
			      $new, $used,
			      $cFails, $options
			      )"/>

      </xsl:when>

      <!--* if the tree is not complete, grow
	  * downwards toward terminals *-->
      <xsl:when test="exists($T/descendant::nonterminal
		      [not(@name=$options('pseudoterminals'))])">
	<xsl:message use-when="false()">
	  <xsl:text>gt:make-trees() growing down. </xsl:text>
	</xsl:message>
	
	<!--* Build new T *-->
	<!--* leResults is new T, separator, and newly used RHS *-->
	<xsl:variable name="leResults" as="element()+">
	  <xsl:apply-templates select="$T" mode="leaf-expansion">
	    <xsl:with-param name="phase" select=" 'pre' "/>
	    <xsl:with-param name="new" as="element(alt)*" tunnel="yes"
			    select="$new"/>
	    <xsl:with-param name="used" as="element(alt)*" tunnel="yes"
			    select="$used"/>
	  </xsl:apply-templates>
	</xsl:variable>
	
	<!--* Extract children and newly used RHS *-->
	<xsl:variable name="T1" as="element(gt:element)"
		      select="gt:extract-elements($leResults)"/>
	<xsl:variable name="newly-used" as="element(alt)*"
		      select="gt:extract-used($leResults)"/>
		
	<!--* Recur. *-->
	<xsl:sequence select="gt:make-trees(
			      $T1, $acc,
			      ($new except $newly-used),
			      (for $e in $used
			      return if (empty($e intersect $newly-used))
			      then $e
			      else (),
			      $newly-used),
			      $cFails, $options
			      )"/>

      </xsl:when>

      <xsl:otherwise>
	<xsl:message terminate="yes">
	  <xsl:text>This turned out not to be </xsl:text>
	  <xsl:text>logically impossible after all.  </xsl:text>
	  <xsl:text>I wonder how?</xsl:text>
	</xsl:message>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:function>

  <xsl:function name="gt:extract-elements" as="element()*">
    <xsl:param name="le" as="element()*"/>
    <xsl:variable name="cSeparator" as="xs:integer"
		  select="gt:find-separator($le)"/>

    <xsl:sequence select="if ($cSeparator gt 0)
			  then subsequence($le, 1, $cSeparator - 1)
			  else ()"/>      
  </xsl:function>
  
  <xsl:function name="gt:extract-used" as="element(alt)*">
    <xsl:param name="le" as="element()*"/>
    
    <xsl:variable name="cSeparator" as="xs:integer"
		  select="gt:find-separator($le)"/>

    <xsl:sequence select="if ($cSeparator gt 0)
			  then subsequence($le, $cSeparator + 1)
			  else ()"/>
  </xsl:function>
  
  <xsl:function name="gt:find-separator" as="xs:integer">
    <xsl:param name="le" as="element()*"/>

    <xsl:variable name="lb" as="xs:boolean*"
		  select="for $e in $le
			  return ($e instance of element(gt:separator))"/>
        
    <xsl:variable name="cSeparator" as="xs:integer?"
		  select="index-of($lb, true())"/>

    <xsl:sequence select="($cSeparator, -1)[1]"/>
  </xsl:function>


  
  <!--****************************************************************
      * Predicates 
      *-->
  
  <!--****************************************************************
      * leaf-expansion mode
      *
      * Depth-first pre- and post-traversal.  First, let's get the
      * movement right.  We have three kinds of node:  ixml terminals,
      * ixml nonterminals, and gt:element elements.
      *
      * . ixml terminals are copied through unchanged.
      * . More generally, any element that has no nonterminal elements
      *   as descendants gets copied through unchanged.
      * . ixml nonterminals are replaced with a RHS.
      * . gt:element nodes get a shallow copy, invoke a right-sibling
      *   traversal of their children, parse the results returned,
      *   and then do a right-sibling call.  This is a way of
      *   simulating a pre- and post-order traversal.
      *
      *-->
  
  <!--* First, a standard template to get the movement right.
      * Different parts of this apply to different kinds of elements;
      * inapplicable parts can be omitted.
      *--> 
  <xsl:template match="dummy-template" mode="leaf-expansion">
    <!--* All of these parameters are tunnel parameters so we can
	* minimize bookkeeping in elements that don't touch them.
	* The three together should always partition the universe of 
	* all RHS.  The parameter $ngused is only an optimization (or
	* intended as such).  It should always include all and
	* only the RHS used by the current element's elder siblings
	* and their descendants; it should be reset to empty for
	* each first child.
	*-->
    <xsl:param name="new" as="element(alt)*" tunnel="yes"/>
    <xsl:param name="used" as="element(alt)*" tunnel="yes"/>
    <xsl:param name="ngused" as="element(alt)*" tunnel="yes"/>

    <!--* (1) First, process children and capture the results in le0. *-->
    <xsl:variable name="le0" as="element()*">
      <xsl:apply-templates select="child::*[1]"
			   mode="leaf-expansion">
	<xsl:with-param name="new" select="$new" tunnel="yes"/>
	<xsl:with-param name="used" select="$used, $ngused" tunnel="yes"/>
	<xsl:with-param name="ngused" select="()" tunnel="yes"/>	
      </xsl:apply-templates>
    </xsl:variable>

    <!--* (2) Parse the results into children and used right-hand 
	* sides. *-->
    
    <xsl:variable name="leNewchildren" as="element()*"
		  select="gt:extract-elements($le0)"/>
    
    <xsl:variable name="leUsed" as="element()*"
		  select="gt:extract-used($le0)"/>

    <!--* sanity check *-->
    <xsl:if test="exists($le0) and empty($leNewchildren)
		  and empty($leUsed)">
      <xsl:message terminate="yes">
	<xsl:text>No separator found, fatal error.  </xsl:text>
	<xsl:text>Find it and fix it.</xsl:text>
	<xsl:text>&#xA;$le0 = </xsl:text>
	<xsl:sequence select="$le0"/>
	<xsl:text>&#xA;$leNewchildren and $leUsed are empty.</xsl:text>
      </xsl:message>
    </xsl:if>

    <!--* (2c) Make the new element with the new children. *-->
    <xsl:copy>
      <xsl:sequence select="@*"/>
      <xsl:sequence select="$leNewchildren"/>
    </xsl:copy>

    <!--* (3) Continue. *-->
    
    <xsl:choose>
      <!--* (3a) Recur to right sibling if you can. *-->
      <xsl:when test="exists(following-sibling::*)">
	<xsl:apply-templates select="following-sibling::*[1]"
			     mode="leaf-expansion">
	  
	  <!--* Trim $new by removing $leUsed. *-->
	  <xsl:with-param name="new" select="$new except $leUsed"/>
	  
	  <!--* If we write ($used except $leUsed), the result will
	      * be in document order.  Our slightly cumbersome
	      * expression tries to avoid that. *-->
	  <xsl:with-param name="used"
			  tunnel="yes"
			  select="for $e in $used
				  return
				  if (empty($e intersect $leUsed))
				  then $e
				  else ()"/>

	  <!--* The same applies to ngused, but this time we append
	      * leUsed at the end of the sequence. *-->
	  <xsl:with-param name="ngused"
			  tunnel="yes"
			  select="for $e in $ngused
				  return
				  if (empty($e intersect $leUsed))
				  then $e
				  else (),
				  $leUsed"/>
	</xsl:apply-templates>
      </xsl:when>
      
      <xsl:otherwise>
	<!--* The result of the xsl:copy above will be gathered up by
	    * the parent, together with the results from all our
	    * left siblings.  Since we are the benjamin, it is our
	    * job to say what was newly used in this generation
	    * and its descendants.
	    *-->
	<xsl:element name="gt:separator"/>
	<xsl:sequence select="for $e in $ngused
			      return
			      if (empty($e intersect $leUsed))
			      then $e
			      else (),
			      $leUsed"/>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>
  
  <!--* Nonterminals do the interesting work.  Let's do them next.
      *--> 
  
  <xsl:template match="nonterminal[not(@name = $pseudoterminals)]"
		mode="leaf-expansion">
    <xsl:param name="new" as="element(alt)*" tunnel="yes"/>
    <xsl:param name="used" as="element(alt)*" tunnel="yes"/>
    <xsl:param name="ngused" as="element(alt)*" tunnel="yes"/>

    <xsl:message use-when="false()">
      <xsl:text>Entering template for reference to nonterminal </xsl:text>
      <xsl:value-of select="@name"/>
      <xsl:text>. &#xA;     </xsl:text>
      <xsl:value-of select="count($new)"/>
      <xsl:text> RHS in $new, </xsl:text>
      <xsl:value-of select="count($used)"/>
      <xsl:text> RHS in $used, </xsl:text>
      <xsl:value-of select="count($ngused)"/>
      <xsl:text> RHS in $ngused: </xsl:text>
      <xsl:sequence select="for $e in $ngused return $e/@id/string()"/>
    </xsl:message>  

    <!--* (1) First, find a rule that applies. *-->
    <!--* To use key() we need the key value. *-->
    <xsl:variable name="name" as="xs:string"
		  select="@name"/>
    <!--* To use key() we also need a node from G, any node will do. *-->
    <xsl:variable name="grammar-node" as="element()"
		  select="($new, $used, $ngused)[1]/root()/ixml"/>
    <!--* Bresaking out the pieces of this calculation to find out
	* where it's going wrong. *-->
    <xsl:variable name="keyed-RHS" as="element(alt)*"
		  select="key('lhs', $name, $grammar-node)"/>
    <xsl:message use-when="false()">
      <xsl:text>Keyed RHS for </xsl:text>
      <xsl:value-of select="$name"/>
      <xsl:text>: &#xA;</xsl:text>
      <xsl:sequence select="$keyed-RHS"/>
      <xsl:text>&#xA;</xsl:text>
    </xsl:message>
    
    <xsl:variable name="new-keyed-RHS" as="element(alt)*"
		  select="$keyed-RHS intersect $new"/>
    
    <xsl:variable name="new-unkeyed-RHS" as="element(alt)*"
		  select="$new[parent::rule/@name eq $name]"/>
    
    <xsl:message use-when="false()">
      <xsl:text>New keyed RHS: </xsl:text>
      <xsl:sequence select="$new-keyed-RHS"/>
      <xsl:text>&#xA;</xsl:text>
      <xsl:text>New unkeyed RHS: </xsl:text>
      <xsl:sequence select="$new-unkeyed-RHS"/>
      <xsl:text>&#xA;</xsl:text>
    </xsl:message>
    
    <xsl:variable name="used-RHS" as="element(alt)*"
		  select="($used, $ngused)[parent::rule/@name = $name]"/>
    <xsl:message use-when="false()">
      <xsl:text>Used RHS: </xsl:text>
      <xsl:sequence select="$used-RHS"/>
      <xsl:text>&#xA;</xsl:text>
    </xsl:message>
    
    <xsl:variable name="rhs" as="element(alt)?"
		  select="head(
			  ((key('lhs', $name, $grammar-node)
			    intersect $new),
			   ($used, $ngused)[parent::rule/@name = $name])
			  )"/>

    <!--* sanity check *-->
    <xsl:if test="empty($rhs)">
      <xsl:message terminate="yes">
	<xsl:text>Reference to undeclared nonterminal </xsl:text>
	<xsl:value-of select="$name"/>
	<xsl:text>, grammar is not clean.&#xA;&#xA;</xsl:text>
      </xsl:message>
    </xsl:if>
    
    <!--* (2) Produce a new gt:element element. *-->
    <!--* To fix:  get the default mark if need be. *-->
    <xsl:element name="gt:element">
      <xsl:sequence select="@*"/>
      <xsl:sequence select="$rhs/*"/>
    </xsl:element>

    <!--* (3) Continue. *-->
    <xsl:variable name="new-ngused" as="element(alt)+"
		  select="for $e in $ngused
			  return
			  if (empty($e intersect $rhs))
			  then $e
			  else (),
			  $rhs"/>
    
    <xsl:message use-when="false()">
      <xsl:text>Preparing to leave template nonterminal </xsl:text>
      <xsl:value-of select="@name"/>
      <xsl:text>. &#xA;     </xsl:text>
      <xsl:value-of select="count($new-ngused)"/>
      <xsl:text> RHS in $new-ngused: </xsl:text>
      <xsl:sequence select="for $e in $new-ngused return $e/@id/string()"/>
    </xsl:message>    
    
    <xsl:choose>
      <!--* (3a) Recur to right sibling if you can. *-->
      <xsl:when test="exists(following-sibling::*)">
	<xsl:apply-templates select="following-sibling::*[1]"
			     mode="leaf-expansion">
	  <xsl:with-param name="new"
			  tunnel="yes"
			  select="$new except $rhs"/>
	  <xsl:with-param name="used"
			  tunnel="yes"
			  select="for $e in $used
				  return
				  if (empty($e intersect $rhs))
				  then $e
				  else ()"/>
	  <xsl:with-param name="ngused"
			  tunnel="yes"
			  select="$new-ngused"/>
	</xsl:apply-templates>
      </xsl:when>
      
      <xsl:otherwise>
	<xsl:element name="gt:separator"/>
	<xsl:sequence select="$new-ngused"/>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>
  
  <!--* gt:element
      *--> 
  <xsl:template match="gt:element[descendant::nonterminal]"
		mode="leaf-expansion">
    <xsl:param name="new" as="element(alt)*" tunnel="yes"/>
    <xsl:param name="used" as="element(alt)*" tunnel="yes"/>
    <xsl:param name="ngused" as="element(alt)*" tunnel="yes"/>

    <xsl:message use-when="false()">
      <xsl:text>Template for gt:element </xsl:text>
      <xsl:value-of select="@name"/>
      <xsl:text> with some descendant nonterminal. &#xA;     </xsl:text>
      <xsl:value-of select="count($new)"/>
      <xsl:text> RHS in $new, </xsl:text>
      <xsl:value-of select="count($used)"/>
      <xsl:text> in $used, </xsl:text>
      <xsl:value-of select="count($ngused)"/>
      <xsl:text> in $ngused. </xsl:text>
    </xsl:message>
    
    <!--* (1) First, process children and capture the results in le0. *-->
    <xsl:variable name="le0" as="element()*">
      <xsl:apply-templates select="child::*[1]"
			   mode="leaf-expansion">
	<xsl:with-param name="new" select="$new" tunnel="yes"/>
	<xsl:with-param name="used" select="$used, $ngused" tunnel="yes"/>
	<xsl:with-param name="ngused" select="()" tunnel="yes"/>	
      </xsl:apply-templates>
    </xsl:variable>
    
    <!--* (2) Parse the results into children and used right-hand 
	* sides. *-->
    
    <xsl:variable name="leNewchildren" as="element()*"
		  select="gt:extract-elements($le0)"/>
    
    <xsl:variable name="leUsed" as="element()*"
		  select="gt:extract-used($le0)"/>

    <!--* sanity check *-->
    <xsl:if test="exists($le0) and empty($leNewchildren)
		  and empty($leUsed)">
      <xsl:message terminate="yes">
	<xsl:text>No separator found, fatal error.  </xsl:text>
	<xsl:text>Find it and fix it.</xsl:text>
	<xsl:text>&#xA;$le0 = </xsl:text>
	<xsl:sequence select="$le0"/>
	<xsl:text>&#xA;$leNewchildren and $leUsed are empty.</xsl:text>
      </xsl:message>
    </xsl:if>

    <!--* (2c) Make the new element with the new children. *-->
    <xsl:copy>
      <xsl:sequence select="@*"/>
      <xsl:sequence select="$leNewchildren"/>
    </xsl:copy>

    <!--* (3) Continue. *-->
    <xsl:variable name="new-ngused" as="element(alt)*"
		  select="for $e in $ngused
			  return
			  if (empty($e intersect $leUsed))
			  then $e
			  else (),
			  $leUsed"/>		  
    
    <xsl:choose>
      <!--* (3a) Recur to right sibling if you can. *-->
      <xsl:when test="exists(following-sibling::*)">
	<xsl:apply-templates select="following-sibling::*[1]"
			     mode="leaf-expansion">
	  
	  <!--* Trim $new by removing $leUsed. *-->
	  <xsl:with-param name="new" tunnel="yes"
			  select="$new except $leUsed"/>
	  
	  <!--* If we write ($used except $leUsed), the result will
	      * be in document order.  Our slightly cumbersome
	      * expression tries to avoid that. *-->
	  <xsl:with-param name="used"
			  tunnel="yes"
			  select="for $e in $used
				  return
				  if (empty($e intersect $leUsed))
				  then $e
				  else ()"/>

	  <!--* The same applies to ngused, but this time we append
	      * leUsed at the end of the sequence. *-->
	  <xsl:with-param name="ngused"
			  tunnel="yes"
			  select="$new-ngused"/>
	</xsl:apply-templates>
      </xsl:when>
      
      <xsl:otherwise>
	<!--* The result of the xsl:copy above will be gathered up by
	    * the parent, together with the results from all our
	    * left siblings.  Since we are the benjamin, it is our
	    * job to say what was newly used in this generation
	    * and its descendants.
	    *-->
	<xsl:element name="gt:separator"/>
	<xsl:sequence select="$new-ngused"/>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <!--* If we are not a nonterminal and have no nonterminal
      * children, we touch nothing, just copy and continue.
      *-->

  <xsl:template match="*[not(descendant-or-self::nonterminal)]
		       | nonterminal[(@name = $pseudoterminals)]"
		mode="leaf-expansion">
    <xsl:param name="ngused" tunnel="yes"/>

    <xsl:message use-when="false()">
      <xsl:text>Template for * with no descendant nonterminal, matching </xsl:text>
      <xsl:value-of select="name(.)"/>
      <xsl:text>. &#xA;     </xsl:text>
      <xsl:value-of select="count($ngused)"/>
      <xsl:text> RHS in $ngused.</xsl:text>
    </xsl:message>
    
    <!--* (1) Copy. *-->
    <xsl:copy-of select="."/>

    <!--* (2) Continue. *-->    
    <xsl:choose>
      <!--* (2a) Recur to right sibling if you can. *-->
      <xsl:when test="exists(following-sibling::*)">
	<xsl:apply-templates select="following-sibling::*[1]"
			     mode="leaf-expansion"/>
      </xsl:when>
      
      <xsl:otherwise>
	<!--* The result of the xsl:copy above will be gathered up by
	    * the parent, together with the results from all our
	    * left siblings.  Since we are the benjamin, it is our
	    * job to say what was newly used in this generation
	    * and its descendants.
	    *-->
	<xsl:element name="gt:separator"/>
	<xsl:sequence select="$ngused"/>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>  



    <!--
    <xsl:choose>
      <xsl:when test="$phase='pre' and exists(child::*)">
	<xsl:apply-templates select="child::*[1]"
			     mode="leaf-expansion">
	  <xsl:with-param name="phase" select=" 'pre' "/>
	</xsl:apply-templates>
      </xsl:when>
      <xsl:when test="$phase='pre'
		      and empty(child::*)
		      and exists(following-sibling::*)">
	<xsl:apply-templates select="following-sibling::*[1]"
			     mode="leaf-expansion">
	  <xsl:with-param name="phase" select=" 'pre' "/>
	</xsl:apply-templates>
      </xsl:when>
      <xsl:when test="$phase='pre'
		      and empty(child::*)
		      and empty(following-sibling::*)">
	<xsl:apply-templates select="parent::*"
			     mode="leaf-expansion">
	  <xsl:with-param name="phase" select=" 'post' "/>
	</xsl:apply-templates>
      </xsl:when>
      
      <xsl:when test="$phase='post'
		      and exists(following-sibling::*)">
	<xsl:apply-templates select="following-sibling::*[1]"
			     mode="leaf-expansion">
	  <xsl:with-param name="phase" select=" 'pre' "/>
	</xsl:apply-templates>
      </xsl:when>
      <xsl:when test="$phase='post'
		      and empty(following-sibling::*)">
	<xsl:apply-templates select="parent::*"
			     mode="leaf-expansion">
	  <xsl:with-param name="phase" select=" 'post' "/>
	</xsl:apply-templates>
      </xsl:when>
    </xsl:choose>
    *-->
    
</xsl:stylesheet>
