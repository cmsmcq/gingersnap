<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    default-mode="make-rtn"
    version="3.0">

  <!--* ixml-to-saprg.xsl
      * Read ixml.xml grammar G which recognizes L(G).  G must be
      * Gluschkov-annotated.  Write out a related grammar G' as an
      * SAPRG: a stack-augmented pseudo-regular grammar in which each
      * 'expanded' nonterminal is replaced by a set of new nonterminals,
      * one for each basic token in its right-hand side plus one
      * start state and one final state.
      *
      * It's pseudo-regular because selected nonterminals are treated
      * as pseudo-terminals and not expanded. (By default:  all
      * non-recursive nonterminals; keeps the result smaller and easier 
      * to understand).  It's stack-augmented because we add @rtn:stack
      * attributes to recursive nonterminals to record required push
      * and pop actions for a stack automaton.
      *
      * When the rtn:stack attributes are attended to, the output 
      * describes a stack automaton which recognizes L(G).
      *
      * When the rtn:stack attributes are ignored, the output is a
      * pseudo-regular grammar G' such that L(G') is the R_0 regular
      * superset of L(G).
      *
      * Note that since pseudo-terminal definitions are left untouched
      * G' will be a mixture of pseduo-regular rules of the form (t, Q)
      * or {{nil}, Q) and normal CFG rules.
      *-->

  <!--* Revisions:
      * 2022-02-19 : CMSMcQ : use rtn:item labels if we have them
      * 2021-01-30 : CMSMcQ : use @xml:id not @id
      * 2021-01-27 : CMSMcQ : use = not eq for some comparisons 
      * 2021-01-17 : CMSMcQ : supply epsilon transition from N_0 to
      *                       N_f if rule as a whole is nullable
      *                       (list of last states omits N_0).
      * 2021-01-12 : CMSMcQ : revise parameters again 
      * 2021-01-01 : CMSMcQ : revise parameters 
      * 2020-12-28 : CMSMcQ : split into main and module to make Saxon 
      *                       stop complaining about multiple import 
      * 2020-12-27 : CMSMcQ : suppress hi-mom message, becoming tedious 
      * 2020-12-23 : CMSMcQ : stop suppressing @gt:*, we need to keep
      *                       @gt:ranges
      * 2020-12-20 : CMSMcQ : define default mode, so I can integrate 
      *                       this into the pipeline handler
      * 2020-12-06 : CMSMcQ : made stylesheet, trying to automate what 
      *                       I have been doing by hand.
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->
  
  <xsl:mode name="make-rtn" on-no-match="shallow-copy"/>

  <!--* fissile: which nonterminals should be broken out?
      * Either '#all' (meaning everything not marked non-fissile)
      * or a list of names.
      * Default is:  #all.
      *-->
  <xsl:param name="fissile" as="xs:string*"
	     select=" '#all' "/>

  <!--* non-fissile: which nonterminals should be treated as
      * pseudo-terminals and NOT be broken out?
      * Either '#non-recursive' (relying on @gt:recursive marking)
      * or '#none' (meaning all nonterminals are fissile)
      * or a list of names (for hand-selected pseudo-terminals)
      * Default is:  #non-recursive.
      *-->
  <xsl:param name="non-fissile" as="xs:string*"
	     select=" '#non-recursive' "/>

  <!--* linkage: What external linkage rules should be injected?
      * In a mixed grammar, every fissile nonterminal N needs linkage
      * rules to make N accept any sequence beginning with N_0 and
      * ending with N_f.  But these linkage rules get in the way in
      * other scenarios, so for pure FSAs no linkage rules are issued.
      * In some cases, the user may wish to specify exactly which
      * nonterminals get linkage rules.
      * 
      * The possible values are:
      * '#none' (meaning no linkage rules at all)
      * list of names (meaning linkage rules for those names only;
      * typically there will just be one
      * '#all' (meaning all fissile nonterminals get linkage)
      *
      * Default is (for backward compatibility):  #all.
      *-->
  <xsl:param name="linkage" as="xs:string*"
	     select=" '#all' "/>

  <!--* start: what is the start symbol of the new grammar?
      *
      * The expected values are:
      * nothing or '#inherit':  do nothing special.  (In mixed
      *     grammars, that means the old start symbol remains.
      *     In pure FSAs (linkage='#none'), that means its N_0
      *     state becomes the start symbol.
      * a name N:  make the N_0 start state of nonterminal N the
      *     start symbol of the output grammar.
      *-->
  <xsl:param name="start" as="xs:string?"
	     select=" '#inherit' "/>

  <!--* keep-non-fissiles: should non-fissile nonterminals be kept
      * or dropped?
      *
      * The expected values are:
      * '#yes' means yes, keep all non-fissile nonterminals
      * '#no' means drop them all
      * a list of names means keep the ones named, drop others.
      *-->
  <xsl:param name="keep-non-fissiles" as="xs:string*"
	     select=" '#yes' "/>

  
  <!--****************************************************************
      * Main / starting template
      ****************************************************************
      *-->
  <!--* With a default identity transform, we don't actually need a
      * main starting template.  But we do want one for ixml, to
      * inject a comment to identify the stylesheet.
      *-->
  <xsl:template match="ixml">
    <xsl:param name="fissile" as="xs:string*" tunnel="yes"
	       select="$fissile"/>
    <xsl:param name="non-fissile" as="xs:string*" tunnel="yes"
	       select="$non-fissile"/>
    <xsl:param name="linkage" as="xs:string*" tunnel="yes"
	       select="$linkage"/>
    <xsl:param name="start" as="xs:string?" tunnel="yes"
	       select="$start"/>
    <xsl:param name="keep-non-fissiles" as="xs:string*" tunnel="yes"
	       select="$keep-non-fissiles"/>
    
    <xsl:variable name="G" as="element(ixml)" select="."/>

    <xsl:if test="false()">
      <xsl:message>Yow!  Are we having fun yet?  I think <xsl:sequence
      select="$fissile"/> is fissile!</xsl:message>
      <xsl:message>What's more,  I think <xsl:sequence
      select="$non-fissile"/> is non-fissile!</xsl:message>
    </xsl:if>
    
    <xsl:copy>
      <xsl:sequence select="@*"/>
      <xsl:attribute name="gt:date" select="current-dateTime()"/>
      <xsl:attribute name="gl:gluschkov" select="'dummy value'"/>
      <xsl:attribute name="rtn:rtn" select="'Recursive transition network'"/>
      <xsl:attribute name="follow:followsets" select="'dummy value'"/>
      <xsl:element name="comment">
	<xsl:text> </xsl:text>
	<xsl:value-of select="current-dateTime()"/>
	<xsl:text> creation of stack-augmented </xsl:text>
	<xsl:text>pseudo-regular grammar (SAPRG) </xsl:text>
	<xsl:text>by ixml-to-saprg.xsl. </xsl:text>
      </xsl:element>
      <xsl:element name="comment">
	<xsl:text> Input grammar G: </xsl:text>
	<xsl:value-of select="base-uri(.)"/>
	<xsl:text> </xsl:text>	
      </xsl:element>
      <xsl:element name="comment">
	<xsl:text> Output grammar G&#x2032;: </xsl:text>
	<xsl:text> this grammar.</xsl:text>	
      </xsl:element>
      <xsl:element name="comment">
	<xsl:text> A stack automaton guided by grammar G&#x2032;</xsl:text>
	<xsl:text>and the rtn:stack attributes should </xsl:text>
	<xsl:text>recognize L(G), the same language </xsl:text>
	<xsl:text>recognized by G.  </xsl:text>
	<xsl:text>If the rtn:stack attributes are ignored, </xsl:text>
	<xsl:text>this is a (pseudo-)regular grammar which </xsl:text>
	<xsl:text>recognizes the R_0 superset of L(G). </xsl:text>
      </xsl:element>
      <xsl:text>&#xA;</xsl:text>

      <xsl:apply-templates select="comment"/>

      <xsl:choose>
	<xsl:when test="empty($start) or ($start eq '#inherit')">
	  <!--* default case:  leave start symbol alone *-->
	  <xsl:apply-templates select="rule">
	    <xsl:with-param name="G" tunnel="yes" select="$G"/>
	  </xsl:apply-templates>
	</xsl:when>
	<xsl:otherwise>
	  <!--* user has specified a name *-->
	  <xsl:variable name="start-rule" as="element(rule)?"
			select="rule[@name eq $start]"/>
	  <xsl:apply-templates select="$start-rule">
	    <xsl:with-param name="G" tunnel="yes" select="$G"/>
	  </xsl:apply-templates>
	  <xsl:apply-templates select="rule except $start-rule">
	    <xsl:with-param name="G" tunnel="yes" select="$G"/>
	  </xsl:apply-templates>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

  <!--* For each rule $r we need to decide whether it is 'fissile' or
      * not.
      *
      * If it's fissile, then we need to 'break it out' or 'break it
      * up'. When we do so, $r is replaced by multiple rules $r_0,
      * $r_1, ... $r_f, one for each one state in a transition network
      * built for $r.  (In theory it could be any FSA built from the
      * RHS of $r; we use the Gluschkov automaton).
      * 
      * If it's non-fissile, and $keep-non-fissiles is '#yes' or
      * matches the name, then we leave it alone and just copy it
      * through unchanged to the output.  If $keep-non-fissiles is
      * #no or lists names that don't match, then we suppress the rule.
      *
      * Normally (and by default), we treat recursive nonterminals as
      * fissile and non-recursive nonterminals as non-fissile.  
      * But the user can specify $non-fissile = '#none', meaning that
      * all nonterminals should be broken out, or specify by name
      * the specific nonterminals to be treated as pseudo-terminals.
      *
      * Warning:  interactions between $fissile and $non-fissile can
      * cause head-scratching.  Think of it as similar to strip-space
      * and preserve-space.
      *-->
  <xsl:template match="rule">    
    <xsl:param name="fissile" as="xs:string*" tunnel="yes"
	       select="$fissile"/>
    <xsl:param name="non-fissile" as="xs:string*" tunnel="yes"
	       select="$non-fissile"/>
    <xsl:param name="linkage" as="xs:string*" tunnel="yes"
	       select="$linkage"/>
    <xsl:param name="start" as="xs:string?" tunnel="yes"
	       select="$start"/>
    <xsl:param name="keep-non-fissiles" as="xs:string*" tunnel="yes"
	       select="$keep-non-fissiles"/>

    <xsl:message use-when="false()">
      <xsl:text>Processing rule for </xsl:text>
      <xsl:value-of select="@name"/>
      <xsl:text> ...</xsl:text>
      <xsl:text>&#xA;   fissile = </xsl:text>
      <xsl:sequence select="$fissile"/>
      <xsl:text>&#xA;   non-fissile = </xsl:text>
      <xsl:sequence select="$non-fissile"/>
      <xsl:text>&#xA;   keep-non-fissiles = </xsl:text>
      <xsl:sequence select="$keep-non-fissiles"/>
    </xsl:message>
    
    <xsl:choose>
      <!--* Case 1.  If $fissile specifies no names, everything 
	  * depends on $non-fissile *-->
      <xsl:when test="$fissile = '#all'">
	<xsl:choose>
	  <!--* Case 1.1: There are no pseudo-terminals, break this
	      * rule out. *-->
	  <xsl:when test="$non-fissile = '#none'">
	    <xsl:message use-when="false()">
	      <xsl:text>    $fissile = '#all'</xsl:text>
	      <xsl:text>&#xA;    $non-fissile = '#none'</xsl:text>
	      <xsl:text>&#xA;    Calling breakout</xsl:text>
	    </xsl:message>
	    <xsl:call-template name="breakout"/>
	  </xsl:when>
	  <!--* Case 1.2 (default case):  break out recursive
	      * nonterminals, leave non-recursive nonterminals
	      * alone.
	      * 1.2.a recursive:  break it out.
	      *-->
	  <xsl:when test="($non-fissile = '#non-recursive')
			  and
			  gt:fIsRecursiverule(.)">
	    <xsl:message use-when="false()">
	      <xsl:text>    $fissile = '#all'</xsl:text>
	      <xsl:text>&#xA;    $non-fissile = '#non-recursive'</xsl:text>
	      <xsl:text>&#xA;    gt:fIsRecursiverule(.) is true</xsl:text>
	      <xsl:text>&#xA;    Calling breakout</xsl:text>
	    </xsl:message>
	    <xsl:call-template name="breakout"/>
	  </xsl:when>
	  <!--* 1.2.b non-recursive, so non-fissile *-->
	  <xsl:when test="($non-fissile = '#non-recursive')
			  and
			  not(gt:fIsRecursiverule(.))">
	    <xsl:message use-when="false()">
	      <xsl:text>    $fissile = '#all'</xsl:text>
	      <xsl:text>&#xA;    $non-fissile = '#non-recursive'</xsl:text>
	      <xsl:text>&#xA;    gt:fIsRecursiverule(.) is false</xsl:text>
	      <xsl:text>&#xA;    Falling back (pseudo-terminal)</xsl:text>
	    </xsl:message>
	    <!--* If $keep-non-fissiles is '#yes' or includes this
		* non-terminal (i.e. self::rule/@name), then apply
		* the next match (and, normally, copy through).
		* Otherwise, suppress it.
		*-->
	    <xsl:if test="$keep-non-fissiles = ('#yes', @name)">
	      <xsl:next-match/>
	    </xsl:if>
	  </xsl:when>
	  <!--* Case 1.3, 1.4.  If we reach this point, the user has
	      * specified a list of pseudo-terminals.  If this rule
	      * matches, leave it alone, else break it out. *-->
	  <xsl:when test="@name = $non-fissile">
	    <!--* Case 1.3. This is a pseudo-terminal. *-->
	    <xsl:message use-when="false()">
	      <xsl:text>    $fissile = '#all'</xsl:text>
	      <xsl:text>&#xA;    $non-fissile matches @name</xsl:text>
	      <xsl:text>&#xA;    This is a pseudo-terminal, falling back</xsl:text>
	    </xsl:message>
	    <xsl:if test="$keep-non-fissiles = ('#yes', @name)">
	      <xsl:next-match/>
	    </xsl:if>
	  </xsl:when>
	  <xsl:otherwise>
	    <!--* Case 1.4. This is NOT a pseudo-terminal. *-->
	    <xsl:message use-when="false()">
	      <xsl:text>    $fissile = '#all'</xsl:text>
	      <xsl:text>&#xA;    $non-fissile does not match @name</xsl:text>
	      <xsl:text>&#xA;    Not a pseudo-terminal, breaking out</xsl:text>
	    </xsl:message>
	    <xsl:call-template name="breakout"/>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:when>
      
      <!--* Case 2.  If the user specified names on $fissile, then do 
	  * those and no others. *-->
      <xsl:when test="@name = $fissile">
	<!-- <xsl:message>Yeow!</xsl:message> -->
	<xsl:message use-when="false()">
	  <xsl:text>    $fissile matches @name</xsl:text>
	  <xsl:text>&#xA;    Calling breakout</xsl:text>
	</xsl:message>
	<xsl:call-template name="breakout"/>
      </xsl:when>

      <!--* Case 3.  $fissile ne '#all', so it is a list of names.  
	  * But this rule's name isn't on the list.  So it's
	  * non-fissile.  Go to next match if we are keeping
	  * non-fissile nonterminals, otherwise suppress it.
	  *-->
      <xsl:otherwise> 
	<xsl:message use-when="false()">
	  <xsl:text>    $fissile does not match @name</xsl:text>
	  <xsl:text>&#xA;    Falling back, confused</xsl:text>
	</xsl:message>   
	<xsl:if test="$keep-non-fissiles = ('#yes', @name)">
	  <xsl:next-match/>
	</xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--* Now the template that does the actual work. *-->
  <xsl:template name="breakout">
    <!--* We need to pick up the global parameters, to pass
	* them to functions that need them. *-->
    <xsl:param name="fissile" as="xs:string*" tunnel="yes"
	       select="$fissile"/>
    <xsl:param name="non-fissile" as="xs:string*" tunnel="yes"
	       select="$non-fissile"/>
    <xsl:param name="linkage" as="xs:string*" tunnel="yes"
	       select="$linkage"/>
    <xsl:param name="start" as="xs:string?" tunnel="yes"
	       select="$start"/>
    
    <xsl:message use-when="false()">
      <xsl:text>Breaking out fissile rule </xsl:text>
      <xsl:value-of select="@name"/>
      <xsl:text> ...</xsl:text>
      <xsl:text>&#xA;   fissile = </xsl:text>
      <xsl:sequence select="$fissile"/>
      <xsl:text>&#xA;   non-fissile = </xsl:text>
      <xsl:sequence select="$non-fissile"/>
      <xsl:text>&#xA;   linkage = </xsl:text>
      <xsl:sequence select="$linkage"/>
      <xsl:text>&#xA;   start = </xsl:text>
      <xsl:sequence select="$start"/>
    </xsl:message>

    <xsl:variable name="n" as="xs:string" select="string(@name)"/>

    <!--* Sanity check.  If this non-terminal is called from
	* more than one place, it is likely to have been a
	* mistake to invoke this process on the grammar.  Don't
	* stop, but do warn the user.
	*
	* Turn this off for now:  if all the references are from
	* fissile non-terminals, the warning is misleading.
	*-->
    <xsl:if test="false() and count(//nonterminal[@name = $n]) gt 1">
      <xsl:message>
	<xsl:text>    ixml-to-saprg:  There is more</xsl:text>
	<xsl:text> than one reference to nonterminal </xsl:text>
	<xsl:value-of select="$n"/>
	<xsl:text>.&#xA;    Inlining the rule may be advisable.</xsl:text>
      </xsl:message>
    </xsl:if>

    <!--* 1. Write out a comment to record original rule. *-->
    <xsl:element name="comment"> Expansion for <xsl:value-of
    select="$n"/>. </xsl:element>
    <xsl:element name="comment">
      <xsl:text> </xsl:text>
      <xsl:value-of select="gt:string(.)"/>
      <xsl:text> </xsl:text>
    </xsl:element>

    <!--* 1b. If appropriate, write out a linkage rule to connect 
	* the original nonterminal to state N_0.  It's appropriate if
	* $linkage names this nonterminal or $linkage is '#all'.
	*-->
    <xsl:if test="$linkage = ('#all', @name)">
      <xsl:element name="rule">
	<xsl:sequence select="@mark, @name"/>
	<xsl:attribute name="rtn:ruletype" select=" 'linkage-stub' "/>      
	<xsl:element name="alt">
      	  <xsl:attribute name="rtn:ruletype" select=" 'linkage' "/>
      	  <xsl:element name="comment">nil</xsl:element>
      	  <xsl:element name="nonterminal">
      	    <xsl:attribute name="name" select="concat(@name, '_0')"/>
      	    <xsl:attribute name="rtn:stack"
			   select=" concat('push ', 'extcall_', $n) "/>
      	  </xsl:element>
	</xsl:element>
	
      </xsl:element>
    </xsl:if>
    
    <!--* 2. Create rule for initial state N_0. *-->
    <xsl:variable name="lidFirst"
		  as="xs:string*"
		  select="tokenize(@gl:first, '\s+')"/>
    <xsl:element name="rule">
      <xsl:attribute name="name" select="concat($n, '_0')"/>
      <!--
      <xsl:comment>* first set:  <xsl:value-of select="@gl:first"/></xsl:comment>
      <xsl:comment>* lidFirst:  <xsl:value-of select="$lidFirst"/></xsl:comment>
      -->
      <xsl:apply-templates mode="arc"
			   select="descendant::*[@xml:id=$lidFirst]"/>
      <!--* If the rule is nullable, then N_0 is final, and needs
	  * an epsilon transition to N_f.  *-->
      <xsl:if test="xs:boolean(@gl:nullable) = true()">
	<xsl:element name="alt">
	  <xsl:element name="comment">rule is nullable</xsl:element>
	  <xsl:element name="comment">nil</xsl:element>
	  <xsl:element name="nonterminal">
	    <xsl:attribute name="name"
			   select="concat(@name, '_f')"/>
	  </xsl:element>
	</xsl:element>
      </xsl:if>
    </xsl:element>
    
    <!--* 3. Handle all other states, passing this rule as
	* parameter. *-->
    <xsl:apply-templates mode="state-rule"
			 select="descendant::*[gt:fIstoken(.)]">
      <xsl:with-param name="rule" as="element(rule)"
		      select="."/>
    </xsl:apply-templates>
    
    <!--* 4. For final state N_f, write all the return rules. *-->
    <xsl:element name="rule">
      <xsl:attribute name="name" select="concat($n, '_f')"/>

      <xsl:for-each select="//nonterminal[@name=$n]">
	<xsl:variable name="eReferrer" as="element()" select="."/>
	<xsl:variable name="idReferrer" as="xs:string" select="string(@xml:id)"/>
	<xsl:variable name="eRefRule" as="element(rule)" select="./ancestor::rule"/>

	<xsl:choose>
	  <xsl:when test="gt:fIsPTrule($eRefRule, $fissile, $non-fissile)">
	    <!--* when we are called from a pseudo-terminal, we don't
		* write an arc for it.  (What DO we do?) *-->
	    <xsl:text>&#xA;</xsl:text>
	    <xsl:comment>We were also called by <xsl:value-of select="$idReferrer"/></xsl:comment>
	    <xsl:text>&#xA;</xsl:text>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:element name="alt">
	      <xsl:attribute name="rtn:ruletype" select=" 'return' "/>
	      <xsl:element name="comment">nil</xsl:element>
	      <xsl:element name="nonterminal">
		<xsl:attribute name="name" select="$idReferrer"/>
		<xsl:attribute name="rtn:stack"
			   select="concat('pop ', $idReferrer)"/>
	      </xsl:element>
	    </xsl:element>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:for-each>

      <!--* 4b If appropriate, add a linkage RHS to return to external
	  * caller.  It's appropriate or not depending on $linkage.
	  *-->
      <xsl:if test="$linkage = ('#all', @name)">
	<xsl:element name="alt">
      	  <xsl:attribute name="rtn:ruletype" select=" 'linkage-return' "/>
      	  <xsl:attribute name="rtn:stack" select=" concat('pop ', 'extcall_', $n) "/>
      	  <xsl:element name="comment">nil</xsl:element>
	</xsl:element>
      </xsl:if>

      <!--* 4c If we are in the FSA for the start symbol, then add an
	  * unconditional empty RHS.
	  *-->
      <xsl:if test="not(preceding-sibling::rule) 
		    and (empty($start) or ($start eq '#inherit'))
		    or
		    ($start eq @name)">
	<xsl:element name="alt">
      	  <xsl:attribute name="rtn:RHStype" select=" 'grammar-final' "/>
      	  <xsl:attribute name="rtn:stack" select=" 'if-stack-empty' "/>
      	  <xsl:element name="comment">nil</xsl:element>
	</xsl:element>
      </xsl:if>
      
    </xsl:element>
    
    <!--* 5. Write out a comment to mark end of expansion. *-->
    <xsl:element name="comment">
      <xsl:text> End of expansion for </xsl:text>
      <xsl:value-of select="$n"/>
      <xsl:text>. </xsl:text>
    </xsl:element>
    
    <xsl:text>&#xA;</xsl:text>
    
  </xsl:template>

  <!--* to make an arc to a particular token, we need to produce
      * an 'alt' element consisting either of
      * - the token itself and a nonterminal for the follow state,
      * or
      * - the empty sequence and a nonterminal for the start state 
      *   of an expanded rule (usually a recursive rule).
      * This mode does not handle return arcs for the second case.
      *-->
  <xsl:template match="*" mode="arc">
    <xsl:param name="G" tunnel="yes"/>
    <xsl:param name="fissile" as="xs:string*" tunnel="yes"
	       select="$fissile"/>
    <xsl:param name="non-fissile" as="xs:string*" tunnel="yes"
	       select="$non-fissile"/>    
    
    <xsl:if test="self::nonterminal" use-when="false()">
      <xsl:variable name="flag" as="xs:boolean"
		    select="gt:fIsPseudoterminal(
 			    string(@name), $G, $fissile, $non-fissile
			    )"/>
      <xsl:message>
	<xsl:text>Debugging:  nonterminal </xsl:text>
	<xsl:value-of select="@name"/>
	<xsl:choose>
	  <xsl:when test="$flag = true()">
	    <xsl:text> is a pseudo-terminal.</xsl:text>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:text> is NOT a pseudo-terminal.</xsl:text>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:message>
    </xsl:if>
    
    <xsl:choose>
      <xsl:when test="not(self::nonterminal)
	or
	self::nonterminal
	[gt:fIsPseudoterminal(
 	    string(@name), $G, $fissile, $non-fissile
	    )]">
		
	<xsl:element name="alt">
	  <xsl:attribute name="rtn:ruletype"
			 select="if (self::nonterminal)
				 then 'pseudoterminal'
				 else 'terminal' "/>
	  <!--* First the terminal or pseudo-terminal.
	      * Strip the id and annotations, because they no
	      * longer apply.
	      *-->	
	  <xsl:copy>
	    <xsl:sequence select="@*
				  except
				  (@xml:id, @gl:*, @follow:*)"/>
	    <xsl:sequence select="node()"/>
	  </xsl:copy>
	  <!--* Then the target state, which is the one for the
	      * element we are processing.  So we use its ID. *-->
	  <xsl:element name="nonterminal">
	    <xsl:attribute name="rtn:nttype"
			   select=" 'state' "/>
	    <xsl:attribute name="name" select="string(@xml:id)"/>
	  </xsl:element>
	</xsl:element>
      </xsl:when>
      <xsl:when test="self::nonterminal
		      [not(gt:fIsPseudoterminal(
		          string(@name), $G, $fissile, $non-fissile
		      ))]">
	<xsl:element name="alt">
	  <xsl:attribute name="rtn:ruletype"
			 select=" 'recursion' "/>
	  <!--* First the terminal, only there is none *-->
	  <xsl:element name="comment">nil</xsl:element>
	  <!--* Then the target state, which is the one for the
	      * element we are processing.  So we use its ID. *-->
	  <xsl:element name="nonterminal">
	    <xsl:attribute name="rtn:nttype"
			   select=" 'call' "/>
	    <xsl:attribute name="name" select="concat(@name, '_0')"/>
	    <xsl:attribute name="rtn:stack"
			   select="concat('push ', string(@xml:id))"/>
	  </xsl:element>
	</xsl:element>
      </xsl:when>
      <xsl:otherwise>
	<xsl:message>Unexpected case!  Fix me quick!</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--* We handle states with mode state-rule *-->
  <xsl:template match="*" mode="state-rule">
    <xsl:param name="rule" as="element(rule)" required="yes"/>
    <xsl:variable name="state" select="@xml:id"/>
    
    <!--* Make a rule for this state. *--> 
    <xsl:element name="rule">
      <xsl:attribute name="name" select="@xml:id"/>
      <xsl:attribute name="rtn:nttype"
		     select=" 'state' "/>
      <!--* If this state is for a symbol that has an @rtn:item 
          * attribute, copy that attribute to the rule, so we
	  * can display it for orientation. *-->
      <xsl:sequence select="@rtn:item"/>

      <!--* For every item in the follow set of this token, 
	  * make an arc to go there. 
	  *-->
      <xsl:variable name="attFollowset"
		    as="attribute()?"
		    select="$rule/@follow:*[local-name() = $state]"/>
      <!--
      <xsl:message>Follow set for <xsl:value-of select="$state"/>: 
      <xsl:copy-of select="$attFollowset"/></xsl:message>
      -->
      <xsl:variable name="lidFollowset"
		    as="xs:string*"
		    select="tokenize($attFollowset, '\s+')"/>
      <!--
      <xsl:comment>Follow set for <xsl:value-of select="$state"/>: 
      <xsl:copy-of select="$lidFollowset"/></xsl:comment>
      -->
      <xsl:apply-templates mode="arc"
			   select="$rule/descendant::*[@xml:id=$lidFollowset]"/>
      
      <!--* If this state is final in $rule, then make an arc to go
	  * to N_f.
	  *-->
      <xsl:variable name="lidLast"
		    as="xs:string*"
		    select="tokenize($rule/@gl:last, '\s+')"/>
      <xsl:if test="@xml:id = $lidLast">
	<xsl:element name="alt">
	  <xsl:element name="comment">nil</xsl:element>
	  <xsl:element name="nonterminal">
	    <xsl:attribute name="name"
			   select="concat($rule/@name, '_f')"/>
	  </xsl:element>
	</xsl:element>
      </xsl:if>
    </xsl:element>
  </xsl:template>  

  <!--****************************************************************
      * Functions
      ****************************************************************
      *-->

  <!--****************************************************************
      * Predicates 
      *-->

  <!--* gt:fIsRecursiveRule($e):  is this rule recursive? 
      * Pretty much what it sounds like, but relies on gt:recursive 
      * annotation instead of finding out for itself. 
      *-->
  <xsl:function name="gt:fIsRecursiverule"
		as="xs:boolean">
    <xsl:param name="e" as="element(rule)?"/>
    
    <!--* if rule has gt:recursive=true, then yes, else no.
	*-->
    <xsl:message use-when="false()">
      <xsl:text>fIsRecursiverule on rule for "</xsl:text>
      <xsl:value-of select="$e/@name"/>
      <xsl:text>" returns </xsl:text>
      <xsl:sequence select="if (empty($e))
			    then false()
			    else xs:boolean($e/@gt:recursive)"/>
    </xsl:message>
    
    <xsl:sequence select="if (empty($e))
			  then false()
			  else xs:boolean($e/@gt:recursive)"/>
    
  </xsl:function>
  
  <!--* gt:fIsPTRule($e):  does this rule define a pseudo-terminal?
      * Depends on what the user said.
      *-->
  <xsl:function name="gt:fIsPTrule"
		as="xs:boolean">
    <xsl:param name="e" as="element(rule)?"/>
    <xsl:param name="fissile" as="xs:string*"/>
    <xsl:param name="non-fissile" as="xs:string*"/>

    <xsl:message use-when="false()">
      <xsl:text>fIsPTRule(</xsl:text>
      <xsl:value-of select="$e/@name"/>
      <xsl:text>, (</xsl:text>
      <xsl:sequence select="$fissile"/>
      <xsl:text>), (</xsl:text>
      <xsl:sequence select="$non-fissile"/>
      <xsl:text>)) ... </xsl:text>
    </xsl:message>   

    <xsl:choose>
      <xsl:when test="($fissile = '#all')
		      and ($non-fissile = '#non-recursive')">
	<!--* default case:  pseudo-terminal iff not recursive *-->
	<xsl:message use-when="false()">  ... able: calling not fIsRecursiverule </xsl:message>
	<xsl:sequence select="not(gt:fIsRecursiverule($e))"/>
      </xsl:when>
      <xsl:when test="($fissile = '#all')
		      and ($non-fissile = '#none')">
	<!--* if there are no pseudo-terminals, then this cannot
	    * be one. *-->
	<xsl:message use-when="false()">  ... baker: false </xsl:message>
	<xsl:sequence select="false()"/>
      </xsl:when>
      <xsl:when test="($fissile = '#all')
		      and ($non-fissile = $e/@name)">
	<!--* if this is named as a pseudo-terminal, then it 
	    * is one (but only if $fissile = '#all') *-->
	<xsl:message use-when="false()">  ... charlie: true </xsl:message>
	<xsl:sequence select="true()"/>
      </xsl:when>
      <xsl:when test="($fissile = '#all')
		      and not($non-fissile = $e/@name)">
	<!--* if we are listing all pseudo-terminals and this is not
	    * in the list, then it is not one *-->	
	<xsl:message use-when="false()">  ... dog: false </xsl:message>
	<xsl:sequence select="false()"/>
      </xsl:when>
      <xsl:when test="($fissile = $e/@name)">
	<!--* If we said this one was fissile, then it is not
	    * a pseudo-terminal, now is it?  Keep up! *-->	
	<xsl:message use-when="false()">  ... easy: false </xsl:message>
	<xsl:sequence select="false()"/>
      </xsl:when>
      <xsl:when test="not($fissile = '#all')
		      and not($fissile = $e/@name)">
	<!--* We are naming fissile nonterminals (because
	    * $fissile ne '#all') but this one is not listed.
	    * So it's by fiat a pseudo-terminal. *-->
	<xsl:message use-when="false()">  ... fox: true </xsl:message>
	<xsl:sequence select="true()"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:message terminate="yes">
	  <xsl:text>The world is ending.  Prepare yourself.</xsl:text>
	  <xsl:text>&#xA;That is, all logic has ceased to function.</xsl:text>
	  <xsl:text>&#xA;Unless, perhaps, there is just an error </xsl:text>
	  <xsl:text>in this branch statement?</xsl:text>
	</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:function>

  <xsl:function name="gt:fIsPseudoterminal"
		as="xs:boolean">
    <xsl:param name="n" as="xs:string"/>
    <xsl:param name="G" as="element(ixml)"/>
    <xsl:param name="fissile" as="xs:string*"/>
    <xsl:param name="non-fissile" as="xs:string*"/>
    
    <!--* We will probably later want to be able to parameterize
	* this, perhaps with a configuration file or perhaps with
	* a command-line argument.
	* But sufficient unto the day is the evil thereof.
	* Today we just want to treat all non-recursive nonterminals
	* as pseudo-terminals.
	*-->

    <xsl:variable name="rule" as="element(rule)?"
		  select="$G/rule[@name = $n ]"/>
    
    <!--* Kick the can to the rule.  If the rule is a
	* pseudo-terminal rule, then yes, else no.
	*-->
    <xsl:message use-when="false()">
      <xsl:text>fIsPseudoterminal is about to call fIsPTRule on "</xsl:text>
      <xsl:value-of select="$n"/>
      <xsl:text>", and fIsPTRule will return </xsl:text>
      <xsl:sequence select="gt:fIsPTrule($rule, $fissile, $non-fissile)"/>
    </xsl:message>
    
    <xsl:sequence select="gt:fIsPTrule($rule, $fissile, $non-fissile)"/>

    <!--
    <xsl:message>gt:fIsPseudoterminal(<xsl:sequence
    select="$n"/>, $G) => <xsl:sequence
    select="gt:fIsPTrule($rule)"/> (count($rule) = <xsl:sequence
    select="count($rule)"/>.</xsl:message>
    -->
    
  </xsl:function>

  <xsl:function name="gt:quote-char"
		as="xs:string">
    <xsl:param name="s" as="xs:string"/>
    <xsl:variable name="sq" as="xs:string" select=" &quot;'&quot;"/>
    <xsl:variable name="dq" as="xs:string" select=' &apos;"&apos;'/>
    <xsl:sequence select="if ($s eq $dq)
			  then concat($sq, $s, $sq)
			  else concat($dq, $s, $dq)"/>
  </xsl:function>
    
  <xsl:function name="gt:string"
		as="xs:string">
    <xsl:param name="e" as="element()?"/>

    <!--* Quick and dirty way to record the original rule
	* in a comment.
	*-->

    <xsl:choose>
      <xsl:when test="$e/self::rule">
	<xsl:variable name="lsAlt"
		      as="xs:string*"
		      select="for $a in $e/alt
			      return gt:string($a)"/>
	<xsl:variable name="sRHS"
		      as="xs:string"
		      select="string-join($lsAlt, '; ')"/>
	<xsl:sequence select="concat(
			      string($e/@mark),
			      string($e/@name),
			      ': ',
			      $sRHS,
			      '.'
			      )"/>
      </xsl:when>
      <xsl:when test="$e/self::alts">
	<xsl:variable name="lsAlt"
		      as="xs:string*"
		      select="for $a in $e/alt
			      return gt:string($a)"/>
	<xsl:sequence select="concat(
			      '(',
			      string-join($lsAlt, '; '),
			      ')'
			      )"/>
      </xsl:when>
      <xsl:when test="$e/self::alt">
	<xsl:variable name="lsTerm"
		      as="xs:string*"
		      select="for $t in $e/*[gt:fIsexpression(.)]
			      return gt:string($t)"/>
	<xsl:sequence select="string-join($lsTerm, ', ')"/>
      </xsl:when>
      <xsl:when test="$e/self::repeat0 or $e/self::repeat1">
	<xsl:variable name="eFactor"
		      as="element()"
		      select="$e/*[gt:fIsexpression(.)][1]"/>
	<xsl:variable name="eSep"
		      as="element(sep)?"
		      select="$e/sep"/>
	<xsl:sequence select="concat(
			      gt:string($eFactor),
			      if ($e/self::repeat0)
			      then '*'
			      else '+',
			      gt:string($eSep)
			      )"/>
      </xsl:when>
      <xsl:when test="$e/self::sep">
	<xsl:variable name="eFactor"
		      as="element()"
		      select="$e/*[gt:fIsexpression(.)][1]"/>
	<xsl:sequence select="gt:string($eFactor)"/>
      </xsl:when>
      <xsl:when test="$e/self::option">
	<xsl:variable name="eFactor"
		      as="element()"
		      select="$e/*[gt:fIsexpression(.)][1]"/>
	<xsl:sequence select="concat(
			      gt:string($eFactor),
			      '?'
			      )"/>
      </xsl:when>
      <xsl:when test="$e/self::nonterminal">
	<xsl:sequence select="concat(
			      string($e/@mark), 
			      string($e/@name)
			      )"/>
      </xsl:when>
      <xsl:when test="$e/self::literal">
	<xsl:sequence select="if ($e/@dstring) then
			      concat(
			      string($e/@tmark),
			      &apos;&quot;&apos; ,
			      string($e/@dstring),
			      &apos;&quot;&apos; 
			      )
			      else if ($e/@sstring) then
			      concat(
			      string($e/@tmark), 
			      &quot;&apos;&quot; , 
			      string($e/@sstring),
			      &quot;&apos;&quot;
			      )
			      else if ($e/@string) then
			      concat(
			      string($e/@tmark), 
			      &quot;&apos;&quot; , 
			      string($e/@string),
			      &quot;&apos;&quot;
			      )
			      else
			      concat(
			      string($e/@tmark), 
			      '#', 
			      string($e/@hex)
			      )
			      "/>
      </xsl:when>
      <xsl:when test="$e/self::inclusion or $e/self::exclusion">
	<xsl:sequence select="concat(
			      string($e/@tmark),
			      if ($e/self::exclusion) then '~' else '',
			      '[',
			      string-join(
			      for $c in $e/*[not(self::comment)]
			      return gt:string($c),
			      '; '),
			      ']'
			      )"/>
      </xsl:when>
      <xsl:when test="$e/self::range">
	<xsl:sequence select="concat(
			      gt:quote-char($e/@from), 
			      '-',
			      gt:quote-char($e/@to)
			      )"/>
      </xsl:when>
      <xsl:when test="$e/self::class">
	<xsl:sequence select="concat(
			      '\p{',
			      string($e/@code),
			      '}'
			      )"/>
      </xsl:when>
      <xsl:when test="empty($e)">
	<xsl:sequence select=" '' "/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:message>Unexpected argument to gt:string(): </xsl:message>
	<xsl:message><xsl:copy-of select="$e"/></xsl:message>
	<!--* U+1F061 = domino tile horizontal-06-06 (boxcars)
	    * U+1F616 = confounded face
	    *-->
	<!-- <xsl:value-of select=" '&#x1F061;' "/> *-->
	<xsl:sequence select=" '&#x1F616;' "/>
      </xsl:otherwise>
      
    </xsl:choose>
    
  </xsl:function>

  
</xsl:stylesheet>
