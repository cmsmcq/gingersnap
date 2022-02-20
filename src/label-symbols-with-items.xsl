<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    default-mode="item-labeling"
    version="3.0">

  <!--* label-symbols-with-items.xsl
      * Read ixml.xml grammar G, write out same grammar with an 
      * rtn:item attribute on each symbol (nonterminal, literal,
      * inclusion, exclusion) in each right-hand side.  The value of 
      * the attribute is (as the name is meant to suggest) an 'item'
      * in the sense usual in parsing:  a copy of the right-hand
      * side with a dot indicating position.
      *-->

  <!--* Revisions:
      * 2022-02-19 : CMSMcQ : Made file, trying to make it a little
      *                       easier to read epsilon-free O_0 
      *                       approximations.
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->
  
  <xsl:mode name="item-labeling" on-no-match="shallow-copy"/>

  <!--* fissile and non-fissile copied in from ixml-to-saprg.lib.xsl.
      * They are not actually used in this stylesheet. *-->
  
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
    
    <xsl:copy>
      <xsl:sequence select="@*"/>
      <xsl:attribute name="gt:date" select="current-dateTime()"/>
      <xsl:element name="comment">
	<xsl:value-of select="current-dateTime()"/>
	<xsl:text>: item-labeling.xsl.</xsl:text>
      </xsl:element>
      <xsl:element name="comment">
	<xsl:text>    Input: </xsl:text>
	<xsl:value-of select="base-uri(/)"/>
      </xsl:element>
      <xsl:element name="comment">
	<xsl:text>    Output:  same grammar with item labels added. </xsl:text>
      </xsl:element>
      
      <xsl:text>&#xA;</xsl:text>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <!--* Inject the attribute *-->
  <xsl:template match="nonterminal | literal | inclusion | exclusion">
    <xsl:copy>
      <xsl:sequence select="@* except rtn:item"/>
      <xsl:attribute name="rtn:item">
	<xsl:apply-templates mode="item-string"
			     select="ancestor::alt[parent::rule]">
	  <xsl:with-param name="kilroy" select="."
			  as="node()" tunnel="yes"/>
	</xsl:apply-templates>
      </xsl:attribute>
      <xsl:apply-templates select="child::node()"/>
    </xsl:copy>
  </xsl:template>

  <!--* Calculate the string for the attribute *-->
  <xsl:template match="rule/alt" mode="item-string">
    <xsl:sequence select="../@name/string()"/>
    <xsl:text> = </xsl:text>
    <xsl:apply-templates mode="item-string"/>
    <xsl:text>.</xsl:text>
  </xsl:template>

  <!--* descendants of alt we need to handle
      * -term, -factor, ^option, ^repeat0, ^repeat1
      * -terminal, ^nonterminal, ^alts, ^alt
      * ^sep, ^literal, -charset, -quoted, -encoded,
      * ^inclusion, ^exclusion
      *-->
  <xsl:template mode="item-string" match="alts/alt">
    <xsl:apply-templates mode="item-string"/>
    <xsl:if test="following-sibling::alt">
      <xsl:text> | </xsl:text>
    </xsl:if>
  </xsl:template>
  
  <xsl:template mode="item-string" match="alts">
    <xsl:text>(</xsl:text> 
    <xsl:apply-templates mode="item-string"/>   
    <xsl:text>)</xsl:text>
    <xsl:call-template name="seq-delimiter"/>
  </xsl:template>
  
  <xsl:template mode="item-string" match="repeat0">
    <xsl:apply-templates mode="item-string" select="* except sep"/>
    <xsl:text>*</xsl:text>
    <xsl:apply-templates mode="item-string" select="sep"/>
    <xsl:call-template name="seq-delimiter"/>
  </xsl:template>
  
  <xsl:template mode="item-string" match="repeat1">
    <xsl:apply-templates mode="item-string" select="* except sep"/>
    <xsl:text>+</xsl:text>
    <xsl:apply-templates mode="item-string" select="sep"/>
    <xsl:call-template name="seq-delimiter"/>
  </xsl:template>
  
  <xsl:template mode="item-string" match="sep"> 
    <xsl:apply-templates mode="item-string"/>
  </xsl:template>
  
  <xsl:template mode="item-string" match="option"> 
    <xsl:apply-templates mode="item-string"/>   
    <xsl:text>?</xsl:text>
    <xsl:call-template name="seq-delimiter"/>
  </xsl:template>
  
  <xsl:template mode="item-string" match="nonterminal">
    <xsl:variable name="nt" as="xs:string" select="@name"/>
    <xsl:variable name="mark" as="xs:string"
		  select="(@mark, 
			  /ixml/rule[@name=$nt]/@mark,
			  '^')[1]"/>
    <xsl:sequence select="$mark || $nt"/>
    <xsl:call-template name="mark-if-kilroy"/>
    <xsl:call-template name="seq-delimiter"/>
  </xsl:template>
  
  <xsl:template mode="item-string" match="literal">
    <xsl:choose>
      <xsl:when test="@string or @dstring or @sstring">
	<xsl:variable name="s" as="xs:string"
		      select="(@string/string(),
			      @dstring/string(),
			      @sstring/string())[1]"/>
	<xsl:text>"</xsl:text>
	<xsl:sequence select="replace($s,'&quot;', '&quot;&quot;')"/>
	<xsl:text>"</xsl:text>
      </xsl:when>
      <xsl:when test="@hex">
	<xsl:text>#</xsl:text>
	<xsl:sequence select="@hex/string()"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:text>&#x1d350;</xsl:text>
	<!-- U+1D350, tetragram for failure -->
      </xsl:otherwise>
    </xsl:choose>
    <xsl:call-template name="mark-if-kilroy"/>
    <xsl:call-template name="seq-delimiter"/>
    <xsl:call-template name="charset-delimiter"/>
  </xsl:template>
  
  <xsl:template mode="item-string" match="inclusion">
    <xsl:text>[</xsl:text> 
    <xsl:apply-templates mode="item-string"/>   
    <xsl:text>]</xsl:text>
    <xsl:call-template name="mark-if-kilroy"/>
    <xsl:call-template name="seq-delimiter"/>
  </xsl:template>
  
  <xsl:template mode="item-string" match="exclusion">
    <xsl:text>~[</xsl:text> 
    <xsl:apply-templates mode="item-string"/>   
    <xsl:text>]</xsl:text>
    <xsl:call-template name="mark-if-kilroy"/>
    <xsl:call-template name="seq-delimiter"/>
  </xsl:template>
  
  <xsl:template mode="item-string" match="range">
    <xsl:text>"</xsl:text>
    <xsl:value-of select="replace(@from,'&quot;','&quot;&quot;')"/>
    <xsl:text>"-"</xsl:text> 
    <xsl:value-of select="replace(@to,'&quot;','&quot;&quot;')"/>
    <xsl:text>"</xsl:text>
    <xsl:call-template name="charset-delimiter"/>
  </xsl:template>
  
  <xsl:template mode="item-string" match="class">
    <xsl:value-of select="@code"/>
    <xsl:call-template name="charset-delimiter"/>
  </xsl:template>

  <!--* We want items short and sweet.  No comments. *-->
  <xsl:template mode="item-string" match="comment"/>

  <xsl:template mode="item-string" match="text() | comment() | processing-instruction()"/>

  <!--* Sequence delimiters:  the logic here is just complicated
      * enough to factor out. 
      *-->
  <xsl:template name="seq-delimiter">
    <xsl:if test="parent::alt
		  and following-sibling::*[not(self::comment)]">
      <xsl:text>, </xsl:text>
    </xsl:if>
  </xsl:template>
  
  <xsl:template name="charset-delimiter">
    <xsl:if test="(parent::inclusion or parent::exclusion)
		  and following-sibling::*[not(self::comment)]">
      <xsl:text>; </xsl:text>
    </xsl:if>
  </xsl:template>

  <!--* Ditto for the actual mark.  We factor it out to a template
      * partly so if we want to shift to a different character
      * it's all in one place. *-->
  <!-- B7 middle dot
       2022 bullet
       2981 z notation spot
       25CF black circle
       25CB white circle
  -->
  <xsl:template name="mark-if-kilroy">
    <xsl:param name="kilroy" as="node()" tunnel="yes"/>
    <xsl:if test=". is $kilroy">
      <xsl:text> &#x2981; </xsl:text>
    </xsl:if>
  </xsl:template>
  
  <!--****************************************************************
      * Functions
      ****************************************************************
      *-->
  
  <!--****************************************************************
      * Predicates 
      *-->
  
</xsl:stylesheet>
