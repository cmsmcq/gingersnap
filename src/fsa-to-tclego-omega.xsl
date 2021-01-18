<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    exclude-result-prefixes="xs gl rtn follow"
    default-mode="omega"
    version="3.0">

  <!--* fsa-to-tclego-omega.xsl:  Read ixml.grammar G, write out a set
      * of omega rules in ixml form.  For details see fsa-to-tclego.xsl
      *
      *-->

  <!--* Revisions:
      * 2021-01-17 : CMSMcQ : Run some simple tests, make fixes
      * 2020-12-29 : CMSMcQ : Rework to remove nonterminal from paths
      * 2020-12-27 : CMSMcQ : make stylesheet by copying 
      *                       fsa-to-tclego-alpha and reversing the
      *                       logic
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->


  <xsl:output method="xml"
	      indent="yes"/>

  <xsl:mode name="omega" on-no-match="shallow-copy"/>

  <!--* Static variable to allow me to shift implementation strategy
      * without deleting things and losing the ability to shift
      * back.
      *-->
  <!--* save-limit:  how many paths to save, from q0 to q?  This
      * determines how many paths to q will be written out.
      * 0 = unlimited
      *-->
  <xsl:variable name="save-limit" as="xs:integer" static="yes"
		select="2"/>
  <!--* extension-limit:  how many paths to extend past q?  This
      * determines how many paths to q will be extended.  The
      * paths to extend are selected independently of the paths
      * to save.
      * 0 = unlimited
      *-->
  <xsl:variable name="extension-limit" as="xs:integer" static="yes"
		select="1"/>
  
  <!--* element-trace:  use elements to trace states? *-->
  <xsl:variable name="element-trace" as="xs:boolean" static="yes"
		select="false()"/>

  <!--* seed 1712 from time of day when I wrote this statement *--> 
  <xsl:variable
      name="random"
      as="map(*)" 
      select="random-number-generator(1712)"
      use-when="function-available('random-number-generator')"/>
  <!--* $random('number'): double such that 0 <= n < 1
      * $random('next'): function returning random number generator
      * $random('permute'): function to accept sequence and permute
      * it.
      *-->

  <!--****************************************************************
      * Main / starting template
      ****************************************************************
      *-->
  <xsl:template match="/">
    <xsl:apply-templates mode="stand-alone-omega"/>
  </xsl:template>
  
  <xsl:template match="ixml" mode="stand-alone-omega">
    <xsl:copy>
      <xsl:apply-templates select=".">
	<xsl:with-param name="G" tunnel="yes" select="."/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="ixml">
    <xsl:variable name="G" as="element(ixml)" select="."/>
  
      <!--* We start our work with the final states, and work
	  * backwards. Final states have an empty RHS.
	  * N.B. ixml does not guarantee that we have any
	  * final states, so $ruleStart may be empty.
	  *-->
    <xsl:variable name="ruleStart" as="element(rule)*"
		  select="rule
			  [alt[empty(* except comment)]]"/>

    <xsl:if test="empty($ruleStart)">
      <xsl:message>
	<xsl:text>    N.B. This FSA has no final states.</xsl:text>
	<xsl:text>&#xA;    The language it recognizes is </xsl:text>
	<xsl:text>the empty set.</xsl:text>
      </xsl:message>
    </xsl:if>
    
    <xsl:call-template name="find-omega-paths">
      
      <xsl:with-param name="G" as="element(ixml)"
		      select="$G"/>
      
      <xsl:with-param name="active-paths" as="element(alt)*">
	<xsl:for-each select="$ruleStart">
	  <xsl:variable name="nmDest" as="xs:string"
			select="@name/string()"/>

	  <xsl:variable name="leIncoming" as="element(alt)*"
			select="$G/rule/alt
				[nonterminal/@name eq $nmDest]"/>

	  <xsl:message use-when="false()">
	    <xsl:text>nmDest = </xsl:text>
	    <xsl:value-of select="$nmDest"/>
	    <xsl:text>, found </xsl:text>
	    <xsl:value-of select="count($leIncoming)"/>
	    <xsl:text> incoming arcs.</xsl:text>
	  </xsl:message>
	  
	  <xsl:for-each select="$leIncoming">
	    <xsl:variable name="pos"
			  select="1 + count(preceding-sibling::alt)"/>
	    <xsl:variable name="nmSource" as="xs:string"
			  select="parent::rule/@name/string()"/>
	    <xsl:copy>
	      <xsl:sequence select="@* except @gt:ranges"/>
	      <!--* insert state trace *-->
	      <xsl:attribute name="gt:from"
			     select="$nmSource"/>
	      <xsl:attribute name="gt:to" select="$nmDest"/>
	      <xsl:attribute name="gt:trace"
			     select="concat(
				     $nmSource,
				     ' . ',
				     $pos,
				     ' / ',
				     $nmDest
				     )"/>
	      <xsl:element name="comment" use-when="$element-trace">
		<xsl:attribute name="gt:state" select="$nmDest"/>
		<xsl:attribute name="gt:arc" select="$pos"/>
		<xsl:value-of select="concat(
				     $nmSource,
				     ' . ',
				     $pos
				     )"/>
	      </xsl:element>
	      <xsl:apply-templates select="* except nonterminal"/>
	      <!-- <xsl:sequence select="*"/> -->
	      <xsl:element name="comment" use-when="$element-trace">
		<xsl:attribute name="gt:state" select="$nmDest"/>
		<xsl:value-of select="$nmDest"/>
	      </xsl:element>
	    </xsl:copy>
	  </xsl:for-each>

	  <!--* if $leIncoming is empty, we have no arcs naming
	      * this $ruleStart state as their target.  So our
	      * only path is going to be the empty path.
	      *-->
	  <xsl:for-each select="alt[empty(* except comment)]">
	    <xsl:variable name="pos"
			  select="1 + count(preceding-sibling::alt)"/>
	    <xsl:copy>
	      <xsl:sequence select="@* except @gt:ranges"/>
	      <!--* insert state trace *-->
	      <xsl:attribute name="gt:from"
			     select="$nmDest"/>
	      <xsl:attribute name="gt:to" select="$nmDest"/>
	      <xsl:attribute name="gt:trace"
			     select="concat(
				     $nmDest,
				     ' . ',
				     $pos,
				     ' / ',
				     $nmDest
				     )"/>
	      <xsl:element name="comment" use-when="$element-trace">
		<xsl:attribute name="gt:state" select="$nmDest"/>
		<xsl:attribute name="gt:arc" select="$pos"/>
		<xsl:value-of select="concat(
				     $nmDest,
				     ' . ',
				     $pos
				     )"/>
	      </xsl:element>
	      <xsl:apply-templates select="* except nonterminal"/>
	      <!-- <xsl:sequence select="*"/> -->
	      <xsl:element name="comment" use-when="$element-trace">
		<xsl:attribute name="gt:state" select="$nmDest"/>
		<xsl:value-of select="$nmDest"/>
	      </xsl:element>
	    </xsl:copy>
	  </xsl:for-each>

	</xsl:for-each>
      </xsl:with-param>
		      
      <xsl:with-param name="lsReached" as="xs:string*"
		      select="()"/>
      
    </xsl:call-template>

  </xsl:template>

  <xsl:template match="comment"/>
  <xsl:template match="text()"/>

  <!--****************************************************************
      * Templates
      ****************************************************************
      *-->
  <xsl:template name="find-omega-paths">
    <xsl:param name="G" as="element(ixml)" select="."/>
    <xsl:param name="active-paths" as="element(alt)*" required="yes"/>
    <xsl:param name="lsReached" as="xs:string*" required="yes"/>
    <xsl:param name="round" as="xs:integer" select="1"/>    

    <!--* As input we have a list of active paths and a list of
	* states we have already found.  
	*
	* Our job:  identify which of the active paths have found new
	* nonterminals.  If none did so, we are done; stop.  Otherwise, 
	* write out the ones that did, add the names of the new
	* nonterminals to lsReached, extend the active paths that
	* found new states, and recur.
	*-->

    <xsl:variable name="dead-paths" as="element(alt)*"
		  select="$active-paths
			  [@gt:from/string() = $lsReached]"/>
    <xsl:variable name="live-paths" as="element(alt)*"
		  select="$active-paths except $dead-paths"/>

    <xsl:message use-when="false()">
      <xsl:text>find-omega-paths called: round </xsl:text>
      <xsl:value-of select="$round"/>
      <xsl:text>, </xsl:text>
      <xsl:value-of select="count($active-paths)"/>
      <xsl:text> active paths, </xsl:text>
      <xsl:value-of select="count($lsReached)"/>
      <xsl:text> nonterminals reached. </xsl:text>
      <xsl:value-of select="count($live-paths)"/>
      <xsl:text> live paths, </xsl:text>
      <xsl:value-of select="count($dead-paths)"/>
      <xsl:text> dead paths. </xsl:text>
    </xsl:message>

    <xsl:choose>
      <xsl:when test="empty($live-paths)">
	<!--* we found no new states.  we must be done. *-->
	<xsl:message use-when="true()">
	  <xsl:text>    find-omega-paths concluding on round </xsl:text>
	  <xsl:value-of select="$round"/>
	  <xsl:text>, found </xsl:text>
	  <xsl:value-of select="count($lsReached)"/>
	  <xsl:text> nonterminals. </xsl:text>
	</xsl:message>
      </xsl:when>
      <xsl:otherwise>
	<!--* For each newly found nonterminal, write out one
	    * rule with one or more paths. *-->
	<xsl:for-each-group select="$live-paths"
			    group-by="@gt:from">
	  
	  <xsl:message use-when="false()">
	    <xsl:text>    saving paths from state </xsl:text>
	    <xsl:value-of select="current-grouping-key()"/>
	    <xsl:text>.  There are </xsl:text>
	    <xsl:value-of select="count(current-group())"/>
	    <xsl:text> paths in the group. </xsl:text>
	  </xsl:message>
	  
	  <xsl:element name="rule">
	    <xsl:attribute name="name"
			   select="concat(
				   'omega-',
				   current-grouping-key()
				   )"/>
	    
	    <!--* Now write out the paths, up to our budget. *-->

	    <!--* If we have no save limit, write them all out *-->
	    <xsl:sequence
		use-when="$save-limit eq 0"
		select="current-group()"/>
	    
	    <!--* If we have a save limit, we should probably take
		* a random selection, or every nth item. But for now,
		* let's do the simplest thing that could possibly
		* work. *-->	    
	    <xsl:sequence
		use-when="false() and $save-limit gt 0"
		select="current-group()[position() le $save-limit]"/>
	    
	    <!--* XPath 3.1 defines a random number generator. Let's 
		* use it. *-->
	    <xsl:sequence
		use-when="$save-limit gt 0
			  and
			  function-available('random-number-generator')"
		select="$random('permute')(current-group())
			[position() le $save-limit]"/>

	    <!--* Saxon HE doesn't support it, though.  Let's fake
		* it. *-->
	    <xsl:sequence
		use-when="$save-limit gt 0
			  and
			  not(function-available('random-number-generator'))"
		select="gt:take-some(current-group(), $save-limit)"/>

	  </xsl:element>
	</xsl:for-each-group>
	
	<!--* What names are new? *-->
	<xsl:variable name="lsNew" as="xs:string*"
		      select="distinct-values(
			      $live-paths/@gt:from/string()
			      )"/>

	<xsl:message use-when="false()">
	  <xsl:text>    lsNew has </xsl:text>
	  <xsl:sequence select="count($lsNew)"/>
	  <xsl:text> names. </xsl:text>
	</xsl:message>	

	<!--* Extend the live paths *-->	  
	<xsl:variable name="extended-paths" as="element(alt)*">
	  <!--* For each path in extended paths, extend it. *-->
	  <!--* First group by initial state in the path, so we can 
	      * limit ourselves to $extension-limit per state.
	      *-->
	  <xsl:for-each-group select="$live-paths"
			      group-by="@gt:from">

	    <xsl:variable name="nmJoint" as="xs:string"
			  select="string(current-grouping-key())"/>
	    <xsl:variable name="leIncoming" as="element(alt)*"
			  select="$G/rule/alt
				  [nonterminal/@name
				  eq
				  current-grouping-key()]" />
	    
	    <xsl:variable name="paths-to-extend"
			  as="element(alt)*"
			  select="current-group()"
			  use-when="$extension-limit eq 0"/>
	    <xsl:variable name="paths-to-extend"
			  as="element(alt)*"
			  select="$random('permute')(current-group())
				  [position() le $extension-limit]"
			  use-when="$extension-limit gt 0
				    and
				    function-available('random-number-generator')  
 				    "/>	    
	    <xsl:variable name="paths-to-extend"
			  as="element(alt)*"
			  select="gt:take-some(current-group(), $extension-limit)"
			  use-when="$extension-limit gt 0 
				    and
				    not(function-available('random-number-generator')) 
				    "/>
	    
	    <xsl:message use-when="false()">
	      <xsl:text>For join-state </xsl:text>
	      <xsl:value-of select="$nmJoint"/>
	      <xsl:text> there are </xsl:text>
	      <xsl:value-of select="count(current-group())"/>
	      <xsl:text> paths, of which we will extend </xsl:text>
	      <xsl:value-of select="count($paths-to-extend)"/>
	      <xsl:text> paths.  We have found </xsl:text>
	      <xsl:value-of select="count($leIncoming)"/>
	      <xsl:text> incoming arcs, of which </xsl:text>
	      <xsl:value-of
		  select="count($leIncoming[not(parent::rule/@name =
			  ($lsReached, $lsNew))])"/>
	      <xsl:text> appear to be new.</xsl:text>
	    </xsl:message>
	    
	    <xsl:for-each select="$paths-to-extend">
	      <xsl:variable name="eThis-path" as="element(alt)"
			    select="."/>

	      <xsl:for-each select="$leIncoming
				    [not(parent::rule/@name
				    = ($lsReached, $lsNew))]">
		<!--* for each path to extend and each incoming arc
		    * that comes from a new state, write a path.
		    *-->
		<!--* prepare the trace element to replace the
		    * final nonterminal in this path *-->
		<xsl:variable name="nmNew-from" as="xs:string"
			      select="parent::rule/@name/string()"/>
		<xsl:variable name="pos"
			      select="1 + count(preceding-sibling::alt)"/>
		<xsl:variable name="arc" select="."/>
		
		<xsl:variable name="eTrace" as="element(comment)"
			      use-when="$element-trace">
		  <xsl:element name="comment">
		    <xsl:attribute name="gt:state" select="$nmNew-from"/>
		    <xsl:attribute name="gt:arc" select="$pos"/>
		    <xsl:value-of select="concat(
					  $nmNew-from,
					  ' . ',
					  $pos
					  )"/>
		  </xsl:element>
		</xsl:variable>
		
		<xsl:variable name="eTrace" as="element(comment)?"
			      use-when="not($element-trace)"
			      select="()"/>
		
		<!--* The new path is the old one, preceded by the 
		    * trace and the current arc (minus nonterminal).
		    *-->
		<xsl:element name="alt">
		  <xsl:sequence select="$eThis-path
					/(@* except @gt:trace)"/>
		  <xsl:attribute name="gt:from"
				 select="$nmNew-from"/>
		  <xsl:attribute name="gt:to"
				 select="$eThis-path/@gt:to"/>
		  <xsl:attribute name="gt:trace"
				 select="concat(
					 $nmNew-from, ' . ', $pos,
					 ' / ', 
					 $eThis-path/@gt:trace
					 )"/>
		  <xsl:sequence select="$eTrace"/>
		  <xsl:apply-templates select="$arc/(* except nonterminal)"/>
		  <xsl:sequence select="$eThis-path/* "/>
		</xsl:element>	      
	      </xsl:for-each>

	    </xsl:for-each>
	  </xsl:for-each-group>
	</xsl:variable>

	<!--* Recur *-->
	<xsl:message use-when="false()">
	  <xsl:text>find-omega-paths (round </xsl:text>
	  <xsl:value-of select="$round"/>
	  <xsl:text>) recurring.  Found </xsl:text>
	  <xsl:value-of select="count($lsNew)"/>
	  <xsl:text> new nonterminals (</xsl:text>
	  <xsl:value-of use-when="false()" select="string-join($lsNew, ', ')"/>
	  <xsl:text>), we have </xsl:text>
	  <xsl:value-of select="count($extended-paths)"/>
	  <xsl:text> active paths and </xsl:text>
	  <xsl:value-of select="count(($lsReached, $lsNew))"/>
	  <xsl:text> states found. </xsl:text>
	</xsl:message>
	<xsl:call-template name="find-omega-paths">	  
	  <xsl:with-param name="G" select="$G"/>
	  <xsl:with-param name="active-paths" select="$extended-paths"/>	  
	  <xsl:with-param name="lsReached" select="$lsReached, $lsNew"/>
	  <xsl:with-param name="round" select="$round + 1"/>
	</xsl:call-template>
      </xsl:otherwise>
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

