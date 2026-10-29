<?xml version="1.0" encoding="UTF-8"?>
<!--
    SBS accessibility metadata for the package document.

    Input: a wrapper element holding the package document and the content
    documents of the EPUB, so that the features can be derived from the
    images. Output: the package document.
-->
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:opf="http://www.idpf.org/2007/opf"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    exclude-result-prefixes="html">

  <xsl:output method="xml" encoding="UTF-8" indent="yes"/>

  <!-- the book's identifier from the DTBook -->
  <xsl:param name="identifier" select="''"/>

  <xsl:template match="/*">
    <xsl:apply-templates select="opf:package">
      <xsl:with-param name="has-alt-text" tunnel="yes"
                      select="exists(//html:img[normalize-space(@alt)])"/>
      <!-- image descriptions (prodnotes) are linked to their image with aria-describedby -->
      <xsl:with-param name="has-long-description" tunnel="yes"
                      select="exists(//html:img[@aria-describedby])"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- upstream generates a random identifier for the intermediate ZedAI; use the book's -->
  <xsl:template match="dc:identifier[@id = ancestor::opf:package/@unique-identifier]">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:value-of select="if ($identifier) then $identifier else ."/>
    </xsl:copy>
  </xsl:template>

  <!-- leftovers of the intermediate ZedAI: empty DCMES elements are invalid,
       dc:format holds the DTBook format, and the MODS record is dropped from the EPUB -->
  <xsl:template match="dc:*[not(normalize-space())]|dc:format|opf:link[@rel='record'][ends-with(@href,'zedai-mods.xml')]"/>

  <!-- upstream still uses the incubation name a11y:pageBreakSource; EPUB 3.4 defines
       pageBreakSource in the default vocabulary (daisy/pipeline-modules#197) -->
  <xsl:template match="opf:meta/@property[. = 'a11y:pageBreakSource']">
    <xsl:attribute name="property" select="'pageBreakSource'"/>
  </xsl:template>

  <!-- replaced by the SBS values below -->
  <xsl:template match="opf:meta[@property=('schema:accessMode','schema:accessModeSufficient','schema:accessibilityHazard')]"/>

  <xsl:template match="opf:metadata">
    <xsl:param name="has-alt-text" tunnel="yes" select="false()"/>
    <xsl:param name="has-long-description" tunnel="yes" select="false()"/>
    <xsl:variable name="features" select="opf:meta[@property='schema:accessibilityFeature']/normalize-space()"/>
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>

      <opf:meta property="schema:accessMode">textual</opf:meta>
      <xsl:if test="//opf:manifest/opf:item[starts-with(@media-type,'image/')]">
        <opf:meta property="schema:accessMode">visual</opf:meta>
      </xsl:if>
      <opf:meta property="schema:accessModeSufficient">textual</opf:meta>
      <opf:meta property="schema:accessibilityHazard">none</opf:meta>
      <xsl:if test="$has-alt-text and not($features = 'alternativeText')">
        <opf:meta property="schema:accessibilityFeature">alternativeText</opf:meta>
      </xsl:if>
      <xsl:if test="$has-long-description and not($features = 'longDescription')">
        <opf:meta property="schema:accessibilityFeature">longDescription</opf:meta>
      </xsl:if>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
