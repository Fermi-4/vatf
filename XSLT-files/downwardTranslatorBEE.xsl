<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	version="1.0" >
	<xsl:output method="xml" indent="yes" encoding="utf-8"
		omit-xml-declaration="no" cdata-section-elements="id description name notes execute params"/>
	<xsl:variable name="CDATABegin" select="'&lt;![CDATA['" />
	<xsl:variable name="CDATAEnd" select="']]&gt;'" />

	<xsl:template match="/">
	<xsl:element name="build_request">
		<xsl:for-each select="top/build">
			<xsl:element name="type">
				<xsl:attribute name="name"><xsl:value-of select="./name"/></xsl:attribute>
				<xsl:element name="version"><xsl:attribute name="name"><xsl:value-of select="./notes"/></xsl:attribute></xsl:element>
			</xsl:element>
		</xsl:for-each>
		<xsl:element name="command">
			<xsl:element name="execute">aragobee</xsl:element>
			<xsl:element name="params">build {staf/aragobee/infiles}</xsl:element>
		</xsl:element>
	</xsl:element>
	</xsl:template>
</xsl:stylesheet>
