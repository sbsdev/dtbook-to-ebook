<?xml version="1.0" encoding="utf-8"?>
<!--
    Classes required by the Nordic Guidelines 2025-1. The upstream conversion
    keeps the class of DTBook elements.

    - page breaks: page-front, page-normal or page-special ("Pagination"),
      from the page attribute that the upstream conversion drops
    - book title and author: title and docauthor ("Title Page")
-->
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:dtb="http://www.daisy.org/z3986/2005/dtbook/"
                exclude-result-prefixes="#all">

  <xsl:output method="xml" encoding="utf-8" indent="no"
              doctype-public="-//NISO//DTD dtbook 2005-3//EN"
              doctype-system="http://www.daisy.org/z3986/2005/dtbook-2005-3.dtd" />

  <xsl:template match="dtb:pagenum">
    <xsl:call-template name="add-class">
      <xsl:with-param name="class" select="concat('page-', (@page, 'normal')[1])"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="dtb:frontmatter/dtb:doctitle">
    <xsl:call-template name="add-class">
      <xsl:with-param name="class" select="'title'"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="dtb:frontmatter/dtb:docauthor">
    <xsl:call-template name="add-class">
      <xsl:with-param name="class" select="'docauthor'"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="add-class">
    <xsl:param name="class"/>
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:attribute name="class" select="normalize-space(string-join((@class, $class), ' '))"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
