<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xsd="http://www.w3.org/2001/XMLSchema"
    xmlns:d2x="http://www.blackmesatech.com/2014/lib/d2x"
    version="3.0">

  <!--* Revisions:
      * 2019-20-25 : CMSMcQ : made XSLT module from XQuery module
      *-->

  <xsl:function name="d2x:d2x" as="xsd:string">
    <xsl:param name="n" as="xsd:integer"/>
    
    <xsl:variable name="r" select = "$n mod 16"/>
    <xsl:variable name="c" select = "substring('0123456789ABCDEF', ($n mod 16) + 1, 1)"/>
    <xsl:variable name="q" select = "($n - $r) idiv 16"/>
    <xsl:value-of select = "if ($q eq 0)
			    then $c
			    else concat(d2x:d2x($q), $c)"/>
  </xsl:function>
    

  <xsl:function name = "d2x:x2d" as="xsd:integer">
    <xsl:param name="hexnum" as = "xsd:string"/>

    <xsl:sequence select="d2x:x2daux(reverse(string-to-codepoints($hexnum)), 0, 1)"/>
  </xsl:function>

  <xsl:function name = "d2x:x2daux" as="xsd:integer">
    <xsl:param name="codepoints" as = "xsd:integer*"/>
    <xsl:param name="accumulator" as="xsd:integer"/>
    <xsl:param name="factor" as="xsd:integer"/>

    <!--
    <xsl:message>d2x:x2daux((<xsl:value-of select="$codepoints"/>,
    <xsl:value-of select="$accumulator"/>,
    <xsl:value-of select="$factor"/>)</xsl:message>
    -->
    
    <xsl:choose>
      <xsl:when test="empty($codepoints)">
	<xsl:sequence select="$accumulator"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:variable name="digit" select="$codepoints[1]"/>
	<xsl:variable name="value" select="
	  ($digit - string-to-codepoints('0'),
          $digit + 10 - string-to-codepoints('A'),
          $digit + 10 - string-to-codepoints('a')
          )[. ge 0][. le 15][1]"/>
	<xsl:sequence select="d2x:x2daux(
	  $codepoints[position() gt 1],
          $accumulator + $value * $factor,
          $factor * 16)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
</xsl:stylesheet>
