<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	version="1.0" >
	<xsl:output method="xml" indent="yes" encoding="utf-8"
		omit-xml-declaration="no" cdata-section-elements="id description name notes execute params"/>
	<xsl:variable name="CDATABegin" select="'&lt;![CDATA['" />
	<xsl:variable name="CDATAEnd" select="']]&gt;'" />

	<xsl:template match="/">
	<xsl:element name="test_session">
	<xsl:element name="testplan_id"/>
	<xsl:copy-of select="top/build"/>
	<xsl:for-each select="top/testsuite/testsuite/testcase">
		<xsl:variable name="tcaseID"> 
			<xsl:value-of select="@name"/>
		</xsl:variable> 
		<xsl:element name="testcase">
			<xsl:element name="id"><xsl:value-of select="$tcaseID"/>
			</xsl:element>
			<xsl:for-each select="custom_fields/custom_field">
			<xsl:variable name="elementName">
				<xsl:value-of select="name"/>
			</xsl:variable>
			<xsl:variable name="elementValue">
				<xsl:value-of select="value"/>
			</xsl:variable>
			<xsl:element name="{$elementName}">
			<xsl:value-of select="$CDATABegin" disable-output-escaping="yes" />
			<xsl:value-of select="$elementValue" disable-output-escaping="yes" />
			<xsl:value-of select="$CDATAEnd" disable-output-escaping="yes" />
			</xsl:element>
			</xsl:for-each>
			<xsl:variable name="desc">
				<xsl:value-of select="summary"/>
			</xsl:variable>
			<xsl:element name="description"><xsl:value-of select="$desc"/></xsl:element>
		</xsl:element>
	</xsl:for-each>
	<xsl:element name="command">
	<xsl:element name="execute">var
	</xsl:element>
	<xsl:element name="params">get shared var kernel
	</xsl:element>
	</xsl:element>
	</xsl:element>
	</xsl:template>
</xsl:stylesheet>