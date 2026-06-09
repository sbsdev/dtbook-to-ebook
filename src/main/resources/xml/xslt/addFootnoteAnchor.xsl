<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0"
                xmlns="http://www.daisy.org/z3986/2005/dtbook/"
		xmlns:f="http://www.daisy.org/pipeline/modules/dtbook-to-ebook/addFootnoteAnchor.xsl"
		xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:dtb="http://www.daisy.org/z3986/2005/dtbook/"
                exclude-result-prefixes="dtb f xs">

  <xsl:import href="copy.xsl"/>

  <xsl:output method="xml" encoding="utf-8" indent="no"/>

  <xsl:function name="f:generate-pretty-id" as="xs:string">
    <xsl:param name="element" as="element()"/>
    <xsl:param name="all-ids"/>
    <xsl:variable name="id">
      <xsl:variable name="element-name" select="local-name($element)"/>
      <xsl:sequence select="concat($element-name,'_',count($element/(ancestor::*|preceding::*)[local-name()=$element-name])+1)"/>
    </xsl:variable>
    <xsl:sequence select="if ($all-ids=$id) then generate-id($element) else $id"/>
  </xsl:function>


  <xsl:template match="dtb:noteref">
    <xsl:variable name="all-ids" select=".//@id"/>
    <a>
      <xsl:attribute name="id" select="f:generate-pretty-id(.,$all-ids)"/>
    </a>
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
