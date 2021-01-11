<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all"
                version="3.0">
   <!-- the tested stylesheet -->
   <xsl:import href="file:/Users/cmsmcq/2021/gingersnap/src/rk-subset.xsl"/>
   <!-- user-provided library module(s) -->
   <xsl:import href="file:/Users/cmsmcq/lib/xslt/strip-ws.xsl"/>
   <!-- XSpec library modules providing tools -->
   <xsl:include href="file:/home2/ex/xspec/xspec/src/common/runtime-utils.xsl"/>
   <xsl:variable name="Q{http://www.jenitennison.com/xslt/xspec}xspec-uri"
                 as="Q{http://www.w3.org/2001/XMLSchema}anyURI">file:/Users/cmsmcq/2021/gingersnap/tests/rk-subset.xspec</xsl:variable>
   <xsl:param xmlns:xsp="http://www.jenitennison.com/xslt/xspec"
              xmlns:xs="http://www.w3.org/2001/XMLSchema"
              xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
              name="Q{}k"
              select="xs:integer(2)"/>
   <xsl:variable xmlns:xsp="http://www.jenitennison.com/xslt/xspec"
                 xmlns:xs="http://www.w3.org/2001/XMLSchema"
                 xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                 name="Q{}strip"
                 as="xs:string"
                 select=" '*' "/>
   <xsl:variable xmlns:xsp="http://www.jenitennison.com/xslt/xspec"
                 xmlns:xs="http://www.w3.org/2001/XMLSchema"
                 xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                 name="Q{}keep"
                 as="xs:string"
                 select=" 'comment' "/>
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
            <xsl:attribute name="xspec" namespace="">file:/Users/cmsmcq/2021/gingersnap/tests/rk-subset.xspec</xsl:attribute>
            <xsl:attribute name="stylesheet" namespace="">file:/Users/cmsmcq/2021/gingersnap/src/rk-subset.xsl</xsl:attribute>
            <xsl:attribute name="date" namespace="" select="current-dateTime()"/>
            <!-- invoke each compiled top-level x:scenario -->
            <xsl:call-template name="Q{http://www.jenitennison.com/xslt/xspec}scenario1"/>
         </xsl:element>
      </xsl:result-document>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario1"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}scenario)">
      <xsl:context-item use="absent"/>
      <xsl:message>Test one-step r_k subset generation</xsl:message>
      <xsl:element name="scenario" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario1</xsl:attribute>
         <xsl:attribute name="xspec" namespace="">file:/Users/cmsmcq/2021/gingersnap/tests/rk-subset.xspec</xsl:attribute>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>Test one-step r_k subset generation</xsl:text>
         </xsl:element>
         <xsl:element name="input-wrap" namespace="">
            <xsl:element name="xsp:context" namespace="http://www.jenitennison.com/xslt/xspec">
               <xsl:namespace name="ws">http://www.blackmesatech.com/2021/nss/ws</xsl:namespace>
               <xsl:namespace name="xs">http://www.w3.org/2001/XMLSchema</xsl:namespace>
               <xsl:attribute name="href" namespace="">file:/Users/cmsmcq/2021/gingersnap/ab/a.ixml.xml</xsl:attribute>
            </xsl:element>
         </xsl:element>
         <xsl:variable name="Q{urn:x-xspec:compile:impl}context-d51e0-doc"
                       as="document-node()"
                       select="doc('file:/Users/cmsmcq/2021/gingersnap/ab/a.ixml.xml')"/>
         <xsl:variable name="Q{urn:x-xspec:compile:impl}context-d51e0"
                       select="$Q{urn:x-xspec:compile:impl}context-d51e0-doc ! ( . )"/>
         <xsl:variable name="Q{http://www.jenitennison.com/xslt/xspec}context"
                       select="$Q{urn:x-xspec:compile:impl}context-d51e0"/>
         <xsl:variable name="Q{http://www.jenitennison.com/xslt/xspec}result" as="item()*">
            <xsl:apply-templates select="$Q{urn:x-xspec:compile:impl}context-d51e0"/>
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
         <xsl:call-template name="Q{http://www.jenitennison.com/xslt/xspec}scenario1-expect2">
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
      <xsl:message>Number of rules should not shrink</xsl:message>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}expect-d50e8" select="()"><!--expected result--></xsl:variable>
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
                  <xsl:sequence xmlns:xsp="http://www.jenitennison.com/xslt/xspec"
                                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                                xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                                select="count(/ixml/rule) ge 1"
                                version="3"/>
               </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence xmlns:xsp="http://www.jenitennison.com/xslt/xspec"
                             xmlns:xs="http://www.w3.org/2001/XMLSchema"
                             xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                             select="count(/ixml/rule) ge 1"
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
               <xsl:sequence select="$Q{urn:x-xspec:compile:impl}test-result =&gt; boolean()"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:message terminate="yes">ERROR in xsp:expect ('Test one-step r_k subset generation Number of rules should not shrink'): Non-boolean @test must be accompanied by @as, @href, @select, or child node.</xsl:message>
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
            <xsl:text>Number of rules should not shrink</xsl:text>
         </xsl:element>
         <xsl:element name="expect-test-wrap" namespace="">
            <xsl:element name="xsp:expect" namespace="http://www.jenitennison.com/xslt/xspec">
               <xsl:namespace name="ws">http://www.blackmesatech.com/2021/nss/ws</xsl:namespace>
               <xsl:namespace name="xs">http://www.w3.org/2001/XMLSchema</xsl:namespace>
               <xsl:attribute name="test" namespace="">count(/ixml/rule) ge 1</xsl:attribute>
            </xsl:element>
         </xsl:element>
         <xsl:if test="not($Q{urn:x-xspec:compile:impl}boolean-test)">
            <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
               <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}test-result"/>
               <xsl:with-param name="report-name" select="'result'"/>
            </xsl:call-template>
         </xsl:if>
         <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
            <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}expect-d50e8"/>
            <xsl:with-param name="report-name" select="'expect'"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario1-expect2"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}test)">
      <xsl:context-item use="absent"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}context" required="yes"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}result" required="yes"/>
      <xsl:message/>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}expect-d50e9-doc"
                    as="document-node()"
                    select="doc('file:/Users/cmsmcq/2021/gingersnap/tests/xml/a.sub.r2.ixml.xml')"/>
      <xsl:variable xmlns:xsp="http://www.jenitennison.com/xslt/xspec"
                    xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                    name="Q{urn:x-xspec:compile:impl}expect-d50e9"
                    select="$Q{urn:x-xspec:compile:impl}expect-d50e9-doc ! ( ws:strip(ixml/rule, $strip, $keep) )"><!--expected result--></xsl:variable>
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
                  <xsl:sequence xmlns:xsp="http://www.jenitennison.com/xslt/xspec"
                                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                                xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                                select="ws:strip(ixml/rule, $strip, $keep)"
                                version="3"/>
               </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence xmlns:xsp="http://www.jenitennison.com/xslt/xspec"
                             xmlns:xs="http://www.w3.org/2001/XMLSchema"
                             xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                             select="ws:strip(ixml/rule, $strip, $keep)"
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
               <xsl:message terminate="yes">ERROR in xsp:expect ('Test one-step r_k subset generation'): Boolean @test must not be accompanied by @as, @href, @select, or child node.</xsl:message>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="Q{urn:x-xspec:common:deep-equal}deep-equal($Q{urn:x-xspec:compile:impl}expect-d50e9, $Q{urn:x-xspec:compile:impl}test-result, '')"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:if test="not($Q{urn:x-xspec:compile:impl}successful)">
         <xsl:message>      FAILED</xsl:message>
      </xsl:if>
      <xsl:element name="test" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario1-expect2</xsl:attribute>
         <xsl:attribute name="successful"
                        namespace=""
                        select="$Q{urn:x-xspec:compile:impl}successful"/>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec"/>
         <xsl:element name="expect-test-wrap" namespace="">
            <xsl:element name="xsp:expect" namespace="http://www.jenitennison.com/xslt/xspec">
               <xsl:namespace name="ws">http://www.blackmesatech.com/2021/nss/ws</xsl:namespace>
               <xsl:namespace name="xs">http://www.w3.org/2001/XMLSchema</xsl:namespace>
               <xsl:attribute name="test" namespace="">ws:strip(ixml/rule, $strip, $keep)</xsl:attribute>
            </xsl:element>
         </xsl:element>
         <xsl:if test="not($Q{urn:x-xspec:compile:impl}boolean-test)">
            <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
               <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}test-result"/>
               <xsl:with-param name="report-name" select="'result'"/>
            </xsl:call-template>
         </xsl:if>
         <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
            <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}expect-d50e9"/>
            <xsl:with-param name="report-name" select="'expect'"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
</xsl:stylesheet>
