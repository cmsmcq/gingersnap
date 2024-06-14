<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:gt="http://blackmesatech.com/2020/grammartools"
		xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
		>

  <!--* Quick stylesheet for ixml grammars *-->
  <xsl:output method="html"
	      indent="yes"/>

  <xsl:param name="empty-set" select=" '&#x2205;' "/>
  

  <!--* default rule:  show the XML *-->
  <xsl:template match="*" name="unknown">
    <div class="unknown">
      <span class="tag starttag">
	<xsl:text>&lt;</xsl:text>
	<xsl:value-of select="name()"/>
	<xsl:apply-templates select="@*" mode="unknown"/>
	<xsl:text>&gt;</xsl:text>
      </span>
      <xsl:apply-templates/>      
      <span class="tag endtag">
	<xsl:text>&lt;/</xsl:text>
	<xsl:value-of select="name()"/>
	<xsl:text>&gt;</xsl:text>
      </span>
    </div>
  </xsl:template>
  
  <xsl:template match="@*" mode="unknown">
    <span class="avs">
      <xsl:text> </xsl:text>
      <span class="attname">
	<xsl:value-of select="name()"/>
      </span>
      <span class="attdelims">
	<xsl:text> = "</xsl:text>
      </span>
      <span class="attval">
	<xsl:value-of select="."/>
      </span>
      <span class="attdelims">	
	<xsl:text>"</xsl:text>
      </span>
    </span>
  </xsl:template>

  <!--* document as a whole *-->
  <xsl:template match="/">
    <html>
      <head>
	<title>iXML grammar</title>
	<style type="text/css">
	  div.unknown { color: red; margin-left: 1em; }
	  span.tag { font-family: Courier, monospace; }
	  div.titlearea { border-bottom: 1px solid black; margin-bottom: 1em; }
	  .comment-body { font-style: italic; }
	  div.rule { margin-top: 0.5em; }
	  div.unsatisfiable { background-color: #EAA; }
	  div.repeatfactor { background-color: #DDDDFF; }
	  div.repeatsep { background-color: #DDFFDD; }
	  span.rhs > span.alt { display: block; margin-left:  1em; }
	  span.stack-rule { font-variant-caps: small-caps; color: navy; }
	  .alts { background-color: #FEE; }
	  .lit-string { color: brown; }
	  .hex { color: orange; }
	  .comment { color: #888; }
          .comment { white-space: pre; }
	  span.rhs > div.comment { margin-left: 1em; }
	  .callers.comment { margin-left: 1em; white-space: normal }
	  .caller { color: #888; }
	  .pragma { background-color: #EFF; }
	  .pragma-delim { color: #ADA; }
	  .pragma-name { color: #080; font-variant: small-caps;}
	  .pragma-data { color: purple; }
	</style>
      </head>
      <body>
	<xsl:apply-templates/>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="ixml">
    <div class="grammar">
      <div class="titlearea">
	<h1>iXML grammar</h1>
      </div>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="ixml/comment | rule/comment" priority="10">
    <div class="comment">
      <span class="comdelim">{</span>
      <span class="comment-body">
	<xsl:apply-templates/>
      </span>      
      <span class="comdelim">}</span>
    </div>
  </xsl:template>

  <xsl:template match="comment" priority="1">
    <span class="comment">
      <span class="comdelim">{</span>
      <span class="comment-body">
	<xsl:apply-templates/>
      </span>      
      <span class="comdelim">}</span>
    </span>
  </xsl:template>

  <xsl:template match="rule">
    <div class="rule" id="{@name}">
      <xsl:if test="child::pragma[not(preceding-sibling::alt)]">
        <xsl:apply-templates select="pragma[not(preceding-sibling::alt)]"
                             mode="pragma"/>
      </xsl:if>
      <span class="lhs">
        <xsl:value-of select="concat(@mark, @name)"/>
        <xsl:apply-templates select="@alias"/>
      </span>
      <span class="ruledelim"> = </span>
      <span class="rhs">
	<xsl:apply-templates/>
      </span>
      <div class="callers comment">
        <span class="comdelim">{</span>
        <span class="comment-body">
          <xsl:variable name="N" select="string(@name)"/>
          <xsl:variable name="callers" select="//nonterminal[@name = $N]"/>
          <xsl:choose>
            <xsl:when test="$callers">
              <xsl:text> Used by: </xsl:text>
              <xsl:for-each select="$callers">
                <xsl:variable name="caller-name" select="ancestor::rule[1]/@name"/>
                <a class="caller" href="#{$caller-name}">
                  <xsl:value-of select="$caller-name"/>
                </a>
                <xsl:choose>
                  <xsl:when test="position() = last()">
                    <xsl:text>. </xsl:text>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:text>, </xsl:text>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text> Not used elsewhere. </xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </span>      
        <span class="comdelim">}</span>
      </div>
      <span class="ruledelim">.</span>
    </div>
  </xsl:template>
  
  <xsl:template match="rule[@gt:satisfiable = 'false']">
    <div class="unsatisfiable rule" id="{@name}">
      <span class="lhs"><xsl:value-of select="concat(@mark, @name)"/></span>
      <span class="ruledelim"> = </span>
      <span class="rhs">
	<xsl:apply-templates/>
      </span>
      <span class="ruledelim">.</span>
    </div>
  </xsl:template>

  <xsl:template match="@alias">
    <span class="aliasdelim"> > </span>
    <span class="alias"><xsl:value-of select="."/></span>
  </xsl:template>
  
  <xsl:template match="alt">
    <span class="alt">
      <xsl:apply-templates/>
      <xsl:apply-templates select="@rtn:stack" mode="stack"/>      
      <xsl:if test="following-sibling::*[1]/self::alt">
	<!-- <span class="altdelim"> | </span> -->
	<span class="altdelim">; </span>
      </xsl:if>
    </span>
  </xsl:template>
  
  <xsl:template match="alts">
    <span class="alts">
      <span class="altsdelim">(</span>
      <xsl:apply-templates/>
      <span class="altsdelim">)</span>
    </span>
    <xsl:apply-templates select="." mode="seqdelim"/>
  </xsl:template>
  
  <xsl:template match="repeat0">
    <span class="repeat0">
      <span class="repeatfactor">
	<xsl:apply-templates mode="repeat-factor"/>
      </span>
      <xsl:choose>
	<xsl:when test="sep">
	  <xsl:text>**</xsl:text>
	  <span class="repeatsep">
	    <xsl:apply-templates select="sep" mode="repeat-sep"/>
	  </span>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:text>*</xsl:text>
	</xsl:otherwise>
      </xsl:choose>
    </span>
    <xsl:apply-templates select="." mode="seqdelim"/>
  </xsl:template>
  
  <xsl:template match="repeat1">
    <span class="repeat1">
      <xsl:apply-templates mode="repeat-factor"/>
      <xsl:text>+</xsl:text>
      <xsl:if test="sep">
	<xsl:text>+</xsl:text>
	<xsl:apply-templates select="sep" mode="repeat-sep"/>
      </xsl:if>
    </span>
    <xsl:apply-templates select="." mode="seqdelim"/>
  </xsl:template>
  
  <xsl:template match="sep">
    <span class="sep">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  
  <xsl:template match="option">
    <span class="option">
      <xsl:apply-templates/>
      <xsl:text>?</xsl:text>
    </span>
    <xsl:apply-templates select="." mode="seqdelim"/>
  </xsl:template>
  
  <xsl:template match="nonterminal">
    <a class="nonterminal" href="#{@name}">
      <xsl:value-of select="concat(@mark, @name)"/>
    </a>
    <xsl:apply-templates select="@rtn:stack" mode="stack"/>
    <xsl:apply-templates select="comment"/>
    <xsl:apply-templates select="." mode="seqdelim"/>
  </xsl:template>
  
  <xsl:template match="literal">
    <span class="literal">
      <xsl:apply-templates select="@*"/>
    </span>
    <xsl:apply-templates select="." mode="seqdelim"/>
  </xsl:template>
  
  <xsl:template match="inclusion">
    <span class="inclusion">
      <span class="inclusiondelim">[</span>
      <xsl:apply-templates/>
      <span class="inclusiondelim">]</span>
    </span>
    <xsl:apply-templates select="." mode="seqdelim"/>
  </xsl:template>
  
  <xsl:template match="exclusion">
    <span class="exclusion">
      <span class="exclusiondelim">~</span>
      <span class="inclusiondelim">[</span>
      <xsl:apply-templates/>
      <span class="inclusiondelim">]</span>
    </span>
    <xsl:apply-templates select="." mode="seqdelim"/>
  </xsl:template>
  
  <xsl:template match="range">
    <span class="range">
      <span class="rangedelim">"</span>
      <span class="rangefrom"><xsl:value-of select="@from"/></span>
      <span class="rangedelim">"-"</span>
      <span class="rangeto"><xsl:value-of select="@to"/></span>
      <span class="rangedelim">"</span>
    </span>
    <xsl:apply-templates select="." mode="seqdelim"/>
  </xsl:template>
  
  <xsl:template match="member[@string]">
    <span class="member">
      <xsl:apply-templates select="@*"/>
    </span>
    <xsl:apply-templates select="." mode="incldelim"/>
  </xsl:template>
  
  <xsl:template match="member[@hex]">
    <span class="member">
      <xsl:apply-templates select="@*"/>
    </span>
    <xsl:apply-templates select="." mode="incldelim"/>
  </xsl:template>
  
  <xsl:template match="member[@from]">
    <span class="range member">
      <xsl:choose>
        <xsl:when test="string-length(@from) > 1
                        and substring(@from, 1, 1) = '#'">
          <span class="hex"><xsl:value-of select="@from"/></span>
        </xsl:when>
        <xsl:otherwise>
          <span class="rangedelim">"</span>
          <span class="rangefrom"><xsl:value-of select="@from"/></span>
          <span class="rangedelim">"</span>
        </xsl:otherwise>
      </xsl:choose>
      <span class="rangesep">-</span>
      <xsl:choose>
        <xsl:when test="string-length(@to) > 1
                        and substring(@to, 1, 1) = '#'">
          <span class="hex"><xsl:value-of select="@to"/></span>
        </xsl:when>
        <xsl:otherwise>
          <span class="rangedelim">"</span>
          <span class="rangefrom"><xsl:value-of select="@to"/></span>
          <span class="rangedelim">"</span>
        </xsl:otherwise>
      </xsl:choose>
    </span>
    <xsl:apply-templates select="." mode="incldelim"/>
  </xsl:template>
  
  <xsl:template match="member[@code]">
    <span class="member">
      <xsl:value-of select="@code"/>
    </span>
    <xsl:apply-templates select="." mode="incldelim"/>
  </xsl:template>

  <xsl:template match="@*" priority="1"/>
  
  <xsl:template match="@dstring" priority="10">
    <xsl:text>"</xsl:text>
    <xsl:value-of select="."/>
    <xsl:text>"</xsl:text>
  </xsl:template>
  
  <xsl:template match="@sstring" priority="10">
    <xsl:text>'</xsl:text>
    <xsl:value-of select="."/>
    <xsl:text>'</xsl:text>
  </xsl:template>
  
  <xsl:template match="@string" priority="10">
    <xsl:text>'</xsl:text>
    <span class="lit-string">
      <xsl:value-of select="."/>
    </span>
    <xsl:text>'</xsl:text>
  </xsl:template>
  
  <xsl:template match="@hex" priority="10">
    <xsl:text>#</xsl:text>
    <xsl:value-of select="."/>
  </xsl:template>
  

  <xsl:template match="ixml/text() | rule/text()"/>
  
  <xsl:template match="*" mode="seqdelim">
    <xsl:if test="parent::alt
		  and not(self::comment)
		  and following-sibling::*[not(self::comment)]">
      <span class="seqdelim">, </span>
    </xsl:if>    
  </xsl:template>
  
  <xsl:template match="inclusion/* | exclusion/*" mode="incldelim">
    <xsl:if test="not(self::comment)
		  and following-sibling::*[not(self::comment)]">
      <span class="classelim">; </span>
    </xsl:if>    
  </xsl:template>

  <xsl:template match="*" mode="repeat-factor">
    <xsl:apply-templates select="."/>
  </xsl:template>
  
  <xsl:template match="sep" mode="repeat-factor"/>

  <xsl:template match="*" mode="repeat-sep"/>
  
  <xsl:template match="sep" mode="repeat-sep">
    <xsl:apply-templates select="."/>
  </xsl:template>


  <xsl:template match="gt:empty-set">
    <span class="empty-set">
      <xsl:value-of select="$empty-set"/>
    </span>
    <xsl:apply-templates select="." mode="seqdelim"/>
  </xsl:template>
  
  <xsl:template match="attribute::rtn:stack" mode="stack">
    <xsl:message>Hi, mom.</xsl:message>
    <span class="stack-rule">
      <xsl:text>{&#x296E; </xsl:text>
      <xsl:value-of select="."/>
      <xsl:text> &#x296F;}</xsl:text>
    </span>
  </xsl:template>

  <!-- Pragmas -->
  <!-- Simple case:  display the pragma -->
  <xsl:template match="pragma" name="pragma">
    <span class="pragma">
      <span class="pragma-delim">{[</span>
      <span class="pragma-name">
        <xsl:value-of select="@pname"/>
      </span>
      <xsl:apply-templates select="pragma-data"/>
      <span class="pragma-delim">]}</span>
    </span>
  </xsl:template>
  
  <!-- pragmas which appear in the naming section of the rule.
       In the XML they appear as first children of rule.
       They require special serialization, so in default mode
       they are skipped. -->
  <xsl:template match="pragma[not(preceding-sibling::alt)]" />
  <xsl:template match="pragma[not(preceding-sibling::alt)]" mode="pragma">
    <xsl:call-template name="pragma"/>
    <xsl:text> </xsl:text>
  </xsl:template>
  
  <xsl:template match="pragma-data">
    <span> </span>
    <xsl:value-of select="string()"/>
  </xsl:template>
  
</xsl:stylesheet>
