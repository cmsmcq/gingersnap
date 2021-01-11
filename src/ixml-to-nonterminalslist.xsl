<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:gt="http://blackmesatech.com/2020/grammartools"
		xmlns:xs="http://www.w3.org/2001/XMLSchema"
		version="3.0">

  <!--* Read ixml.xml grammar, produce list of nonterminals,
      * their children, and their descendants.  Mark
      * recursive nonterminals.
      *-->

  <!--* 2020-11-28 : CMSMcQ : made stylesheet *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->

  <xsl:output method="xml"
	      indent="yes"/>

  <!--****************************************************************
      * Main / starting template
      ****************************************************************
      *-->
  <xsl:template match="ixml">
    <xsl:variable name="lnDef"
		  as="xs:string*"
		  select="distinct-values(
			  rule/@name/string()
			  )"/>
    <xsl:variable name="lnRef"
		  as="xs:string*"
		  select="distinct-values(
			  rule/descendant::nonterminal/@name/string()
			  )"/>
    <xsl:variable name="lnUndef"
		  as="xs:string*"
		  select="$lnRef[not(. = $lnDef)]"/>
    <xsl:variable name="lnUnref"
		  as="xs:string*"
		  select="$lnDef[not(. = $lnRef)]"/>
    
    <xsl:element name="nonterminals-report">
      <xsl:element name="p">
	<xsl:text>Nonterminals in grammar.</xsl:text>
      </xsl:element>
      <xsl:element name="p">
	<xsl:text>Input: </xsl:text>
	<xsl:value-of select="base-uri(.)"/>
      </xsl:element>
      <xsl:element name="p">
	<xsl:text>Calculated </xsl:text>
	<xsl:value-of select="current-dateTime()"/>
	<xsl:text> by ixml-to-nonterminalslist.xsl.</xsl:text>
      </xsl:element>
      <xsl:apply-templates/>
      <xsl:element name="unreferenced">
	<xsl:for-each select="$lnUnref">
	  <xsl:sort select="lower-case(.)"/>
	  <xsl:element name="nonterminal">
	    <xsl:attribute name="name" select="."/>
	  </xsl:element>
	</xsl:for-each>
      </xsl:element>
      <xsl:element name="undeclared">
	<xsl:for-each select="$lnUndef">
	  <xsl:sort select="lower-case(.)"/>
	  <xsl:element name="nonterminal">
	    <xsl:attribute name="name" select="."/>
	  </xsl:element>
	</xsl:for-each>
      </xsl:element>
    </xsl:element>
  </xsl:template>


  <xsl:template match="rule">
    <xsl:variable name="n"
		  as="xs:string"
		  select="string(@name)"/>
    <xsl:variable name="lnChildren"
		  as="xs:string*"
		  select="gt:lnChildrenXGN(.., $n)"/>
    <xsl:variable name="lnDescendants"
		  as="xs:string*"
		  select="gt:lnDescXGN(.., $n)"/>
		     
    <xsl:element name="nonterminal">
      <xsl:sequence select="@name"/>
      <xsl:attribute name="recursive"
		     select="($n = $lnDescendants)"/>
      <xsl:for-each select="$lnChildren">
	<xsl:sort select="lower-case(.)"/>
	<xsl:element name="child">
	  <xsl:attribute name="name" select="."/>
	</xsl:element>
      </xsl:for-each>
      <xsl:for-each select="$lnDescendants
			    [not(. = $lnChildren)]">
	<xsl:sort select="lower-case(.)"/>
	<xsl:element name="descendant">
	  <xsl:attribute name="name" select="."/>
	</xsl:element>
      </xsl:for-each>
    </xsl:element>
  </xsl:template>  

  <!--****************************************************************
      * Functions
      ****************************************************************
      *-->

  <!--* lnChildrenXGN:
      * list of nonterminal children
      * from grammar G, nonterminal N
      *-->
  <xsl:function name="gt:lnChildrenXGN"
		as="xs:string*">
    <xsl:param name="G" as="element(ixml)"/>
    <xsl:param name="n" as="xs:string"/>

    <xsl:sequence select="distinct-values(
			  $G/rule[@name=$n]/descendant::nonterminal
			  /@name/string())"/>
  </xsl:function>

  
  <!--* gt:lnDescXGN:
      * list of nonterminal descendants
      * from grammar G, nonterminal N
      *-->
  <xsl:function name="gt:lnDescXGN"
		as="xs:string*">
    <xsl:param name="G" as="element(ixml)"/>
    <xsl:param name="n" as="xs:string"/>

    <xsl:sequence select="gt:lnDescXGNAQ($G, $n, (), $n)"/>
  </xsl:function>
  
  
  <!--* gt:lnDescXGNAQ:
      * list of nonterminal descendants
      * from grammar G, nonterminal N
      * given accumulator A, queue Q.
      *-->
  <xsl:function name="gt:lnDescXGNAQ"
		as="xs:string*">
    <xsl:param name="G" as="element(ixml)"/>
    <xsl:param name="n" as="xs:string"/>
    <xsl:param name="acc" as="xs:string*"/>
    <xsl:param name="queue" as="xs:string*"/>

    <xsl:variable name="lnCandidates"
		  as="xs:string*"
		  select="distinct-values(
			  $G/rule[@name=$queue]/descendant::nonterminal
			  /@name/string())"/>

    <xsl:variable name="lnNew"
		  as="xs:string*"
		  select="$lnCandidates
			  [ not( . = $acc) ]"/>

    <xsl:sequence select="if (empty($lnNew))
      then $acc
      else gt:lnDescXGNAQ($G, $n, ($acc, $lnNew), $lnNew)"/>
  </xsl:function>
  
</xsl:stylesheet>
