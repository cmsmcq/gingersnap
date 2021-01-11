<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:d2x="http://www.blackmesatech.com/2014/lib/d2x"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    default-mode="normalize-terminals"
    version="3.0">

  <!--* normalize-terminals.xsl
      * Read ixml.xml grammar, write it out again, normalizing
      * terminals to make determinization easier.
      * . Replace multi-character literals with a sequence of
      *   one-character literals.  Exact markup of result depends on
      *   context (literal+ or alts/alt/literal+).
      * . In every range, literal, or class, add gt:ranges attribute
      *   with a sequence of ranges.  Value to be an even number
      *   of natural numbers in ascending order, with the obvious
      *   meaning.
      * . In every inclusion, take the union of the ranges (and
      *   get them into the right order).
      * . In every exclusion, first take the union of the ranges
      *   and then subtract that from the ranges in $xmlchar.
      *-->

  <!--* Revisions:
      * 2020-12-28 : CMSMcQ : split into main and module to quiet Saxon
      * 2020-12-28 : CMSMcQ : move merge-elements function into
      *                       range-operations, needed elsewhere
      * 2020-12-25 : CMSMcQ : bug fix
      * 2020-12-24 : CMSMcQ : move most functions to range-operations 
      * 2020-12-23 : CMSMcQ : add test cases, union operation, ... 
      * 2020-12-22 : CMSMcQ : broaden focus from just splitting 
      *                       literals to general terminal 
      *                       normalization.
      * 2020-12-21 : CMSMcQ : made stylesheet, as preparatory step 
      *                       for making regular grammars / FSAs
      *                       deterministic.
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->

  <xsl:mode name="normalize-terminals" on-no-match="shallow-copy"/>

  <xsl:variable name="dq" as="xs:string" select=" &apos;&quot;&apos; "/>
  <xsl:variable name="sq" as="xs:string" select=" &quot;&apos;&quot; "/>

  <xsl:variable name="lrXMLchar" as="xs:integer+"
		select="(32, 55295,
			57344, 65533,
			65537, 1114111)"/>
  <!--* XML character ranges:
      * U+0020 - U+D7FF = 32 - 55295
      * U+E000 - U+FFFD = 57344 - 65533
      * U+10000 - U+10FFFF = 65536 - 1114111
      *-->

  <xsl:variable name="character-classes"
		as="document-node(element(unicode-classes))"
		select="doc('unicode-classes.xml')"/>

  <!--****************************************************************
      * Templates
      ****************************************************************
      *-->
  <xsl:template match="text()[not(parent::comment)]"/>
    

  <!--****************************************************************
      * Literals
      *-->
  
  <!--* For literals with @hex, no splitting is needed, just
      * @gt:ranges. *-->
  <xsl:template match="literal[@hex]">
    <xsl:copy>
      <xsl:sequence select="@*"/>
      <xsl:variable name="cp" as="xs:integer"
		    select="d2x:x2d(string(@hex))"/>      
      <xsl:attribute name="gt:ranges" select="$cp, $cp"/>      
    </xsl:copy>
  </xsl:template>
  
  <!--* For literals with @dstring or @sstring, we split the string
      * if need be, and add @gt:range to each. *-->
  <xsl:template match="literal[@dstring or @sstring]">
    <!--* First, get the string. *-->
    <xsl:variable name="s" as="xs:string"
		  select="(@dstring/string(),
			  @sstring/string())[1]"/>
    
    <!--* Then generate a sequence of literal elements. *-->
    <xsl:variable name="leLiterals" as="element(literal)+">
      <xsl:for-each select="1 to string-length($s)">
	<xsl:variable name="c" as="xs:string"
		      select="substring($s, ., 1)"/>
	<xsl:variable name="cp" as="xs:integer"
		      select="string-to-codepoints($c)"/>
	<xsl:element name="literal">
	  <xsl:choose>
	    <xsl:when test="$c eq $dq">
	      <xsl:attribute name="sstring" select="$c"/>
	    </xsl:when>
	    <xsl:otherwise>
	      <xsl:attribute name="dstring" select="$c"/>
	    </xsl:otherwise>
	  </xsl:choose>
	  <xsl:attribute name="gt:ranges" select="$cp, $cp"/>
	</xsl:element>
      </xsl:for-each>
    </xsl:variable>
    
    <!--* Finally, emit the sequence, wrapping it if need be. *-->
    <xsl:choose>
      <xsl:when test="parent::alt
		      or parent::inclusion or parent::exclusion">
	<!--* Sometimes, just replace one literal with several. 
	    * So in an alt, an inclusion, or an exclusion. 
	    *-->
	<xsl:sequence select="$leLiterals"/>
      </xsl:when>
      <xsl:when test="parent::repeat0
		      or parent::repeat1 
		      or parent::option 
		      or parent::sep"> 
	<!--* Sometimes, we need to wrap the new literals in alts/alt. 
	    * So in repeat0, repeat1, option, sep.
	    *-->
	<xsl:element name="alts">
	  <xsl:element name="alt">
	    <xsl:sequence select="$leLiterals"/>
	  </xsl:element>
	</xsl:element>
      </xsl:when>
      <xsl:otherwise>
	<xsl:message terminate="yes">
	  <xsl:text>normalize-terminals:  Literal element </xsl:text>
	  <xsl:text>in unknown context (</xsl:text>
	  <xsl:value-of select="name(parent::*)"/>
	  <xsl:text>), cannot cope.</xsl:text>
	</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>

  <!--****************************************************************
      * Ranges 
      *-->
  <xsl:template match="range">
    <xsl:copy>
      <xsl:sequence select="@*"/>

      <!--* @from and @to are either a literal character or
	  * '#' plus a hex code. *-->
      <xsl:variable name="cpFrom" as="xs:integer"
		    select="if (string-length(@from) gt 1)
			    then d2x:x2d(substring(@from, 2))
			    else string-to-codepoints(@from)"/>
      <xsl:variable name="cpTo" as="xs:integer"
		    select="if (string-length(@to) gt 1)
			    then d2x:x2d(substring(@to, 2))
			    else string-to-codepoints(@to)"/>
      <xsl:if test="$cpTo lt $cpFrom">
	<xsl:message terminate="yes">
	  <xsl:text>normalize-terminals:  Range element </xsl:text>
	  <xsl:text>has bad range (</xsl:text>
	  <xsl:value-of select="concat($cpFrom, ' - ', $cpTo)"/>
	  <xsl:text>), cannot cope.</xsl:text>
	  <xsl:text>&#xA;(What *should* that mean, by the way?)</xsl:text>
	</xsl:message>
      </xsl:if>
      <xsl:attribute name="gt:ranges" select="$cpFrom, $cpTo"/>
    </xsl:copy>
  </xsl:template>

  <!--****************************************************************
      * Unicode classes
      *-->
  <xsl:template match="class">
    <xsl:copy>
      <xsl:sequence select="@*"/>

      <xsl:variable name="code" as="xs:string"
		    select="string(@code)"/>
      <xsl:variable name="eInclusion"
		    as="element(inclusion)?"
		    select="$character-classes/unicode-classes
			    /inclusion[@gt:code = $code]"/>
      <xsl:choose>
	<xsl:when test="exists($eInclusion)">
	  <xsl:sequence select="$eInclusion/@gt:ranges"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:message terminate="yes">
	    <xsl:text>normalize-terminals:  Class element </xsl:text>
	    <xsl:text>has a class code (</xsl:text>
	    <xsl:value-of select="$code"/>
	    <xsl:text>) for which no ranges are known.</xsl:text>
	  </xsl:message>
	  <!--* to do:  create the ranges here, by interrogation of
	      * Saxon.  Example in class-codes-to-ranges.xq. *-->
	</xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

  <!--****************************************************************
      * Inclusions 
      *-->
  <xsl:template match="inclusion">
    
    <!--* Normalize the children; then they'll have @gt:ranges. *-->
    <xsl:variable name="leCh" as="element()*">
      <xsl:apply-templates select="*"/>
    </xsl:variable>

    <!--* Merge the children's ranges, one by one. *-->
    <xsl:variable name="lrMerged" as="xs:integer*">
      <xsl:sequence select="gt:merge-element-ranges($leCh)"/>
    </xsl:variable>

    <!--* Write it all out. *-->
    <xsl:copy>
      <xsl:sequence select="@*"/>
      <xsl:attribute name="gt:ranges" select="$lrMerged"/>
      <xsl:sequence select="$leCh"/>
    </xsl:copy>
  </xsl:template>
  
  <!--****************************************************************
      * Exclusions 
      *-->
  <xsl:template match="exclusion">
    
    <!--* Normalize the children; then they'll have @gt:ranges. *-->
    <xsl:variable name="leCh" as="element()*">
      <xsl:apply-templates select="*"/>
    </xsl:variable>

    <!--* Merge the children's ranges, one by one. *-->
    <xsl:variable name="lrMerged" as="xs:integer*">
      <xsl:sequence select="gt:merge-element-ranges($leCh)"/>
    </xsl:variable>    

    <!--* Subtract lrMerged from the universe *-->
    <xsl:variable name="lrExcl" as="xs:integer+"
		  select="gt:lrDiff($lrXMLchar, $lrMerged)"/>
    
    <!--* Write it all out. *-->
    <xsl:copy>
      <xsl:sequence select="@*"/>
      <xsl:attribute name="gt:ranges" select="$lrExcl"/>
      <xsl:sequence select="$leCh"/>
    </xsl:copy>
  </xsl:template>
  

  <!--****************************************************************
      * Functions
      ****************************************************************
      *-->
  <!--* most functions originally defined here are now in
      * range-operations.xsl
      *-->
  
  <!--* Simple test cases *-->
  <!--* At some point these should probably migrate to
      * an XSpec test suite.
      *-->
  <xsl:template name="run-tests" as="element(test-results)">
    <xsl:variable name="element-tests" as="element(test)*">
      <test>
	<i><literal hex="41"/></i>
	<o><literal hex="41" gt:ranges="65 65"/></o>
      </test>
      <test>
	<i><alt><literal dstring="then"/></alt></i>
	<o><alt>
	  <literal dstring="t" gt:ranges="116 116"/>
	  <literal dstring="h" gt:ranges="104 104"/>
	  <literal dstring="e" gt:ranges="101 101"/>
	  <literal dstring="n" gt:ranges="110 110"/>
	</alt></o>
      </test>
      <test>
	<i><range from="a" to="z"/></i>
	<o><range from="a" to="z" gt:ranges="97 122"/></o>
      </test>
      <test>
	<i><range from="#20" to="#7f"/></i>
	<o><range from="#20" to="#7f" gt:ranges="32 127"/></o>
      </test>
      <test>
	<i><class code="Zs"/></i>
	<o><class code="Zs" gt:ranges="32 32 160 160 5760 5760 8192 8202 8239 8239 8287 8287 12288 12288"/></o>
      </test>
      <test>
	<i><inclusion>
	  <range from="b" to="c"/>
	  <range from="a" to="d"/>	  
	</inclusion></i>
	<o><inclusion gt:ranges="97 100">
	  <range from="b" to="c" gt:ranges="98 99"/>
	  <range from="a" to="d" gt:ranges="97 100"/>
	</inclusion></o>
      </test>
      <test>
	<i><inclusion>
	  <range from="b" to="z"/>
	  <range from="a" to="d"/>	  
	</inclusion></i>
	<o><inclusion gt:ranges="97 122">
	  <range from="b" to="z" gt:ranges="98 122"/>
	  <range from="a" to="d" gt:ranges="97 100"/>
	</inclusion></o>
      </test>
      <test>
	<i><inclusion>
	  <range from="x" to="z"/>
	  <range from="a" to="d"/>	  
	</inclusion></i>
	<o><inclusion gt:ranges="97 100 120 122">
	  <range from="x" to="z" gt:ranges="120 122"/>
	  <range from="a" to="d" gt:ranges="97 100"/>
	</inclusion></o>
      </test>
      <test>
	<i><inclusion>
	  <range from="a" to="d"/>
	  <range from="b" to="c"/>
	  <class code="Zs"/>
	</inclusion></i>
	<o><inclusion gt:ranges="32 32 97 100 160 160 5760 5760 8192 8202 8239 8239 8287 8287 12288 12288">
	  <range from="a" to="d" gt:ranges="97 100"/>
	  <range from="b" to="c" gt:ranges="98 99"/>
	  <class code="Zs"
		 gt:ranges="32 32 160 160 5760 5760 8192 8202 8239 8239 8287 8287 12288 12288"/>
	</inclusion></o>
      </test>
      <test>
	<i><exclusion>
	  <range from="a" to="d"/>
	  <range from="b" to="c"/>
	  <class code="Zs"/>
	</exclusion></i>
	<o><exclusion gt:ranges="33 96 101 159 161 5759 5761 8191 8203 8238 8240 8286 8288 12287 12289 55295 57344 65533 65537 1114111">
	  <!-- * min="32 55295 57344 65533 65537 1114111" *-->
	  <!--*  sub="32 32 97 100 160 160 5760 5760 8192 8202 8239
                      8239 8287 8287 12288 12288" *-->
	  <range from="a" to="d" gt:ranges="97 100"/>
	  <range from="b" to="c" gt:ranges="98 99"/>
	  <class code="Zs"
		 gt:ranges="32 32 160 160 5760 5760 8192 8202 8239 8239 8287 8287 12288 12288"/>
	</exclusion></o>
      </test>
    </xsl:variable>
    
    <test-results gt:date="{current-dateTime()}">
      <div id="element-tests">
      <xsl:for-each select="$element-tests">
	<xsl:variable name="result" as="element(o)">
	  <o><xsl:apply-templates select="i/*"/></o>
	</xsl:variable>
	<xsl:choose>
	  <xsl:when test="deep-equal(o, $result)">
	    <test n="{position()}" result="pass"/>
	  </xsl:when>
	  <xsl:otherwise>
	    <test n="{position()}" result="fail">
	      <input><xsl:sequence select="i"/></input>
	      <expected><xsl:sequence select="o"/></expected>
	      <actual><xsl:sequence select="$result"/></actual>
	    </test>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:for-each>
      </div>
    </test-results>
  </xsl:template>


</xsl:stylesheet>

