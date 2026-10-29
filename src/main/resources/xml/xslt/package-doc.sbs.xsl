<?xml version="1.0" encoding="UTF-8"?>
<!--
    Package document metadata as required by the Nordic Guidelines 2025-1
    (ADR-0006), "Package Document" and "Accessibility Metadata", and the SBS
    accessibility metadata.

    Input: a wrapper element holding the package document and the content
    documents of the EPUB, so that the features can be derived from the
    images. Output: the package document.
-->
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:opf="http://www.idpf.org/2007/opf"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns="http://www.idpf.org/2007/opf"
    exclude-result-prefixes="html opf">

  <xsl:output method="xml" encoding="UTF-8" indent="yes"/>

  <!-- the book's identifier from the DTBook -->
  <xsl:param name="identifier" select="''"/>

  <!-- SBS is both the ordering agency and the supplier -->
  <xsl:variable name="agency" select="'SBS'"/>
  <xsl:variable name="guidelines" select="'2025-1'"/>

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

  <xsl:template match="opf:package">
    <xsl:copy>
      <xsl:apply-templates select="@* except (@prefix, @unique-identifier)"/>
      <xsl:attribute name="prefix"
                     select="normalize-space(string-join((@prefix, 'nordic: http://www.mtm.se/epub/'), ' '))"/>
      <xsl:attribute name="unique-identifier" select="'pub-identifier'"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <!-- upstream generates a random identifier for the intermediate ZedAI; use the book's -->
  <xsl:template match="dc:identifier[@id = ancestor::opf:package/@unique-identifier]">
    <xsl:copy>
      <xsl:apply-templates select="@* except @id"/>
      <xsl:attribute name="id" select="'pub-identifier'"/>
      <xsl:value-of select="if ($identifier) then $identifier else ."/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="dc:title[1]/@id">
    <xsl:attribute name="id" select="'title'"/>
  </xsl:template>

  <xsl:template match="opf:meta/@refines[. = concat('#', ancestor::opf:metadata/dc:title[1]/@id)]">
    <xsl:attribute name="refines" select="'#title'"/>
  </xsl:template>

  <!-- leftovers of the intermediate ZedAI: empty DCMES elements are invalid,
       dc:format holds the DTBook format, and the MODS record is dropped from the EPUB -->
  <xsl:template match="dc:*[not(normalize-space())]|dc:format|opf:link[@rel='record'][ends-with(@href,'zedai-mods.xml')]"/>

  <!-- upstream still uses the incubation name a11y:pageBreakSource; EPUB 3.4 defines
       pageBreakSource in the default vocabulary (daisy/pipeline-modules#197). The
       guidelines identify an ISBN as a URN. -->
  <xsl:template match="opf:meta[@property = ('a11y:pageBreakSource', 'pageBreakSource')]">
    <xsl:variable name="isbn" select="replace(normalize-space(.), '[\s-]', '')"/>
    <meta property="pageBreakSource">
      <xsl:apply-templates select="@* except @property"/>
      <xsl:value-of select="if (matches($isbn, '^(97[89])?\d{9}[\dXx]$')) then concat('urn:isbn:', upper-case($isbn)) else ."/>
    </meta>
  </xsl:template>

  <!-- replaced by the SBS values below -->
  <xsl:template match="opf:meta[@property=('schema:accessMode','schema:accessModeSufficient','schema:accessibilityHazard')]"/>

  <xsl:template match="opf:metadata">
    <xsl:param name="has-alt-text" tunnel="yes" select="false()"/>
    <xsl:param name="has-long-description" tunnel="yes" select="false()"/>
    <xsl:variable name="features" select="opf:meta[@property='schema:accessibilityFeature']/normalize-space()"/>
    <xsl:variable name="new-features"
                  select="('displayTransformability', 'structuralNavigation', 'readingOrder',
                           'pageBreakMarkers'[$features = 'pageNavigation'],
                           'alternativeText'[$has-alt-text],
                           'longDescription'[$has-long-description])[not(. = $features)]"/>
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>

      <meta property="nordic:guidelines"><xsl:value-of select="$guidelines"/></meta>
      <meta property="nordic:supplier"><xsl:value-of select="$agency"/></meta>
      <meta property="schema:accessMode">textual</meta>
      <xsl:if test="//opf:manifest/opf:item[starts-with(@media-type,'image/')]">
        <meta property="schema:accessMode">visual</meta>
      </xsl:if>
      <meta property="schema:accessModeSufficient">textual</meta>
      <meta property="schema:accessibilityHazard">none</meta>
      <xsl:for-each select="$new-features">
        <meta property="schema:accessibilityFeature"><xsl:value-of select="."/></meta>
      </xsl:for-each>
      <link rel="dcterms:conformsTo" href="https://format.mtm.se/nordic_epub/{$guidelines}"/>
      <!-- EPUB Accessibility 1.1, "Conformance reporting" -->
      <meta property="dcterms:conformsTo">EPUB Accessibility 1.1 - WCAG 2.1 Level AA</meta>
      <meta property="a11y:certifiedBy"><xsl:value-of select="$agency"/></meta>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
