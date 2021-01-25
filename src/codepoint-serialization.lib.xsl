<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    exclude-result-prefixes="gt xs gl rtn follow"
    version="3.0">

  <!--* codepoint serialization.xsl: functions for turning a terminal
      * symbol into a string.
      *
      *-->

  <!--* Revisions:
      * 2021-01-24 : CMSMcQ : fix an oversight in the handling of range
      *                       lists with a single range.
      * 2021-01-23 : CMSMcQ : split off from tcrecipes-to-testcases, so 
      *                       the functions can also be used in
      *                       testcases-from-parsetrees.xsl
      *-->


  <!--* codepoint selector:  how do we choose a code point
      * from a given range?
      *-->
  <xsl:variable name="cp-selector" as="xs:string" static="yes"
		select="('first',
			'last',
			'better-than-nothing',
			'random', 
			'guided'
			)[3]"/>


  <!--****************************************************************
      * Functions
      ****************************************************************
      *-->

  <!--* serialize($leTerminals): return a string made from this
      * sequence of terminals
      *-->
  <xsl:function name="gt:serialize" as="xs:string">
    <xsl:param name="leTerminals" as="element()*"/>

    <!--* make a sequence of code points *-->
    <xsl:variable name="lcp" as="xs:integer*">
      <xsl:for-each select="$leTerminals">
	<xsl:variable name="lr" as="xs:integer*"
		      select="for $t
			      in tokenize(@gt:ranges, '\s+')
			      [normalize-space()]
			      return xs:integer($t)
			      "/>
	<xsl:sequence select="if ((count($lr) eq 2)
			          and ($lr[1] eq $lr[2]))
			      then $lr[1]
			      else if (count($lr) eq 0)
			      then ()
			      else gt:pick-codepoint($lr, .)
			      "/>
      </xsl:for-each>
    </xsl:variable>
    
    <!--* return the string they make *-->
    <xsl:sequence select="codepoints-to-string($lcp)"/>
  </xsl:function>

  <!--* pick-codepoint($lr, $terminal): return a code point
      * for the range list passed in as argument.  The
      * terminal symbol is only there for obfuscation.
      *-->
  <xsl:function name="gt:pick-codepoint" as="xs:integer">
    <xsl:param name="lr" as="xs:integer+"/>
    <xsl:param name="eTerminal" as="element()"/>

    <!--* Simple-minded hacks:  return first or last character
	* of the terminal *-->
    <xsl:sequence use-when="$cp-selector eq 'first'"
		  select="$lr[1]"/>
    <xsl:sequence use-when="$cp-selector eq 'last'"
		  select="$lr[last()]"/>

    <!--* slightly better than nothing:  return a character
	* from somewhere among the ranges.
	*-->
    <!--* c:  how many items are in $lr?  Two for each range. *-->
    <xsl:variable name="c" as="xs:integer"
		  use-when="$cp-selector eq 'better-than-nothing'"
		  select="count($lr)"/>
    <!--* nT is an arbitrary number to try to simulate randomness *-->
    <xsl:variable name="nT" as="xs:integer"
		  use-when="$cp-selector eq 'better-than-nothing'"
		  select="1 + count($eTerminal/preceding-sibling::*)"/>
    <!--* nR is now misnamed, no longer number of rule, but an
	* arbitrary larger number. *-->
    <xsl:variable name="nR" as="xs:integer"
		  use-when="$cp-selector eq 'better-than-nothing'"
		  select="1 + count($eTerminal/preceding::*)"/>
    <!-- For the record (why?  who cares?), the initial version
	 is reproduced here.  It works badly for parse-trees, which
	 lack rule elements. -->
    <!-- <xsl:variable name="nR" as="xs:integer"
		  use-when="$cp-selector eq 'better-than-nothing'"
		  select="1 + count($eTerminal
			  /ancestor::rule
			  /preceding-sibling::*)"/> -->

    <!--* iIndex:  an integer index into $lr *-->
    <xsl:variable name="iIndex" as="xs:integer"
		  use-when="$cp-selector eq 'better-than-nothing'"
		  select="1 + ($nR * $nT) mod $c"/>
    <xsl:choose use-when="$cp-selector eq 'better-than-nothing'">
      <!--* some of the time, take the index value, which will
	  * be either the minimum or the maximum of a range *-->
      <xsl:when test="$nR mod 3 = 0">
	<xsl:sequence select="$lr[$iIndex]"/>
      </xsl:when>
      <!--* at other times, take something in the middle *-->
      <xsl:otherwise>
	<!--* Get the min and max of the range *-->
	<xsl:variable name="iMin" as="xs:integer"
		      select="if ($iIndex mod 2 eq 1)
			      then $lr[$iIndex]
			      else $lr[$iIndex - 1]"/>
	<xsl:variable name="iMax" as="xs:integer"
		      select="if ($iIndex mod 2 eq 1)
			      then $lr[$iIndex + 1]
			      else $lr[$iIndex]"/>

	<xsl:variable name="iIncrement" as="xs:integer"
		      select="round(
			      ($iMax - $iMin)
			      * (min(($nT, $nR))
			      div
			      max(($nT, $nR)))
			      ) cast as xs:integer"/>
	
	<xsl:sequence select="$iMin + $iIncrement"/>
      </xsl:otherwise>
    </xsl:choose>

    <!--* random: use a random number generator *-->
    <xsl:message use-when="$cp-selector eq 'random'"
		 terminate="yes">
      <xsl:text>Random character selection has not </xsl:text>
      <xsl:text>been implemented. </xsl:text>
    </xsl:message>
      
    <!--* guided: accept a configuration file, pick from it
	* somehow tbd *-->
    <xsl:message use-when="$cp-selector eq 'guided'"
		 terminate="yes">
      <xsl:text>Guided character selection has not </xsl:text>
      <xsl:text>been implemented. </xsl:text>
    </xsl:message>
    
  </xsl:function>

  <xsl:function name="gt:pick-codepoint" as="xs:integer"
		use-when="false()">
    <xsl:param name="eTerminal" as="element()"/>

    <xsl:if test="normalize-space($eTerminal/@gt:ranges) = ''">
      <xsl:message terminate="yes">
	<xsl:text>Encountered a terminal without </xsl:text>
	<xsl:text>@gt:ranges, dying.</xsl:text>
      </xsl:message>
    </xsl:if>

    <xsl:variable name="lr" as="xs:integer+"
		  select="for $t
			  in tokenize($eTerminal/@gt:ranges, '\s+')
			  return xs:integer($t)"/>

    <!--* Simple-minded hacks:  return first or last character
	* of the terminal *-->
    <xsl:sequence use-when="$cp-selector eq 'first'"
		  select="$lr[1]"/>
    <xsl:sequence use-when="$cp-selector eq 'last'"
		  select="$lr[last()]"/>

    <!--* slightly better than nothing:  return a character
	* from somewhere among the ranges.  (Currently
	* always the start or end of an atomic range; later,
	* make it sometimes pick a middle code point.)
	*-->
    <xsl:variable name="c" as="xs:integer"
		  use-when="$cp-selector eq 'better-than-nothing'"
		  select="count($lr)"/>
    <xsl:variable name="nT" as="xs:integer"
		  use-when="$cp-selector eq 'better-than-nothing'"
		  select="count($eTerminal/preceding-sibling::*)"/>
    <xsl:variable name="nR" as="xs:integer"
		  use-when="$cp-selector eq 'better-than-nothing'"
		  select="count($eTerminal
			  /ancestor::rule
			  /preceding-sibling::*)"/>
    <xsl:sequence use-when="$cp-selector eq 'better-than-nothing'"
		  select="$lr[1 + ($nR * $nT) mod $c]"/>

    <!--* random: use a random number generator *-->
    <xsl:message use-when="$cp-selector eq 'random'"
		 terminate="yes">
      <xsl:text>Random character selection has not </xsl:text>
      <xsl:text>been implemented. </xsl:text>
    </xsl:message>
      
    <!--* guided: accept a configuration file, pick from it
	* somehow tbd *-->
    <xsl:message use-when="$cp-selector eq 'guided'"
		 terminate="yes">
      <xsl:text>Guided character selection has not </xsl:text>
      <xsl:text>been implemented. </xsl:text>
    </xsl:message>
    
  </xsl:function>  

  <!--****************************************************************
      * Predicates 
      *-->    

</xsl:stylesheet>
