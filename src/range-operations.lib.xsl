<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:d2x="http://www.blackmesatech.com/2014/lib/d2x"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    version="3.0">

  <!--* range-operations.xsl: functions for handling sequences of
      * character ranges represented as lists of integers or for
      * some purposes as strings.
      *-->

  <!--* Revisions:
      * 2020-12-28 : CMSMcQ : Move merge-elements here, too
      * 2020-12-25 : CMSMcQ : Better choice of hex or literal 
      * 2020-12-24 : CMSMcQ : Add intersection, serialization 
      * 2020-12-24 : CMSMcQ : Move functions from normalize-terminals 
      *                       into this library.
      *-->

  <!--* To do:
      * . Write a function for testing well-formedness of a range list.
      * . Write a function to take the union of a set of unordered
      *   ranges and produce a well-formed range list.  (Insertion
      *   sort, probably.)
      *   That function can replace merge-element ranges, which is
      *   less general.
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->
  <xsl:import href="../../../lib/xslt/d2x.xsl"/>

  <xsl:output method="xml"
	      indent="yes"/>

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
      * Functions
      ****************************************************************
      *-->

  <!--****************************************************************
      * Union and related 
      *-->

  <!--* Perform union operation on a pair of range lists *-->
  <!--* Assumes that the range lists are well formed. *-->
  <!--* gt:lrUnion#2, for external use *-->
  <xsl:function name="gt:lrUnion" as="xs:integer*">
    <xsl:param name="lrA" as="xs:integer*"/>
    <xsl:param name="lrB" as="xs:integer*"/>

    <xsl:sequence select="gt:lrUnion($lrA, $lrB, ())"/>
  </xsl:function>

  <!--* gt:lrUnion#2, internal aux function *-->
  <xsl:function name="gt:lrUnion" as="xs:integer*">
    <xsl:param name="lrA" as="xs:integer*"/>
    <xsl:param name="lrB" as="xs:integer*"/>
    <xsl:param name="acc" as="xs:integer*"/>

    <xsl:choose>
      <xsl:when test="empty($lrA)">
	<!--* if one argument is empty, return what we have. *-->
	<xsl:sequence select="$acc, $lrB"/>
      </xsl:when>
      <xsl:when test="empty($lrB)">
	<!--* if other argument is empty, return what we have. *-->
	<xsl:sequence select="$acc, $lrA"/>
      </xsl:when>
      <xsl:otherwise>
	<!--* neither argument is empty, each has a first range *-->
	<xsl:variable name="loA" as="xs:integer" select="$lrA[1]"/>
	<xsl:variable name="hiA" as="xs:integer" select="$lrA[2]"/>
	<xsl:variable name="loB" as="xs:integer" select="$lrB[1]"/>
	<xsl:variable name="hiB" as="xs:integer" select="$lrB[2]"/>

	<!--* We assume the ranges are well formed, so we have:
	    * loA <= hiA, loB <= hiB
	    *-->
	<xsl:choose>
	  <!--* Note that (loA le loB) OR (loA gt loB) *-->
	  <xsl:when test="$loA le $loB">
	    <!--* We have loA <= hiA, loB <= hiB, loA <= loB 
		* So: loA <= loB <= hiB
		* Where is hiA?
		*-->
	    <xsl:choose>
	      <!--* (hiA+1 << loB) OR (hiA <= hiB) OR (hiA > hiB)) *-->
	      <xsl:when test="($hiA + 1) lt $loB">
		<!--* We have loA <= loB <= hiB, hiA << loB 
		    * So: loA <= hiA << loB <= hiB
		    * Ranges are disjoint.  Accumulate A and recur.
		    * Keep B around, it may overlap the next A. 
		    *-->
		<xsl:sequence select="gt:lrUnion(
				      $lrA[position() gt 2],
				      $lrB,
				      ($acc, $loA, $hiA)
				      )"/>
	      </xsl:when>
	      <xsl:when test="$hiA le $hiB">
		<!--* We have loA <= loB <<= hiA <= hiB
		    * So ranges overlap, and B ends higher.
		    * Merge the ranges.
		    * A and B are done and go away.
		    * Push merger onto lrB, it may overlap the next A.
		    *-->
		<xsl:sequence select="gt:lrUnion(
				      $lrA[position() gt 2],
				      ($loA, $hiB, $lrB[position() gt 2]),
				      $acc
				      )"/>
	      </xsl:when>
	      <xsl:otherwise>
		<!--* We have loA <= loB <= hiB < hiA 
		    * So: range A includes range B entirely.
		    * B has achieved its goal and fades away.
		    * A stays; perhaps it overlaps with next B.
		    *-->
		<xsl:sequence select="gt:lrUnion(
				      $lrA,
				      $lrB[position() gt 2],
				      $acc
				      )"/>
	      </xsl:otherwise>
	    </xsl:choose>
	  </xsl:when>

	  <!--* Y'know, you could get rid of this second set of
	      * three cases by just recurring with A and B reversed.
	      * Did you ever think of that?
	      * Of course I thought of that.  I just said so,
	      * didn't I?
	      * Then where were you when I needed you?
	      *-->
	  
	  <!--* loA <= hiA, loB <= hiB 
	      * loA > loB 
	      * So: loB < loA <= hiA
	      * Where is hiB?
	      *-->
	  <!--* (hiB << loA) OR (hiB <= hiA) OR (hiB > hiA) *-->
	  <xsl:when test="($hiB + 1) lt $loA">
	    <!--* loB < hiB << loA <= hiA *-->
	    <!--* We have daylight between B and A.
		* Accumulate B, keep A, it may overlap next B. *-->
	    <xsl:sequence select="gt:lrUnion(
				  $lrA,
				  $lrB[position() gt 2],
				  ($acc, $loB, $hiB)
				  )"/>
	  </xsl:when>
	  <xsl:when test="$hiB le $hiA">
	    <!--* loB << loA <<= hiB <= hiA *-->
	    <!--* Ranges overlap; merge them.
		* A and B are done, push merger onto lrA, it may
		* overlap next B.
		*-->

		<xsl:sequence select="gt:lrUnion(
				      ($loB, $hiA, $lrA[position() gt 2]),
				      $lrB[position() gt 2],
				      $acc
				      )"/>
	  </xsl:when>
	  <xsl:otherwise>
	    <!--* loB << loA <= hiA < hiB *-->
	    <!--* B strictly contains A.  A is done, keep B
		* around, it may overlap next A. *-->
	    <xsl:sequence select="gt:lrUnion(
				  $lrA[position() gt 2],
				  $lrB,
				  $acc
				  )"/>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <!--* Hack: union operation on a pair of strings *-->
  <xsl:function name="gt:lrUnionSS" as="xs:integer*">
    <xsl:param name="sA" as="xs:string"/>
    <xsl:param name="sB" as="xs:string"/>

    <xsl:sequence select="gt:lrUnion(
			  for $t in tokenize($sA,'\s+')
			  [normalize-space()]
			  return xs:integer($t),
			  
			  for $t in tokenize($sB,'\s+') 
			  [normalize-space()]
			  return xs:integer($t)
			  )"/>
  </xsl:function>
  
 
  <!--****************************************************************
      * Intersection and related 
      *-->

  <!--* Perform intersection operation on a pair of range lists *-->
  <!--* Assumes that the range lists are well formed. *-->
  <!--* gt:lrIntersection#2, for external use *-->
  <xsl:function name="gt:lrIntersection" as="xs:integer*">
    <xsl:param name="lrA" as="xs:integer*"/>
    <xsl:param name="lrB" as="xs:integer*"/>

    <xsl:sequence select="gt:lrIntersection($lrA, $lrB, ())"/>
  </xsl:function>

  <!--* gt:lrIntersection#2, internal aux function *-->
  <xsl:function name="gt:lrIntersection" as="xs:integer*">
    <xsl:param name="lrA" as="xs:integer*"/>
    <xsl:param name="lrB" as="xs:integer*"/>
    <xsl:param name="acc" as="xs:integer*"/>

    <xsl:choose>
      <xsl:when test="empty($lrA)">
	<!--* if one argument is empty, the intersection is
	    * as big as it's going to get. *-->
	<xsl:sequence select="$acc"/>
      </xsl:when>
      <xsl:when test="empty($lrB)">
	<!--* if other argument is empty, similarly. *-->
	<xsl:sequence select="$acc"/>
      </xsl:when>
      <xsl:otherwise>
	<!--* neither argument is empty, each has a first range *-->
	<xsl:variable name="loA" as="xs:integer" select="$lrA[1]"/>
	<xsl:variable name="hiA" as="xs:integer" select="$lrA[2]"/>
	<xsl:variable name="loB" as="xs:integer" select="$lrB[1]"/>
	<xsl:variable name="hiB" as="xs:integer" select="$lrB[2]"/>

	<!--* We assume the ranges are well formed, so we have:
	    * loA <= hiA, loB <= hiB
	    *-->
	<xsl:choose>
	  <!--* Note that (loA le loB) OR (loA gt loB) *-->
	  <xsl:when test="$loA le $loB">
	    <!--* We have loA <= hiA, loB <= hiB, loA <= loB 
		* So: loA <= loB <= hiB
		* Where is hiA?
		*-->
	    <xsl:choose>
	      <!--* (hiA+1 << loB) OR (hiA <= hiB) OR (hiA > hiB)) *-->
	      <xsl:when test="($hiA) lt $loB">
		<!--* We have loA <= loB <= hiB, hiA < loB 
		    * So: loA <= hiA < loB <= hiB
		    * Ranges are disjoint.  Drop A and recur.
		    * Keep B around, it may overlap the next A. 
		    *-->
		<xsl:sequence select="gt:lrIntersection(
				      $lrA[position() gt 2],
				      $lrB,
				      ($acc)
				      )"/>
	      </xsl:when>
	      <xsl:when test="$hiA le $hiB">
		<!--* We have loA <= loB <= hiA <= hiB
		    * So ranges overlap, and B ends higher.
		    * Take the middle part.
		    * A is done and can go away.
		    * Keep  B, it may overlap the next A.
		    *-->
		<xsl:sequence select="gt:lrIntersection(
				      $lrA[position() gt 2],
				      ($lrB),
				      ($acc, $loB, $hiA)
				      )"/>
	      </xsl:when>
	      <xsl:otherwise>
		<!--* We have loA <= loB <= hiB < hiA 
		    * So: range A includes range B entirely.
		    * B has achieved its goal and fades away.
		    * A stays; perhaps it overlaps with next B.
		    *-->
		<xsl:sequence select="gt:lrIntersection(
				      $lrA,
				      $lrB[position() gt 2],
				      ($acc, $loB, $hiB)
				      )"/>
	      </xsl:otherwise>
	    </xsl:choose>
	  </xsl:when>

	  <!--* Y'know, you could get rid of this second set of
	      * three cases by just recurring with A and B reversed.
	      * Did you ever think of that?
	      * Of course I thought of that.  I just said so,
	      * didn't I?
	      * Then where were you when I needed you?
	      * Right here.  All the time, right here.
	      *-->

	  <xsl:otherwise>
	    <xsl:sequence select="gt:lrIntersection($lrB, $lrA, $acc)"/>
	  </xsl:otherwise>
	  
	</xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <!--* Hack: intersection operation on a pair of strings *-->
  <xsl:function name="gt:lrIntersectionSS" as="xs:integer*">
    <xsl:param name="sA" as="xs:string"/>
    <xsl:param name="sB" as="xs:string"/>

    <xsl:sequence select="gt:lrIntersection(
			  for $t in tokenize($sA,'\s+')
			  [normalize-space()]
			  return xs:integer($t),
			  
			  for $t in tokenize($sB,'\s+') 
			  [normalize-space()]
			  return xs:integer($t)
			  )"/>
  </xsl:function>

  <!--****************************************************************
      * Difference and related 
      *-->
  
  <!--* gt:lrDiff:  given two normalized sequences of ranges,
      * subtract second from first.
      *-->
  <xsl:function name="gt:lrDiff"
		as="xs:integer*">
    <xsl:param name="lrMinuend" as="xs:integer*"/>
    <xsl:param name="lrSubtrahend" as="xs:integer*"/>
    <xsl:sequence select="gt:lrDiff($lrMinuend, $lrSubtrahend, ())"/>
  </xsl:function>
  
  <xsl:function name="gt:lrDiff"
		as="xs:integer*">
    <xsl:param name="lrMinuend" as="xs:integer*"/>
    <xsl:param name="lrSubtrahend" as="xs:integer*"/>
    <xsl:param name="acc" as="xs:integer*"/>

    <xsl:choose>
      <!--* boundary case: nothing left to subtract *-->
      <xsl:when test="empty($lrSubtrahend)">
	<xsl:sequence select="$acc, $lrMinuend"/>
      </xsl:when>
      
      <!--* boundary case: nothing left to subtract from *-->
      <xsl:when test="empty($lrMinuend)">
	<xsl:sequence select="$acc"/>
      </xsl:when>

      <xsl:otherwise>
	<xsl:variable name="loMin" as="xs:integer"
		      select="$lrMinuend[1]"/>
	<xsl:variable name="hiMin" as="xs:integer"
		      select="$lrMinuend[2]"/>
	<xsl:variable name="loSub" as="xs:integer"
		      select="$lrSubtrahend[1]"/>
	<xsl:variable name="hiSub" as="xs:integer"
		      select="$lrSubtrahend[2]"/>
	
	<!--* We have: loMin <= hiMin, loSub <= hiSub *-->
	<xsl:choose>
	  <xsl:when test="$loSub le $loMin">
	    <!--* We have loSub <= loMin <= hiMin.
		* Where does hiSub fit? *-->
	    <xsl:choose>
	      <xsl:when test="$hiSub lt $loMin">
		<!--* loSub <= hiSub < loMin <= hiMin *-->
		<!--* No overlap.  Subtrahend is
		    * gegenstandlos and can be skipped.
		    * Keep the minuend, the next subtrahend
		    * could touch it.
		    *-->
		<xsl:sequence select="gt:lrDiff(
				      $lrMinuend,
				      $lrSubtrahend[position() gt 2],
				      $acc
				      )"/>
		    
	      </xsl:when>
	      <xsl:when test="$hiSub lt $hiMin">
		<!--* loSub <= loMin < hiSub < hiMin *-->
		<!--* Minuend loses from loMin to hiSub, inclusive.
		    * Subtrahend has now done its work and can go.
		    * Keep the rest of the minuend (hiSub+1, hiMin)
		    * on the list, the next subtrahend might touch
		    * it. *-->
		<xsl:sequence select="gt:lrDiff(
				      ($hiSub + 1, $hiMin,
				      $lrMinuend[position() gt 2]),
				      $lrSubtrahend[position() gt 2],
				      $acc
				      )"/>		
	      </xsl:when>
	      <xsl:when test="$hiSub ge $hiMin">
		<!--* loSub <= loMin <= hiMin <= hiSub *-->
		<!--* Subtrahend includes the minuend.  Nothing is
		    * left of the minuend; drop it.  Keep the
		    * subtrahend:  it could also cover the next
		    * minuend. *-->
		<xsl:sequence select="gt:lrDiff(
				      $lrMinuend[position() gt 2],
				      $lrSubtrahend,
				      $acc
				      )"/>
	      </xsl:when>
	      
	      <xsl:otherwise>
		<xsl:message terminate="yes">
		  <xsl:text>Numbers are required to be </xsl:text>
		  <xsl:text>less than, equal to, or </xsl:text>
		  <xsl:text>greater than each other.</xsl:text>
		  <xsl:text>&#xA;Live with it.</xsl:text>
		</xsl:message>
	      </xsl:otherwise>
	    </xsl:choose>

	  </xsl:when>

	  <!--* Since loSub is not le LoMin,
	      * we have loMin < loSub <= hiSub.
	      * Where does hiMin fit? *-->
	  <xsl:when test="$hiMin lt $loSub">
	    <!--* loMin <= hiMin < loSub <= hiSub *-->
	    <!--* No overlap.  This part of the minuend is now safe
		* and can be accumulated. *-->
	    <xsl:sequence select="gt:lrDiff(
				  $lrMinuend[position() gt 2],
				  $lrSubtrahend,
				  ($acc, $loMin, $hiMin)
				  )"/>
	  </xsl:when>
	  
	  <xsl:when test="$hiMin le $hiSub">
	    <!--* loMin < loSub <= hiMin <= hiSub *-->
	    <!--* The minuend loses from loSub to hiMin.
		* Accumulate loMin to loSub - 1.
		* Keep the subtrahend, it may have more work to do.
		*-->
	    <xsl:sequence select="gt:lrDiff(
				  $lrMinuend[position() gt 2],
				  $lrSubtrahend,
				  ($acc, $loMin, ($loSub - 1))
				  )"/>
	  </xsl:when>
	  
	  <xsl:when test="$hiMin gt $hiSub">
	    <!--* loMin < loSub <= hiSub < hiMin *-->
	    <!--* The subtrahend knocks out part of the minuend and 
		* is done.  Accumulate the low surviving subrange,
		* keep the high subrange for the next subtrahend.
		*-->
	    <xsl:sequence select="gt:lrDiff(
				  ($hiSub + 1, $hiMin,
				  $lrMinuend[position() gt 2]),
				  $lrSubtrahend[position() gt 2],
				  ($acc, $loMin, ($loSub - 1))
				  )"/>
	  </xsl:when>

	  <xsl:otherwise>
	    <xsl:message terminate="yes">
	      <xsl:text>For any two numbers a and b,</xsl:text>
	      <xsl:text>we should have a lt b, a = b, or a gt b.</xsl:text>
	      <xsl:text>&#xA;I'm disappointed with a world </xsl:text>
	      <xsl:text>in which this appears not to hold.</xsl:text>
	    </xsl:message>
	  </xsl:otherwise>

	</xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <!--* Hack: diff operation on a pair of strings *-->
  <xsl:function name="gt:lrDiffSS" as="xs:integer*">
    <xsl:param name="sA" as="xs:string"/>
    <xsl:param name="sB" as="xs:string"/>

    <xsl:sequence select="gt:lrDiff(
			  for $t in tokenize($sA,'\s+')
			  [normalize-space()]
			  return xs:integer($t), 
			  for $t in tokenize($sB,'\s+') 
			  [normalize-space()]
			  return xs:integer($t)
			  )"/>
  </xsl:function>
  

  <!--****************************************************************
      * Serialization
      *-->
  <!--* gt:serialize-range-list($lr):  create an element for the given
      * range:  literal for single-character single rangers,
      * inclusion otherwise.  Code copied from initial sketch in
      * class-codes-to-ranges.xq
      *-->
  <xsl:function name="gt:serialize-range-list"
		as="element()">
    <xsl:param name="lr" as="xs:integer*"/>

    <xsl:choose>
      <xsl:when test="(count($lr) eq 2)
		      and $lr[1] eq $lr[2]">
	<!--* one-character range *-->
	<xsl:variable name="hex-value" as="xs:string"
		      select="d2x:d2x($lr[1])"/>
	<xsl:element name="literal">
	  <xsl:sequence select="gt:make-char-attribute('lit',$lr[1])"/>
	  <!-- <xsl:attribute name="hex" select="$hex-value"/> -->
	  <xsl:attribute name="gt:ranges" select="$lr[1], $lr[2]"/>
	  <xsl:element name="comment">
	    <xsl:text> #</xsl:text>
	    <xsl:value-of select="$hex-value"/>
	    <xsl:text> = &#xBB;</xsl:text>
	    <xsl:value-of select="codepoints-to-string($lr[1])"/>
	    <xsl:text>&#xAB; </xsl:text>
	  </xsl:element>
	</xsl:element>
      </xsl:when>
      <xsl:when test="count($lr) eq 0">
	<!--* something is very wrong *-->
	<xsl:message>Something is very very wrong. </xsl:message>
	<xsl:element name="comment">
	  <xsl:text> empty range </xsl:text>
	</xsl:element>
      </xsl:when>
      <xsl:otherwise>
	<xsl:element name="inclusion">
	  <xsl:attribute name="gt:ranges" select="$lr"/>
	  <xsl:sequence select="gt:serialize-as-members($lr, ())"/>
	</xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!--* gt:serialize-as-members($lr): serialize each range
      * in the list as a range or a literal element *-->
  <xsl:function name="gt:serialize-as-members"
		as="element()*">
    <xsl:param name="lr" as="xs:integer*"/>
    <xsl:param name="acc" as="element()*"/>

    <xsl:choose>
      <xsl:when test="empty($lr)">
	<xsl:sequence select="$acc"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:variable name="e" as="element()">
	  <xsl:choose>
	    <xsl:when test="$lr[1] eq $lr[2]">
	      <xsl:variable name="hex-value"
			    as="xs:string"
			    select="d2x:d2x($lr[1])"/>
	      <xsl:element name="literal">
		<xsl:sequence
		    select="gt:make-char-attribute('lit', $lr[1])"/>
		<!--
		<xsl:attribute name="hex" select="$hex-value"/>
		-->
		<xsl:attribute name="gt:ranges"
			       select="$lr[1], $lr[2]"/>
		<xsl:element name="comment">
		  <xsl:text> #</xsl:text>
		  <xsl:value-of select="$hex-value"/>
		  <xsl:text> = &#xBB;</xsl:text>
		  <xsl:value-of select="codepoints-to-string($lr[1])"/>
		  <xsl:text>&#xAB; </xsl:text>
		</xsl:element>
	      </xsl:element>
	    </xsl:when>      
	    <xsl:otherwise>
	      <xsl:element name="range">
	      <xsl:variable name="hex-1"
			    as="xs:string"
			    select="d2x:d2x($lr[1])"/>
	      <xsl:variable name="hex-2"
			    as="xs:string"
			    select="d2x:d2x($lr[2])"/>
	      <xsl:sequence
		  select="gt:make-char-attribute('from', $lr[1]),
			  gt:make-char-attribute('to', $lr[2])"/>
	      <!--*
		  <xsl:attribute name="from"
			       select="concat('#', $hex-1)"/>
		  <xsl:attribute name="to"
			       select="concat('#', $hex-2)"/>
			       *-->
	      <xsl:attribute name="gt:ranges"
			     select="$lr[1], $lr[2]"/>
	      <xsl:element name="comment">
		<xsl:text> </xsl:text>
		<xsl:value-of select="concat(
				      '#',
				      $hex-1, 
				      ' - #',
				      $hex-2					
				      )"/>
		<xsl:text> = &#xBB;</xsl:text>
		<xsl:value-of select="codepoints-to-string($lr[1])"/>
		<xsl:text>&#xAB; - &#xBB;</xsl:text>
		<xsl:value-of select="codepoints-to-string($lr[2])"/>
		<xsl:text>&#xAB; </xsl:text>
	      </xsl:element>
	      </xsl:element>
	    </xsl:otherwise>
	  </xsl:choose>
	</xsl:variable>
	<xsl:sequence select="gt:serialize-as-members(
			      $lr[position() gt 2],
			      ($acc, $e)
			      )"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="gt:make-char-attribute" as="attribute()">
    <!--* an: attribute name *-->
    <xsl:param name="an" as="xs:string"/>
    <!--* cp: code point, as integer *-->
    <xsl:param name="cp" as="xs:integer"/>

    <!--* hex: hexadecimal numeral for code point *-->
    <xsl:variable name="sHex" as="xs:string"
		  select="d2x:d2x($cp)"/>
    <!--* c: character, as string *-->
    <xsl:variable name="c" as="xs:string"
		  select="codepoints-to-string($cp)"/>

    <!--* Now choose how we want this character written out.
	* As hex, or as string?  We prefer string but use hex to avoid
	* confusion and complications, 
	*-->
    <xsl:variable name="fHex" as="xs:boolean">
      <xsl:choose>
	<xsl:when test="$c eq ' '">
	  <xsl:value-of select="false()"/>
	</xsl:when>
	<xsl:when test="$sHex = ('22', '27')">
	  <!--* #22 dq, #27 sq *-->
	  <xsl:value-of select="true()"/>
	</xsl:when>
	<xsl:when test="matches($c, '\p{Pi}|\p{Pf}')">
	  <!--* class of initial and final quotation marks *-->
	  <xsl:value-of select="true()"/>
	</xsl:when>
	<xsl:when test="matches($c, '\p{Z}')">
	  <!--* class of separators *-->
	  <xsl:value-of select="true()"/>
	</xsl:when>
	<xsl:when test="matches($c, '\p{C}')">
	  <!--* class of control characters *-->
	  <xsl:value-of select="true()"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:value-of select="false()"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="$an = ('from', 'to')">
	<xsl:attribute name="{$an}"
		       select="if ($fHex)
			   then concat('#', $sHex)
			   else $c"/>
      </xsl:when>
      <!--* if attribute name is not from or two, we have
	  * to choose the attribute name based on value.
	  *-->
      <xsl:when test="$fHex">
	<xsl:attribute name="hex" select="$sHex"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:attribute name="dstring" select="$c"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!--****************************************************************
      * Well-formedness checking 
      *-->

  <!--****************************************************************
      * Miscellaneous 
      *-->

  <!--* merge-element-ranges:  given a sequence of elements (e.g.
      * children of an inclusion), merge their ranges.
      * Assume that each range is well formed.
      *
      * (Very ad hoc:  this code should be replaced by something
      * more general.)
      *-->
  <xsl:function name="gt:merge-element-ranges"
		as="xs:integer*">
    <xsl:param name="le" as="element()*"/>
    <!--* pass the work off to an auxiliary function *-->
    <xsl:sequence select="gt:merge-element-ranges($le, ())"/>
  </xsl:function>
  
  <xsl:function name="gt:merge-element-ranges"
		as="xs:integer*">
    <xsl:param name="le" as="element()*"/>
    <xsl:param name="acc" as="xs:integer*"/>

    <xsl:choose>
      <xsl:when test="empty($le)">
	<!--* Element list is done, return what we have. *-->
	<xsl:sequence select="$acc"/>
      </xsl:when>
      <xsl:otherwise>
	<!--* Element list is not done, merge next element into
	    * accumulator and recur.  We pass the actual merger
	    * to a general union operator on lists of ranges.
	    *-->
	<xsl:variable name="li" as="xs:integer*"
		      select="for $t
			      in tokenize(head($le)/@gt:ranges, '\s+')
			      [normalize-space()]
			      return xs:integer($t)"/>
	<xsl:variable name="new-acc" as="xs:integer*"
		      select="gt:lrUnion($li, $acc)"/>
	<xsl:sequence select="gt:merge-element-ranges(tail($le), $new-acc)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <!--* normalize ordered ranges:  given a sequence of ranges in
      * ascending order of start position, eliminate duplicates
      * and overlaps.
      *
      * Nice try, but the input isn't guaranteed to be ordered in
      * the way this function assumes:  not all inputs to the sort
      * are atomic ranges. (1 4 17 20) and (2 7) won't be handled
      * right by this function.
      *-->
  <xsl:function name="gt:normalize-ordered-ranges"
		as="xs:integer*">
    <xsl:param name="lr" as="xs:integer*"/>
    <xsl:param name="acc" as="xs:integer*"/>

    <xsl:message>n-o-r call: lr = <xsl:sequence select="$lr"/></xsl:message>
    <xsl:message>n-o-r call: acc = <xsl:sequence select="$acc"/></xsl:message>
    
    <xsl:choose>
      <xsl:when test="empty($lr)">
	<xsl:message>n-o-r call: lr empty, return = <xsl:sequence select="$acc"/></xsl:message>
	<xsl:message>-----</xsl:message>	
	<xsl:sequence select="$acc"/>
      </xsl:when>
      <xsl:when test="count($lr) eq 2">
	<!--* only one range left, take it. *-->
	<xsl:message>n-o-r call: |lr|=2, return = <xsl:sequence select="($acc,
	$lr)"/></xsl:message>
	<xsl:message>-----</xsl:message>		
	<xsl:sequence select="$acc, $lr"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:variable name="loThis" as="xs:integer"
		      select="$lr[1]"/>
	<xsl:variable name="hiThis" as="xs:integer"
		      select="$lr[2]"/>
	<xsl:variable name="loNext" as="xs:integer"
		      select="$lr[3]"/>
	<xsl:variable name="hiNext" as="xs:integer"
		      select="$lr[4]"/>

	<!--* assert:  loThis <= hiThis *-->
	<!--* assert:  loNext <= hiNext *-->
	<!--* assert:  loThis <= loNext *-->
	<!--* Thus loThis <= loNext <= hiNext *-->
	<xsl:choose>
	  <xsl:when test="($hiThis + 1) lt $loNext">
	    <!--* loThis <= hiThis < loNext <= hiNext *-->	    
	    <!--* Daylight between This and Next.
		* Add This to accumulator, recur *-->
	    <xsl:message>assert that: <xsl:value-of
	    select="concat($loThis,
	    ' le ', $hiThis,
	    ' lt ', $loNext,
	    ' le ', $hiNext)"
	    /></xsl:message>
	    <xsl:message>n-o-r call: daylight.  Accumulate, recur</xsl:message>
	    <xsl:sequence select="gt:normalize-ordered-ranges(
				  $lr[position() gt 2],
				  ($acc, $loThis, $hiThis)
				  )"/>
	  </xsl:when>
	  
	  <!--* assumed: loThis <= loNext <= hiNext *-->	  
	  <!--* assert: ($hiThis + 1) gt $loNext *-->
	  <!--* So either of: 
	      *    loThis <= loNext <= hiThis <= hiNext 
	      *    loThis <= loNext <= hiNext <= hiThis 
	      *-->	    
	  <xsl:when test="true()">
	  <!-- $hiThis ge $hiNext" *-->

	    <!--* This and Next overlap.  Merge them, recur.
		*--><xsl:message>assert that:  <xsl:value-of
	    select="concat($loThis,
	    ' le ', $loNext,
	    ' le ', $hiNext,
	    ' le ', $hiThis,
	    ' OR: ',
	    $loThis,
	    ' le ', $loNext,
	    ' le ', $hiThis,
	    ' le ', $hiNext, 
	    '.'
	    )"
	    /></xsl:message>
	    <xsl:variable name="newHi" as="xs:integer"
			  select="max( ($hiThis, $hiNext) )"/>
	    <xsl:message>New high is <xsl:value-of select="$newHi"/></xsl:message>
	    <xsl:message>n-o-r call: overlap.  Merge, recur</xsl:message>	    
	    <xsl:sequence select="gt:normalize-ordered-ranges(
				  ($loThis, $newHi,
				  $lr[position() gt 4]),
				  $acc
				  )"/>
	  </xsl:when>
	  
	  <xsl:otherwise>
	    <!--* loThis <= loNext <= hiThis <= hiNext *-->
	    <xsl:message>This case was unanticipated.</xsl:message>
	    <xsl:message>-----</xsl:message>
	  </xsl:otherwise>
	  
	</xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  

  

  <!--****************************************************************
      * Templates
      ****************************************************************
      *-->
  
  <!--* No templates.  What part of the phrase "function library"
      * led you to expect templates?  Sheesh.
      *-->

  <!--* Hard to say.  Maybe the named template for running tests? *-->

  <!--* Simple test cases *-->
  <!--* At some point these should probably migrate to
      * an XSpec test suite.
      *-->
  <xsl:template name="run-f-tests" as="element(test-results)">
    <xsl:variable name="function-tests" as="element(f-test)*">
      <!--* edge cases, empty range lists *-->
      <f-test expect="1 100"
	      test="gt:lrUnionSS('1 100', '  ')"
	      result="{gt:lrUnionSS('1 100', '  ')}"
	      />
      <f-test expect=""
	      test="gt:lrUnionSS('', '')"
	      result="{gt:lrUnionSS('', '')}"
	      />
      <f-test expect="1 10"
	      test="gt:lrUnionSS('', '1 10')"
	      result="{gt:lrUnionSS('', '1 10')}"
	      />
      
      <!--* A A B B *-->
      <!--* B B A A *-->
      
      <!--* A=A=B=B *-->
      <f-test expect="1 1"
	      test="gt:lrUnionSS('1 1', '1 1')"
	      result="{gt:lrUnionSS('1 1', '1 1')}"
	      />
      <!--* A=A<B=B *-->
      <!--* Disjoint, with daylight *-->
      <f-test expect="1 3 7 9"
	      test="gt:lrUnionSS('1 3', '7 9')"
	      result="{gt:lrUnionSS('1 3', '7 9')}"
	      />
      <f-test expect="1 3 7 9"
	      test="gt:lrUnionSS('7 9', '1 3')"
	      result="{gt:lrUnionSS('7 9', '1 3')}"
	      />

      <!--* Disjoint, abutting *-->
      <f-test expect="1 9"
	      test="gt:lrUnionSS('1 5', '6 9')"
	      result="{gt:lrUnionSS('1 5', '6 9')}"
	      />
      <f-test expect="1 9"
	      test="gt:lrUnionSS('7 9', '1 6')"
	      result="{gt:lrUnionSS('7 9', '1 6')}"
	      />
      

      <!--* A B B A *-->
      <!--* B A A B *-->
      <!--* Containment *-->
      <f-test expect="1 9"
	      test="gt:lrUnionSS('1 9', '3 5')"
	      result="{gt:lrUnionSS('1 9', '3 5')}"
	      />
      <f-test expect="1 9"
	      test="gt:lrUnionSS('3 5', '1 9')"
	      result="{gt:lrUnionSS('3 5', '1 9')}"
	      />
      <!--* Shared start *-->
      <f-test expect="1 9"
	      test="gt:lrUnionSS('1 5', '1 9')"
	      result="{gt:lrUnionSS('1 5', '1 9')}"
	      />
      <f-test expect="1 9"
	      test="gt:lrUnionSS('1 9', '1 5')"
	      result="{gt:lrUnionSS('1 9', '1 5')}"
	      />
      <!--* Shared end *-->
      <f-test expect="1 9"
	      test="gt:lrUnionSS('1 9', '5 9')"
	      result="{gt:lrUnionSS('1 9', '5 9')}"
	      />
      <f-test expect="1 9"
	      test="gt:lrUnionSS('5 9', '1 9')"
	      result="{gt:lrUnionSS('5 9', '1 9')}"
	      />

      
      <!--* A B A B *-->
      <!--* B A B A *-->
      <!--* Overlap *-->
      <f-test expect="1 9"
	      test="gt:lrUnionSS('1 7', '5 9')"
	      result="{gt:lrUnionSS('1 7', '5 9')}"
	      />
      <f-test expect="1 9"
	      test="gt:lrUnionSS('4 9', '1 5')"
	      result="{gt:lrUnionSS('4 9', '1 5')}"
	      />

      <f-test expect="32 32 160 160 5760 5760 8192 8202 8239 8239"
	      test="gt:lrUnionSS(
		    '32 32 160 160 5760 5760 8192 8202 8239 8239', 
		    '   ' 
		    )"
	      result="{gt:lrUnionSS(
		    '32 32 160 160 5760 5760 8192 8202 8239 8239', 
		    '   ' 
		    )}"
	      />
      
      <f-test expect="32 32 160 160 5760 5760 8192 8202 8239 8239"
	      test="gt:lrUnionSS(
		    '   ',
		    '32 32 160 160 5760 5760 8192 8202 8239 8239'
		    )"
	      result="{gt:lrUnionSS(
		    '   ',
		    '32 32 160 160 5760 5760 8192 8202 8239 8239'
		    )}"
	      />
      
      <f-test expect="10 12 32 32 48 57 160 160 5760 5760 8190 8300"
	      test="gt:lrUnionSS(
		    '32 32 160 160 5760 5760 8192 8202', 
		    '10 12 48 57 160 160 8190 8191 8200 8300' 
		    ) "
	      result="{gt:lrUnionSS(
		    '32 32 160 160 5760 5760 8192 8202', 
		    '10 12 48 57 160 160 8190 8191 8200 8300' 
		    ) }"
	      />



      <!--* Diff tests *-->
      <!--* edge cases, empty range lists *-->
      <f-test expect="1 100"
	      test="gt:lrDiffSS('1 100', '  ')"
	      result="{gt:lrDiffSS('1 100', '  ')}"
	      />
      <f-test expect=""
	      test="gt:lrDiffSS('', '')"
	      result="{gt:lrDiffSS('', '')}"
	      />
      <f-test expect=""
	      test="gt:lrDiffSS('', '1 10')"
	      result="{gt:lrDiffSS('', '1 10')}"
	      />
      
      <!--* A A B B *-->
      <!--* B B A A *-->
      
      <!--* A=A=B=B *-->
      <f-test expect=""
	      test="gt:lrDiffSS('1 1', '1 1')"
	      result="{gt:lrDiffSS('1 1', '1 1')}"
	      />
      <!--* A=A<B=B *-->
      <!--* Disjoint, with daylight *-->
      <f-test expect="1 3"
	      test="gt:lrDiffSS('1 3', '7 9')"
	      result="{gt:lrDiffSS('1 3', '7 9')}"
	      />
      <f-test expect="7 9"
	      test="gt:lrDiffSS('7 9', '1 3')"
	      result="{gt:lrDiffSS('7 9', '1 3')}"
	      />

      <!--* Disjoint, abutting *-->
      <f-test expect="1 5"
	      test="gt:lrDiffSS('1 5', '6 9')"
	      result="{gt:lrDiffSS('1 5', '6 9')}"
	      />
      <f-test expect="7 9"
	      test="gt:lrDiffSS('7 9', '1 6')"
	      result="{gt:lrDiffSS('7 9', '1 6')}"
	      />
      <f-test expect="1 5"
	      test="gt:lrDiffSS('1 6', '6 9')"
	      result="{gt:lrDiffSS('1 5', '6 9')}"
	      />
      <f-test expect="7 9"
	      test="gt:lrDiffSS('6 9', '1 6')"
	      result="{gt:lrDiffSS('7 9', '1 6')}"
	      />
      

      <!--* A B B A *-->
      <!--* B A A B *-->
      <!--* Containment *-->
      <f-test expect="1 2 6 9"
	      test="gt:lrDiffSS('1 9', '3 5')"
	      result="{gt:lrDiffSS('1 9', '3 5')}"
	      />
      <f-test expect=""
	      test="gt:lrDiffSS('3 5', '1 9')"
	      result="{gt:lrDiffSS('3 5', '1 9')}"
	      />
      <f-test expect="1 5 7 9"
	      test="gt:lrDiffSS('1 9', '6 6')"
	      result="{gt:lrDiffSS('1 9', '6 6')}"
	      />
      <f-test expect=""
	      test="gt:lrDiffSS('6 6', '1 9')"
	      result="{gt:lrDiffSS('6 6', '1 9')}"
	      />
      <!--* Shared start *-->
      <f-test expect=""
	      test="gt:lrDiffSS('1 5', '1 9')"
	      result="{gt:lrDiffSS('1 5', '1 9')}"
	      />
      <f-test expect="6 9"
	      test="gt:lrDiffSS('1 9', '1 5')"
	      result="{gt:lrDiffSS('1 9', '1 5')}"
	      />
      <!--* Shared end *-->
      <f-test expect="1 4"
	      test="gt:lrDiffSS('1 9', '5 9')"
	      result="{gt:lrDiffSS('1 9', '5 9')}"
	      />
      <f-test expect=""
	      test="gt:lrDiffSS('5 9', '1 9')"
	      result="{gt:lrDiffSS('5 9', '1 9')}"
	      />

      
      <!--* A B A B *-->
      <!--* B A B A *-->
      <!--* Overlap *-->
      <f-test expect="1 4"
	      test="gt:lrDiffSS('1 7', '5 9')"
	      result="{gt:lrDiffSS('1 7', '5 9')}"
	      />
      <f-test expect="6 9"
	      test="gt:lrDiffSS('4 9', '1 5')"
	      result="{gt:lrDiffSS('4 9', '1 5')}"
	      />

      <f-test expect="32 32 160 160 5760 5760 8192 8202 8239 8239"
	      test="gt:lrDiffSS(
		    '32 32 160 160 5760 5760 8192 8202 8239 8239', 
		    '   ' 
		    )"
	      result="{gt:lrDiffSS(
		    '32 32 160 160 5760 5760 8192 8202 8239 8239', 
		    '   ' 
		    )}"
	      />
      
      <f-test expect=""
	      test="gt:lrDiffSS(
		    '   ',
		    '32 32 160 160 5760 5760 8192 8202 8239 8239'
		    )"
	      result="{gt:lrDiffSS(
		    '   ',
		    '32 32 160 160 5760 5760 8192 8202 8239 8239'
		    )}"
	      />
      
      <f-test expect="32 32 5760 5760 8192 8199"
	      test="gt:lrDiffSS(
		    '32 32 160 160 5760 5760 8192 8202', 
		    '10 12 48 57 160 160 8190 8191 8200 8300' 
		    ) "
	      result="{gt:lrDiffSS(
		    '32 32 160 160 5760 5760 8192 8202', 
		    '10 12 48 57 160 160 8190 8191 8200 8300' 
		    ) }"
	      />
      
      <f-test expect="10 12 48 57 8190 8191 8203 8300"
	      test="gt:lrDiffSS(
		    '10 12 48 57 160 160 8190 8191 8200 8300' ,
		    '32 32 160 160 5760 5760 8192 8202'
		    ) "
	      result="{gt:lrDiffSS(
		    '10 12 48 57 160 160 8190 8191 8200 8300' ,
		    '32 32 160 160 5760 5760 8192 8202'
		    ) }"
	      />



      <!--* edge cases, empty range lists *-->
      <f-test expect=""
	      test="gt:lrIntersectionSS('1 100', '  ')"
	      result="{gt:lrIntersectionSS('1 100', '  ')}"
	      />
      <f-test expect=""
	      test="gt:lrIntersectionSS('', '')"
	      result="{gt:lrIntersectionSS('', '')}"
	      />
      <f-test expect=""
	      test="gt:lrIntersectionSS('', '1 10')"
	      result="{gt:lrIntersectionSS('', '1 10')}"
	      />
      
      <!--* A A B B *-->
      <!--* B B A A *-->
      
      <!--* A=A=B=B *-->
      <f-test expect="1 1"
	      test="gt:lrIntersectionSS('1 1', '1 1')"
	      result="{gt:lrIntersectionSS('1 1', '1 1')}"
	      />
      <!--* A=A<B=B *-->
      <!--* Disjoint, with daylight *-->
      <f-test expect=""
	      test="gt:lrIntersectionSS('1 3', '7 9')"
	      result="{gt:lrIntersectionSS('1 3', '7 9')}"
	      />
      <f-test expect=""
	      test="gt:lrIntersectionSS('7 9', '1 3')"
	      result="{gt:lrIntersectionSS('7 9', '1 3')}"
	      />

      <!--* Disjoint, abutting *-->
      <f-test expect=""
	      test="gt:lrIntersectionSS('1 5', '6 9')"
	      result="{gt:lrIntersectionSS('1 5', '6 9')}"
	      />
      <f-test expect=""
	      test="gt:lrIntersectionSS('7 9', '1 6')"
	      result="{gt:lrIntersectionSS('7 9', '1 6')}"
	      />
      

      <!--* A B B A *-->
      <!--* B A A B *-->
      <!--* Containment *-->
      <f-test expect="3 5"
	      test="gt:lrIntersectionSS('1 9', '3 5')"
	      result="{gt:lrIntersectionSS('1 9', '3 5')}"
	      />
      <f-test expect="3 5"
	      test="gt:lrIntersectionSS('3 5', '1 9')"
	      result="{gt:lrIntersectionSS('3 5', '1 9')}"
	      />
      <!--* Shared start *-->
      <f-test expect="1 5"
	      test="gt:lrIntersectionSS('1 5', '1 9')"
	      result="{gt:lrIntersectionSS('1 5', '1 9')}"
	      />
      <f-test expect="1 5"
	      test="gt:lrIntersectionSS('1 9', '1 5')"
	      result="{gt:lrIntersectionSS('1 9', '1 5')}"
	      />
      <!--* Shared end *-->
      <f-test expect="5 9"
	      test="gt:lrIntersectionSS('1 9', '5 9')"
	      result="{gt:lrIntersectionSS('1 9', '5 9')}"
	      />
      <f-test expect="5 9"
	      test="gt:lrIntersectionSS('5 9', '1 9')"
	      result="{gt:lrIntersectionSS('5 9', '1 9')}"
	      />

      
      <!--* A B A B *-->
      <!--* B A B A *-->
      <!--* Overlap *-->
      <f-test expect="5 7"
	      test="gt:lrIntersectionSS('1 7', '5 9')"
	      result="{gt:lrIntersectionSS('1 7', '5 9')}"
	      />
      <f-test expect="4 5"
	      test="gt:lrIntersectionSS('4 9', '1 5')"
	      result="{gt:lrIntersectionSS('4 9', '1 5')}"
	      />

      <f-test expect=""
	      test="gt:lrIntersectionSS(
		    '32 32 160 160 5760 5760 8192 8202 8239 8239', 
		    '   ' 
		    )"
	      result="{gt:lrIntersectionSS(
		    '32 32 160 160 5760 5760 8192 8202 8239 8239', 
		    '   ' 
		    )}"
	      />
      
      <f-test expect=""
	      test="gt:lrIntersectionSS(
		    '   ',
		    '32 32 160 160 5760 5760 8192 8202 8239 8239'
		    )"
	      result="{gt:lrIntersectionSS(
		    '   ',
		    '32 32 160 160 5760 5760 8192 8202 8239 8239'
		    )}"
	      />
      
      <f-test expect="160 160 8200 8202"
	      test="gt:lrIntersectionSS(
		    '32 32 160 160 5760 5760 8192 8202', 
		    '10 12 48 57 160 160 8190 8191 8200 8300' 
		    ) "
	      result="{gt:lrIntersectionSS(
		    '32 32       160 160 5760 5760           8192 8202', 
		    '10 12 48 57 160 160           8190 8191 8200 8300' 
		    ) }"
	      />

      

    </xsl:variable>
    
    <test-results gt:date="{current-dateTime()}">
      <div id="function-tests">
      <xsl:for-each select="$function-tests">
	<xsl:choose>
	  <xsl:when test="string(@expect) eq string(@result)">
	    <test n="{position()}" result="pass"/>
	  </xsl:when>
	  <xsl:otherwise>
	    <test n="{position()}" result="fail">
	      <test><xsl:value-of select="@test"/></test>
	      <expected><xsl:sequence select="@expect"/></expected>
	      <actual><xsl:sequence select="@result"/></actual>
	    </test>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:for-each>
      </div>
    </test-results>
  </xsl:template>

</xsl:stylesheet>

