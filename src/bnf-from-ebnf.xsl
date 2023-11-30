<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    exclude-result-prefixes="xsl gt xs gl rtn follow"
    default-mode="ebnf-rewriting"
    version="3.0">

  <!--* bnf-from-ebnf.xsl: read an ixml grammar, produce an equivalent
        BNF grammar, using whatever rewrite rules are selected.
      
        The current version uses parameters to select templates.
      
        Elements involving a choice (alts, option, repeat0, repeat1)
        are rewritten; other constructs are left alone.  Choice
        elements alone at the top of a RHS are rewritten as a set of
        RHS in BNF form; choice elements elsewhere are handled by
        rule.  
      
        The work is done in two passes: in the first pass, any
        additional rules needed are embedded in comments immediately
        following the rewritten construct; in the second pass, those
        comments are removed and the additional rules are appended to
        the grammar.

        We work bottom up: to rewrite any non-BNF expression E, begin
        by rewriting the children of E, then rewriting E itself using
        those rewritten children.

      *-->

  <!--* Revisions:
      * 2023-11-30 : CMSMcQ : working to fix O3a and O3b.
      *                       . be more careful about ch-right-alt-2
      *                       . supply IDs for everything first
      *                       . supply name for created alt, to avoid
      *                         getting _xx multiple times.
      *                       to do:
      *                       . avoid duplication of the injected rule
      * 2023-11-29 : CMSMcQ : begin this, starting from old
      *                       bnf-from-ebnf.tc.xsl
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->
  
  <xsl:mode name="id-all-non-ebnf" on-no-match="shallow-copy" />
  <xsl:mode name="ebnf-rewriting" on-no-match="shallow-copy"/>
  <xsl:mode name="rule-extraposition" on-no-match="shallow-copy"/>
  
  <xsl:strip-space elements="*"/>
  <xsl:output method="xml" indent="yes"/>

  <!-- Shift from static variable to parameter.  It's already
       inconvenient to edit the source to change the testing
       situation. -->
  <xsl:param name="option" as="xs:string"
             select="( 'O1a', 'O1b', 'O2a', 'O2b',
                     'O3a', 'O3b', 'O4a', 'O4b')[5]"/>

  <xsl:variable name="ns-gt" as="xs:string"
                select=" 'http://blackmesatech.com/2020/grammartools' "/>  
  
  <!--****************************************************************
      * Main / starting template
      ****************************************************************
      *-->
  <xsl:template match="/" name="main">

    <xsl:variable name="stylesheet-pi" as="processing-instruction()">
      <xsl:processing-instruction name="xml-stylesheet">
	<xsl:text>type="text/xsl" href="ixml-html.xsl"</xsl:text>
      </xsl:processing-instruction>
    </xsl:variable>    

    <xsl:variable name="R0" as="element(ixml)">
      <xsl:apply-templates mode="id-all-non-ebnf" select="ixml"/>
    </xsl:variable>

    <xsl:variable name="R1" as="element(ixml)">
      <xsl:apply-templates mode="ebnf-rewriting" select="$R0"/>
    </xsl:variable>
    
    <xsl:variable name="R2" as="element(ixml)">
      <xsl:apply-templates mode="rule-extraposition" select="$R1"/>
    </xsl:variable>

    <xsl:sequence select="$stylesheet-pi, $R2"/>
  </xsl:template>  

  <!--****************************************************************
      * MODE id-all-non-ebnf
      ****************************************************************
      *-->
  <!--* special-case ixml, to put a gt namespace declaration on it. -->
  <xsl:template match="ixml" mode="id-all-non-ebnf">
    <xsl:copy>
      <xsl:namespace name="gt" select="$ns-gt"/>
      <xsl:sequence select="@*"/>
      <xsl:apply-templates select="*" mode="id-all-non-ebnf"/>
    </xsl:copy>
  </xsl:template>
      
  <xsl:template match="option
                       | repeat0
                       | repeat1
                       | rule/alt/descendant::alts
                       | alt[option]"
                mode="id-all-non-ebnf">
    <xsl:copy>
      <xsl:sequence select="@*"/>
      <xsl:if test="not(@gt:expname)">
        <xsl:attribute name="gt:expname" select="gt:generate-nonterminal(.)"/>
      </xsl:if>
      <xsl:apply-templates mode="id-all-non-ebnf"/>
    </xsl:copy>
  </xsl:template>
  
  <!--****************************************************************
      * MODE ebnf-rewriting
      ****************************************************************
      *-->
  <!--****************************************************************
      * Option in mode ebnf-rewriting
      *-->
  
  <!--* Rule O1a:  inline, empty-last
      * Rule 01b:  inline, empty-first
      * A, B?, C rewrites to (A, B, C | A C), or (A, C | A, B, C).
      * The template must act on the entire sequence, not just B?.
      *-->
  <xsl:template match="alt[option][$option = ('O1a', 'O1b')]"
                mode="ebnf-rewriting"
                >
    <!--* 1 Normalize all non-option children.
        * 2 Duplicate once with and once without the first option
        * 3 If there are further options, apply templates to them.
        *   Otherwise, just return a choice containing the two
        *   option-free sequences.
        *-->
    
    <!--* 1 Normalize all non-option children. *-->
    <xsl:variable name="children-0" as="element()*">
      <xsl:apply-templates select="*" mode="ebnf-rewriting"/>
    </xsl:variable>
    
    <!--* 2 Duplicate once with and once without the first option -->
    <xsl:variable name="gis" as="xs:string*"
                  select="for $e in $children-0 return local-name($e)"/>
    
    <xsl:variable name="indices" as="xs:integer*"
                  select="index-of($gis, 'option')"/>
    <!--* Note:  because we may apply this template repeatedly to
        * an alt element, $indices is NOT guaranteed non-empty. *-->
    <xsl:variable name="index" as="xs:integer?"
                  select="$indices[1]"/>

    <xsl:choose>
      <xsl:when test="exists($index)">
        <!-- Take the children preceding the first option,
             then the child of the first option (children, maybe: comments)
             then the children following the first option -->
        <xsl:variable name="ch-with" as="element()*"
                      select="$children-0[position() lt $index],
                              $children-0[$index]/*,
                              $children-0[position() gt $index]"/>
        <!-- Now the same, without the option's child[ren]. -->
        <xsl:variable name="ch-without" as="element()*"
                      select="$children-0[position() lt $index],
                              $children-0[position() gt $index]"/>
        <xsl:choose>
          <!--* 3a If there are no further options, return. -->
          <xsl:when test="count($indices) eq 1">
            <!-- 1a puts empty last, 1b puts empty first -->
            <xsl:choose>
              <xsl:when test="$option eq 'O1a'">
                <alt>
                  <!--
                      <xsl:copy-of select="$ch-with" copy-namespaces="no"/>
                      -->
                  <!-- Just embedding the sequence is no good,
                       it causes an implicit copy with
                       copy-namespaces="yes" -->
                  <xsl:sequence select="$ch-with"/>
                </alt>
                <alt>
                  <xsl:sequence select="$ch-without"/>
                </alt>
              </xsl:when>
              <xsl:when test="$option eq 'O1b'">
                <alt><xsl:sequence select="$ch-without"/></alt>
                <alt><xsl:sequence select="$ch-with"/></alt>
              </xsl:when>
            </xsl:choose>
          </xsl:when>
          <!--* 3b If there are further options, apply templates to them. -->
          <xsl:when test="count($indices) gt 1">
            <xsl:variable name="alt-with" as="element(alt)">
              <xsl:element name="alt">
                <xsl:sequence select="$ch-with"/>
              </xsl:element>
            </xsl:variable>
            <xsl:variable name="alt-without" as="element(alt)">
              <xsl:element name="alt">
                <xsl:sequence select="$ch-without"/>
              </xsl:element>
            </xsl:variable>
            <!-- 1a puts empty last, 1b puts empty first -->
            <xsl:choose>
              <xsl:when test="$option eq 'O1a'">
                <xsl:apply-templates mode="ebnf-rewriting"
                                     select="$alt-with, $alt-without"/>
              </xsl:when>
              <xsl:when test="$option eq 'O1b'">
                <xsl:apply-templates mode="ebnf-rewriting"
                                     select="$alt-without, $alt-with"/>
              </xsl:when>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
            <!-- we found no option here -->
            <alt><xsl:sequence select="$children-0"/></alt>
            <xsl:message>Yes, this really did happen!</xsl:message>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <alt><xsl:sequence select="$children-0"/></alt>
        <xsl:message>YOW!  I didn't think this could really happen!</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--................................................................-->
  <!--* Rule O2a:  reifying, empty-last
      * Rule O2b:  reifying, empty-first
      * A, B?, C rewrites to (A, opt-B, C), with new opt-B.
      *-->
  <xsl:template match="option[$option = ('O2a', 'O2b')]"
                mode="ebnf-rewriting"
                >
    <!--* 1 Normalize all non-option children.
        * 2 Write a new nonterminal
        * 3 Write a rule for that nonterminal, with one alt
        *   with the option's child, and one empty.
        *-->
    
    <!--* 1 Normalize all children. *-->
    <xsl:variable name="children-0" as="element()*">
      <xsl:apply-templates select="*" mode="ebnf-rewriting"/>
    </xsl:variable>
    
    <!--* 2 Write a new nonterminal-->
    <xsl:variable name="N" as="xs:string"
                  select="gt:generate-nonterminal(.)"/>

    <xsl:element name="nonterminal">
      <xsl:attribute name="name" select="$N"/>
      <xsl:attribute name="mark" select=" '-' "/>
    </xsl:element>
    
    <!--* 3 Write the rule for that nonterminal -->
    <xsl:element name="comment">
      <xsl:attribute name="gt:flag" select="'injection'"/>
      <xsl:element name="rule">
        <xsl:attribute name="name" select="$N"/>
        <xsl:attribute name="mark" select=" '-' "/>

        <xsl:if test="$option eq 'O2b'">
          <xsl:element name="alt"/>
        </xsl:if>
        <xsl:element name="alt">
          <xsl:sequence select="$children-0"/>
        </xsl:element>
        <xsl:if test="$option eq 'O2a'">
          <xsl:element name="alt"/>
        </xsl:if>
      </xsl:element>
    </xsl:element>
    
  </xsl:template>

  <!-- ................................................................ -->
  <!--* Rule O3a:  reify with right context, empty-last
      * Rule O3b:  reify with right context, empty-first
      * A, B?, C rewrites to A, opt-B, with opt-B = B, C | C.
      * Because this captures the right-context, it must act on
      * the containing alt, not just on the option.
      *-->
  <xsl:template match="alt[option][$option = ('O3a', 'O3b')]"
                mode="ebnf-rewriting"
                >
    <!--* 1 Normalize all non-option children.
        * 2 Split the sequence at the first option.
        * 3 If there are options after the first,
        *   apply templates to handle them.
        * 4 Write out the left context and a new nonterminal.
        * 5 Write the rule for the new nonterminal.
        *   Two alt children, one with and one without.
        *-->
    
    <!--* 1 Normalize all children. *-->
    <!--* Expected:  any sequence of terms, including at least one option element *-->
    <xsl:variable name="children-0" as="element()*">
      <xsl:apply-templates select="*" mode="ebnf-rewriting"/>
    </xsl:variable>

    <!--* 2 Split the sequence at the first option. *-->
    <xsl:variable name="gis" as="xs:string*"
                  select="for $e in $children-0 return local-name($e)"/>

    <xsl:message expand-text="yes">gis of children-0: {$gis}</xsl:message>
    
    <xsl:variable name="indices" as="xs:integer*"
                  select="index-of($gis, 'option')"/>
    <!--* Note:  because we may apply this template repeatedly to
        * an alt element, $indices is NOT guaranteed non-empty. *-->
    <xsl:variable name="index" as="xs:integer?"
                  select="($indices, count($gis) + 1)[1]"/>

    <xsl:variable name="ch-left" as="element()*"
                  select="$children-0[position() lt $index]"/>
    <xsl:variable name="ch-center" as="element()*"
                  select="$children-0[position() eq $index]"/>
    <xsl:variable name="ch-right-0" as="element()*"
                  select="$children-0[position() gt $index]"/>
    <!--* Expected:  any sequence of terms, possibly including option elements *-->

    <xsl:variable name="tmp-gis-r-0" as="xs:string*"
                  select="for $e in $ch-right-0 return local-name($e)"/>
    <xsl:message expand-text="yes">gis of ch-right-0: {$tmp-gis-r-0}</xsl:message>    
        
    <!--* 3 If there are options after the first,
        *   apply templates to handle them. *-->
    <xsl:variable name="ch-right-alt-1" as="element(alt)">
      <xsl:element name="alt">
        <xsl:if test="$ch-right-0[self::option]">
          <xsl:attribute name="gt:expname"
                         select="concat('_xx',
                                 $ch-right-0[self::option][1]
                                 /@gt:expname)"/>
        </xsl:if>
        <xsl:sequence select="$ch-right-0"/>
      </xsl:element>
    </xsl:variable>
    <!--* Expected:  either an alt whose children are as before
        * (but normalized)
        * or an alt whose (option, ...) suffix is replaced by
        * a new nonterminal
        * Either way: no option children
        *-->

    <xsl:variable name="tmp-gis-1" as="xs:string*"
                  select="for $e in $ch-right-alt-1 return name($e)"/>
    <xsl:message expand-text="yes">ch-right-alt-1: {$tmp-gis-1}</xsl:message>

    <xsl:variable name="tmp-gis-1ch" as="xs:string*"
                  select="for $e in $ch-right-alt-1/* return name($e)"/>
    <xsl:message expand-text="yes">ch-right-alt-1/*: {$tmp-gis-1ch}</xsl:message>
    
    <xsl:variable name="ch-right-alt-2" as="element()*">
      <!-- Expected: alt, or (alt, comment) -->
      <xsl:choose>
        <xsl:when test="count($indices) gt 1">
          <xsl:apply-templates mode="ebnf-rewriting"
                               select="$ch-right-alt-1"/>
        </xsl:when>
        <xsl:otherwise>
          <!-- In principle, we don't need this choice,
               since apply-templates should in this case
               be an identity transform. But ... -->
          <xsl:sequence select="$ch-right-alt-1"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <!--* Expected: an alt with no options among children,
        * optionally followed by comment with injected rule.
        *-->

    <xsl:variable name="tmp-gis-2" as="xs:string*"
                  select="for $e in $ch-right-alt-2 return name($e)"/>
    <xsl:message expand-text="yes">ch-right-alt-2: {$tmp-gis-2}</xsl:message>    

    <xsl:variable name="tmp-gis-2ch" as="xs:string*"
                  select="for $e in $ch-right-alt-2/* return name($e)"/>
    <xsl:message expand-text="yes">ch-right-alt-2/*: {$tmp-gis-2ch}</xsl:message>
        
    <!--* 4 Write out an alt element containing the left context
        * and a new nonterminal. *-->
    <xsl:variable name="N" as="xs:string"
                  select="gt:generate-nonterminal(.)"/>
    
    <xsl:element name="alt">
      <xsl:sequence select="$ch-left"/>
      <xsl:element name="nonterminal">
        <xsl:attribute name="name" select="$N"/>
        <xsl:attribute name="mark" select=" '-' "/>
      </xsl:element>
    </xsl:element>
    
    <!--* 5 Write the rule for the new nonterminal.
        *   Two alt children, one with and one without. *-->
    <xsl:element name="comment">
      <xsl:attribute name="gt:flag" select="'injection'"/>
      <xsl:element name="rule">
        <xsl:attribute name="name" select="$N"/>
        <xsl:attribute name="mark" select=" '-' "/>

        <xsl:choose>
          <xsl:when test="$option eq 'O3a'">
            <!-- An alt with the optional material -->
            <xsl:element name="alt">
              <xsl:sequence select="$ch-center/*"/>
              <!-- <xsl:sequence select="$ch-right-alt-2/*"/> -->
              <!-- <xsl:sequence select="for $e in $ch-right-alt-2/*
                                    return if ($e/self::option)
                                    then $e/*
                                    else $e"/> -->
              <xsl:sequence select="for $e in $ch-right-alt-2
                                    return if ($e/self::alt)
                                    then $e/*
                                    else $e"/>
            </xsl:element>
            <!-- An alt without the optional material -->
            <xsl:sequence select="$ch-right-alt-2"/>
          </xsl:when>
          <xsl:when test="$option eq 'O3b'">
            <!-- An alt without the optional material -->
            <xsl:sequence select="$ch-right-alt-2"/>
            <!-- An alt with the optional material -->
            <xsl:element name="alt">
              <xsl:sequence select="$ch-center/*"/>
              <xsl:sequence select="for $e in $ch-right-alt-2
                                    return if ($e/self::alt)
                                    then $e/*
                                    else $e"/>
            </xsl:element>
          </xsl:when>
        </xsl:choose>
      </xsl:element>
    </xsl:element>

  </xsl:template>
  
  <!--****************************************************************
      * MODE rule-extraposition
      ****************************************************************
      *-->
  <!--* Copy everything except comments with gt:flag='injection'.
      * Move their comments to the end of the ixml element.
      *
      * Also do any other miscellaneous cleanup needed.
      * . strip gt:* attributes
      *-->
  <xsl:template match="comment[@gt:flag='injection']"
                mode="rule-extraposition"/>
  
  <xsl:template match="@gt:*"
                mode="rule-extraposition"/>
  
  <xsl:template match="ixml"
                mode="rule-extraposition">
    <xsl:copy>
      <xsl:sequence select="@*"/>      
      <xsl:apply-templates mode="rule-extraposition"/>

      <xsl:if test="descendant::comment[@gt:flag='injection']">
        <xsl:element name="comment">
          <xsl:text>* New rules *</xsl:text>
        </xsl:element>
      </xsl:if>


      <xsl:apply-templates mode="rule-extraposition"
                           select="descendant::comment[@gt:flag='injection']
                           /rule"/>

      <!-- we apply templates because otherwise nested injections
           still show up as comments -->
      <!--
      <xsl:sequence select="descendant::comment[@gt:flag='injection']
                            /rule"/>
                           -->
    </xsl:copy>
  </xsl:template>
  
  
  <!--****************************************************************
      * Predicates 
      *-->


 
  <!--****************************************************************
      * Functions
      ****************************************************************
      *-->
  <!--* Copied from bnf-from-ebnf-tc because importing had problems. *-->
  <xsl:function name="gt:generate-nonterminal"
		as="xs:string">
    <xsl:param name="E" as="element()"/>

    <xsl:variable name="easy-solution" as="xs:string?"
		  select="($E/@gt:expname/string(),
			  $E/@xml:id/string())[1]"/>
    <xsl:choose>
      <xsl:when test="exists($easy-solution)">
	<xsl:value-of select="$easy-solution"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:variable name="gi" as="xs:string"
		      select="local-name($E)"/>
	<xsl:variable name="g" as="xs:string"
		      select="if ($gi eq 'alts')
			      then 'or'
			      else if ($gi eq 'alt')
			      then 'xx'
			      else if ($gi eq 'repeat0')
			      then 'star'
			      else if ($gi eq 'repeat1')
			      then 'plus'
			      else if ($gi eq 'option')
			      then 'opt'
			      else $gi"/>
	<xsl:variable name="n" as="xs:integer">
	  <xsl:number count="*" level="any" select="$E"/>
	</xsl:variable>
	<!--
	<xsl:variable name="n" as="xs:integer"
		      select="count($E/preceding::*)
			      + count($E/ancestor-or-self::*)"/>
	-->
	<xsl:value-of select="concat('_', $g, $n)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
</xsl:stylesheet>
