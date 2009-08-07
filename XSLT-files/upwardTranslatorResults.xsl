<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	version="1.0" >
	<xsl:output method="xml" indent="yes" encoding="utf-8"
		omit-xml-declaration="no"/>
		<xsl:variable name="CDATABegin" select="'&lt;![CDATA['" />
		<xsl:variable name="CDATAEnd" select="']]&gt;'" />
	<xsl:template match="/" >
	<results>
	<xsl:element name="testplan">
		<xsl:attribute name="id">1</xsl:attribute>
	<xsl:for-each select="hash/test-session/test-session/testcase/testcase">
		<xsl:variable name="tcaseID"> 
			<xsl:value-of select="id"/>
		</xsl:variable> 
		<xsl:element name="testcase">
			<xsl:attribute name="external_id"><xsl:value-of select="$tcaseID"/></xsl:attribute>
			<xsl:element name="timestamp"><xsl:value-of select="test-iteration/test-iteration/end-time"/>
			</xsl:element>
			<xsl:variable name="testpass">
					<xsl:value-of select="test-iteration/test-iteration/passed"/>
			</xsl:variable>
			<xsl:element name="result">
				<xsl:if test="$testpass">p</xsl:if>
			</xsl:element>
			<xsl:element name="notes">
			<xsl:value-of select="$CDATABegin" disable-output-escaping="yes" />
			<xsl:text disable-output-escaping="yes">
			<![CDATA[<p>this case passed and log is at 
			<a href="file:///]]></xsl:text><xsl:value-of select="../../logpath"/>
			<xsl:text disable-output-escaping="yes"><![CDATA["</a></p>]]>
			</xsl:text><xsl:value-of select="$CDATAEnd" disable-output-escaping="yes" />
		</xsl:element>
		</xsl:element>
	</xsl:for-each>
	</xsl:element>
	</results>
	</xsl:template>
</xsl:stylesheet>