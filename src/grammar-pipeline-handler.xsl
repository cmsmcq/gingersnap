<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    version="3.0">

  <!--* simplify-saprg.xsl
      * Ad hoc stylesheet to simplify stack-augmented pseudo-regular
      * grammar for Program grammar.
      *-->

  <!--* Revisions:
      * 2021-01-12 : CMSMcQ : add new parameters to make-rtn;
      *                       re-import eliminate-arc-overlap
      * 2020-12-28 : CMSMcQ : Split several stylesheets into main
      *                       and library modules, to make Saxon stop
      *                       complaining about multiple imports.
      *                       Changed pointers to foo.lib.xsl where
      *                       needed.
      * 2020-12-28 : CMSMcQ : add fsa-to-tclego -to-tcrecipes
      *                       -to-testcases
      * 2020-12-25 : CMSMcQ : add determinize 
      * 2020-12-24 : CMSMcQ : add eliminate-arc-overlap 
      * 2020-12-23 : CMSMcQ : split-literals becomes normalize-terminals 
      * 2020-12-21 : CMSMcQ : keep adding more bricks 
      * 2020-12-19 : CMSMcQ : make this into a pipeline handler; the 
      *                       user writes a pipeline manifest, and we
      *                       interpret it here.  First sketch of the
      *                       idea in mail to SJD 15 Dec 2020.
      * 2020-12-12 : CMSMcQ : made stylesheet, trying to automate what 
      *                       I have been doing by hand.
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->

  <xsl:import href="ixml-grammar-tools.lib.xsl"/> 
  <xsl:import href="range-operations.lib.xsl"/> 

  <!--* annotation *-->
  <xsl:import href="ixml-annotate-pc.lib.xsl"/>
  <xsl:import href="ixml-annotate-gluschkov.lib.xsl"/>
  
  <!--* algebra *-->
  <xsl:import href="rule-substitution.xsl"/>
  <xsl:import href="eliminate-unit-rules.xsl"/>
  <xsl:import href="right-factor.xsl"/>
  <xsl:import href="distribute-seq-over-disj.xsl"/>
  <xsl:import href="ardens-lemma.xsl"/>
  <xsl:import href="simplify-epsilon.xsl"/>
  <xsl:import href="simplify-nested-sequences.xsl"/>
  <xsl:import href="simplify-expressions.xsl"/>
  <xsl:import href="normalize-terminals.lib.xsl"/>
  <xsl:import href="eliminate-arc-overlap.lib.xsl"/>
  <xsl:import href="determinize-ixml-fsa.lib.xsl"/>
  
  <!--* modification *-->
  <xsl:import href="add-final-state-flag.xsl"/>
  
  <!--* deletion *-->
  <xsl:import href="rtn-linkage-removal.xsl"/>
  <xsl:import href="rule-removal.xsl"/>
  <xsl:import href="remove-unreachables.xsl"/>
  <xsl:import href="empty-selfloop-removal.lib.xsl"/>
  <xsl:import href="strip-rtn-attributes.xsl"/>
  
  <!--* derivation *-->
  <xsl:import href="ixml-to-rk-subset.xsl"/>
  <xsl:import href="ixml-to-saprg.lib.xsl"/>
  <xsl:import href="fsa-to-tclego.xsl"/>
  <xsl:import href="tclego-to-tcrecipes.lib.xsl"/>
  <xsl:import href="tcrecipes-to-testcases.lib.xsl"/>
  
  <!--* miscellaneous *-->
  <xsl:import href="relabel.xsl"/>
  <xsl:import href="sort-nonterminals.xsl"/>
  

  <xsl:output method="xml"
	      indent="yes"/>

  <xsl:mode on-no-match="shallow-copy"/>

  <xsl:param name="stepsfile"
	     as="xs:string?"
	     required="no"/>

  <xsl:variable name="base-uri"
		as="xs:string"
		select=" base-uri(/) "/>
  
  <xsl:variable name="steps-doc"
		as="document-node(element(grammar-pipeline))?"
		select="if (exists($stepsfile))
			then doc(resolve-uri($stepsfile, $base-uri))
			else ()"/> 
  

  
  <!--****************************************************************
      * Starting point
      ****************************************************************
      *-->
  <xsl:template match="/">
    <xsl:call-template name="gt:pipeline-handler">
      <xsl:with-param name="grammar" select="."/>
      <xsl:with-param name="steps"
		      select="$steps-doc/grammar-pipeline
			      /(* except desc)"/>
    </xsl:call-template>
  </xsl:template>

  
  <!--****************************************************************
      * Pipeline handler
      ****************************************************************
      *-->

  <xsl:template name="gt:pipeline-handler"
		as="document-node(element(ixml))">
    <xsl:param name="grammar" as="document-node(element(ixml))"/>
    <xsl:param name="steps"   as="element()*"/>

    <xsl:choose>
      <xsl:when test="empty($steps)">
	<xsl:sequence select="$grammar"/>
      </xsl:when>
      <xsl:otherwise>
	<!--* What's next? *-->
	<xsl:variable name="step"
		      as="element()"
		      select="head($steps)"/>

	<xsl:message>Grammar-pipeline handler:  step <xsl:value-of
	select="name($step)"/></xsl:message>
	
	<!--* Perform this step *-->
	<xsl:variable name="newgrammar"
		      as="document-node(element(ixml))">
	  
	  <xsl:choose>

	    <!--* We have reached the point where we need to
		* group these steps.
		*
		* Group 1.  Annotation
		*-->
	    
	    <xsl:when test="$step/self::annotate-pc">
	      <xsl:apply-templates select="$grammar"
				   mode="annotate-pc"/>
	    </xsl:when>
	    
	    <xsl:when test="$step/self::annotate-gl">
	      <xsl:apply-templates select="$grammar"
				   mode="annotate-gl"/>
	    </xsl:when>
	    
	    <!--*
		* Group 2.  Algebraic manipulations:
		* expanding references, right-factoring,
		* Arden's lemma, expression simplification
		*
		* For larger changes, see Deriving new grammars.
		*-->
	    
	    <xsl:when test="$step/self::expand-references">
	      <!--* For this one we have a function, not
		  * apply-templates *-->
	      <xsl:sequence
		  select="gt:expand-references(
			  $grammar,
			  tokenize($step/@nonterminals, '\s+'),
			  if ($step/@keep=('yes', '1', 'true'))
			  then true()
			  else false()
			  )"/>
	    </xsl:when>
	    
	    <xsl:when test="$step/self::eliminate-unit-rules">
	      <xsl:apply-templates select="$grammar"
				   mode="eliminate-unit-rules"/>
	    </xsl:when>
	    
	    <xsl:when test="$step/self::right-factor">
	      <xsl:apply-templates select="$grammar"
				   mode="right-factor">
		<xsl:with-param name="nonterminal" tunnel="yes"
				select="string($step/@rule)"/>
		<xsl:with-param name="follow-state" tunnel="yes"
				select="string($step/@follow-state)"/>
		<xsl:with-param name="where" tunnel="yes"
				select="string($step/@where)"/>
	      </xsl:apply-templates>	      
	    </xsl:when>
	    
	    <xsl:when test="$step/self::distribute-sequence-over-disjunction">
	      <xsl:apply-templates select="$grammar"
				   mode="distribute-sequence-over-disjunction">
		<xsl:with-param name="which" tunnel="yes"
				select="($step/@which/string(), 'first')[1]"/>
	      </xsl:apply-templates>
	    </xsl:when>
	    
	    <xsl:when test="$step/self::ardens-lemma">
	      <xsl:apply-templates select="$grammar"
				   mode="ardens-lemma">
		<xsl:with-param name="nonterminal" tunnel="yes"
				select="string($step/@rule)"/>
	      </xsl:apply-templates>	      
	    </xsl:when>
	    
	    <xsl:when test="$step/self::simplify-epsilon-expressions">
	      <xsl:apply-templates select="$grammar"
				   mode="simplify-epsilon-expressions"/>
	    </xsl:when>
	    
	    <xsl:when test="$step/self::simplify-expressions">
	      <xsl:apply-templates select="$grammar"
				   mode="simplify-expressions"/>
	    </xsl:when>
	    
	    <xsl:when test="$step/self::simplify-nested-sequences">
	      <xsl:apply-templates select="$grammar"
				   mode="simplify-nested-sequences"/>
	    </xsl:when>
	    
	    <xsl:when test="$step/self::normalize-terminals">
	      <xsl:apply-templates select="$grammar"
				   mode="normalize-terminals"/>
	    </xsl:when>
	    
	    <xsl:when test="$step/self::eliminate-arc-overlap">
	      <xsl:apply-templates select="$grammar"
				   mode="arc-overlap"/>
	    </xsl:when>
	    
	    <xsl:when test="$step/self::determinize">
	      <xsl:apply-templates select="$grammar"
				   mode="determinize"/>
	    </xsl:when>


	    <!--* Group 3:  changing the grammar under user control.
		* (See also group 4, removing things.)
		*-->
	    
	    <xsl:when test="$step/self::add-final-flag">
	      <xsl:apply-templates select="$grammar"
				   mode="add-final-flag">
		<xsl:with-param name="final" tunnel="yes"
				select="string($step/@final)"/>
	      </xsl:apply-templates>	      
	    </xsl:when>
	    

	    <!--* Group 4: removing things, selectively or
		* automatically 
		*-->
	    
	    <xsl:when test="$step/self::linkage-removal">
	      <xsl:apply-templates select="$grammar"
				   mode="linkage-removal"/>
	    </xsl:when>

	    <xsl:when test="$step/self::rule-removal">
	      <xsl:apply-templates select="$grammar"
				   mode="rule-removal">
		<xsl:with-param name="delenda" tunnel="yes"
				select="tokenize($step/@delenda, '\s+')"/>
	      </xsl:apply-templates>	      
	    </xsl:when>
	    
	    <xsl:when test="$step/self::remove-unreachables">
	      <xsl:apply-templates select="$grammar"
				   mode="remove-unreachables"/>
	    </xsl:when>
	    
	    <xsl:when test="$step/self::empty-selfloop-removal">
	      <xsl:apply-templates select="$grammar"
				   mode="empty-selfloop-removal"/>
	    </xsl:when>
	    
	    <xsl:when test="$step/self::strip-rtn-attributes">
	      <xsl:apply-templates select="$grammar"
				   mode="strip-rtn-attributes"/>
	    </xsl:when>
	    

	    <!--* Group 5:  Deriving related grammars
		*-->
	    <xsl:when test="$step/self::rk-subset">
	      <xsl:message>
		<xsl:text> @config = </xsl:text>
		<xsl:value-of select="$step/@config"/>
		<xsl:text>&#xA; base uri = </xsl:text>
		<xsl:value-of select="$base-uri"/>
		<xsl:text>&#xA; effective uri = </xsl:text>
		<xsl:value-of select="resolve-uri($step/@config, $base-uri)"/>
	      </xsl:message>
	      <xsl:apply-templates select="$grammar"
				   mode="rk-subset">
		<xsl:with-param name="k" tunnel="yes"
				select="xs:integer($step/@k)"/>
		<xsl:with-param name="config" tunnel="yes"
				select="if ($step/@config eq 'no-config-file') 
					then 'no-config-file'
					else if (string($step/@config) eq '') 
					then 'no-config-file' 					
					else resolve-uri(
					$step/@config,
					$base-uri)"/>
		<xsl:with-param name="starters" tunnel="yes"
				select="tokenize(
					string($step/@starters),
					'\s+')"/>
	      </xsl:apply-templates>	      
	    </xsl:when>
	    
	    <xsl:when test="$step/self::make-rtn">
	      <xsl:message use-when="false()">
		<xsl:text>Fissile:  </xsl:text>
		<xsl:sequence
		    select="tokenize($step/@fissile, '\s+')"/>
	      </xsl:message>	      
	      <xsl:apply-templates select="$grammar"
				   mode="make-rtn">
		<xsl:with-param name="G" tunnel="yes"
				select="$grammar"/>
		<xsl:with-param name="fissile" tunnel="yes"
				select="if (string($step/@fissile) eq '')
					then '#all'
					else tokenize(
					$step/@fissile,
					'\s+')"/>
		<xsl:with-param name="non-fissile" tunnel="yes"
				select="if (string($step/@non-fissile) eq '')
					then '#non-recursive'
					else tokenize(
					$step/@non-fissile,
					'\s+')"/>
		<xsl:with-param name="linkage" tunnel="yes"
				select="if (string($step/@linkage) eq '')
					then '#all'
					else tokenize(
					$step/@linkage,
					'\s+')"/>
		<xsl:with-param name="start" tunnel="yes"
				select="if (string($step/@start) eq '')
					then '#inherit'
					else $step/@start/string()"/>
		<xsl:with-param name="keep-non-fissiles" tunnel="yes"
				select="if (string($step/@keep-non-fissiles) eq '')
					then '#yes'
					else tokenize(
					$step/@keep-non-fissiles,
					'\s+')"/>
	      </xsl:apply-templates>
	    </xsl:when>
	    
	    <xsl:when test="$step/self::fsa-to-tclego">
	      <xsl:apply-templates select="$grammar"
				   mode="fsa-to-tclego"/>
	    </xsl:when>
	    
	    <xsl:when test="$step/self::tclego-to-tcrecipes">
	      <xsl:apply-templates select="$grammar"
				   mode="tclego-to-tcrecipes">
		<xsl:with-param name="coverage" tunnel="yes"
				select="($step/@coverage,
					'arc-final')[1]"/>
		<xsl:with-param name="polarity" tunnel="yes"
				select="($step/@polarity,
					'negative')[1]"/>
	      </xsl:apply-templates>
	    </xsl:when>
	    
	    <xsl:when test="$step/self::tcrecipes-to-testcases">
	      <xsl:apply-templates select="$grammar"
				   mode="tcrecipes-to-testcases"/>
	    </xsl:when>

	    <!--* Group 6:  miscellaneous 
		*-->

	    <xsl:when test="$step/self::relabel">
	      <xsl:apply-templates select="$grammar"
				   mode="relabel">
		<xsl:with-param name="desc" tunnel="yes"
				select="string($step/@newdesc)"/>
	      </xsl:apply-templates>	      
	    </xsl:when>

	    <xsl:when test="$step/self::sort-nonterminals">
	      <xsl:apply-templates select="$grammar"
				   mode="sort-nonterminals"/>
	    </xsl:when>

	    <!--* It would be tempting to try to handle all the
		* steps that don't take options / arguments in
		* a single 'when' element, like this :
		
	    <xsl:when test="name($step) =
			    ('linkage-removal',
			    'distribute-sequence-over-disjunction',
			    'simplify-epsilon-expressions',
			    'empty-selfloop-removal'
			    )">
	      <xsl:apply-templates select="$grammar"
				   mode="{ name($step) }"/>
	   </xsl:when>

                * But 'mode' takes a token; it's not an
		* attribute value template.  So: one by one.
	        *-->
	    
	    <!-- ... -->
	    <xsl:otherwise>
	      <xsl:message>
		<xsl:text>! Unrecognized pipeline step: </xsl:text>
		<xsl:value-of select="name($step)"/>
	      </xsl:message>
	    </xsl:otherwise>
	  </xsl:choose>
	</xsl:variable>

	<!--* Save the result, if requested *-->
	<xsl:if test="exists($step/@save)">
	  <xsl:result-document href="{resolve-uri($step/@save, $base-uri)}">
	    <xsl:sequence select="$newgrammar"/>
	  </xsl:result-document>
	</xsl:if>

      	<!--* Recur *-->
	<xsl:call-template name="gt:pipeline-handler">
	  <xsl:with-param name="grammar" select="$newgrammar"/>
	  <xsl:with-param name="steps" select="tail($steps)"/>
	</xsl:call-template>

      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  
  <!--****************************************************************
      * Simple pipeline functions
      ****************************************************************
      *-->
  <xsl:function name="gt:expand-references"
		as="document-node(element(ixml))">
    <xsl:param name="doc"
	       as="document-node(element(ixml))"/>
    <xsl:param name="queue"
	       as="xs:string*"/>
    <xsl:param name="fKeep"
	       as="xs:boolean"/>

    <xsl:choose>
      <xsl:when test="empty($queue)">
	<xsl:sequence select="$doc"/>
      </xsl:when>
      <xsl:otherwise>
	<!--* What nonterminal are we to expand next? *-->
	<xsl:variable name="n"
		      select="$queue[1]"/>
	<xsl:variable name="new-queue"
		      select="$queue[position() gt 1]"/>

	<!--* Do the expansion. *-->
	<xsl:variable name="result" as="document-node(element(ixml))">	  
	  <xsl:apply-templates select="$doc" mode="inline-nonterminal">
	    <xsl:with-param name="nt" tunnel="yes" select="$n"/>
	    <xsl:with-param name="fKeep" tunnel="yes" select="$fKeep"/>
	  </xsl:apply-templates>
	</xsl:variable>

	<!--* Recur. *-->
	<xsl:sequence
	    select="gt:expand-references($result, $new-queue, $fKeep)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

 
</xsl:stylesheet>
