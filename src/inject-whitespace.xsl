<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    
    xmlns:rng="http://relaxng.org/ns/structure/1.0"
    
    default-mode="injecting-ws"
    version="3.0">

  <!--* inject-whitespace.xsl: read an invisible-XML grammar, write 
      * a similar ixml grammar in which various changes have been
      * made, as directed by the parameters (see below).
      *-->
  
  <!--* 
      * The nonterminal named in the 'start' parameter (if any) is made
      * the start symbol and moved to the beginning of the grammar.
      *-->
  <xsl:param name="start" as="xs:string?" select="()"/>
  
  <!--* 
      * The 'whitespace' parameter specifies the name of the symbol to
      * be added to the grammar for whitespace.  Defaults to 's'.  The
      * definition is based to that in ixml:  s = -[Zs; #9; #A; #D].  
      * There is no user control over the definition, only over the 
      * name.  If you need a different rule, edit the output by hand.  
      * In particular, if you need to add comments to the definition of 
      * whitespace, edit by hand.
      *-->
  <xsl:param name="whitespace" as="xs:string?" select="'s'"/>

  <!--* 
      * The parameter 'literals' determines how literal strings
      * in the grammar are treated.  Values are
      *       
      *     trailing:  a whitespace nonterminal (typically s) is 
      *         added after each literal and low-level token.
      *      
      *     leading:   the whitespace symbol is added befor each
      *         literal and low-level token.
      *       
      *     none:  no whitespace symbols are added (why are you     
      *         running this stylesheet?)  If 'none' is specified, 
      *         the rule for whitespace is not added.
      *-->  
  <xsl:param name="literals" as="xs:string?" select="'trailing'"/>

  <!--* 
      * The parameter 'hide-literals' specifies whether to hide literal 
      * strings in the grammar.
      *-->  
  <xsl:param name="hide-literals" as="xs:boolean?" select=" true() "/>
  
  <!--* 
      * If the 'tokens' parameter is specified, then each nonterminal 
      * named in it is treated as a low-level token. The whitespace 
      * nonterminal is added at the end of every right-hand side 
      * (top-level alt).
      *-->
  <xsl:param name="tokens" as="xs:string?" select="()"/>

  <xsl:variable name="ls-tokens" as="xs:string*"
		select="tokenize($tokens, '\+|\s+')[normalize-space(.)]"/>
  
  <!--* 
      * If the 'hide' parameter is specified, then the nonterminals 
      * named will get mark="-" in the output.
      *-->
  <xsl:param name="hide" as="xs:string?" select="()"/>
  
  <xsl:variable name="ls-hidden" as="xs:string*"
		select="tokenize($hide, '\+|\s+')[normalize-space(.)]"/>

  <!--* 
      * The parameter 'make-token-rules specifies whether to turn each
      * literal into a reference to a nonterminal representing that 
      * token (with trailing whitespace), or not.
      *-->  
  <xsl:param name="make-token-rules" as="xs:boolean?" select=" true() "/>
  
  <!--* 
      * If the 'literal-names' parameter is specified, then the 
      * indicated file will be read as a configuration file and
      * consulted to see what nonterminal names should be used
      * for literals if the literals are not NCNames.  Ignored
      * if make-token-rules is not true.  NCNames become their own
      * nonterminals unless overridden in the map.
      *-->
  <xsl:param name="literal-names" as="xs:string?" select="()"/>
  
  <xsl:variable name="map-lit-name" as="document-node()?"
		select="if (exists($literal-names))
			then doc($literal-names)
			else ()"/>
    

  <!--* Current status:
      * 2022-06-22:  under construction.
      *-->

  <!--* Known limits:
      * 
      * - The initial use case is for mechanical processing of Niklaus 
      *   Wirth's grammar for Oberon.  Any dark corners or complications 
      *   not arising there may be blithely ignored.  No testing has 
      *   been done on other grammars.
      *
      * Forewarned is forearmed.
      *-->


  <!--* Revisions:
      * 2022-06-22 : CMSMcQ : made first draft
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->
  <xsl:mode name="injecting-ws" on-no-match="shallow-copy"/>
  
  <xsl:strip-space elements="*"/>
  <xsl:output method="xml" indent="yes"/>

  <!--* Since we inject this in several different places, let's
      * define it once for brevity and consistency. *-->
  <xsl:variable name="ws-ref" as="element(option)">
    <xsl:element name="option">
      <xsl:element name="nonterminal">
	<xsl:attribute name="name" select="$whitespace"/>
      </xsl:element>
    </xsl:element>
  </xsl:variable>
  
  <!--****************************************************************
      * Main / starting template
      ****************************************************************
      *-->
  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>
  
  <xsl:template match="ixml">
    <xsl:copy>
      <xsl:sequence select="@*"/>

      <!-- 1 Provide a little metadata -->
      <xsl:element name="comment">
	<xsl:text>* </xsl:text>
	<xsl:value-of select="adjust-date-to-timezone(
			      current-date(),
			      ())"/>
	<xsl:text>: whitespace handling added by </xsl:text>
	<xsl:text>inject-whitespace.xsl *</xsl:text>
	
	<xsl:text>&#xA; * start = </xsl:text>
	<xsl:sequence select="($start, '- (not specified)')[1]"/>
	<xsl:text>&#xA; * whitespace = </xsl:text>
	<xsl:sequence select="($whitespace, '- (none specified)')[1]"/>
	<xsl:text>&#xA; * literal = </xsl:text>
	<xsl:sequence select="($literals, '- (not specified)')[1]"/>
	<xsl:text>&#xA; * tokens = </xsl:text>
	<xsl:sequence select="($tokens, '- (not specified)')[1]"/>
	<xsl:text>&#xA; * hide = </xsl:text>
	<xsl:sequence select="($hide, '- (not specified)')[1]"/>
	<xsl:text>&#xA;</xsl:text>
      </xsl:element>
      
      <!-- 2 Do the work -->
      <xsl:variable name="first-rule" as="element(rule)?"
		    select="rule[@name eq $start]"/>
      <xsl:apply-templates select="$first-rule"/>
      <xsl:apply-templates select="* except $first-rule"/>
      
      <!-- 3 Add the whitespace definition -->
      <xsl:if test="not($literals = 'none') or $make-token-rules">
	<xsl:element name="comment">
	  <xsl:text>* </xsl:text>
	  <xsl:text> Rules added by </xsl:text>
	  <xsl:text>inject-whitespace.xsl *</xsl:text>
	</xsl:element>
      </xsl:if>
	
      <xsl:if test="not($literals = 'none')">
	<xsl:element name="rule">
	  <xsl:attribute name="name" select="$whitespace"/>
	  <xsl:attribute name="mark" select=" '-' "/>
	  <xsl:element name="alt">
	    <xsl:element name="inclusion">
	      <xsl:attribute name="tmark" select=" '-' "/>
	      <xsl:element name="member">
		<xsl:attribute name="code" select=" 'Zs' "/>
	      </xsl:element>
	      <xsl:element name="member">
		<xsl:attribute name="hex" select=" '9' "/>
	      </xsl:element>
	      <xsl:element name="member">
		<xsl:attribute name="hex" select=" 'A' "/>
	      </xsl:element>
	      <xsl:element name="member">
		<xsl:attribute name="hex" select=" 'D' "/>
	      </xsl:element>
	    </xsl:element>
	  </xsl:element>
	</xsl:element>
      </xsl:if>

      <!--* 4 Add any token-level rules we are generating *-->
      <xsl:if test="$make-token-rules">
	<xsl:for-each select="distinct-values(//literal/@string)">
	  <xsl:sort select="."/>
	  <xsl:variable name="this-literal" as="xs:string"
			select="."/>
	  <xsl:variable name="nt" as="xs:string"
			select="gt:nt-from-literal(.)"/>
	  
	  <xsl:element name="rule">
	    <xsl:attribute name="name" select="$nt"/>
	    <xsl:attribute name="mark" select=" '-' "/>
	    <xsl:element name="alt">
	      <xsl:element name="literal">
		<xsl:attribute name="tmark" select=" '-' "/>
		<xsl:attribute name="string" select="$this-literal"/>
	      </xsl:element>
	      <xsl:sequence select="$ws-ref"/>
	    </xsl:element>
	  </xsl:element>
	</xsl:for-each>
      </xsl:if>

    </xsl:copy>
  </xsl:template>


  <!--****************************************************************
      * Literal
      ****************************************************************
      *-->
  <xsl:template match="literal">

    <xsl:choose>
      <xsl:when test="$make-token-rules and exists(@string)">
	<xsl:variable name="nt" as="xs:string"
		      select="gt:nt-from-literal(@string)"/>
	<xsl:element name="nonterminal">
	  <xsl:attribute name="name" select="$nt"/>
	</xsl:element>
      </xsl:when>
      
      <xsl:otherwise>
	<xsl:variable name="lit" as="element(literal)">
	  <xsl:choose>
	    <xsl:when test="$hide-literals">
	      <xsl:element name="literal">
		<xsl:attribute name="tmark" select=" '-' "/>
		<xsl:sequence select="@* except @tmark, *"/>
	      </xsl:element>
	    </xsl:when>
	    <xsl:otherwise>
	      <xsl:sequence select="."/>
	    </xsl:otherwise>
	  </xsl:choose>
	</xsl:variable>

	<xsl:element name="alts">
	  <xsl:attribute name="gt:type" select=" 'literal-token' "/>
	  <xsl:element name="alt">
	    <xsl:choose>
	      <xsl:when test="$literals = 'trailing'">
		<xsl:sequence select="$lit, $ws-ref"/>
	      </xsl:when>
	      <xsl:when test="$literals = 'leading'">
		<xsl:sequence select="$ws-ref, $lit"/>
	      </xsl:when>
	      <xsl:otherwise>
		<xsl:sequence select="$lit"/>
	      </xsl:otherwise>	  
	    </xsl:choose>
	  </xsl:element>
	</xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!--****************************************************************
      * Low-level tokens (e.g. ident ...)
      ****************************************************************
      *-->
  <!--* For nonterminals identified as 'tokens', we append a
      * whitespace reference at the end of each RHS.
      *-->
  <xsl:template match="rule[@name = $ls-tokens]/alt">
    <xsl:copy>
      <xsl:sequence select="@*"/>
      <xsl:apply-templates/>
      <xsl:sequence select="$ws-ref"/>
    </xsl:copy>
  </xsl:template>
  
  <!--****************************************************************
      * Hidden non-terminals (e.g. letter, digit, ...)
      ****************************************************************
      *-->
  <!--* For nonterminals identified as 'hidden', we provide a mark
      * on their rule and also on every reference.  (For the avoidance
      * of all doubt.)
      *-->
  <xsl:template match="rule[@name = $ls-hidden]">
    <xsl:copy>
      <xsl:sequence select="@* except @mark"/>
      <xsl:attribute name="mark" select=" '-' "/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="nonterminal[@name = $ls-hidden]">
    <xsl:copy>
      <xsl:sequence select="@* except @mark"/>
      <xsl:attribute name="mark" select=" '-' "/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>


  <!--****************************************************************
      * Functions
      ****************************************************************
      *-->

  <xsl:function name="gt:nt-from-literal" as="xs:string">
    <xsl:param name="s" as="xs:string"/>
    <xsl:variable name="nt0" as="xs:string?"
		  select="$map-lit-name
			  //map[@string = $s]
			  /@nonterminal/string()"/>
    <xsl:sequence
	select="if (exists($nt0))
		then $nt0
		else if ($s castable as xs:NCName)
	        then $s
		else '__' 
                     || string-join(string-to-codepoints($s), '.')
		"/>
  </xsl:function>
  
  <!--****************************************************************
      * Predicates 
      *-->
      
</xsl:stylesheet>

