<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:opf="http://www.idpf.org/2007/opf"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    exclude-result-prefixes="dc">

  <xsl:output method="xml" encoding="UTF-8" indent="yes"/>

  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- Add SBS accessibility metadata to the OPF metadata block -->
  <xsl:template match="opf:metadata">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>

      <!-- accessMode: textual is always present -->
      <opf:meta property="schema:accessMode" content="textual">textual</opf:meta>

      <!-- accessMode: visual only when images are present in the manifest -->
      <xsl:if test="//opf:manifest/opf:item[starts-with(@media-type,'image/')]">
        <opf:meta property="schema:accessMode" content="visual">visual</opf:meta>
      </xsl:if>

      <!-- accessModeSufficient -->
      <opf:meta property="schema:accessModeSufficient" content="textual">textual</opf:meta>

      <!-- accessibilityFeature: alternativeText -->
      <opf:meta property="schema:accessibilityFeature" content="alternativeText">alternativeText</opf:meta>

      <!-- accessibilityFeature: longDescription -->
      <opf:meta property="schema:accessibilityFeature" content="longDescription">longDescription</opf:meta>

    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
