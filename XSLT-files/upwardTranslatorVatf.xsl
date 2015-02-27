<?xml version="1.0"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:op="http://op"
	version="1.0"
  exclude-result-prefixes="op">
	<xsl:output method="xml" indent="yes" encoding="utf-8"
		omit-xml-declaration="no"/>

		<xsl:function name="op:getDuration" as="xs:string">
			<xsl:param name="start" as="xs:string"/>
			<xsl:param name="end" as="xs:string"/>
			<xsl:choose>
			<xsl:when test="$start != '' and $end != ''">
			  <xsl:variable name="sArr" select="tokenize($start,'\s+')"/>
			  <xsl:variable name="eArr" select="tokenize($end,'\s+')"/> 
		    <xsl:variable name="sDateTime" select="dateTime(xs:date($sArr[1]),xs:time($sArr[2]))"/>
		    <xsl:variable name="eDateTime" select="dateTime(xs:date($eArr[1]),xs:time($eArr[2]))"/>
		    <xsl:value-of select="($eDateTime - $sDateTime) div xs:dayTimeDuration('PT1S')"/>
		  </xsl:when>
		  <xsl:otherwise>0</xsl:otherwise>
		 </xsl:choose>
		</xsl:function>

		<xsl:variable name="CDATABegin" select="'&lt;![CDATA['" />
		<xsl:variable name="CDATAEnd" select="']]&gt;'" />
	<xsl:template match="/" >
	<results>
	<xsl:element name="testplan">
		<xsl:attribute name="id"></xsl:attribute>
	<xsl:for-each select="hash/test-session/test-session/testcase/testcase">
		<xsl:variable name="tcaseID"> 
			<xsl:value-of select="id"/>
		</xsl:variable> 
		<xsl:element name="testcase">
			<xsl:attribute name="id"><xsl:value-of select="$tcaseID"/></xsl:attribute>
			<xsl:element name="execution-time">
				<xsl:variable name="sTime"><xsl:value-of select="test-iteration/test-iteration/start-time"/></xsl:variable>
			  <xsl:variable name="eTime"><xsl:value-of select="test-iteration/test-iteration/end-time"/></xsl:variable>
				<xsl:value-of select="op:getDuration($sTime, $eTime)"/>
			</xsl:element>
			<xsl:variable name="testpass">
					<xsl:value-of select="test-iteration/test-iteration/passed"/>
			</xsl:variable>
      <xsl:variable name="testns">
          <xsl:value-of select="test-iteration/test-iteration/ns"/>
      </xsl:variable>
			<xsl:element name="result">
				<xsl:choose>
				<xsl:when test="$testpass = 'true'">p</xsl:when>
				<xsl:when test="$testns = 'true'">x</xsl:when>
				<xsl:otherwise>f</xsl:otherwise>
				</xsl:choose>
			</xsl:element>
			<xsl:element name="notes">
				<xsl:variable name="testNotes">
                  <xsl:value-of select="test-iteration/test-iteration/comments"/>
                </xsl:variable>
				<xsl:value-of select="$CDATABegin" disable-output-escaping="yes" />
                <xsl:choose>
                  <xsl:when test="contains($testNotes,'href')">
				    <xsl:value-of select="$testNotes" disable-output-escaping="yes"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="$testNotes"/>
                  </xsl:otherwise>
                </xsl:choose>
				<xsl:text disable-output-escaping="yes">
					<![CDATA[<p><a href="]]></xsl:text><xsl:value-of select="logpath"/>
					<xsl:text disable-output-escaping="yes"><![CDATA[" target="_blank">LOG PATH</a></p>]]>
				</xsl:text><xsl:value-of select="$CDATAEnd" disable-output-escaping="yes" />
			</xsl:element>
			<xsl:copy-of select="test-iteration/test-iteration/performance"/>
		</xsl:element>
	</xsl:for-each>
	</xsl:element>
	</results>
	</xsl:template>
</xsl:stylesheet>
