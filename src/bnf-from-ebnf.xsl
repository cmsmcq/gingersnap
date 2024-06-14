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
      * 2023-11-30 : CMSMcQ : We'll need a fixpoint step after all.
      *                       Add it.  This brings back multiple
      *                       delivery on promises, to be repaired.
      *                       
      * 2023-11-30 : CMSMcQ : working to fix O3a and O3b.
      *                       . be more careful about ch-right-alt-2
      *                       . supply IDs for everything first
      *                       . supply name for created alt, to avoid
      *                         getting _xx multiple times.
      *                       . avoid duplicating the injected rule
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

  <!-- Behavior is controlled with these parameters.  (For mass
       processing, static variables would be better, but for
       experimentation this is better.) -->
  <!-- Default is to do nothing; this simplifies testing rules
       in isolation.  It also requires the user to say what is wanted,
       rather than providing a useful default, in a slightly
       passive-aggessive way. -->
  <xsl:param name="option" as="xs:string"
             select="('none'
                     'O1a', 'O1b',
                     'O2a', 'O2b',
                     'O3a', 'O3b',
                     'O4a', 'O4b'
                     )[1]"/>
  <xsl:param name="star" as="xs:string"
             select="('none',
                     'S1a', 'S1b', 'S1c', 'S1d',
                     'S2a', 'S2b',
                     'S3a', 'S3b', 
                     'S4a', 'S4b', 'S4c', 'S4d'
                     )[1]"/>
  <xsl:param name="plus" as="xs:string"
             select="('none',
                     'P1a', 'P1b', 'P1c', 'P1d',
                     'P2a', 'P2b',
                     'P3a', 'P3b', 'P3c', 'P3d',  
                     ('P4aw', 'P4ax', 'P4ay', 'P4az',
                     'P4bw', 'P4bx', 'P4by', 'P4bz',
                     'P4cw', 'P4cx', 'P4cy', 'P4cz',
                     'P4dw', 'P4dx', 'P4dy', 'P4dz',
                     'P4ew', 'P4ex', 'P4ey', 'P4ez',
                     'P4fw', 'P4fx', 'P4fy', 'P4fz'
                     )[1]"/>
  <xsl:param name="starstar" as="xs:string"
             select="(
                     'none',
                     'SS1a', 'SS1b', 'SS1c', 'SS1d',
                     'SS2',
                     'SS3',
                     'SS4',
                     'SS5',
                     'SS6a', 'SS6b', 'SS6c', 'SS6d',
                     'SS7a', 'SS7b', 'SS7c', 'SS7d',
                     )[1]"/>
  <xsl:param name="plusplus" as="xs:string"
             select="(
                     'none',
                     'PP1a', 'PP1b',
                     'PP2',
                     'PP3a', 'PP3b',
                     'PP4a', 'PP4b',
                     'PP5a', 'PP5b', 'PP5c', 'PP5d'
                     )[1]"/>
  <xsl:param name="alts" as="xs:string"
             select="('none',
                     'C1 C2'
                     )[1]"/>

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

  <!--* Rule:  call fixpoint template on alt children while work
      * remains to be done *-->
  <xsl:template match="rule" mode="ebnf-rewriting">
    <xsl:copy copy-namespaces="no">
      <xsl:sequence select="@*"/>
      
      <xsl:for-each select="*">
        <xsl:choose>
          <xsl:when test="self::alt">
            <xsl:call-template name="find-fixpoint">
              <xsl:with-param name="E" select="."/>
              <xsl:with-param name="rule" select="../@name"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <!-- Anything else should be a comment, but
                 we'll apply templates just in case -->              
            <xsl:apply-templates mode="ebnf-rewriting"
                                 select="."/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>

    </xsl:copy>    
  </xsl:template>
  
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
                as="element(alt)+"
                >
    <!--* 1 Process the children of the alt.
        * 2 Split the processed children into L, C, R on the
        *   first option element.
        * 3 Process the children of C.
        * 4 If R includes any further option elements, call
        *   apply-templates recursively on R to process them.
        *   It will return multiple alt elements, and possibly
        *   some promises.
        * 5 For every alt element A returned by the recursion on R,
        *   return two alts:  one with (L, C/*, A), one (L, A).
        *-->
    
    <!--* (old description)
        * 1 Normalize all non-option children.
        * 2 Duplicate once with and once without the first option
        * 3 If there are further options, apply templates to them.
        *   Otherwise, just return a choice containing the two
        *   option-free sequences.
        *-->
    
    <!--* 1 Process all non-option children. *-->
    <!--* [Note:  yes, it's safe to process all children.
        * Option elements will be untouched (no template for
        * them) and will be handled here and by recursion.
        * You do not need to postpone handling the siblings
        * that follow the first option.  Stop asking me this
        * question!]
        *-->
    <xsl:variable name="children-0" as="element()*">
      <xsl:apply-templates select="*" mode="ebnf-rewriting"/>
    </xsl:variable>
    
    <!--* 2 Split $children-0 on the first option -->
    
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
        <!-- 2 Split the sibling sequence -->
        <!-- 3 Process children of C -->
        <xsl:variable name="ch-L" as="element()*"
                      select="$children-0[position() lt $index]"/>
        <xsl:variable name="chch-C" as="element()*">
          <xsl:apply-templates mode="ebnf-rewriting"
                               select="$children-0[$index]/*"/>
        </xsl:variable>
        <xsl:variable name="ch-R" as="element()*"
                      select="$children-0[position() gt $index]"/>

        <!-- 4 Recur on R (in case of further option elements) -->
        <xsl:variable name="alt-ch-R1" as="element(alt)">
          <xsl:element name="alt">
            <xsl:sequence select="$ch-R"/>
          </xsl:element>
        </xsl:variable>

        <xsl:variable name="alts-ch-R2" as="element(alt)+">          
          <xsl:apply-templates mode="ebnf-rewriting"
                               select="$alt-ch-R1"/>
        </xsl:variable>

        <!-- 5 Return alts, two for each alt in $alt-ch-R2 -->
        <xsl:for-each select="$alts-ch-R2">
          <xsl:variable name="this-R" as="element(alt)" select="."/>
          <xsl:choose>
            <xsl:when test="$option eq 'O1a'">
              <!-- O1a is empty-last -->
              <xsl:element name="alt">
                <xsl:sequence select="$ch-L, $chch-C, $this-R/*"/>
              </xsl:element>
              <xsl:element name="alt">
                <xsl:sequence select="$ch-L, $this-R/*"/>
              </xsl:element>
            </xsl:when>
            <xsl:when test="$option eq 'O1b'">
              <!-- O1a is empty-first -->
              <xsl:element name="alt">
                <xsl:sequence select="$ch-L, $this-R/*"/>
              </xsl:element>
              <xsl:element name="alt">
                <xsl:sequence select="$ch-L, $chch-C, $this-R/*"/>
              </xsl:element>
            </xsl:when>
          </xsl:choose>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <alt><xsl:sequence select="$children-0"/></alt>
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
      
      <!--* 3 Write the rule for that nonterminal
          * (inside the nonterminal, so namespaced) -->      
      <xsl:element name="gt:comment">
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

    <!-- <xsl:message expand-text="yes">gis of children-0: {$gis}</xsl:message> -->
    
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
    <!-- <xsl:message expand-text="yes">gis of ch-right-0: {$tmp-gis-r-0}</xsl:message> -->    
        
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
    <!-- <xsl:message expand-text="yes">ch-right-alt-1: {$tmp-gis-1}</xsl:message> -->

    <xsl:variable name="tmp-gis-1ch" as="xs:string*"
                  select="for $e in $ch-right-alt-1/* return name($e)"/>
    <!-- <xsl:message expand-text="yes">ch-right-alt-1/*: {$tmp-gis-1ch}</xsl:message> -->
    
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
    <!-- <xsl:message expand-text="yes">ch-right-alt-2: {$tmp-gis-2}</xsl:message> -->    

    <xsl:variable name="tmp-gis-2ch" as="xs:string*"
                  select="for $e in $ch-right-alt-2/* return name($e)"/>
    <!-- <xsl:message expand-text="yes">ch-right-alt-2/*: {$tmp-gis-2ch}</xsl:message> -->
        
    <!--* 4 Write out an alt element containing the left context
        * and a new nonterminal. *-->
    <xsl:variable name="N" as="xs:string"
                  select="gt:generate-nonterminal(.)"/>
    
    <xsl:element name="alt">
      <xsl:sequence select="$ch-left"/>
      <xsl:element name="nonterminal">
        <xsl:attribute name="name" select="$N"/>
        <xsl:attribute name="mark" select=" '-' "/>
        
        <!--* 5 Write the rule for the new nonterminal,
            *   inside the new nonterminal reference.
            *   Two alt children, one with and one without. *-->
        <xsl:element name="gt:comment">
          <xsl:attribute name="gt:flag" select="'injection'"/>
          <xsl:element name="rule">
            <xsl:attribute name="name" select="$N"/>
            <xsl:attribute name="mark" select=" '-' "/>

            <xsl:choose>
              <xsl:when test="$option eq 'O3a'">
                <!-- An alt with the optional material
                     but without injected rule -->
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
                                        else if ($e/self::gt:comment[@gt:flag='injection'])
                                        then ()
                                        else $e"/>
                </xsl:element>
                <!-- An alt without the optional material
                     but with the injected rule -->
                <!-- don't take children of ch-right-alt-2, we want the alt -->
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
                                        else if ($e/self::gt:comment[@gt:flag='injection'])
                                        then ()
                                        else $e"/>
                </xsl:element>
              </xsl:when>
            </xsl:choose>
          </xsl:element>
        </xsl:element>
      </xsl:element>
    </xsl:element>

  </xsl:template>
  
  <!--* Rule O4a:  inline nested choice, empty-last
      * Rule 04b:  inline nested choice, empty-first
      * A, B?, C rewrites to (A, (B|), C), or (A, (|B), C).
      *-->
  <xsl:template match="option[$option = ('O4a', 'O4b')]"
                mode="ebnf-rewriting"
                >
    <!--* 1 Normalize all non-option children.
        * 2 Produce alts element with choice of children or nothing.
        *-->
    
    <!--* 1 Normalize all non-option children. *-->
    <xsl:variable name="children-0" as="element()*">
      <xsl:apply-templates select="*" mode="ebnf-rewriting"/>
    </xsl:variable>

    <!--* 2 Return choice *-->
    <xsl:element name="alts">
      <xsl:choose>
        <xsl:when test="$option eq 'O4a'">
          <xsl:element name="alt">
            <xsl:sequence select="$children-0"/>
          </xsl:element>
          <xsl:element name="alt"/>
        </xsl:when>
        <xsl:when test="$option eq 'O4b'">
          <xsl:element name="alt"/>
          <xsl:element name="alt">
            <xsl:sequence select="$children-0"/>
          </xsl:element>
        </xsl:when>
      </xsl:choose>
    </xsl:element>
    
  </xsl:template>

  <!--****************************************************************
      * repeat0 (star) in mode ebnf-rewriting
      *-->
  <!--* To be supplied *-->

  <!--****************************************************************
      * repeat1 (plus) in mode ebnf-rewriting
      *-->
  <!--* To be supplied *-->

  <!--****************************************************************
      * repeat0 with separator (starstar) in mode ebnf-rewriting
      *-->
  <!--* To be supplied *-->

  <!--****************************************************************
      * repeat1 with separator (plusplus) in mode ebnf-rewriting
      *-->
  <!--* To be supplied *-->


  <!--****************************************************************
      * Alts (nested-or) in mode ebnf-rewriting
      *-->

  <!--* Rule C1:  push choice outwards.
      * Need to act on enclosing alt, to get the entire sequence
      * of siblings.
      *-->
  <xsl:template match="alt[child::alts]
                       [$alts eq 'C1']"
                mode="ebnf-rewriting">
    <!--* 1 Process children (so: nested alts and siblings)
        * 2 Split children into L, C, R on first alts
        * 3 Process children of C.
        * 4 Process R recursively to catch any further alts in
        *   the sibling sequence.
        * 5 For each alt A returned by the recursion on R,
        *   and for each child E of C,
        *   return an alt containing L, E, A
        *-->
    <!--* 1 Process the children *-->
    <xsl:variable name="children-0" as="element()*">
      <xsl:apply-templates select="*" mode="ebnf-rewriting"/>
    </xsl:variable>

    <!--* 2 Split the children L, C, R *-->
    <xsl:variable name="gis" as="xs:string*"
                  select="for $e in $children-0
                          return local-name($e)"/>
    <xsl:variable name="index" as="xs:integer*"
                  select="(index-of($gis, 'alts'),
                          1+count($gis))[1]"/>

    <xsl:variable name="pch-L" as="element()*"
                  select="$children-0[position() lt $index]"/>
    <xsl:variable name="pchch-C" as="element()*">
      <xsl:apply-templates mode="ebnf-rewriting"
                           select="$children-0
                                   [position() eq $index]
                                   /*"/>
    </xsl:variable>
    <xsl:variable name="pch-R" as="element()*"
                  select="$children-0[position() gt $index]"/>

    <!--* 4 Process R recursively *-->
    <xsl:variable name="alt-pch-R1" as="element(alt)">
      <alt><xsl:sequence select="$pch-R"/></alt>
    </xsl:variable>
    <xsl:variable name="alts-pch-R2" as="element(alt)+">
      <xsl:apply-templates mode="ebnf-rewriting"
                           select="$alt-pch-R1"/>
    </xsl:variable>
    
    <!--* 5 For each alt A returned by the recursion on R,
        *   and for each child E of C,
        *   return an alt containing L, E, A
        *-->
    <xsl:for-each select="$pchch-C">
      <xsl:variable name="this-C" as="element(alt)"
                    select="."/>
      
      <xsl:for-each select="$alts-pch-R2">
        <xsl:variable name="this-R" as="element(alt)"
                      select="."/>
        <xsl:element name="alt">
          <xsl:sequence select="$pch-L, $this-C/*, $this-R/*"/>
        </xsl:element>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:template>
  
  <!--* Rule C2:  reify. *-->
  <xsl:template match="alts
                       [$alts eq 'C2']"
                mode="ebnf-rewriting"
                as="element()+">
    <!-- returns nonterminal plus comment -->

    <xsl:variable name="p-alts-0" as="element(alt)*">
      <xsl:apply-templates mode="ebnf-rewriting"
                           select="alt"/>
      <!-- suppress comments, for simplicity and better
           type checking -->
    </xsl:variable>
    <xsl:variable name="N" as="xs:string"
                  select="gt:generate-nonterminal(.)"/>
    <xsl:element name="nonterminal">
      <xsl:attribute name="name" select="$N"/>
      <xsl:attribute name="mark" select=" '-' "/>
      <xsl:element name="gt:comment">
        <xsl:attribute name="gt:flag" select="'injection'"/>
        <xsl:element name="rule">
          <xsl:attribute name="name" select="$N"/>
          <xsl:attribute name="mark" select=" '-' "/>
          <xsl:sequence select="$p-alts-0"/>
        </xsl:element>
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
  <xsl:template match="gt:comment[@gt:flag='injection']"
                mode="rule-extraposition"/>
  
  <xsl:template match="@gt:*"
                mode="rule-extraposition"/>
  
  <xsl:template match="ixml"
                mode="rule-extraposition">
    <xsl:copy>
      <xsl:sequence select="@*"/>      
      <xsl:apply-templates mode="rule-extraposition"/>

      <xsl:if test="descendant::gt:comment[@gt:flag='injection']">
        <xsl:element name="comment">
          <xsl:text>* New rules *</xsl:text>
        </xsl:element>
      </xsl:if>


      <xsl:variable name="promises-to-keep" as="element(rule)*"
                    select="descendant::gt:comment[@gt:flag='injection']
                            /rule"/>
      
      <xsl:variable name="new_nonterminals" as="xs:string*"
                    select="$promises-to-keep/@name/string()"/>

      <xsl:variable name="indices" as="xs:integer*"
                    select="for $N in distinct-values($new_nonterminals)
                            return index-of($new_nonterminals, $N)[1]"/>
      
      <xsl:apply-templates mode="rule-extraposition"
                           select="$promises-to-keep[position() = $indices]"/>
      
      <!-- <xsl:apply-templates mode="rule-extraposition"
                           select="descendant::gt:comment[@gt:flag='injection']
                           /rule"/> -->

      <!-- we apply templates because otherwise nested injections
           still show up as comments -->
      <!--
      <xsl:sequence select="descendant::gt:comment[@gt:flag='injection']
                            /rule"/>
                           -->
    </xsl:copy>
  </xsl:template>
  
  
  <!--****************************************************************
      * Predicates 
      *-->


 
  <!--****************************************************************
      * Named templates
      ****************************************************************
      *-->
  <!--* Find-fixpoint:  called by rule template on each alt element.
      * Calls itself until all constructs are normalized or until
      * time is up.
      *-->
  <xsl:template name="find-fixpoint"
                as="element(alt)+">
    <!--* E:  the element we are working on. *-->
    <xsl:param name="E" as="element(alt)"/>

    <!--* ttl:  time to live.  Give up (detect loop) at zero *-->
    <!--* 10 set for debugging; use larger number for production *-->
    <xsl:param name="ttl" as="xs:integer" select="10"/>
    <xsl:param name="rule" as="xs:string?"/>
    <!--
    <xsl:message>
      <xsl:text>find-fixpoint($E, </xsl:text>
      <xsl:value-of select="$ttl"/>
      <xsl:text>), where $E is: </xsl:text>
      <xsl:copy-of select="$E"/>
    </xsl:message> -->
    
    <xsl:variable name="finished" as="xs:boolean"
                  select="count($E/descendant::alts
                          | $E/descendant::option
                          | $E/descendant::repeat0
                          | $E/descendant::repeat1
                          ) eq 0"/>
    <!--
    <xsl:message>Find-fixpoint:  ttl <xsl:value-of select="$ttl"/></xsl:message>
    -->
    
    <xsl:choose>
      <xsl:when test="$finished">
        <!--<xsl:message>
          <xsl:text> ... nothing to do. </xsl:text>
        </xsl:message> -->
        <xsl:sequence select="$E"/>
      </xsl:when>
      <xsl:when test="$ttl eq 0">
        <xsl:message>
          <xsl:text>! Ran out of time - infinite loop? </xsl:text>
          <xsl:choose>
            <xsl:when test="exists($rule)">
              <xsl:text>&#xA;This RHS of rule </xsl:text>
              <xsl:value-of select="$rule"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>&#xA;This expression (rule unknown) </xsl:text>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:text>is not yet BNF:&#xA;</xsl:text>
          <xsl:copy-of select="$E"/>
        </xsl:message>
        <xsl:sequence select="$E"/>
      </xsl:when>
      <xsl:otherwise>
        <!-- Apply templates, then call recursivelly
             on each alt element returned. -->
        <xsl:variable name="alts" as="element(alt)+">
          <xsl:apply-templates mode="ebnf-rewriting"
                               select="$E"/>
        </xsl:variable>        
        <xsl:for-each select="$alts">
          <!--<xsl:message>
            <xsl:text> ... recurring </xsl:text>
          </xsl:message> -->
          <xsl:call-template name="find-fixpoint">
            <xsl:with-param name="E" select="."/>
            <xsl:with-param name="rule" select="$rule"/>
            <xsl:with-param name="ttl" select="$ttl - 1"/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>
  
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
