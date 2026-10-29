<?xml version="1.0" encoding="utf-8"?>
<!--
    Untitled sections as required by the Nordic Guidelines 2025-1 (ADR-0006),
    "Untitled Sections".

    Every level1 without heading gets a placeholder heading with class
    "aria-label", so that the upstream conversion lists the section in the
    table of contents. sections.sbs.xsl turns it into an aria-label on the
    section. The label is "Titelseite" for the title page, otherwise the first
    three words of the section followed by " …". Untitled subsections get no
    heading.
-->
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:dtb="http://www.daisy.org/z3986/2005/dtbook/"
                xmlns:pf="http://www.daisy.org/ns/pipeline/functions"
                exclude-result-prefixes="#all">

  <xsl:import href="http://www.daisy.org/pipeline/modules/common-utils/i18n.xsl"/>

  <xsl:output method="xml" encoding="utf-8" indent="no"
              doctype-public="-//NISO//DTD dtbook 2005-3//EN"
              doctype-system="http://www.daisy.org/z3986/2005/dtbook-2005-3.dtd" />

  <xsl:variable name="translations" select="document('../i18n/translations.xml')/*"/>

  <!-- ponytail: only the title page gets a default label; add the other standard
       sections of the guidelines (dedication, colophon, ...) when SBS marks them -->
  <xsl:template match="dtb:level1[not(dtb:h1)]">
    <xsl:variable name="language" select="('de',ancestor-or-self::*[@xml:lang|@lang]/(@xml:lang|@lang)[1])[last()]"/>
    <xsl:variable name="words"
                  select="tokenize(normalize-space(string-join(.//text()[not(ancestor::dtb:pagenum)], ' ')), ' ')[. != '']"/>
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <h1 xmlns="http://www.daisy.org/z3986/2005/dtbook/" class="aria-label">
        <xsl:value-of select="if (tokenize(@class, '\s+') = 'titlepage')
                              then pf:i18n-translate('titlepage', $language, $translations)
                              else if (exists($words))
                              then concat(string-join($words[position() le 3], ' '), ' …')
                              else pf:i18n-translate('without-heading', $language, $translations)"/>
      </h1>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <!-- Convert the fake sections on the title page to divs -->
  <xsl:template match="dtb:frontmatter//dtb:level1[@class='titlepage']/dtb:level2">
    <xsl:element name="div" namespace="http://www.daisy.org/z3986/2005/dtbook/">
      <xsl:apply-templates select="@*|node()"/>
    </xsl:element>
  </xsl:template>

  <!-- Copy all other elements and attributes -->
  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
