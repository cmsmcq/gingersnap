<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    default-mode="dnf-from-andor"
    version="3.0">

  <!--* dnf-from-andor.xsl: Read ixml.xml grammar G, write out
      * equivalent grammar G' in disjunctive normal form.
      *-->

  <!--* Revisions:
      * 2021-01-18 : CMSMcQ : draft transform
      *-->

  <!--* To do:
      * . At some point include rules for empty set / unsatisfiable
      *   expressions.
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->
  
  <xsl:mode name="dnf-from-andor" on-no-match="shallow-copy"/>
  <xsl:strip-space elements="*"/>
  <xsl:output method="xml" indent="yes"/>

  <!--* loops: what is maximum number of rounds of simplification?
      * When do we quit if we don't reach a steady state?
      *-->
  <xsl:variable name="loops" as="xs:integer" select="100"/>
  
  <!--****************************************************************
      * Main / starting template
      ****************************************************************
      *-->
  <xsl:template match="ixml">
    
    <xsl:copy>
      <xsl:sequence select="@*"/>
      <xsl:attribute name="gt:date" select="current-dateTime()"/>
      <xsl:element name="comment">
	<xsl:value-of select="current-dateTime()"/>
	<xsl:text>: dnf-from-andor.xsl.</xsl:text>
      </xsl:element>
      <xsl:element name="comment">
	<xsl:text>    Input: </xsl:text>
	<xsl:value-of select="base-uri(/)"/>
      </xsl:element>
      <xsl:element name="comment">
	<xsl:text>    Output:  equivalent grammar in </xsl:text>
	<xsl:text>disjunctive normal form.</xsl:text>
      </xsl:element>
      
      <xsl:text>&#xA;</xsl:text>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="rule">
    <xsl:param name="loops" as="xs:integer" tunnel="yes"
	       select="$loops"/>
    <xsl:sequence select="gt:dnf(., $loops)"/>
  </xsl:template>


  <!--****************************************************************
      * Functions
      ****************************************************************
      *-->
  <xsl:function name="gt:dnf" as="element(rule)">
    <xsl:param name="r0" as="element(rule)"/>
    <xsl:param name="ttl" as="xs:integer"/>

    <xsl:choose>
      <xsl:when test="$ttl le 0">
	<!--* time to live is zero, give up and go home *-->
	<xsl:message>dfn() ran out of time.</xsl:message>
	<xsl:sequence select="$r0"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:variable name="r" as="element(rule)">
	  <xsl:copy select="$r0">
	    <xsl:sequence select="$r0/@*"/>
	    <xsl:apply-templates select="$r0/*"/>
	  </xsl:copy>
	</xsl:variable>

	<xsl:choose>
	  <xsl:when test="deep-equal($r, $r0)">
	    <xsl:message>
	      <xsl:text>dfn() reached fixed point </xsl:text>
	      <xsl:text>with </xsl:text>
	      <xsl:value-of select="$ttl"/>
	      <xsl:text> ticks left to live.</xsl:text>
	    </xsl:message>
	    <xsl:sequence select="$r0"/>
	  </xsl:when>
	  <xsl:otherwise>
	    <!--* not there yet, try again *-->
	    <xsl:sequence select="gt:dnf($r, $ttl - 1)"/>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <!--* (E, (F, G)) = ((E, F), G) = (E, F, G) *-->
  <!--* (E, (F; G)) = (E, F); (E, G)  *-->
  <!--* ((E; F), G)) = (E, G); (F, G)  *-->
  <!--* (E; (F; G)) = ((E; F); G) = (E; F; G) *-->
  <!--* Do this simplification from the inside out.  That is,
      * start at the level in which a sequence (alt) has a
      * single level of choices beneat it.  We'll do the
      * higher levels in later passes.
      * We are not trying for speed here (maybe later),
      * first we want a correct working program.
      *-->
  <xsl:template match="alt[alts][not(alts/alt/alts)]">
    <xsl:apply-templates select="alts[1]/alt" mode="promotion"/>
  </xsl:template>

  <xsl:template match="alt" mode="promotion">
    <xsl:copy>
      <xsl:sequence select="parent::alts/parent::alt/@*"/>
      <xsl:sequence select="@*"/>
      <!--* I think it's safe to use apply-templates and not
	  * sequence here, and better to do so.  But I'm unsure
	  * enough that I'm writing this note.  If something
	  * goes wrong, future me, you might consider shifting
	  * all of these to just sequence and see if that helps.
	  * It may cost more passes.  Boo hoo.
	  *-->
      <xsl:apply-templates select="parent::alts/preceding-sibling::*"/>
      <xsl:apply-templates select="*"/>
      <xsl:apply-templates select="parent::alts/following-sibling::*"/>
    </xsl:copy>
  </xsl:template>
  
  <!--* It may not be obvious that the single pair of rules just given
      * handle all these cases; it may be clearer if I rewrite
      * them in Lispish notation.
      *
      * Sequence within sequence:  rule applies at outer level.
      * (alt E (alts (alt F G))) = (alt (alts (alt E F)) G) 
      *     = (alt E F G) 
      *
      * Choice within sequence:  rule at outer level.
      * (alt E (alts (alt F) (alt G))) = (alt E F) (alt F G)
      * (alt (alts (alt E) (alt F)) G) = (alt E G) (alt F G)
      *
      * Choice within choice:  rule applies to outer 'fat' alt.
      * (alts (alt E) (alt (alts (alt F) (alt G)))) 
      * = (alts (alt (alts (alt E) (alt F))) (alt G))
      * = (alts (alt E) (alt F) (alt G))
      *-->

  <!--* I think this epsilon rule is a nop. *-->
  <!--* ('', E) = (E, '') = E *-->
  <!--* This can be very useful but I think I can get by for a bit
      * without it. *-->
  <!--* (E; E) = E *-->

  
  <!--****************************************************************
      * Predicates 
      *-->
  
</xsl:stylesheet>
