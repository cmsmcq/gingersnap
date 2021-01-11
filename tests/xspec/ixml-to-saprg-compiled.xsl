<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">
   <!-- the tested stylesheet -->
   <xsl:import href="file:/Users/cmsmcq/2021/gingersnap/src/ixml-to-saprg.xsl"/>
   <!-- user-provided library module(s) -->
   <xsl:import href="file:/Users/cmsmcq/lib/xslt/strip-ws.xsl"/>
   <!-- XSpec library modules providing tools -->
   <xsl:include href="file:/home2/ex/xspec/xspec/src/common/runtime-utils.xsl"/>
   <xsl:variable name="Q{http://www.jenitennison.com/xslt/xspec}xspec-uri"
                 as="Q{http://www.w3.org/2001/XMLSchema}anyURI">file:/Users/cmsmcq/2021/gingersnap/tests/ixml-to-saprg.xspec</xsl:variable>
   <!-- the main template to run the suite -->
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}main"
                 as="empty-sequence()">
      <xsl:context-item use="absent"/>
      <!-- info message -->
      <xsl:message>
         <xsl:text>Testing with </xsl:text>
         <xsl:value-of select="system-property('Q{http://www.w3.org/1999/XSL/Transform}product-name')"/>
         <xsl:text> </xsl:text>
         <xsl:value-of select="system-property('Q{http://www.w3.org/1999/XSL/Transform}product-version')"/>
      </xsl:message>
      <!-- set up the result document (the report) -->
      <xsl:result-document format="Q{{http://www.jenitennison.com/xslt/xspec}}xml-report-serialization-parameters">
         <xsl:element name="report" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:attribute name="xspec" namespace="">file:/Users/cmsmcq/2021/gingersnap/tests/ixml-to-saprg.xspec</xsl:attribute>
            <xsl:attribute name="stylesheet" namespace="">file:/Users/cmsmcq/2021/gingersnap/src/ixml-to-saprg.xsl</xsl:attribute>
            <xsl:attribute name="date" namespace="" select="current-dateTime()"/>
            <!-- invoke each compiled top-level x:scenario -->
            <xsl:call-template name="Q{http://www.jenitennison.com/xslt/xspec}scenario1"/>
         </xsl:element>
      </xsl:result-document>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario1"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}scenario)">
      <xsl:context-item use="absent"/>
      <xsl:message>When invoked without parameters</xsl:message>
      <xsl:element name="scenario" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario1</xsl:attribute>
         <xsl:attribute name="xspec" namespace="">file:/Users/cmsmcq/2021/gingersnap/tests/ixml-to-saprg.xspec</xsl:attribute>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>When invoked without parameters</xsl:text>
         </xsl:element>
         <xsl:element name="input-wrap" namespace="">
            <xsl:element name="xspec:context" namespace="http://www.jenitennison.com/xslt/xspec">
               <xsl:namespace name="ws">http://www.blackmesatech.com/2021/nss/ws</xsl:namespace>
               <xsl:namespace name="xs">http://www.w3.org/2001/XMLSchema</xsl:namespace>
               <xsl:attribute name="href" namespace="">file:/Users/cmsmcq/2021/gingersnap/tests/xml/Program.pcgl.ixml.xml</xsl:attribute>
               <xsl:attribute name="mode" namespace="">make-rtn</xsl:attribute>
            </xsl:element>
         </xsl:element>
         <xsl:variable name="Q{urn:x-xspec:compile:impl}context-d48e0-doc"
                       as="document-node()"
                       select="doc('file:/Users/cmsmcq/2021/gingersnap/tests/xml/Program.pcgl.ixml.xml')"/>
         <xsl:variable name="Q{urn:x-xspec:compile:impl}context-d48e0"
                       select="$Q{urn:x-xspec:compile:impl}context-d48e0-doc ! ( . )"/>
         <xsl:variable name="Q{http://www.jenitennison.com/xslt/xspec}context"
                       select="$Q{urn:x-xspec:compile:impl}context-d48e0"/>
         <xsl:variable name="Q{http://www.jenitennison.com/xslt/xspec}result" as="item()*">
            <xsl:apply-templates select="$Q{urn:x-xspec:compile:impl}context-d48e0" mode="Q{}make-rtn"/>
         </xsl:variable>
         <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
            <xsl:with-param name="sequence"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
            <xsl:with-param name="report-name" select="'result'"/>
         </xsl:call-template>
         <!-- invoke each compiled x:expect -->
         <xsl:call-template name="Q{http://www.jenitennison.com/xslt/xspec}scenario1-expect1">
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}context"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}context"/>
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}result"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario1-expect1"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}test)">
      <xsl:context-item use="absent"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}context" required="yes"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}result" required="yes"/>
      <xsl:message>then expand all nonterminals and add linkage</xsl:message>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}expect-d47e5-doc"
                    as="document-node()"
                    select="doc('file:/Users/cmsmcq/2021/gingersnap/tests/xml/Program.r0sup.saprg.ixml.xml')"/>
      <xsl:variable xmlns:xspec="http://www.jenitennison.com/xslt/xspec"
                    xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                    name="Q{urn:x-xspec:compile:impl}expect-d47e5"
                    select="$Q{urn:x-xspec:compile:impl}expect-d47e5-doc ! ( ws:strip(ixml/rule,'*','') )"><!--expected result--></xsl:variable>
      <!-- wrap $x:result into a document node if possible -->
      <xsl:variable name="Q{urn:x-xspec:compile:impl}test-items" as="item()*">
         <xsl:choose>
            <xsl:when test="exists($Q{http://www.jenitennison.com/xslt/xspec}result) and Q{http://www.jenitennison.com/xslt/xspec}wrappable-sequence($Q{http://www.jenitennison.com/xslt/xspec}result)">
               <xsl:sequence select="Q{http://www.jenitennison.com/xslt/xspec}wrap-nodes($Q{http://www.jenitennison.com/xslt/xspec}result)"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <!-- evaluate the predicate with $x:result (or its wrapper document node) as context item if it is a single item; if not, evaluate the predicate without context item -->
      <xsl:variable name="Q{urn:x-xspec:compile:impl}test-result" as="item()*">
         <xsl:choose>
            <xsl:when test="count($Q{urn:x-xspec:compile:impl}test-items) eq 1">
               <xsl:for-each select="$Q{urn:x-xspec:compile:impl}test-items">
                  <xsl:sequence xmlns:xspec="http://www.jenitennison.com/xslt/xspec"
                                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                                xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                                select="ws:strip(ixml/rule,'*','')"
                                version="3"/>
               </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence xmlns:xspec="http://www.jenitennison.com/xslt/xspec"
                             xmlns:xs="http://www.w3.org/2001/XMLSchema"
                             xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                             select="ws:strip(ixml/rule,'*','')"
                             version="3"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}boolean-test"
                    as="Q{http://www.w3.org/2001/XMLSchema}boolean"
                    select="$Q{urn:x-xspec:compile:impl}test-result instance of Q{http://www.w3.org/2001/XMLSchema}boolean"/>
      <!-- did the test pass? -->
      <xsl:variable name="Q{urn:x-xspec:compile:impl}successful"
                    as="Q{http://www.w3.org/2001/XMLSchema}boolean">
         <xsl:choose>
            <xsl:when test="$Q{urn:x-xspec:compile:impl}boolean-test">
               <xsl:message terminate="yes">ERROR in xspec:expect ('When invoked without parameters then expand all nonterminals and add linkage'): Boolean @test must not be accompanied by @as, @href, @select, or child node.</xsl:message>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="Q{urn:x-xspec:common:deep-equal}deep-equal($Q{urn:x-xspec:compile:impl}expect-d47e5, $Q{urn:x-xspec:compile:impl}test-result, '')"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:if test="not($Q{urn:x-xspec:compile:impl}successful)">
         <xsl:message>      FAILED</xsl:message>
      </xsl:if>
      <xsl:element name="test" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario1-expect1</xsl:attribute>
         <xsl:attribute name="successful"
                        namespace=""
                        select="$Q{urn:x-xspec:compile:impl}successful"/>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>then expand all nonterminals and add linkage</xsl:text>
         </xsl:element>
         <xsl:element name="expect-test-wrap" namespace="">
            <xsl:element name="xspec:expect" namespace="http://www.jenitennison.com/xslt/xspec">
               <xsl:namespace name="ws">http://www.blackmesatech.com/2021/nss/ws</xsl:namespace>
               <xsl:namespace name="xs">http://www.w3.org/2001/XMLSchema</xsl:namespace>
               <xsl:attribute name="test" namespace="">ws:strip(ixml/rule,'*','')</xsl:attribute>
            </xsl:element>
         </xsl:element>
         <xsl:if test="not($Q{urn:x-xspec:compile:impl}boolean-test)">
            <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
               <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}test-result"/>
               <xsl:with-param name="report-name" select="'result'"/>
            </xsl:call-template>
         </xsl:if>
         <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
            <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}expect-d47e5"/>
            <xsl:with-param name="report-name" select="'expect'"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
</xsl:stylesheet>
