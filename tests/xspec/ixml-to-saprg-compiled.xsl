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
            <xsl:call-template name="Q{http://www.jenitennison.com/xslt/xspec}scenario2"/>
            <xsl:call-template name="Q{http://www.jenitennison.com/xslt/xspec}scenario3"/>
            <xsl:call-template name="Q{http://www.jenitennison.com/xslt/xspec}scenario4"/>
            <xsl:call-template name="Q{http://www.jenitennison.com/xslt/xspec}scenario5"/>
         </xsl:element>
      </xsl:result-document>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario1"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}scenario)">
      <xsl:context-item use="absent"/>
      <xsl:message>When invoked without parameters ...</xsl:message>
      <xsl:element name="scenario" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario1</xsl:attribute>
         <xsl:attribute name="xspec" namespace="">file:/Users/cmsmcq/2021/gingersnap/tests/ixml-to-saprg.xspec</xsl:attribute>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>When invoked without parameters ... </xsl:text>
         </xsl:element>
         <xsl:element name="input-wrap" namespace="">
            <xsl:element name="xspec:context" namespace="http://www.jenitennison.com/xslt/xspec">
               <xsl:namespace name="ws">http://www.blackmesatech.com/2021/nss/ws</xsl:namespace>
               <xsl:namespace name="xs">http://www.w3.org/2001/XMLSchema</xsl:namespace>
               <xsl:attribute name="href" namespace="">file:/Users/cmsmcq/2021/gingersnap/tests/xml/Program.pcgl.ixml.xml</xsl:attribute>
               <xsl:attribute name="mode" namespace="">make-rtn</xsl:attribute>
            </xsl:element>
         </xsl:element>
         <xsl:variable name="Q{urn:x-xspec:compile:impl}context-d52e0-doc"
                       as="document-node()"
                       select="doc('file:/Users/cmsmcq/2021/gingersnap/tests/xml/Program.pcgl.ixml.xml')"/>
         <xsl:variable name="Q{urn:x-xspec:compile:impl}context-d52e0"
                       select="$Q{urn:x-xspec:compile:impl}context-d52e0-doc ! ( . )"/>
         <xsl:variable name="Q{http://www.jenitennison.com/xslt/xspec}context"
                       select="$Q{urn:x-xspec:compile:impl}context-d52e0"/>
         <xsl:variable name="Q{http://www.jenitennison.com/xslt/xspec}result" as="item()*">
            <xsl:apply-templates select="$Q{urn:x-xspec:compile:impl}context-d52e0" mode="Q{}make-rtn"/>
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
      <xsl:message>then expand recursive nonterminals and add linkage</xsl:message>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}expect-d51e5-doc"
                    as="document-node()"
                    select="doc('file:/Users/cmsmcq/2021/gingersnap/tests/xml/Program.r0sup.saprg.ixml.xml')"/>
      <xsl:variable xmlns:xspec="http://www.jenitennison.com/xslt/xspec"
                    xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                    name="Q{urn:x-xspec:compile:impl}expect-d51e5"
                    select="$Q{urn:x-xspec:compile:impl}expect-d51e5-doc ! ( ws:strip(ixml/rule,'*','') )"><!--expected result--></xsl:variable>
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
               <xsl:message terminate="yes">ERROR in xspec:expect ('When invoked without parameters ... then expand recursive nonterminals and add linkage'): Boolean @test must not be accompanied by @as, @href, @select, or child node.</xsl:message>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="Q{urn:x-xspec:common:deep-equal}deep-equal($Q{urn:x-xspec:compile:impl}expect-d51e5, $Q{urn:x-xspec:compile:impl}test-result, '')"/>
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
            <xsl:text>then expand recursive nonterminals and add linkage</xsl:text>
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
            <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}expect-d51e5"/>
            <xsl:with-param name="report-name" select="'expect'"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario2"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}scenario)">
      <xsl:context-item use="absent"/>
      <xsl:message>When ixml template invoked with non-fissile = #none</xsl:message>
      <xsl:element name="scenario" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario2</xsl:attribute>
         <xsl:attribute name="xspec" namespace="">file:/Users/cmsmcq/2021/gingersnap/tests/ixml-to-saprg.xspec</xsl:attribute>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>When ixml template invoked with non-fissile = #none</xsl:text>
         </xsl:element>
         <xsl:element name="input-wrap" namespace="">
            <xsl:element name="xspec:context" namespace="http://www.jenitennison.com/xslt/xspec">
               <xsl:namespace name="ws">http://www.blackmesatech.com/2021/nss/ws</xsl:namespace>
               <xsl:namespace name="xs">http://www.w3.org/2001/XMLSchema</xsl:namespace>
               <xsl:attribute name="href" namespace="">file:/Users/cmsmcq/2021/gingersnap/tests/xml/Program.pcgl.ixml.xml</xsl:attribute>
               <xsl:attribute name="select" namespace="">ixml</xsl:attribute>
               <xsl:attribute name="mode" namespace="">make-rtn</xsl:attribute>
               <xsl:element name="xspec:param" namespace="http://www.jenitennison.com/xslt/xspec">
                  <xsl:namespace name="ws">http://www.blackmesatech.com/2021/nss/ws</xsl:namespace>
                  <xsl:namespace name="xs">http://www.w3.org/2001/XMLSchema</xsl:namespace>
                  <xsl:attribute name="name" namespace="">non-fissile</xsl:attribute>
                  <xsl:attribute name="tunnel" namespace="">yes</xsl:attribute>
                  <xsl:attribute name="select" namespace=""> '#none' </xsl:attribute>
               </xsl:element>
            </xsl:element>
         </xsl:element>
         <xsl:variable name="Q{urn:x-xspec:compile:impl}context-d64e0-doc"
                       as="document-node()"
                       select="doc('file:/Users/cmsmcq/2021/gingersnap/tests/xml/Program.pcgl.ixml.xml')"/>
         <xsl:variable xmlns:xspec="http://www.jenitennison.com/xslt/xspec"
                       xmlns:xs="http://www.w3.org/2001/XMLSchema"
                       xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                       name="Q{urn:x-xspec:compile:impl}context-d64e0"
                       select="$Q{urn:x-xspec:compile:impl}context-d64e0-doc ! ( ixml )"/>
         <xsl:variable name="Q{http://www.jenitennison.com/xslt/xspec}context"
                       select="$Q{urn:x-xspec:compile:impl}context-d64e0"/>
         <xsl:variable name="Q{http://www.jenitennison.com/xslt/xspec}result" as="item()*">
            <xsl:variable xmlns:xspec="http://www.jenitennison.com/xslt/xspec"
                          xmlns:xs="http://www.w3.org/2001/XMLSchema"
                          xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                          name="Q{}non-fissile"
                          select=" '#none' "/>
            <xsl:apply-templates select="$Q{urn:x-xspec:compile:impl}context-d64e0" mode="Q{}make-rtn">
               <xsl:with-param xmlns:xspec="http://www.jenitennison.com/xslt/xspec"
                               xmlns:xs="http://www.w3.org/2001/XMLSchema"
                               xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                               name="Q{}non-fissile"
                               select="$Q{}non-fissile"
                               tunnel="yes"/>
            </xsl:apply-templates>
         </xsl:variable>
         <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
            <xsl:with-param name="sequence"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
            <xsl:with-param name="report-name" select="'result'"/>
         </xsl:call-template>
         <!-- invoke each compiled x:expect -->
         <xsl:call-template name="Q{http://www.jenitennison.com/xslt/xspec}scenario2-expect1">
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}context"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}context"/>
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}result"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
         </xsl:call-template>
         <xsl:call-template name="Q{http://www.jenitennison.com/xslt/xspec}scenario2-expect2">
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}context"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}context"/>
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}result"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
         </xsl:call-template>
         <xsl:call-template name="Q{http://www.jenitennison.com/xslt/xspec}scenario2-expect3">
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}context"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}context"/>
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}result"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario2-expect1"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}test)">
      <xsl:context-item use="absent"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}context" required="yes"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}result" required="yes"/>
      <xsl:message>then result should be an ixml element</xsl:message>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}expect-d51e9" select="()"><!--expected result--></xsl:variable>
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
                                select="name($xspec:result) eq 'ixml'"
                                version="3"/>
               </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence xmlns:xspec="http://www.jenitennison.com/xslt/xspec"
                             xmlns:xs="http://www.w3.org/2001/XMLSchema"
                             xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                             select="name($xspec:result) eq 'ixml'"
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
               <xsl:message terminate="yes">ERROR in xspec:expect ('When ixml template invoked with non-fissile = #none then result should be an ixml element'): Non-boolean @test must be accompanied by @as, @href, @select, or child node.</xsl:message>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:if test="not($Q{urn:x-xspec:compile:impl}successful)">
         <xsl:message>      FAILED</xsl:message>
      </xsl:if>
      <xsl:element name="test" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario2-expect1</xsl:attribute>
         <xsl:attribute name="successful"
                        namespace=""
                        select="$Q{urn:x-xspec:compile:impl}successful"/>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>then result should be an ixml element</xsl:text>
         </xsl:element>
         <xsl:element name="expect-test-wrap" namespace="">
            <xsl:element name="xspec:expect" namespace="http://www.jenitennison.com/xslt/xspec">
               <xsl:namespace name="ws">http://www.blackmesatech.com/2021/nss/ws</xsl:namespace>
               <xsl:namespace name="xs">http://www.w3.org/2001/XMLSchema</xsl:namespace>
               <xsl:attribute name="test" namespace="">name($xspec:result) eq 'ixml'</xsl:attribute>
            </xsl:element>
         </xsl:element>
         <xsl:if test="not($Q{urn:x-xspec:compile:impl}boolean-test)">
            <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
               <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}test-result"/>
               <xsl:with-param name="report-name" select="'result'"/>
            </xsl:call-template>
         </xsl:if>
         <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
            <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}expect-d51e9"/>
            <xsl:with-param name="report-name" select="'expect'"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario2-expect2"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}test)">
      <xsl:context-item use="absent"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}context" required="yes"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}result" required="yes"/>
      <xsl:message>then result should be an ixml element</xsl:message>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}expect-d51e10" select="()"><!--expected result--></xsl:variable>
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
                                select="name(./*) eq 'ixml'"
                                version="3"/>
               </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence xmlns:xspec="http://www.jenitennison.com/xslt/xspec"
                             xmlns:xs="http://www.w3.org/2001/XMLSchema"
                             xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                             select="name(./*) eq 'ixml'"
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
               <xsl:message terminate="yes">ERROR in xspec:expect ('When ixml template invoked with non-fissile = #none then result should be an ixml element'): Non-boolean @test must be accompanied by @as, @href, @select, or child node.</xsl:message>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:if test="not($Q{urn:x-xspec:compile:impl}successful)">
         <xsl:message>      FAILED</xsl:message>
      </xsl:if>
      <xsl:element name="test" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario2-expect2</xsl:attribute>
         <xsl:attribute name="successful"
                        namespace=""
                        select="$Q{urn:x-xspec:compile:impl}successful"/>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>then result should be an ixml element</xsl:text>
         </xsl:element>
         <xsl:element name="expect-test-wrap" namespace="">
            <xsl:element name="xspec:expect" namespace="http://www.jenitennison.com/xslt/xspec">
               <xsl:namespace name="ws">http://www.blackmesatech.com/2021/nss/ws</xsl:namespace>
               <xsl:namespace name="xs">http://www.w3.org/2001/XMLSchema</xsl:namespace>
               <xsl:attribute name="test" namespace="">name(./*) eq 'ixml'</xsl:attribute>
            </xsl:element>
         </xsl:element>
         <xsl:if test="not($Q{urn:x-xspec:compile:impl}boolean-test)">
            <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
               <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}test-result"/>
               <xsl:with-param name="report-name" select="'result'"/>
            </xsl:call-template>
         </xsl:if>
         <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
            <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}expect-d51e10"/>
            <xsl:with-param name="report-name" select="'expect'"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario2-expect3"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}test)">
      <xsl:context-item use="absent"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}context" required="yes"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}result" required="yes"/>
      <xsl:message>then expand ALL nonterminals and add linkage</xsl:message>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}expect-d51e11-doc"
                    as="document-node()"
                    select="doc('file:/Users/cmsmcq/2021/gingersnap/tests/xml/Program.r0sup.saprg.bigfsa.ixml.xml')"/>
      <xsl:variable xmlns:xspec="http://www.jenitennison.com/xslt/xspec"
                    xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                    name="Q{urn:x-xspec:compile:impl}expect-d51e11"
                    select="$Q{urn:x-xspec:compile:impl}expect-d51e11-doc ! ( ws:strip(ixml/rule,'*','') )"><!--expected result--></xsl:variable>
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
               <xsl:message terminate="yes">ERROR in xspec:expect ('When ixml template invoked with non-fissile = #none then expand ALL nonterminals and add linkage'): Boolean @test must not be accompanied by @as, @href, @select, or child node.</xsl:message>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="Q{urn:x-xspec:common:deep-equal}deep-equal($Q{urn:x-xspec:compile:impl}expect-d51e11, $Q{urn:x-xspec:compile:impl}test-result, '')"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:if test="not($Q{urn:x-xspec:compile:impl}successful)">
         <xsl:message>      FAILED</xsl:message>
      </xsl:if>
      <xsl:element name="test" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario2-expect3</xsl:attribute>
         <xsl:attribute name="successful"
                        namespace=""
                        select="$Q{urn:x-xspec:compile:impl}successful"/>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>then expand ALL nonterminals and add linkage</xsl:text>
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
            <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}expect-d51e11"/>
            <xsl:with-param name="report-name" select="'expect'"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario3"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}scenario)">
      <xsl:context-item use="absent"/>
      <xsl:message>When ixml template invoked with start symbol (etc.)</xsl:message>
      <xsl:element name="scenario" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario3</xsl:attribute>
         <xsl:attribute name="xspec" namespace="">file:/Users/cmsmcq/2021/gingersnap/tests/ixml-to-saprg.xspec</xsl:attribute>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>When ixml template invoked with start symbol (etc.)</xsl:text>
         </xsl:element>
         <xsl:element name="input-wrap" namespace="">
            <xsl:element name="xspec:context" namespace="http://www.jenitennison.com/xslt/xspec">
               <xsl:namespace name="ws">http://www.blackmesatech.com/2021/nss/ws</xsl:namespace>
               <xsl:namespace name="xs">http://www.w3.org/2001/XMLSchema</xsl:namespace>
               <xsl:attribute name="href" namespace="">file:/Users/cmsmcq/2021/gingersnap/tests/xml/Program.pcgl.ixml.xml</xsl:attribute>
               <xsl:attribute name="select" namespace="">ixml</xsl:attribute>
               <xsl:attribute name="mode" namespace="">make-rtn</xsl:attribute>
               <xsl:element name="xspec:param" namespace="http://www.jenitennison.com/xslt/xspec">
                  <xsl:namespace name="ws">http://www.blackmesatech.com/2021/nss/ws</xsl:namespace>
                  <xsl:namespace name="xs">http://www.w3.org/2001/XMLSchema</xsl:namespace>
                  <xsl:attribute name="name" namespace="">keep-non-fissiles</xsl:attribute>
                  <xsl:attribute name="tunnel" namespace="">yes</xsl:attribute>
                  <xsl:attribute name="select" namespace=""> '#no' </xsl:attribute>
               </xsl:element>
               <xsl:element name="xspec:param" namespace="http://www.jenitennison.com/xslt/xspec">
                  <xsl:namespace name="ws">http://www.blackmesatech.com/2021/nss/ws</xsl:namespace>
                  <xsl:namespace name="xs">http://www.w3.org/2001/XMLSchema</xsl:namespace>
                  <xsl:attribute name="name" namespace="">linkage</xsl:attribute>
                  <xsl:attribute name="tunnel" namespace="">yes</xsl:attribute>
                  <xsl:attribute name="select" namespace=""> '#none' </xsl:attribute>
               </xsl:element>
               <xsl:element name="xspec:param" namespace="http://www.jenitennison.com/xslt/xspec">
                  <xsl:namespace name="ws">http://www.blackmesatech.com/2021/nss/ws</xsl:namespace>
                  <xsl:namespace name="xs">http://www.w3.org/2001/XMLSchema</xsl:namespace>
                  <xsl:attribute name="name" namespace="">start</xsl:attribute>
                  <xsl:attribute name="tunnel" namespace="">yes</xsl:attribute>
                  <xsl:attribute name="select" namespace=""> 'block' </xsl:attribute>
               </xsl:element>
            </xsl:element>
         </xsl:element>
         <xsl:variable name="Q{urn:x-xspec:compile:impl}context-d90e0-doc"
                       as="document-node()"
                       select="doc('file:/Users/cmsmcq/2021/gingersnap/tests/xml/Program.pcgl.ixml.xml')"/>
         <xsl:variable xmlns:xspec="http://www.jenitennison.com/xslt/xspec"
                       xmlns:xs="http://www.w3.org/2001/XMLSchema"
                       xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                       name="Q{urn:x-xspec:compile:impl}context-d90e0"
                       select="$Q{urn:x-xspec:compile:impl}context-d90e0-doc ! ( ixml )"/>
         <xsl:variable name="Q{http://www.jenitennison.com/xslt/xspec}context"
                       select="$Q{urn:x-xspec:compile:impl}context-d90e0"/>
         <xsl:variable name="Q{http://www.jenitennison.com/xslt/xspec}result" as="item()*">
            <xsl:variable xmlns:xspec="http://www.jenitennison.com/xslt/xspec"
                          xmlns:xs="http://www.w3.org/2001/XMLSchema"
                          xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                          name="Q{}keep-non-fissiles"
                          select=" '#no' "/>
            <xsl:variable xmlns:xspec="http://www.jenitennison.com/xslt/xspec"
                          xmlns:xs="http://www.w3.org/2001/XMLSchema"
                          xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                          name="Q{}linkage"
                          select=" '#none' "/>
            <xsl:variable xmlns:xspec="http://www.jenitennison.com/xslt/xspec"
                          xmlns:xs="http://www.w3.org/2001/XMLSchema"
                          xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                          name="Q{}start"
                          select=" 'block' "/>
            <xsl:apply-templates select="$Q{urn:x-xspec:compile:impl}context-d90e0" mode="Q{}make-rtn">
               <xsl:with-param xmlns:xspec="http://www.jenitennison.com/xslt/xspec"
                               xmlns:xs="http://www.w3.org/2001/XMLSchema"
                               xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                               name="Q{}keep-non-fissiles"
                               select="$Q{}keep-non-fissiles"
                               tunnel="yes"/>
               <xsl:with-param xmlns:xspec="http://www.jenitennison.com/xslt/xspec"
                               xmlns:xs="http://www.w3.org/2001/XMLSchema"
                               xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                               name="Q{}linkage"
                               select="$Q{}linkage"
                               tunnel="yes"/>
               <xsl:with-param xmlns:xspec="http://www.jenitennison.com/xslt/xspec"
                               xmlns:xs="http://www.w3.org/2001/XMLSchema"
                               xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                               name="Q{}start"
                               select="$Q{}start"
                               tunnel="yes"/>
            </xsl:apply-templates>
         </xsl:variable>
         <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
            <xsl:with-param name="sequence"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
            <xsl:with-param name="report-name" select="'result'"/>
         </xsl:call-template>
         <!-- invoke each compiled x:expect -->
         <xsl:call-template name="Q{http://www.jenitennison.com/xslt/xspec}scenario3-expect1">
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}context"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}context"/>
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}result"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario3-expect1"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}test)">
      <xsl:context-item use="absent"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}context" required="yes"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}result" required="yes"/>
      <xsl:message>then produce an O0 grammar for THAT nonterminal with no linkage</xsl:message>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}expect-d51e17-doc"
                    as="document-node()"
                    select="doc('file:/Users/cmsmcq/2021/gingersnap/tests/xml/Program.O0.block.ixml.xml')"/>
      <xsl:variable xmlns:xspec="http://www.jenitennison.com/xslt/xspec"
                    xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                    name="Q{urn:x-xspec:compile:impl}expect-d51e17"
                    select="$Q{urn:x-xspec:compile:impl}expect-d51e17-doc ! ( ws:strip(ixml/rule,'*','') )"><!--expected result--></xsl:variable>
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
               <xsl:message terminate="yes">ERROR in xspec:expect ('When ixml template invoked with start symbol (etc.) then produce an O0 grammar for THAT nonterminal with no linkage'): Boolean @test must not be accompanied by @as, @href, @select, or child node.</xsl:message>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="Q{urn:x-xspec:common:deep-equal}deep-equal($Q{urn:x-xspec:compile:impl}expect-d51e17, $Q{urn:x-xspec:compile:impl}test-result, '')"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:if test="not($Q{urn:x-xspec:compile:impl}successful)">
         <xsl:message>      FAILED</xsl:message>
      </xsl:if>
      <xsl:element name="test" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario3-expect1</xsl:attribute>
         <xsl:attribute name="successful"
                        namespace=""
                        select="$Q{urn:x-xspec:compile:impl}successful"/>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>then produce an O0 grammar for THAT nonterminal with no linkage</xsl:text>
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
            <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}expect-d51e17"/>
            <xsl:with-param name="report-name" select="'expect'"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario4"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}scenario)">
      <xsl:context-item use="absent"/>
      <xsl:message>When ixml template invoked with start symbol (etc.)</xsl:message>
      <xsl:element name="scenario" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario4</xsl:attribute>
         <xsl:attribute name="xspec" namespace="">file:/Users/cmsmcq/2021/gingersnap/tests/ixml-to-saprg.xspec</xsl:attribute>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>When ixml template invoked with start symbol (etc.)</xsl:text>
         </xsl:element>
         <xsl:element name="input-wrap" namespace="">
            <xsl:element name="xspec:context" namespace="http://www.jenitennison.com/xslt/xspec">
               <xsl:namespace name="ws">http://www.blackmesatech.com/2021/nss/ws</xsl:namespace>
               <xsl:namespace name="xs">http://www.w3.org/2001/XMLSchema</xsl:namespace>
               <xsl:attribute name="href" namespace="">file:/Users/cmsmcq/2021/gingersnap/tests/xml/Program.pcgl.ixml.xml</xsl:attribute>
               <xsl:attribute name="select" namespace="">ixml</xsl:attribute>
               <xsl:attribute name="mode" namespace="">make-rtn</xsl:attribute>
               <xsl:element name="xspec:param" namespace="http://www.jenitennison.com/xslt/xspec">
                  <xsl:namespace name="ws">http://www.blackmesatech.com/2021/nss/ws</xsl:namespace>
                  <xsl:namespace name="xs">http://www.w3.org/2001/XMLSchema</xsl:namespace>
                  <xsl:attribute name="name" namespace="">keep-non-fissiles</xsl:attribute>
                  <xsl:attribute name="tunnel" namespace="">yes</xsl:attribute>
                  <xsl:attribute name="select" namespace=""> '#no' </xsl:attribute>
               </xsl:element>
               <xsl:element name="xspec:param" namespace="http://www.jenitennison.com/xslt/xspec">
                  <xsl:namespace name="ws">http://www.blackmesatech.com/2021/nss/ws</xsl:namespace>
                  <xsl:namespace name="xs">http://www.w3.org/2001/XMLSchema</xsl:namespace>
                  <xsl:attribute name="name" namespace="">linkage</xsl:attribute>
                  <xsl:attribute name="tunnel" namespace="">yes</xsl:attribute>
                  <xsl:attribute name="select" namespace=""> '#none' </xsl:attribute>
               </xsl:element>
               <xsl:element name="xspec:param" namespace="http://www.jenitennison.com/xslt/xspec">
                  <xsl:namespace name="ws">http://www.blackmesatech.com/2021/nss/ws</xsl:namespace>
                  <xsl:namespace name="xs">http://www.w3.org/2001/XMLSchema</xsl:namespace>
                  <xsl:attribute name="name" namespace="">start</xsl:attribute>
                  <xsl:attribute name="tunnel" namespace="">yes</xsl:attribute>
                  <xsl:attribute name="select" namespace=""> 'statement' </xsl:attribute>
               </xsl:element>
            </xsl:element>
         </xsl:element>
         <xsl:variable name="Q{urn:x-xspec:compile:impl}context-d102e0-doc"
                       as="document-node()"
                       select="doc('file:/Users/cmsmcq/2021/gingersnap/tests/xml/Program.pcgl.ixml.xml')"/>
         <xsl:variable xmlns:xspec="http://www.jenitennison.com/xslt/xspec"
                       xmlns:xs="http://www.w3.org/2001/XMLSchema"
                       xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                       name="Q{urn:x-xspec:compile:impl}context-d102e0"
                       select="$Q{urn:x-xspec:compile:impl}context-d102e0-doc ! ( ixml )"/>
         <xsl:variable name="Q{http://www.jenitennison.com/xslt/xspec}context"
                       select="$Q{urn:x-xspec:compile:impl}context-d102e0"/>
         <xsl:variable name="Q{http://www.jenitennison.com/xslt/xspec}result" as="item()*">
            <xsl:variable xmlns:xspec="http://www.jenitennison.com/xslt/xspec"
                          xmlns:xs="http://www.w3.org/2001/XMLSchema"
                          xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                          name="Q{}keep-non-fissiles"
                          select=" '#no' "/>
            <xsl:variable xmlns:xspec="http://www.jenitennison.com/xslt/xspec"
                          xmlns:xs="http://www.w3.org/2001/XMLSchema"
                          xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                          name="Q{}linkage"
                          select=" '#none' "/>
            <xsl:variable xmlns:xspec="http://www.jenitennison.com/xslt/xspec"
                          xmlns:xs="http://www.w3.org/2001/XMLSchema"
                          xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                          name="Q{}start"
                          select=" 'statement' "/>
            <xsl:apply-templates select="$Q{urn:x-xspec:compile:impl}context-d102e0" mode="Q{}make-rtn">
               <xsl:with-param xmlns:xspec="http://www.jenitennison.com/xslt/xspec"
                               xmlns:xs="http://www.w3.org/2001/XMLSchema"
                               xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                               name="Q{}keep-non-fissiles"
                               select="$Q{}keep-non-fissiles"
                               tunnel="yes"/>
               <xsl:with-param xmlns:xspec="http://www.jenitennison.com/xslt/xspec"
                               xmlns:xs="http://www.w3.org/2001/XMLSchema"
                               xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                               name="Q{}linkage"
                               select="$Q{}linkage"
                               tunnel="yes"/>
               <xsl:with-param xmlns:xspec="http://www.jenitennison.com/xslt/xspec"
                               xmlns:xs="http://www.w3.org/2001/XMLSchema"
                               xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                               name="Q{}start"
                               select="$Q{}start"
                               tunnel="yes"/>
            </xsl:apply-templates>
         </xsl:variable>
         <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
            <xsl:with-param name="sequence"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
            <xsl:with-param name="report-name" select="'result'"/>
         </xsl:call-template>
         <!-- invoke each compiled x:expect -->
         <xsl:call-template name="Q{http://www.jenitennison.com/xslt/xspec}scenario4-expect1">
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}context"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}context"/>
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}result"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario4-expect1"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}test)">
      <xsl:context-item use="absent"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}context" required="yes"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}result" required="yes"/>
      <xsl:message>then produce an O0 grammar for THAT nonterminals with no linkage</xsl:message>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}expect-d51e23-doc"
                    as="document-node()"
                    select="doc('file:/Users/cmsmcq/2021/gingersnap/tests/xml/Program.O0.statement.ixml.xml')"/>
      <xsl:variable xmlns:xspec="http://www.jenitennison.com/xslt/xspec"
                    xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                    name="Q{urn:x-xspec:compile:impl}expect-d51e23"
                    select="$Q{urn:x-xspec:compile:impl}expect-d51e23-doc ! ( ws:strip(ixml/rule,'*','') )"><!--expected result--></xsl:variable>
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
               <xsl:message terminate="yes">ERROR in xspec:expect ('When ixml template invoked with start symbol (etc.) then produce an O0 grammar for THAT nonterminals with no linkage'): Boolean @test must not be accompanied by @as, @href, @select, or child node.</xsl:message>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="Q{urn:x-xspec:common:deep-equal}deep-equal($Q{urn:x-xspec:compile:impl}expect-d51e23, $Q{urn:x-xspec:compile:impl}test-result, '')"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:if test="not($Q{urn:x-xspec:compile:impl}successful)">
         <xsl:message>      FAILED</xsl:message>
      </xsl:if>
      <xsl:element name="test" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario4-expect1</xsl:attribute>
         <xsl:attribute name="successful"
                        namespace=""
                        select="$Q{urn:x-xspec:compile:impl}successful"/>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>then produce an O0 grammar for THAT nonterminals with no linkage</xsl:text>
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
            <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}expect-d51e23"/>
            <xsl:with-param name="report-name" select="'expect'"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario5"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}scenario)">
      <xsl:context-item use="absent"/>
      <xsl:message>When ixml template invoked with non-fissile = '#none' and linkage='#none'</xsl:message>
      <xsl:element name="scenario" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario5</xsl:attribute>
         <xsl:attribute name="xspec" namespace="">file:/Users/cmsmcq/2021/gingersnap/tests/ixml-to-saprg.xspec</xsl:attribute>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>When ixml template invoked with     non-fissile = '#none' and linkage='#none'</xsl:text>
         </xsl:element>
         <xsl:element name="input-wrap" namespace="">
            <xsl:element name="xspec:context" namespace="http://www.jenitennison.com/xslt/xspec">
               <xsl:namespace name="ws">http://www.blackmesatech.com/2021/nss/ws</xsl:namespace>
               <xsl:namespace name="xs">http://www.w3.org/2001/XMLSchema</xsl:namespace>
               <xsl:attribute name="href" namespace="">file:/Users/cmsmcq/2021/gingersnap/tests/xml/a.pcgl.ixml.xml</xsl:attribute>
               <xsl:attribute name="select" namespace="">ixml</xsl:attribute>
               <xsl:attribute name="mode" namespace="">make-rtn</xsl:attribute>
               <xsl:element name="xspec:param" namespace="http://www.jenitennison.com/xslt/xspec">
                  <xsl:namespace name="ws">http://www.blackmesatech.com/2021/nss/ws</xsl:namespace>
                  <xsl:namespace name="xs">http://www.w3.org/2001/XMLSchema</xsl:namespace>
                  <xsl:attribute name="name" namespace="">non-fissile</xsl:attribute>
                  <xsl:attribute name="tunnel" namespace="">yes</xsl:attribute>
                  <xsl:attribute name="select" namespace=""> '#none' </xsl:attribute>
               </xsl:element>
               <xsl:element name="xspec:param" namespace="http://www.jenitennison.com/xslt/xspec">
                  <xsl:namespace name="ws">http://www.blackmesatech.com/2021/nss/ws</xsl:namespace>
                  <xsl:namespace name="xs">http://www.w3.org/2001/XMLSchema</xsl:namespace>
                  <xsl:attribute name="name" namespace="">linkage</xsl:attribute>
                  <xsl:attribute name="tunnel" namespace="">yes</xsl:attribute>
                  <xsl:attribute name="select" namespace=""> '#none' </xsl:attribute>
               </xsl:element>
            </xsl:element>
         </xsl:element>
         <xsl:variable name="Q{urn:x-xspec:compile:impl}context-d114e0-doc"
                       as="document-node()"
                       select="doc('file:/Users/cmsmcq/2021/gingersnap/tests/xml/a.pcgl.ixml.xml')"/>
         <xsl:variable xmlns:xspec="http://www.jenitennison.com/xslt/xspec"
                       xmlns:xs="http://www.w3.org/2001/XMLSchema"
                       xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                       name="Q{urn:x-xspec:compile:impl}context-d114e0"
                       select="$Q{urn:x-xspec:compile:impl}context-d114e0-doc ! ( ixml )"/>
         <xsl:variable name="Q{http://www.jenitennison.com/xslt/xspec}context"
                       select="$Q{urn:x-xspec:compile:impl}context-d114e0"/>
         <xsl:variable name="Q{http://www.jenitennison.com/xslt/xspec}result" as="item()*">
            <xsl:variable xmlns:xspec="http://www.jenitennison.com/xslt/xspec"
                          xmlns:xs="http://www.w3.org/2001/XMLSchema"
                          xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                          name="Q{}non-fissile"
                          select=" '#none' "/>
            <xsl:variable xmlns:xspec="http://www.jenitennison.com/xslt/xspec"
                          xmlns:xs="http://www.w3.org/2001/XMLSchema"
                          xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                          name="Q{}linkage"
                          select=" '#none' "/>
            <xsl:apply-templates select="$Q{urn:x-xspec:compile:impl}context-d114e0" mode="Q{}make-rtn">
               <xsl:with-param xmlns:xspec="http://www.jenitennison.com/xslt/xspec"
                               xmlns:xs="http://www.w3.org/2001/XMLSchema"
                               xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                               name="Q{}non-fissile"
                               select="$Q{}non-fissile"
                               tunnel="yes"/>
               <xsl:with-param xmlns:xspec="http://www.jenitennison.com/xslt/xspec"
                               xmlns:xs="http://www.w3.org/2001/XMLSchema"
                               xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                               name="Q{}linkage"
                               select="$Q{}linkage"
                               tunnel="yes"/>
            </xsl:apply-templates>
         </xsl:variable>
         <xsl:call-template name="Q{urn:x-xspec:common:report-sequence}report-sequence">
            <xsl:with-param name="sequence"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
            <xsl:with-param name="report-name" select="'result'"/>
         </xsl:call-template>
         <!-- invoke each compiled x:expect -->
         <xsl:call-template name="Q{http://www.jenitennison.com/xslt/xspec}scenario5-expect1">
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}context"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}context"/>
            <xsl:with-param name="Q{http://www.jenitennison.com/xslt/xspec}result"
                            select="$Q{http://www.jenitennison.com/xslt/xspec}result"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
   <xsl:template name="Q{http://www.jenitennison.com/xslt/xspec}scenario5-expect1"
                 as="element(Q{http://www.jenitennison.com/xslt/xspec}test)">
      <xsl:context-item use="absent"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}context" required="yes"/>
      <xsl:param name="Q{http://www.jenitennison.com/xslt/xspec}result" required="yes"/>
      <xsl:message>then expand ALL nonterminals and add no extcall linkage</xsl:message>
      <xsl:variable name="Q{urn:x-xspec:compile:impl}expect-d51e28-doc"
                    as="document-node()"
                    select="doc('file:/Users/cmsmcq/2021/gingersnap/tests/xml/a.O0.ixml.xml')"/>
      <xsl:variable xmlns:xspec="http://www.jenitennison.com/xslt/xspec"
                    xmlns:xs="http://www.w3.org/2001/XMLSchema"
                    xmlns:ws="http://www.blackmesatech.com/2021/nss/ws"
                    name="Q{urn:x-xspec:compile:impl}expect-d51e28"
                    select="$Q{urn:x-xspec:compile:impl}expect-d51e28-doc ! ( ws:strip(ixml/rule,'*','') )"><!--expected result--></xsl:variable>
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
               <xsl:message terminate="yes">ERROR in xspec:expect ('When ixml template invoked with non-fissile = '#none' and linkage='#none' then expand ALL nonterminals and add no extcall linkage'): Boolean @test must not be accompanied by @as, @href, @select, or child node.</xsl:message>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="Q{urn:x-xspec:common:deep-equal}deep-equal($Q{urn:x-xspec:compile:impl}expect-d51e28, $Q{urn:x-xspec:compile:impl}test-result, '')"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:if test="not($Q{urn:x-xspec:compile:impl}successful)">
         <xsl:message>      FAILED</xsl:message>
      </xsl:if>
      <xsl:element name="test" namespace="http://www.jenitennison.com/xslt/xspec">
         <xsl:attribute name="id" namespace="">scenario5-expect1</xsl:attribute>
         <xsl:attribute name="successful"
                        namespace=""
                        select="$Q{urn:x-xspec:compile:impl}successful"/>
         <xsl:element name="label" namespace="http://www.jenitennison.com/xslt/xspec">
            <xsl:text>then expand ALL nonterminals and add no extcall linkage</xsl:text>
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
            <xsl:with-param name="sequence" select="$Q{urn:x-xspec:compile:impl}expect-d51e28"/>
            <xsl:with-param name="report-name" select="'expect'"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
</xsl:stylesheet>
