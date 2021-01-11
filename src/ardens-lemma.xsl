<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    default-mode="ardens-lemma"
    version="3.0">

  <!--* ardens-lemma.xsl
      * Read ixml.xml grammar, write it out again, applying Arden's
      * lemma to the specified rule.
      *
      * Arden's lemma is that if P is not nullable, then
      * (L = B; P, L) if and only if (L = P*, B).
      *
      * We don't actually perform the non-nullable check on P; we
      * would if we could think of any easy way to do it.  But for
      * now, it's the user's responsibility.  
      *
      * This is used in simplifying FSAs.
      *-->

  <!--* Revisions:
      * 2020-12-13 : CMSMcQ : made stylesheet, for the process of
      *                       working with R_0 grammars.
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->

  <xsl:output method="xml"
	      indent="yes"/>

  <xsl:mode name="ardens-lemma" on-no-match="shallow-copy"/>
  <xsl:mode name="prefix-cleaning" on-no-match="shallow-copy"/>


  <!--****************************************************************
      * Templates
      ****************************************************************
      *-->
  <xsl:template match="rule">
    <xsl:param name="nonterminal"
	       as="xs:string*"
	       tunnel="yes"
	       required="yes"/>
    
    <xsl:choose>
      <!--* if the rule's name matches any name in the list of
	  * nonterminals to be handled, then process it.
	  *-->
      <xsl:when test="@name = $nonterminal">

	<xsl:variable name="rulename"
		      as="xs:string"
		      select="string(@name)"/>

	<!--* Prefix RHS are those of the form (L: P L) *-->
	<xsl:variable name="prefix-RHS"
		      as="element(alt)+"
		      select="alt[
			      *[last()]/self::nonterminal[@name = $rulename]
			      ]"/>

	<!--* Base RHS are everything else *-->
	<xsl:variable name="base-RHS"
		      as="element(alt)+"
		      select="alt except $prefix-RHS"/>

	<!--* copy the rule *-->
	<xsl:copy>
	  <xsl:sequence select="@*"/>

	  <xsl:element name="comment">
	    <xsl:text> Arden's lemma has been applied here. </xsl:text>
	  </xsl:element>

	  <!--* we want (P)*, (B) *-->
	  <xsl:element name="alt">
	    <xsl:attribute name="rtn:ruletype"
			   select=" 'ardens-lemma-result' "/>

	    <!--* (P)* *-->
	    <xsl:element name="repeat0">
	      <xsl:element name="alts">
		<!--* 
		    <xsl:sequence select="$prefix-RHS"/>
		    *-->
		
	    	<xsl:apply-templates select="$prefix-RHS"
				     mode="prefix-cleaning">
		  <xsl:with-param name="target"
				  select="$rulename"/>
		</xsl:apply-templates>

  	      </xsl:element>
	    </xsl:element>
	    
	    <!--* (B) *-->
	    <xsl:element name="alts">
	      <xsl:sequence select="$base-RHS"/>
	    </xsl:element>	    

	  </xsl:element>
	  
	</xsl:copy>
      </xsl:when>

      <!--* if the name does not match, leave the rule alone. *-->
      <xsl:otherwise>
	<xsl:copy-of select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="nonterminal"
		mode="prefix-cleaning">
    <xsl:param name="target" required="yes"/>
    <xsl:choose>
      <xsl:when test="@name = $target"/>
      <xsl:otherwise>
	<xsl:copy-of select="."/>
      </xsl:otherwise>      
    </xsl:choose>
  </xsl:template>

  
  
</xsl:stylesheet>
