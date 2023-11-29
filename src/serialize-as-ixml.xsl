<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    default-mode="serialize-as-ixml"
    version="3.0">

  <!--* Read ixml grammar, write out in ixml notation.
      *-->

  <!--* Revisions:
      * 2023-11-28 : CMSMcQ : support ++ and ** operators
      * 2021-01-26 : CMSMcQ : provide default mode, to make it easier
      *                       to use this from other stylesheets
      * 2020-12-16 : CMSMcQ : made stylesheet, in a bit of a rush 
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->
  
  <xsl:output method="text"/>

  <xsl:mode name="serialize-as-ixml" on-no-match="text-only-copy"/>

  <xsl:template match="*">
    <xsl:message>You never told me there would be <xsl:value-of
    select="name()"/> elements!</xsl:message>
  </xsl:template>

  <!--****************************************************************
      * Main / starting template
      ****************************************************************
      *-->
  <xsl:template match="ixml">
    <xsl:text>{ ixml grammar serialized &#xA;  </xsl:text>
    <xsl:value-of select="current-dateTime()"/>
    <xsl:text>&#xA;  by serialize-as-ixml.xsl from &#xA;  </xsl:text>
    <xsl:value-of select="base-uri()"/>
    <xsl:text>&#xA;}&#xA;</xsl:text>
    
    <xsl:apply-templates/>

  </xsl:template>
  

  <!--****************************************************************
      * Match templates for rules and nonterminals on RHS
      ****************************************************************
      *-->  
  
  <xsl:template match="comment">
    <xsl:choose>
      <xsl:when test="parent::ixml">
	<xsl:text>&#xA;</xsl:text>
      </xsl:when>
      <xsl:otherwise>
	<xsl:text> </xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
    <xsl:choose>
      <xsl:when test="parent::ixml">
	<xsl:text>&#xA;</xsl:text>
      </xsl:when>
      <xsl:otherwise>
	<xsl:text> </xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="rule">
    <xsl:apply-templates select="@mark, @name"/>
    <xsl:text> = </xsl:text>
    <xsl:call-template name="string-join">
      <xsl:with-param name="ln" select="alt"/>
      <xsl:with-param name="delim" select=" ' | ' "/>
    </xsl:call-template>
    <xsl:text>.&#xA;</xsl:text>
  </xsl:template>
  
  <xsl:template match="alts">
    <xsl:text>(</xsl:text>
    <xsl:call-template name="string-join">
      <xsl:with-param name="ln" select="*"/>
      <xsl:with-param name="delim" select=" ' | ' "/>
    </xsl:call-template>
    <xsl:text>)</xsl:text>
  </xsl:template>
  
  <xsl:template match="alt">
    <xsl:call-template name="string-join">
      <xsl:with-param name="ln" select="*"/>
      <xsl:with-param name="delim" select=" ', ' "/>
    </xsl:call-template>    
  </xsl:template>
  
  <xsl:template name="string-join">
    <xsl:param name="ln" as="node()*" required="yes"/>
    <xsl:param name="delim" as="xs:string" required="yes"/>
    
    <xsl:variable name="ls" as="xs:string*">
      <xsl:for-each select="$ln">
	<xsl:variable name="lsT" as="xs:string*">
	  <xsl:apply-templates select="."/>
	</xsl:variable>
	<xsl:value-of select="string-join($lsT,'')"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:value-of select="string-join($ls, $delim)"/>    
  </xsl:template>

  <xsl:template match="repeat0">
    <xsl:call-template name="repeat">
      <xsl:with-param name="op" select=" '*' "/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="repeat1">
    <xsl:call-template name="repeat">
      <xsl:with-param name="op" select=" '+' "/>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template name="repeat">
    <xsl:param name="op"/>
    <xsl:apply-templates select="* except *[self::sep or preceding-sibling::sep]"/>
    <xsl:choose>
      <xsl:when test="*[self::sep or preceding-sibling::sep]">
        <xsl:value-of select="concat($op, $op)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$op"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates select="*[self::sep or preceding-sibling::sep]"/>
  </xsl:template>
  
  <xsl:template match="option">
    <xsl:apply-templates/>
    <xsl:text>?</xsl:text>
  </xsl:template>

  <xsl:template match="sep">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="nonterminal">    
    <xsl:value-of select="concat(@mark, @name)"/>
  </xsl:template>

  <xsl:template match="literal[@hex]">
    <xsl:value-of select="concat(@tmark, '#', @hex)"/>
  </xsl:template>
  <xsl:template match="literal[@string]">
    <xsl:value-of select="concat(@tmark,
                          '&quot;', 
			  replace(@string, '&quot;', '&quot;&quot;'),
			  '&quot;')"/>
  </xsl:template>

  <xsl:template match="inclusion">
    <xsl:value-of select="@tmark"/>
    <xsl:text>[</xsl:text>
    <xsl:variable name="ls"
		  as="xs:string*">
      <xsl:apply-templates select="*"/>
    </xsl:variable>
    <xsl:value-of select="string-join($ls, '; ')"/>
    <xsl:text>]</xsl:text>    
  </xsl:template>
  
  <xsl:template match="exclusion">
    <xsl:value-of select="@tmark"/>
    <xsl:text>~[</xsl:text>
    <xsl:variable name="ls"
		  as="xs:string*">
      <xsl:apply-templates select="*"/>
    </xsl:variable>
    <xsl:value-of select="string-join($ls, '; ')"/>
    <xsl:text>]</xsl:text>    
  </xsl:template>
  
  <xsl:template match="member[@from]">
    <xsl:value-of select="concat(
      &quot;&apos;&quot;, @from, &quot;&apos;&quot;, 
      '-',
      &quot;&apos;&quot;, @to, &quot;&apos;&quot;)"/>    
  </xsl:template>
  
  <xsl:template match="member[@code]">
    <xsl:value-of select="@code"/>    
  </xsl:template>
  
  <xsl:template match="member[@string]">
    <xsl:value-of select="@string"/>
  </xsl:template>
  
  <xsl:template match="member[@hex]">
    <xsl:value-of select="concat('#', @hex)"/>
  </xsl:template>

  <xsl:template match="text()"/>
  <xsl:template match="comment/text()">
    <xsl:value-of select="."/>
  </xsl:template>

</xsl:stylesheet>
