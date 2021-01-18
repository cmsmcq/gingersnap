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

  <!--* fsa-to-tclego-alpha.xsl:  Read ixml.grammar G, write out a set
      * of alpha rules in ixml form.  For details see fsa-to-tclego.xsl
      *
      *-->

  <!--* Revisions:
      * 2021-01-17 : CMSMcQ : Changes while working through tests in
      *                       toys:  g010 etc.  I suspect we are
      *                       wrongly dropping or excluding
      *                       zero-length paths, but first must fix
      *                       type errors.
      * 
      * 2020-12-29 : CMSMcQ : Rework:
      *                       Include arc ID in first step.
      *                       Drop nonterminal.
      *                       Drop gt:ranges from alt.
      * 2020-12-27 : CMSMcQ : make stylesheet as part of fsa-to-tclego 
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->


  <xsl:output method="xml"
	      indent="yes"/>

  <xsl:mode name="alpha" on-no-match="shallow-copy"/>

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


  <!--****************************************************************
      * Main / starting template
      ****************************************************************
      *-->
  <xsl:template match="/">
    <xsl:apply-templates mode="stand-alone-alpha"/>
  </xsl:template>
  
  <xsl:template match="ixml" mode="stand-alone-alpha">
    <xsl:copy>
      <xsl:apply-templates select=".">
	<xsl:with-param name="G" tunnel="yes" select="."/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="ixml">
    <xsl:param name="G" as="element(ixml)" tunnel="yes"
			select="."/>
    <xsl:variable name="ruleStart" as="element(rule)"
		  select="rule[1]"/>
    <xsl:variable name="nmSource" as="xs:string"
		  select="$ruleStart/@name/string()"/>
    
    <xsl:call-template name="find-alpha-paths">
      
      <xsl:with-param name="G" as="element(ixml)"
		      select="."/>
      
      <xsl:with-param name="active-paths" as="element(alt)+">
	<xsl:for-each select="$ruleStart/alt">
	  <xsl:variable name="pos" select="position()"/>
	  <xsl:variable name="nmDest" as="xs:string"
			select="(nonterminal/@name/string(),
				../@name/string())[1]"/>
	  <!--* The alt may be empty and have no destination name.
	      * In that case it marks the $ruleStart as final and we
	      * have a path from that state to itself. It's an empty
	      * path, but it's a path. *-->
	  <xsl:variable name="trace" as="xs:string"
			select="concat(
				$nmSource,
				' . ',
				$pos,
				' / ',
				$nmDest
				)"/>
	  <xsl:copy>
	    <xsl:sequence select="@* except @gt:ranges"/>
	    <xsl:attribute name="gt:from" select="$nmSource"/>
	    <xsl:attribute name="gt:to" select="$nmDest"/>
	    <xsl:attribute name="gt:trace" select="$trace"/>
	    <!--* insert start-state trace *-->
	    <xsl:element name="comment" use-when="$element-trace">
	      <xsl:attribute name="gt:state" select="$nmSource"/>
	      <xsl:attribute name="gt:arc" select="$pos"/>
	      <xsl:value-of select="$trace"/>
	    </xsl:element>
	    <xsl:apply-templates select="* except nonterminal"/>
	    <!-- <xsl:sequence select="*"/> -->
	  </xsl:copy>
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
  <xsl:template name="find-alpha-paths">
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
			  [@gt:to/string() = $lsReached]"/>
    <xsl:variable name="live-paths" as="element(alt)*"
		  select="$active-paths except $dead-paths"/>

    <xsl:choose>
      <xsl:when test="empty($live-paths)">
	<!--* we found no new states.  we must be done. *-->
	<xsl:message use-when="true()">
	  <xsl:text>    find-alpha-paths concluding on round </xsl:text>
	  <xsl:value-of select="$round"/>
	  <xsl:text>, found </xsl:text>
	  <xsl:value-of select="count($lsReached)"/>
	  <xsl:text> nonterminals. </xsl:text>
	</xsl:message>
      </xsl:when>
      <xsl:when test="exists($live-paths)">
	<!--* For each newly found nonterminal, write out one
	    * rule with one or more paths. *-->
	<xsl:for-each-group select="$live-paths"
			    group-by="@gt:to">
	  <xsl:element name="rule">
	    <xsl:attribute name="name"
			   select="concat(
				   'alpha-',
				   current-grouping-key()
				   )"/>
	    
	    <!--* Now write out the paths, up to our budget. *-->
	    <!--* Exactly how many to save depends on our
		* save limit.  Let's hide the logic in a
		* a function.
		*-->
	    <xsl:sequence
		select="gt:take-some(current-group(), $save-limit)"/>

	  </xsl:element>
	</xsl:for-each-group>
	

	<!--* What names are new? *-->
	<xsl:variable name="lsNew" as="xs:string*"
		      select="distinct-values(
			      $live-paths
			      /@gt:to/string()
			      )"/>


	<xsl:message use-when="false()">
	  <xsl:text>find-alpha-paths called with </xsl:text>
	  <xsl:sequence select="count($active-paths)"/>
	  <xsl:text>.  Of these, </xsl:text>
	  <xsl:sequence select="count($live-paths)"/>
	  <xsl:text> are now live and </xsl:text>
	  <xsl:sequence select="count($dead-paths)"/>
	  <xsl:text> dead. </xsl:text>
	</xsl:message>	

	<!--* Extend the live paths *-->	  
	<xsl:variable name="extended-paths" as="element(alt)*">
	  <!--* For each path in extended paths, extend it. *-->
	  <!--* First group by follow state, so we can limit
	      * ourselves to $extension-limit per state.
	      *-->
	  <xsl:for-each-group select="$live-paths"
			      group-by="@gt:to">
	    
	    <xsl:variable name="paths-to-extend"
			  as="element(alt)*"
			  select="gt:take-some(current-group(),
				  $extension-limit)"/>
	    
	    <xsl:for-each select="$paths-to-extend">
	      <xsl:variable name="eThis-path" as="element(alt)"
			    select="."/>
	      <xsl:variable name="nmJoin" as="xs:string?"
			    select="@gt:to/string()"/>
	      <xsl:variable name="eNextrule" as="element(rule)?"
			    select="$G/rule[@name eq $nmJoin]"/>

	      <xsl:for-each select="$eNextrule/alt[nonterminal]
				    [not(nonterminal/@name
				    = ($lsReached, $lsNew))]">
		<!--* prepare the trace element to replace the
		    * final nonterminal in this path *-->
		<xsl:variable name="pos" select="position()"/>
		<xsl:variable name="arc" select="."/>
		<xsl:variable name="nmDest" as="xs:string"
			      select="nonterminal/@name/string()"/>
		
		<xsl:variable name="eTrace" as="element(comment)"
			      use-when="$element-trace">
		  <xsl:element name="comment">
		    <xsl:attribute name="gt:state" select="$nmJoin"/>
		    <xsl:attribute name="gt:arc" select="$pos"/>
		    <xsl:value-of
			select="concat($nmJoin, ' . ', $pos)"/>
		  </xsl:element>
		</xsl:variable>
		<xsl:variable name="eTrace" as="element(comment)?"
			      use-when="not($element-trace)"
			      select="()"/>
		
		<!--* The new path is the old one (minus the
		    * nonterminal), plus the trace, plus the
		    * current arc, minus the nonterminal.
		    *-->
		<xsl:element name="alt">
		  <xsl:sequence
		      select="$eThis-path
			      /(@* except (@gt:trace, @gt:to))"/>
		  <xsl:attribute name="gt:to" select="$nmDest"/>
		  <xsl:attribute name="gt:trace"
				 select="concat(
					 $eThis-path/@gt:trace,
					 ' . ', $pos,
					 ' / ', $nmDest
					 )"/>
		  <xsl:sequence
		      select="$eThis-path/(* except nonterminal),
			      $eTrace"/>
		  <xsl:apply-templates
		      select="$arc/(* except nonterminal)"/>
		</xsl:element>	      
	      </xsl:for-each>

	    </xsl:for-each>
	  </xsl:for-each-group>
	</xsl:variable>

	<!--* Recur *-->
	<xsl:message use-when="false()">
	  <xsl:text>find-alpha-paths (round </xsl:text>
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
	<xsl:call-template name="find-alpha-paths">	  
	  <xsl:with-param name="G" select="$G"/>
	  <xsl:with-param name="active-paths" select="$extended-paths"/>	  
	  <xsl:with-param name="lsReached" select="$lsReached, $lsNew"/>
	  <xsl:with-param name="round" select="$round + 1"/>
	  
	</xsl:call-template>
      </xsl:when>
    </xsl:choose>
  </xsl:template>  
  

  <!--****************************************************************
      * Functions
      ****************************************************************
      *-->

  <!--* gt:take-some($seq, $n): return $n items from $seq (or as
      * many as you can).  Take a random selection if possible, and
      * if not, then fake it.
      *-->
  <xsl:function name="gt:take-some" as="item()*">
    <xsl:param name="seq" as="item()*"/>
    <xsl:param name="n" as="xs:integer"/>
    
    <xsl:variable name="c" as="xs:integer"
		  select="count($seq)"/>
    <xsl:variable name="r" as="xs:integer"
		  select="$c idiv $n"/>
    
    <xsl:message use-when="false()">
      <xsl:text>function gt:take-some():  </xsl:text>
      <xsl:text>seq length c = </xsl:text>
      <xsl:value-of select="$c"/>
      <xsl:text>, n = </xsl:text>
      <xsl:value-of select="$n"/>
      <xsl:text>, r = </xsl:text>
      <xsl:value-of select="$r"/>
    </xsl:message>
    
    <xsl:choose>
      <xsl:when test="$n eq 0">
	<!--* limit is set to 0, meaning no limit *-->
	<xsl:sequence select="$seq"/>
      </xsl:when>
      
      <xsl:when test="$c le $n">
	<!--* limit is more than we have, take all *-->
	<xsl:sequence select="$seq"/>
      </xsl:when>
      
      <xsl:when test="true()" use-when="false()">
	<!--* We would like a random or systematic selection, but
	    * in case of doubt, we can do the simplest thing
	    * that could possibly work. *-->
	<xsl:sequence select="$seq[position() le $n]"/>
      </xsl:when>
      
      <xsl:when test="true()"
	  use-when="function-available('random-number-generator')">
	<!--* XPath 3.1 defines a random number generator.  If we
	    * have it, let's use it.  1712 is an arbitrarily chosen
	    * number without occult significance (time of day when 
	    * I first wrote this expression).  Change it if you like.
	    *-->
	<xsl:variable name="rng" as="map(*)"
		      select="random-number-generator(1712)"/>
	<xsl:sequence
	    select="subsequence($rng('permute')($seq), 1, $n)"/>
      </xsl:when>
      
      <xsl:when test="$r lt 2"
	  use-when="not(function-available('random-number-generator'))">
	<!--* We have to take at least half of the sequence.
	    * Take either the first n or the last n.
	    *-->
	<xsl:choose>
	  <xsl:when test="($c mod 2) eq 0">
	    <xsl:sequence select="$seq[position() le $n]"/>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:sequence select="$seq[position() gt ($c - $n)]"/>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:when>
      <xsl:otherwise 
	  use-when="not(function-available('random-number-generator'))">
	<!--* take every rth item *-->
	<xsl:sequence select="$seq[(position() mod $r) eq 0]"/> 
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  

  <!--****************************************************************
      * Predicates 
      *-->    


  
      
</xsl:stylesheet>
