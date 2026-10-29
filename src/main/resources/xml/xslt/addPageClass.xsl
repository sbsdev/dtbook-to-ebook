<?xml version="1.0" encoding="utf-8"?>
<!--
    Page breaks need a class page-front, page-normal or page-special (Nordic
    Guidelines 2025-1, "Pagination"). The upstream conversion drops the page
    attribute of pagenum but keeps its class.
-->
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:dtb="http://www.daisy.org/z3986/2005/dtbook/"
                exclude-result-prefixes="#all">

  <xsl:output method="xml" encoding="utf-8" indent="no"
              doctype-public="-//NISO//DTD dtbook 2005-3//EN"
              doctype-system="http://www.daisy.org/z3986/2005/dtbook-2005-3.dtd" />

  <xsl:template match="dtb:pagenum">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:attribute name="class" select="normalize-space(string-join((@class, concat('page-', (@page, 'normal')[1])), ' '))"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
