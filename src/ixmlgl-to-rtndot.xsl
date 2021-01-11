<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    version="3.0">

  <!--* Read ixml grammar, produce RTN graph in dot notation.
      * If ixml grammar has been not augmented with gl:* attributes,
      * bail out.
      *-->

  <!--* 2020-11-30 : CMSMcQ : made stylesheet *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->

  <xsl:import href="dot-tools.xsl"/>
  
  <xsl:output method="text"
	      indent="yes"/>

  <!--* dir:  TD or LR *-->
  <xsl:param name="dir"
	     as="xs:string"
	     select=" 'LR' "/>
  
  <xsl:param name="fWrapsubgraphs"
	     as="xs:boolean"
	     select="true()"/>

  <!--* What color should be box around wrapped subgraphs be?
      * 'transparent' makes it go away.
      * 'black' is the Graphviz default.
      *-->
  <xsl:param name="sBoxcolor"
	     as="xs:string"
	     select=" 'blue' "/>
  
  <!--* fLinksubgraphs:  add links from one network to the other? *-->
  <xsl:param name="fLinksubgraphs"
	     as="xs:boolean"
	     select="true()"/>

  <!--* linkwhich:  recursive? or all? *-->
  <xsl:param name="linkwhich"
	     as="xs:string"
	     select=" 'recursive' "/>

  <xsl:variable name="G"
		as="element(ixml)"
		select="/*"/>
  

  <!--****************************************************************
      * Main / starting template
      ****************************************************************
      *-->
  <xsl:template match="ixml">
    <xsl:text>digraph rtn {&#xA;</xsl:text>
    
    <xsl:text>  /* Recursive transition network for a grammar. &#xA;</xsl:text>
    <xsl:text>     Generated by ixml-to-pcdot.xsl.&#xA;</xsl:text>
    <xsl:text>     Input:</xsl:text>
    <xsl:value-of select="base-uri()"/>
    <xsl:text>&#xA;</xsl:text>
    <xsl:text>     Generated:</xsl:text>
    <xsl:value-of select="current-dateTime()"/>
    <xsl:text> */&#xA;&#xA;</xsl:text>

    <xsl:text>  graph [rankdir="</xsl:text>
    <xsl:value-of select="$dir"/>
    <xsl:text>"];&#xA;</xsl:text>
    
    <xsl:apply-templates select="rule"/>

    <xsl:if test="$fLinksubgraphs">
      <!--* If user has requested that subgraph links be shown, then
	  * for every nonterminal N state in a RHS, for every state p 
	  * with a link from p to N (so p can precede N in a path) add a
	  * link from p to N_0; also for every final state f in the FSA
	  * for nonterminal N, add a link from f to N.
	  *-->
      <xsl:text>&#xA;</xsl:text>
      <xsl:text>  /* Inter-rule links */&#xA;</xsl:text>
      <xsl:text>     edge [color=gray, style=dashed]; &#xA;</xsl:text>
      <xsl:text>&#xA;</xsl:text>
      <xsl:for-each select="rule/descendant::nonterminal">
	<xsl:variable name="pos" as="element()" select="."/>
	<xsl:variable name="sym" as="xs:string" select="string(@name)"/>
	<xsl:variable name="posid" as="xs:string" select="string(@id)"/>
	<xsl:variable name="rule" as="element(rule)"
		      select="$G/rule[@name=$sym]"/>
	<xsl:variable name="fRec" as="xs:boolean"
		      select="xs:boolean($rule/@gt:recursive)"/>
	<xsl:if test="$fRec or ($linkwhich = 'all')">
	  <!--* find states that precede this position *-->
	  <!--* first, the follow:* attributes *-->
	  <xsl:variable name="laFollow"
			as="attribute()*"
			select="$pos/ancestor::rule/@follow:*"/>
	  
	  <!--* Then, the local names in follow:* attributes
	      * with a matching token in the value. *-->	  
	  <xsl:variable name="lidPredecessors"
			as="xs:string*"
			select="for $a
				in $laFollow
				[tokenize(., '\s+') = $posid]
				return local-name($a)"/>
	  <!--* also, if pos is in first() of its parent, we need
	      * the name of its parent's initial state *-->
	  <xsl:variable name="sPQ0"
			as="xs:string"
			select="gt:nodename(
				concat(
				$pos/ancestor::rule/@name/string(),
				'_0'))"/>
	  <xsl:variable name="idSilentpredecessor"
			as="xs:string?"
			select="if (
				tokenize($pos/ancestor::rule/@gl:first, '\s+')
				= $posid
				)
				then $sPQ0 else ()"/>
	  
	  <!--* draw links to the zero state of the nonterminal *-->
	  <xsl:variable name="q0" as="xs:string"
			select="gt:nodename(concat($sym, '_0'))"/>	  
	  <xsl:for-each select="($idSilentpredecessor, $lidPredecessors)">
	    <xsl:text>    </xsl:text>
	    <xsl:value-of select="gt:nodename(.)"/>
	    <xsl:text> -> </xsl:text>
	    <xsl:value-of select="$q0"/>
	    <xsl:text>;&#xA;</xsl:text>
	  </xsl:for-each>

	  <!--* find final states of the rule for this nonterminal *-->
	  <xsl:variable name="lidReturnstates"
			as="xs:string*"
			select="tokenize($rule/@gl:last, '\s+')"/>

	  <!--* draw links returning from the final states of
	      * the nonterminal *-->
	  <xsl:variable name="qt" as="xs:string"
			select="gt:nodename($posid)"/>
	  <xsl:for-each select="$lidReturnstates">
	    <xsl:text>    </xsl:text>
	    <xsl:value-of select="gt:nodename(.)"/>
	    <xsl:text> -> </xsl:text>
	    <xsl:value-of select="$qt"/>
	    <xsl:text>;&#xA;</xsl:text>
	  </xsl:for-each>
	</xsl:if>
      </xsl:for-each>
    </xsl:if>
    
    <xsl:text>}&#xA;</xsl:text>
  </xsl:template>
  

  <!--****************************************************************
      * Match templates for rules and nonterminals on RHS
      ****************************************************************
      *-->  
  
  <xsl:template match="comment"/>
  
  <xsl:template match="rule">

    <xsl:variable name="rule"
		  as="element(rule)"
		  select="."/>

    <!--* Tokenize the lists of first and last states *-->
    <xsl:variable name="lidFirst"
		  as="xs:string*"
		  select="tokenize(@gl:first, '\s+')"/>
    <xsl:variable name="lidLast"
		  as="xs:string*"
		  select="tokenize(@gl:last, '\s+')"/>
    
    <!--* Make a list of all states (from follow:*) *-->
    <xsl:variable name="lidStates"
		  as="xs:string*"
		  select="for $a in @follow:*
			  return local-name($a)"/>

    <!--* wrap the FSA for this rule in a subgraph *-->
    <xsl:text>&#xA;</xsl:text>
    <xsl:if test="$fWrapsubgraphs">
      <xsl:text>  subgraph cluster_</xsl:text>
      <xsl:value-of select="gt:nodename($rule/@name)"/>
      <xsl:text>{&#xA;</xsl:text>
      <xsl:text>    graph [pencolor=</xsl:text>
      <xsl:value-of select="$sBoxcolor"/>
      <xsl:text>]&#xA;</xsl:text>
    </xsl:if>
    
    <!--* For each state, declare the node with a label 
	* showing the symbol and (parenthesized on second line) 
	* the state name. *-->
    <xsl:for-each select="$lidStates">
      <xsl:variable name="id"
		    as="xs:string"
		    select="."/>
      <xsl:variable name="token"
		    as="element()"
		    select="$rule/descendant::*[@id=$id]"/>

      <xsl:text>    </xsl:text>
      <xsl:value-of select="gt:nodename($id)"/>
      <xsl:text>[label="</xsl:text>
      <xsl:apply-templates select="$token"/>
      <xsl:text>\n(</xsl:text>
      <xsl:value-of select="$id"/>
      <xsl:text>)"</xsl:text>
      <xsl:if test="$id = $lidLast">
	<xsl:text>, peripheries=2</xsl:text>
      </xsl:if>
      <xsl:text>];&#xA;</xsl:text>
    </xsl:for-each>

    <!--* Add a q_0 start state, with arcs to the first states. *-->
    <xsl:variable name="q0"
		  as="xs:string"
		  select="concat(string(@name), '_0')"/>

    <xsl:text>    </xsl:text>
    <xsl:value-of select="gt:nodename($q0)"/>
    <xsl:text>[label="</xsl:text>
    <xsl:apply-templates select="$q0"/>
    <xsl:text>"];&#xA;</xsl:text>    

    <xsl:for-each select="$lidFirst">
      <xsl:text>    </xsl:text>
      <xsl:value-of select="gt:nodename($q0)"/>
      <xsl:text> -> </xsl:text>
      <xsl:value-of select="gt:nodename(.)"/>
      <xsl:text>;&#xA;</xsl:text>
    </xsl:for-each>
    
    <!--* For each follow:* attribute, write an arc for each
	* token in the value. *-->
    <xsl:for-each select="@follow:*">
      <xsl:variable name="source"
		    as="xs:string"
		    select="gt:nodename(local-name(.))"/>
      <xsl:for-each select="tokenize(., '\s+')">
	<xsl:variable name="target"
		      as="xs:string"
		      select="gt:nodename(.)"/>
	<xsl:text>    </xsl:text>
	<xsl:value-of select="$source"/>
	<xsl:text> -> </xsl:text>
	<xsl:value-of select="$target"/>
	<xsl:text>;&#xA;</xsl:text>
      </xsl:for-each>
    </xsl:for-each>

    <xsl:if test="$fWrapsubgraphs">      
      <xsl:text>}&#xA;</xsl:text>
    </xsl:if>    
    
  </xsl:template>

  <xsl:template match="nonterminal">
    <xsl:value-of select="@name"/>
  </xsl:template>

  <xsl:template match="literal[@hex]">
    <xsl:value-of select="concat('#x', @hex)"/>
  </xsl:template>
  <xsl:template match="literal[@dstring]">
    <xsl:value-of select="concat('\&quot;', @dstring, '\&quot;')"/>
  </xsl:template>
  <xsl:template match="literal[@sstring]">
    <xsl:value-of select="concat(&quot;&apos;&quot;,
			  replace(@sstring, '&quot;', '\\&quot;'),
			  &quot;&apos;&quot;)"/>
  </xsl:template>

  <xsl:template match="inclusion">
    <xsl:text>[</xsl:text>
    <xsl:variable name="ls"
		  as="xs:string*">
      <xsl:apply-templates select="*"/>
    </xsl:variable>
    <xsl:value-of select="string-join($ls, '; ')"/>
    <xsl:text>]</xsl:text>    
  </xsl:template>
  
  <xsl:template match="exclusion">
    <xsl:text>~[</xsl:text>
    <xsl:variable name="ls"
		  as="xs:string*">
      <xsl:apply-templates select="*"/>
    </xsl:variable>
    <xsl:value-of select="string-join($ls, '; ')"/>
    <xsl:text>]</xsl:text>    
  </xsl:template>
  
  <xsl:template match="range">
    <xsl:value-of select="concat(
      &quot;&apos;&quot;, @from, &quot;&apos;&quot;, 
      '-',
      &quot;&apos;&quot;, @to, &quot;&apos;&quot;)"/>    
  </xsl:template>
  
  <xsl:template match="class">
    <xsl:value-of
	select="concat(
		'\p{', @code, '}')"/>    
  </xsl:template>

</xsl:stylesheet>
