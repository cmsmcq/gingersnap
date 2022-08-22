<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    xmlns:d2x="http://www.blackmesatech.com/2014/lib/d2x"
    
    xmlns:rng="http://relaxng.org/ns/structure/1.0"
    
    default-mode="ixml-to-rng"
    version="3.0">

  <!--* ixml-to-rng.xsl: read an invisible-XML grammar, write a
      * Relax NG schema that enforces the structural constraints of
      * the schema.  N.B. constraints on character data are NOT 
      * enforced; v.Next might add Schematron rules.
      *
      * Initial use case is for the ixml specification grammar, so 
      * any dark corners or complications not arising there may be
      * blithely ignored.  Be forewarned.
      *-->

  <!--* Known limits:
      * Assumes that nonterminals are legal XML names.
      *-->

  <!--* Revisions:
      * 2022-05-20 : CMSMcQ : make all content models interleave extensions
      * 2022-05-19 : CMSMcQ : handle easy attributes
      * 2022-03-15 : CMSMcQ : made first draft
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->
  <xsl:import href="d2x.xsl"/>
  
  <xsl:mode name="ixml-to-rng" on-no-match="fail"/>
  <xsl:mode name="regex-from-rules" on-no-match="fail"/>
  <xsl:mode name="inline-nt-refs" on-no-match="shallow-copy"/>
  
  <xsl:strip-space elements="*"/>
  <xsl:output method="xml" indent="yes"/>
  
  <!--****************************************************************
      * Main / starting template
      ****************************************************************
      *-->
  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>
  
  <xsl:template match="ixml">
    <rng:grammar datatypeLibrary="http://www.w3.org/2001/XMLSchema-datatypes">
      <rng:start>
	<rng:ref name="{rule[1]/@name}"/>
      </rng:start>

      <xsl:apply-templates/>

      <xsl:call-template name="define-extension-patterns"/>      
    </rng:grammar>
  </xsl:template>


  <!--****************************************************************
      * Rules
      ****************************************************************
      *-->
  <xsl:template match="rule">
    
    <xsl:variable name="N" as="xs:string"
		  select="@name/string()"/>
    <xsl:variable name="mark" as="xs:string"
		  select="(@mark/string(), '^')[1]"/>
    
    <!--* 1. Define the default rule for this nonterminal, based
	* on the mark.
	*-->
    <rng:define name="{@name}">      
      <rng:ref name="{
		     if ($mark = '^') 
                     then 'e.'
                     else if ($mark = '@')
		     then 'a.'
		     else if ($mark = '-')
                     then 'h.'
                     else '!!!mark!!!.'
		     }{$N}"/>
    </rng:define>
    
    <!--* 2. Define the explicit rules we need for this nonterminal,
        * based on all the marks it carries anywhere.  *-->
    <xsl:variable name="reference-marks" as="xs:string*"
		  select="distinct-values(
			  ..//nonterminal[@name = $N]/@mark/string()
			  )"/>
    
    <xsl:if test="'^' = ($mark, $reference-marks)">
      <rng:define name="e.{$N}">
	<rng:element name="{$N}">
	  <rng:ref name="extension-attributes"/>
	  <rng:interleave>
	    <rng:ref name="extension-elements"/>
	    <xsl:call-template name="content-pattern"/>
	  </rng:interleave>
	</rng:element>
      </rng:define>
    </xsl:if>
    
    <xsl:if test="'@' = ($mark, $reference-marks)">
      <rng:define name="a.{$N}">
	<rng:attribute name="{$N}">
	  <xsl:call-template name="attribute-value-pattern"/>
	</rng:attribute>
      </rng:define>
    </xsl:if>
    
    <xsl:if test="'-' = ($mark, $reference-marks)">
      <rng:define name="h.{$N}">
	<xsl:call-template name="content-pattern"/>
      </rng:define>
    </xsl:if>
  </xsl:template>
  
  <!--****************************************************************
      * Content patterns
      ****************************************************************
      *-->
  <xsl:template name="content-pattern">
    <xsl:choose>
      <xsl:when test="count(alt) gt 1">
	<rng:choice>
	  <xsl:apply-templates/>
	</rng:choice>
      </xsl:when>
      <xsl:otherwise>
	<xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="alts">
    <xsl:choose>
      <xsl:when test="count(alt) gt 1">
	<rng:choice>
	  <xsl:apply-templates/>
	</rng:choice>
      </xsl:when>
      <xsl:otherwise>
	<xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="alt">
    <xsl:variable name="children" as="item()*">
      <xsl:apply-templates/>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="exists($children)">
	<rng:group>
	  <xsl:sequence select="$children"/>
	</rng:group>
      </xsl:when>
      <xsl:otherwise>
	<xsl:comment> alt with no realized children </xsl:comment>
	<rng:empty/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="repeat0">
    <xsl:choose>
      <xsl:when test="count(* except comment) eq 1">
	<rng:zeroOrMore>
	  <xsl:apply-templates/>
	</rng:zeroOrMore>
      </xsl:when>
      <xsl:when test="count(* except comment) eq 2">
	<rng:optional>
	  <xsl:apply-templates select="(* except comment)[1]"/>
	  <rng:zeroOrMore>
	    <xsl:apply-templates select="(* except comment)[2]"/>
	    <xsl:apply-templates select="(* except comment)[1]"/>
	  </rng:zeroOrMore>
	</rng:optional>
      </xsl:when>
      <xsl:otherwise>
	<xsl:message terminate="yes">
	  <xsl:text>repetition with wrong number of arguments:</xsl:text>
	  <xsl:copy-of select="."/>
	</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="repeat1">
    <xsl:choose>
      <xsl:when test="count(* except comment) eq 1">
	<rng:oneOrMore>
	  <xsl:apply-templates/>
	</rng:oneOrMore>
      </xsl:when>
      <xsl:when test="count(* except comment) eq 2">
	<rng:group>
	  <xsl:apply-templates select="(* except comment)[1]"/>
	  <rng:zeroOrMore>
	    <xsl:apply-templates select="(* except comment)[2]"/>
	    <xsl:apply-templates select="(* except comment)[1]"/>
	  </rng:zeroOrMore>
	</rng:group>
      </xsl:when>
      <xsl:otherwise>
	<xsl:message terminate="yes">
	  <xsl:text>repetition with wrong number of arguments:</xsl:text>
	  <xsl:copy-of select="."/>
	</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="option">
    <rng:optional>
      <xsl:apply-templates/>
    </rng:optional>
  </xsl:template>

  <xsl:template match="sep">
    <xsl:apply-templates/>
  </xsl:template>
  
  <xsl:template match="nonterminal">
    <rng:ref
	name="{
	      if (@mark eq '^') 
	      then 'e.'
	      else if (@mark eq '@')
	      then 'a.'
	      else if (@mark eq '-')
	      then 'h.'
	      else ''
	      }{@name}"/>
  </xsl:template>

  <xsl:template match="inclusion">
    <xsl:if test="not(@tmark eq '-')">
      <xsl:comment> can a data element be used? </xsl:comment>
      <rng:text/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="exclusion">
    <xsl:if test="not(@tmark eq '-')">
      <xsl:comment> can a data element be used? </xsl:comment>
      <rng:text/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="literal">
    <xsl:if test="not(@tmark eq '-')">
      <xsl:comment> can a data element be used? </xsl:comment>
      <rng:text/>
    </xsl:if>
  </xsl:template>
  
  <!--****************************************************************
      * Attribute value patterns
      ****************************************************************
      *-->
  <!--* We make this distinct so that we can (try to) make a regular
      * expression for an attribute, if in fact it accepts a regular
      * language. 
      *
      * Current element is rule.  We assume parent/child annotation.
      *-->
  <xsl:template name="attribute-value-pattern">
    <xsl:choose>
      <!-- First case:  simple attribute, no nonterminals in the RHS -->
      <xsl:when test="exists(@gt:descendants) and (@gt:descendants eq '')">
	<xsl:element name="rng:data">
	  <xsl:attribute name="type" select=" 'string' "/>
	  <xsl:element name="rng:param">
	    <xsl:attribute name="name" select=" 'pattern' "/>
	    <xsl:apply-templates mode="regex-from-rules"/>
	  </xsl:element>
	</xsl:element>
      </xsl:when>

      <!-- Next case:   nonterminal in the RHS (handle if regular) -->
      <xsl:when test="exists(@gt:descendants) 
		      and (@gt:descendants ne '')
                      and (@gt:recursive eq 'false')
		      and (every $nm-d in tokenize(@gt:descendants,'\s+')
		      satisfies (//rule[@name = $nm-d]/@gt:recursive = 'false')
		      )">
	<!-- First, flatten the rhs of this rule -->
	<xsl:variable name="flat-rule" as="element(rule)">
	  <xsl:apply-templates select="." mode="inline-nt-refs"/>
	</xsl:variable>
		      
	<!-- Then make a regex from the flattened rule -->
	<xsl:element name="rng:data">
	  <xsl:attribute name="type" select=" 'string' "/>
	  <xsl:element name="rng:param">
	    <xsl:attribute name="name" select=" 'pattern' "/>
	    <xsl:apply-templates select="$flat-rule/child::node()" mode="regex-from-rules"/>
	  </xsl:element>
	</xsl:element>
      </xsl:when>
      
      <!-- Fallback case:   no gt annotations, do nothing -->
      <xsl:otherwise>
	<xsl:comment> No annotations found, falling back to 'text'. </xsl:comment>
	<rng:text/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!--****************************************************************
      * Misc
      ****************************************************************
      *-->
  <xsl:template match="comment"/>

  <xsl:template match="processing-instruction()">
    <xsl:copy-of select="."/>
  </xsl:template>  

  <!--****************************************************************
      * regex-from-rules mode
      ****************************************************************
      *-->
  <xsl:template match="alts" mode="regex-from-rules">
    <xsl:text>(</xsl:text>	
    <xsl:apply-templates mode="regex-from-rules"/>
    <xsl:text>)</xsl:text>
  </xsl:template>
  
  <xsl:template match="alt" mode="regex-from-rules">
    <xsl:choose>
      <xsl:when test="following-sibling::alt">
	<xsl:text>(</xsl:text>	
	<xsl:apply-templates mode="regex-from-rules"/>
	<xsl:text>)|</xsl:text>
      </xsl:when>
      <xsl:when test="preceding-sibling::alt">
	<xsl:text>(</xsl:text>	
	<xsl:apply-templates mode="regex-from-rules"/>
	<xsl:text>)</xsl:text>
      </xsl:when>
      <xsl:otherwise>	
	<xsl:apply-templates mode="regex-from-rules"/>
      </xsl:otherwise>
    </xsl:choose>    
  </xsl:template>
  
  <xsl:template match="repeat0[not(sep)]"
		mode="regex-from-rules">
    <xsl:apply-templates mode="regex-from-rules"/>
    <xsl:text>*</xsl:text>
  </xsl:template>
  
  <xsl:template match="repeat1[not(sep)]"
		mode="regex-from-rules">
    <xsl:apply-templates mode="regex-from-rules"/>
    <xsl:text>+</xsl:text>
  </xsl:template>
  
  <xsl:template match="option"
		mode="regex-from-rules">
    <xsl:apply-templates mode="regex-from-rules"/>
    <xsl:text>?</xsl:text>
  </xsl:template>
  
  <xsl:template match="literal"
		mode="regex-from-rules">
    <xsl:if test="not(@tmark='-')">
      <xsl:sequence select="gt:ensafen-literal(@string)"/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="inclusion" mode="regex-from-rules">
    <xsl:text>[</xsl:text>	
    <xsl:apply-templates mode="regex-from-rules"/>
    <xsl:text>]</xsl:text>
  </xsl:template>
  
  <xsl:template match="exclusion" mode="regex-from-rules">
    <xsl:text>[^</xsl:text>	
    <xsl:apply-templates mode="regex-from-rules"/>
    <xsl:text>]</xsl:text>
  </xsl:template>
  
  <xsl:template match="inclusion/member|exclusion/member" mode="regex-from-rules">
    <xsl:choose>
      
      <xsl:when test="@string">
	<xsl:sequence select="gt:ensafen-pos-char-class(@string)"/>
      </xsl:when>
      
      <xsl:when test="@hex">
	<xsl:sequence select="codepoints-to-string(
			      d2x:x2d(@hex/string())
			      )"/>
      </xsl:when>
      
      <xsl:when test="@from">
	<xsl:variable name="f" as="xs:string"
		      select="gt:range-bound-to-char(@from/string())"/>
	<xsl:variable name="t" as="xs:string"
		      select="gt:range-bound-to-char(@to/string())"/>
	<xsl:value-of select="concat($f, '-', $t)"/>
      </xsl:when>
      
      <xsl:when test="@code">
	<xsl:value-of select="concat('\p{', @code, '}')"/>
      </xsl:when>
      
      <xsl:otherwise>
	<xsl:message>
	  <xsl:text>regex-from-rules mode is not ready for this:&#xA;</xsl:text>
	  <xsl:copy-of select="."/>
	</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="text()[normalize-space() eq '']" mode="regex-from-rules"/>


  <!--****************************************************************
      * inline-nt-refs mode:  replace all references with their rhs.
      * 
      * The caller is responsible for ensuring that there are no 
      * recursive calls.
      ****************************************************************
      *-->
  <xsl:template match="nonterminal" mode="inline-nt-refs">
    <xsl:variable name="nt" as="xs:string" select="@name/string()"/>
    
    <xsl:element name="alts">
      <xsl:apply-templates select="//rule[@name=$nt]/alt" mode="inline-nt-refs"/>
    </xsl:element>
  </xsl:template>

  
  <!--****************************************************************
      * Functions
      ****************************************************************
      *-->
  <xsl:function name="gt:range-bound-to-char" as="xs:string">
    <xsl:param name="s" as="xs:string"/>
    <xsl:sequence select="if (string-length($s) eq 1)
      then $s
      else if (starts-with($s, '#') and (translate($s, '#0123456789abcdefABCDEF', '') eq ''))
      then codepoints-to-string(d2x:x2d(substring($s, 2)))
      else ''"/>
  </xsl:function>

  <xsl:function name="gt:ensafen-pos-char-class" as="xs:string">
    <xsl:param name="s" as="xs:string"/>
    <xsl:sequence select="replace($s, '([\^\-\[\]])', '\\$1')"/>
  </xsl:function>

  <xsl:function name="gt:ensafen-literal" as="xs:string">
    <xsl:param name="s" as="xs:string"/>
    <xsl:sequence select="replace($s, '([\^\-\[\]\{\}\.\\\?*+()\|])', '\\$1')"/>
  </xsl:function>
  
  <!--****************************************************************
      * Predicates 
      *-->

  <!--****************************************************************
      * Miscellaneous
      *-->

  <xsl:template name="define-extension-patterns">
    <!-- Extension attributes are any namespace-qualified attributes -->
    <rng:define name="extension-attributes">
      <rng:zeroOrMore>
	<rng:ref name="nsq-att"/>
      </rng:zeroOrMore>
    </rng:define>
    <rng:define name="nsq-att">
      <rng:attribute>
	<rng:anyName>
          <rng:except>
            <rng:nsName ns=""/>
          </rng:except>
	</rng:anyName>
      </rng:attribute>
    </rng:define>
    
    <!-- Extension elements are any namespace-qualified elements -->
    <rng:define name="extension-elements">
      <rng:zeroOrMore>
	<rng:ref name="nsq-element"/>
      </rng:zeroOrMore>
    </rng:define>
    <rng:define name="nsq-element">
      <rng:element>
	<rng:anyName>
          <rng:except>
            <rng:nsName ns=""/>
          </rng:except>
	</rng:anyName>
	<rng:ref name="anything"/>	
      </rng:element>
    </rng:define>
    
    <!-- Extension elements can include anything, including
	 unqualified elements and ixml elements -->
    <rng:define name="anything">
      <rng:zeroOrMore>
	<rng:choice>
          <rng:ref name="any-element"/>
          <rng:ref name="any-attribute"/>
          <rng:text/>
	</rng:choice>
      </rng:zeroOrMore>
    </rng:define>
    <rng:define name="any-element">
      <rng:element>
	<rng:anyName/>
	<rng:ref name="anything"/>
      </rng:element>
    </rng:define>
    <rng:define name="any-attribute">
      <rng:attribute>
	<rng:anyName/>
      </rng:attribute>
    </rng:define>
    
  </xsl:template>
  
</xsl:stylesheet>
