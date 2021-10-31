<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    default-mode="annotate-gl"
    version="3.0">

  <!--* ixml-annotate-gluschkov.xsl
      * Read ixml.xml grammar, write it out again with some
      * annotations and additions.  Each right-hand side (and
      * each subexpression of a right-hand side) gets attributes
      * specifying the Gluschkov automaton for the expression.
      *
      * Every expression gets an ID to make this work.
      * @gl:first specifies the tokens for possible initial symbols.
      * @gl:last specifies the final tokens (states). 
      * @gl:nullable specifies whether L(E) include the empty string.
      * @follow:X specifies (for each token X) what states (tokens)
      * can follow X.
      *
      * Algorithm is from ABK, "Regular expressions into finite
      * automata", as elaborated for more complicated expressions
      * in Gluschkov.xqm.
      *
      * See ixml-to-rtndot.xsl for a translation to dot to draw the
      * recursive transition network.
      *-->

  <!--* Revisions:
      * 2021-01-30 : CMSMcQ : generate @xml:id not @id
      * 2020-12-28 : CMSMcQ : split into main and module 
      * 2020-12-04 : CMSMcQ : found error in handling of sequences. 
      *                       Fixed (typo in handling option).
      *
      * 2020-11-29 : CMSMcQ : made stylesheet, as XSLT successor to 
      *                       Gluschkov.xqm
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->

  <xsl:mode name="annotate-gl" on-no-match="shallow-copy"/>

  <xsl:variable name="nullable-true"
		as="attribute(gl:nullable)">
    <xsl:attribute name="gl:nullable" select="true()"/>
  </xsl:variable>
  
  <!--****************************************************************
      * Main / starting template
      ****************************************************************
      *-->
  <!--* With a default identity transform, we don't actually need a
      * main starting template.  But we do want one for ixml, to
      * inject a comment to identify the stylesheet.
      *-->
  <xsl:template match="ixml">
    <xsl:copy>
      <xsl:sequence select="@* except @gl:*"/>
      <xsl:attribute name="gt:date" select="current-dateTime()"/>
      <xsl:attribute name="gl:gluschkov" select="'dummy value'"/>
      <xsl:attribute name="follow:followsets" select="'dummy value'"/>


      <xsl:element name="comment">
	<xsl:value-of select="current-dateTime()"/>
	<xsl:text>: ixml-annotate-gluschkov.xsl.</xsl:text>
      </xsl:element>
      <xsl:element name="comment">
	<xsl:text>    Input: </xsl:text>
	<xsl:value-of select="base-uri(/)"/>
      </xsl:element>
      <xsl:element name="comment">
	<xsl:text>    Grammar augmented with Gluschkov automata (@gl:*).</xsl:text>
      </xsl:element>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <!--* Working bottom up.  Basic tokens. *-->
  <xsl:template match="nonterminal | inclusion | exclusion | literal">
    <xsl:variable name="id" select="gt:generate-id(.)"/>    
    <xsl:copy>
      <xsl:sequence select="@* except @gl:*"/>
      <xsl:attribute name="xml:id" select="$id"/>
      <xsl:attribute name="gl:nullable" select="false()"/>
      <xsl:attribute name="gl:first" select="$id"/>
      <xsl:attribute name="gl:last" select="$id"/>
      <xsl:attribute name="follow:{$id}" select=" '' "/>	
      <xsl:sequence select="child::node()"/>
    </xsl:copy>
  </xsl:template>

  <!--* factor is not marked.
      * -factor: terminal; nonterminal; "(", S, alts, ")", S.
      *-->
  
  <!--* sep: factor. Nullability, first, last, and follow all
      * copied from the single child.
      *-->
  <xsl:template match="sep">
    
    <!--* lnChildren is all children of the sep element, 
	* including comments and text nodes. 
	*-->
    <xsl:variable name="lnChildren" as="node()*">
      <xsl:apply-templates/>
    </xsl:variable>
    
    <!--* eFactor is the 'main' child, the grammatical expression.
	* There should be exactly one (and if there isn't, we'll
	* throw a type error).
	*-->
    <xsl:variable name="eFactor" as="node()"
		  select="$lnChildren[gt:fIsexpression(.)]"/>
       
    <xsl:copy>
      <xsl:sequence select="@* except @gl:*"/>
      <xsl:sequence select="$eFactor/@gl:*, $eFactor/@follow:*"/>	
      <xsl:sequence select="$lnChildren"/>
    </xsl:copy>
  </xsl:template>
  
  <!--* option: factor, "?", S.
      * Forces nullability to true, otherwise gets all properties
      * from its single child.
      *-->
  <xsl:template match="option">

    <!--* Structure of this template follows that for sep. *-->
    <!--* lnChildren is all children. *-->
    <xsl:variable name="lnChildren" as="node()*">
      <xsl:apply-templates/>
    </xsl:variable>
    
    <!--* eFactor is the 'main' child. *-->
    <xsl:variable name="eFactor" as="node()"
		  select="$lnChildren[gt:fIsexpression(.)]"/>
       
    <xsl:copy>
      <xsl:sequence select="@* except @gl:*"/>
      <xsl:sequence select="$nullable-true"/>
      <xsl:sequence select="$eFactor/@gl:* except $eFactor/@gl:nullable"/>
      <xsl:sequence select="$eFactor/@follow:*"/>	
      <xsl:sequence select="$lnChildren"/>
    </xsl:copy>
  </xsl:template>
  
  <!--* repeat0: factor, "*", S, sep?.
      * repeat1: factor, "+", S, sep?.
      * This one gets a bit complicated.
      *-->
  <xsl:template match="repeat0 | repeat1">
    <!--* 1.  Some basic setup, things we'll need later. *-->
    <!--* lnChildren is all children. *-->
    <xsl:variable name="lnChildren" as="node()*">
      <xsl:apply-templates/>
    </xsl:variable>
    
    <!--* eFactor is the factor. *-->
    <xsl:variable name="eFactor" as="node()"
		  select="$lnChildren[gt:fIsexpression(.)][1]"/>
    
    <!--* eSep is the separator, if any. *-->
    <xsl:variable name="eSep" as="node()?"
		  select="$lnChildren[self::sep]"/>

    <!--* fFNullable, fSNullable: F, S are nullable? *-->
    <xsl:variable name="fFNullable" as="xs:boolean"
		  select="xs:boolean($eFactor/@gl:nullable) = true()"/>
    <xsl:variable name="fSNullable" as="xs:boolean"
		  select="xs:boolean($eSep/@gl:nullable) = true()"/>

    <!--* lidFFirst is a list of the (IDs of the) last states of eFactor. *-->
    <xsl:variable name="lidFFirst" as="xs:string*"
		  select="tokenize($eFactor/@gl:first,'\s+')
			  [not(normalize-space(.) = '')]"/>

    <!--* lidSFirst is a list of the (IDs of the) last states of eSep. *-->
    <xsl:variable name="lidSFirst" as="xs:string*"
		  select="tokenize($eSep/@gl:first,'\s+')
			  [not(normalize-space(.) = '')]"/>

    <!--* lidFLast is a list of the (IDs of the) last states of eFactor. *-->
    <xsl:variable name="lidFLast" as="xs:string*"
		  select="tokenize($eFactor/@gl:last,'\s+')
			  [not(normalize-space(.) = '')]"/>

    <!--* lidSLast is a list of the (IDs of the) last states of eSep. *-->
    <xsl:variable name="lidSLast" as="xs:string*"
		  select="tokenize($eSep/@gl:last,'\s+')
			  [not(normalize-space(.) = '')]"/>

    <!--* 2.  First set. If factor is nullable, add first of sep. *-->
    <xsl:variable name="lidFirst"
		  as="xs:string*"
		  select="if ($fFNullable)
			  then ($lidFFirst, $lidSFirst)
			  else ($lidFFirst)"/>
    
    <!--* 3.  Last set. If factor is nullable, add last of sep. *-->
    <xsl:variable name="lidLast"
		  as="xs:string*"
		  select="if ($fFNullable)
			  then ($lidFLast, $lidSLast)
			  else ($lidFLast)"/>
    
    <!--* 4.  Follow sets. *-->
    <xsl:variable name="laFollow"
		  as="attribute()*">
      <xsl:choose>
	<xsl:when test="not(sep)">
	  <!--* When there is no separator, for all p in positions(F)
	      * follow(F*,p) = if (p in last(F))
	      *                then follow(F, p) union first(F)
	      *                else follow(F, p)
	      *-->
	  <xsl:for-each select="$eFactor/@follow:*">
	    <xsl:variable name="p" as="xs:string"
			  select="local-name(.)"/>

	    <xsl:attribute name="follow:{$p}"
			   select="if ($p = $lidFLast)
				   then gt:merge((string(.), $lidFFirst))
				   else string(.)"/>
	  </xsl:for-each>
	</xsl:when>
	<xsl:otherwise>
	  <!-- <xsl:message>Repetition in <xsl:value-of
	  select="ancestor::rule/@name"/> ...</xsl:message> -->
	  
	  <!--* When there is a separator, then follow(F*S, p) depends
	      * on where we are and whether factor and sep are nullable.
	      *-->	  
	  <xsl:for-each select="$eFactor/@follow:*, $eSep/@follow:*">
	    <xsl:variable name="p" as="xs:string"
			  select="local-name(.)"/>

	    <!-- <xsl:message>  <xsl:copy-of select="name(.)"/> ...</xsl:message> -->
    
	    <xsl:choose>
	      <!--* p in last(Factor):  merge follow(F,p) with
		  * first(S) and possibly also first(F).	*-->
	      <xsl:when test="$p = $lidFLast">
		<xsl:attribute
		    name="follow:{$p}"
		    select="gt:merge((
			    string(.),
			    $lidSFirst,
			    if ($fSNullable) then $lidFFirst else ()))"
		    />
	      </xsl:when>
	      <!--* p in last(Sep):  merge follow(F,p) with 
		  * first(F) and possibly also first(S).	*-->
	      <xsl:when test="$p = $lidSLast">
		<xsl:attribute
		    name="follow:{$p}"
		    select="gt:merge((
			    string(.),
			    $lidFFirst,
			    if ($fFNullable) then $lidSFirst else ()))"
		    />
	      </xsl:when>
	      <!--* Otherwise, follow(F*S, p) is unchanged from follow(F, p)
		  * or follow(S, p). *-->
	      <xsl:otherwise>
		<xsl:sequence select="."/>
	      </xsl:otherwise>
	    </xsl:choose>
	  </xsl:for-each>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    

    <xsl:copy>
      <xsl:sequence select="@* except @gl:*"/>
      <xsl:sequence select="if (self::repeat0)
			    then $nullable-true 
			    else $eFactor/@nullable"/>
      <xsl:attribute name="gl:first"
		     select="$lidFirst"/>
      <xsl:attribute name="gl:last"
		     select="$lidLast"/>
      <xsl:sequence select="$laFollow"/>
      <xsl:sequence select="$lnChildren"/>
    </xsl:copy>
  </xsl:template>

  <!--* alt does a sequence; everything is complicated. *-->
  <xsl:template match="alt">
    
    <!--* lnChildren is all children of the alt element, 
	* including comments and text nodes. 
	*-->
    <xsl:variable name="lnChildren" as="node()*">
      <xsl:apply-templates/>
    </xsl:variable>
    <xsl:variable name="lnExpressions" as="node()*"
		  select="$lnChildren[gt:fIsexpression(.)]"/>       
    <xsl:copy>
      <xsl:sequence select="@* except @gl:*"/>
      <xsl:attribute
	  name="gl:nullable"
	  select="if (empty($lnExpressions))
		  then true()
		  else if
		  (every $nCh in $lnExpressions
		  satisfies (xs:boolean($nCh/@gl:nullable) = true()))
		  then true()
		  else false()"/>
      <xsl:attribute name="gl:first" select="gt:first-of-seq($lnChildren)"/>
      <xsl:attribute name="gl:last" select="gt:last-of-seq($lnChildren)"/>
      <xsl:sequence select="gt:follow-in-seq($lnChildren)"/>
      <xsl:sequence select="$lnChildren"/>
    </xsl:copy>
    
  </xsl:template>
  
  <!--* alts does a choice; most things are simple. *-->
  <xsl:template match="alts" name="gt:alts">
    
    <!--* lnChildren is all children of the alts element, 
	* including comments and text nodes. 
	*-->
    <xsl:variable name="lnChildren" as="node()*">
      <xsl:apply-templates/>
    </xsl:variable>
    <xsl:variable name="le"
		  as="element()*"
		  select="$lnChildren[self::*][gt:fIsexpression(.)]"/>
       
    <xsl:copy>
      <xsl:sequence select="@* except @gl:*"/>
      <xsl:attribute name="gl:nullable"
		     select="if (empty($lnChildren))
			     then false()
			     else if
			     (some $nCh in $lnChildren
			     satisfies xs:boolean($nCh/@gl:nullable))
			     then true()
			     else false()"/>
      <xsl:attribute name="gl:first"
		     select="gt:merge(for $e in $le return string($e/@gl:first))"/>
      <xsl:attribute name="gl:last"
		     select="gt:merge(for $e in $le return string($e/@gl:last))"/>
      <xsl:sequence select="$le/@follow:*"/>
      <xsl:sequence select="$lnChildren"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="rule">
    <xsl:call-template name="gt:alts"/>    
  </xsl:template>

  <!--****************************************************************
      * Functions
      ****************************************************************
      *-->

  <!--****************************************************************
      * Predicates 
      *-->

  
  <!--****************************************************************
      * Making things
      *-->
  
  <!--* make an ID for a token *-->
  <xsl:function name="gt:generate-id"
		as="xs:string">
    <xsl:param name="e" as="element()"/>
    
    <xsl:choose>
      <xsl:when test="not($e/ancestor::rule)">
	<xsl:value-of select="generate-id($e)"/>
      </xsl:when>
      <xsl:when test="not(gt:fIstoken($e))">
	<xsl:value-of select="generate-id($e)"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:variable name="lnRHS"
		      as="element()*"
		      select="$e/ancestor::rule/descendant::*"/>
	<xsl:variable name="lnTokens"
		      as="element()*"
		      select="$lnRHS[gt:fIstoken(.)]"/>
	<xsl:variable name="lnPrecedingtokens"
		      as="element()*"
		      select="$lnTokens[. &lt;&lt; $e]"/>
	<xsl:variable name="pos"
		      select="1 + count($lnPrecedingtokens)"/>
	<xsl:variable name="nmParent"
		      as="xs:string"
		      select="$e/ancestor::rule/@name/string()"/>
	<xsl:value-of select="concat($nmParent, '_', $pos)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!--* gt:merge(): given a list of strings, tokenize all of them and
      * return the distinct tokens.
      *-->
  <xsl:function name="gt:merge"
		as="xs:string*">
    <xsl:param name="ls" as="xs:string*"/>

    <xsl:variable name="lTokens" as="xs:string*"
		  select="for $s in $ls return tokenize($s, '\s+')
			  [normalize-space() ne '']"/>

    <xsl:sequence select="distinct-values($lTokens)"/>
  </xsl:function>

  <!--****************************************************************
      * Calculations of last sets, first sets, follow sets.
      * Mostly this happens inline in the templates; functions are
      * only used when it takes more than a couple of lines.
      *-->
  
  <!--* if E is a sequence (F, G, ...), and F is not nullable,
      * then first(E) is first(F).
      * If F is nullable, then it's first(F) union first(G, ...)
      *-->
  <xsl:function name="gt:first-of-seq"
		as="xs:string*">
    <xsl:param name="ln" as="node()*"/>
    <xsl:variable name="le" as="element()*"
		  select="$ln[self::*]"/>
    <!--* pass the real work off to a function with an accumulator *-->
    <xsl:sequence select="gt:first-of-seq-aux($le, ())"/>
  </xsl:function>

  <xsl:function name="gt:first-of-seq-aux"
		as="xs:string*">
    <xsl:param name="le" as="element()*"/>
    <xsl:param name="lsAcc" as="xs:string*"/>

    <xsl:choose>
      <xsl:when test="empty($le)">
	<!--* Base case:  we have no elements left in the sequence. 
	    * Return what we've got. 
	    *-->
	<xsl:sequence select="$lsAcc"/>
      </xsl:when>
      <xsl:otherwise>
	<!--* Usual case:  we have at least one element left in the sequence. 
	    * Find its first set, merge with the accumulator, and either
	    * return or recur.
	    *-->
	<xsl:variable name="eThis" as="element()?"
		      select="$le[1]"/>
	<xsl:variable name="lsAcc2" as="xs:string*"
		      select="gt:merge(($lsAcc, $eThis/@gl:first/string()))"/>

	<xsl:choose>
	  <xsl:when test="xs:boolean($eThis/@gl:nullable)">
	    <xsl:sequence select="gt:first-of-seq-aux($le[position() gt 1], $lsAcc2)"/>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:sequence select="$lsAcc2"/>
	  </xsl:otherwise>	  
	</xsl:choose>	
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!--* first() and last() are structurally parallel.
      * If I thought more abstractly, I would use higher-order
      * functions for both of them.
      * But I won't bother for now.
      *-->
  <xsl:function name="gt:last-of-seq"
		as="xs:string*">
    <xsl:param name="ln" as="node()*"/>
    <xsl:variable name="le" as="element()*"
		  select="$ln[self::*]"/>
    <!--* pass the real work off to a function with an accumulator *-->
    <xsl:sequence select="gt:last-of-seq-aux($le, ())"/>
  </xsl:function>

  <xsl:function name="gt:last-of-seq-aux"
		as="xs:string*">
    <xsl:param name="le" as="element()*"/>
    <xsl:param name="lsAcc" as="xs:string*"/>

    <xsl:choose>
      <xsl:when test="empty($le)">
	<!--* Base case:  we have no elements left in the sequence. 
	    * Return what we've got. 
	    *-->
	<xsl:sequence select="$lsAcc"/>
      </xsl:when>
      <xsl:otherwise>
	<!--* Usual case:  we have at least one element left in the sequence. 
	    * Find its last set, merge with the accumulator, and either
	    * return or recur.
	    *-->
	<xsl:variable name="eThis" as="element()?"
		      select="$le[last()]"/>
	<xsl:variable name="lsAcc2" as="xs:string*"
		      select="gt:merge(($lsAcc, $eThis/@gl:last/string()))"/>

	<xsl:choose>
	  <xsl:when test="xs:boolean($eThis/@gl:nullable)">
	    <xsl:sequence select="gt:last-of-seq-aux($le[position() lt last()], $lsAcc2)"/>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:sequence select="$lsAcc2"/>
	  </xsl:otherwise>	  
	</xsl:choose>	
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!--* For any sequence E = (F, G, ...), the follow-set of each
      * position p in last(F) is follow(p, F) union first(G, ...).
      * first(G, ...) differs from first(G) when G is nullable.
      *-->
  <xsl:function name="gt:follow-in-seq"
		as="attribute()*">
    <xsl:param name="ln" as="node()*"/>
    <xsl:variable name="le" as="element()*"
		  select="$ln[self::*][gt:fIsexpression(.)]"/>
    <xsl:sequence select="gt:follow-in-seq-aux($le, ())"/>
  </xsl:function>

  <!--* Auxiliary function with an accumulator *-->
  <xsl:function name="gt:follow-in-seq-aux"
		as="attribute()*">
    <xsl:param name="le" as="element()*"/>
    <xsl:param name="la" as="attribute()*"/>
    
    <xsl:choose>
      <xsl:when test="empty($le)">
	<!--* base case:  no more list, return what we've got *-->
	<xsl:sequence select="$la"/>
      </xsl:when>
      <xsl:otherwise>
	<!--* recursive case:  augment the accumulator, recur *-->
	<!--* remember head and tail *-->
	<xsl:variable name="eHead"
		      as="element()"
		      select="$le[1]"/>
	<xsl:variable name="leTail"
		      as="element()*"
		      select="$le[position() gt 1]"/>
	
	<!--* remember some IDs that depend on head and tail *-->	
	<!--* list of ids in last(eHead) *-->
	<xsl:variable name="lidLastXHead"
		      as="xs:string*"
		      select="gt:last-of-seq($eHead)"/>
	<!--* list of ids in first(leTail) *-->
	<xsl:variable name="lidFirstXTail"
		      as="xs:string*"
		      select="gt:first-of-seq($leTail)"/>
	
	<!--* list of follow:* attributes from head. *-->
	<xsl:variable name="laXHead"
		      as="attribute()*">
	  <xsl:for-each select="$eHead/@follow:*">
	    <!--* pos:  id of this position in expression *-->
	    <xsl:variable name="pos"
			  as="xs:string"
			  select="local-name(.)"/>
	    <xsl:choose>
	      <xsl:when test="$pos = $lidLastXHead">
		<!--* augment the follow set from eHead with the first
		    * set of the remainder of the sequence *-->
		<xsl:attribute name="follow:{$pos}"
			       select="gt:merge( (string(.), $lidFirstXTail) )"/>
	      </xsl:when>
	      <xsl:otherwise>
		<!--* pos is internal, just carry it forward *-->
		<xsl:sequence select="."/>
	      </xsl:otherwise>
	    </xsl:choose>
	  </xsl:for-each>
	</xsl:variable>
	<xsl:sequence select="gt:follow-in-seq-aux($le[position() gt 1], ($la, $laXHead))"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  
</xsl:stylesheet>
