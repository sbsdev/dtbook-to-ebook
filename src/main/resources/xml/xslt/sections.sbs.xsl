<?xml version="1.0" encoding="UTF-8"?>
<!--
    Semantics of the top-level sections as required by the Nordic Guidelines
    2025-1 (ADR-0006), "Structural Divisions and Semantics".

    - epub:type moves from body to the top-level sections, combined with a
      division taken from the section's class, or chapter in the bodymatter
    - role is the DPUB-ARIA role of that division, if there is one
    - aria-labelledby points to the section's heading; a placeholder heading
      from addEmptyHeaders.xsl becomes an aria-label instead
-->
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:f="http://www.sbs.ch/pipeline/functions"
    xmlns:epub="http://www.idpf.org/2007/ops"
    xmlns="http://www.w3.org/1999/xhtml"
    xpath-default-namespace="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="#all">

  <xsl:output method="xml" encoding="UTF-8"/>

  <xsl:variable name="partitions" select="('cover', 'frontmatter', 'bodymatter', 'backmatter')"/>

  <!-- divisions of the EPUB Structural Semantics Vocabulary -->
  <xsl:variable name="divisions"
                select="('abstract', 'acknowledgments', 'afterword', 'appendix', 'bibliography',
                         'chapter', 'colophon', 'conclusion', 'contributors', 'copyright-page',
                         'credits', 'dedication', 'epigraph', 'epilogue', 'errata', 'foreword',
                         'glossary', 'halftitlepage', 'imprimatur', 'imprint', 'index',
                         'introduction', 'loa', 'loi', 'lot', 'lov', 'notice', 'other-credits',
                         'part', 'preamble', 'preface', 'prologue', 'seriespage', 'titlepage',
                         'toc', 'volume')"/>

  <!-- the divisions that have a DPUB-ARIA role doc-{division} -->
  <xsl:variable name="roles"
                select="('abstract', 'acknowledgments', 'afterword', 'appendix', 'bibliography',
                         'chapter', 'colophon', 'conclusion', 'credits', 'dedication', 'epigraph',
                         'epilogue', 'errata', 'foreword', 'glossary', 'index', 'introduction',
                         'part', 'preface', 'prologue', 'toc')"/>

  <xsl:function name="f:tokens" as="xs:string*">
    <xsl:param name="attr" as="attribute()?"/>
    <xsl:sequence select="tokenize($attr, '\s+')[. != '']"/>
  </xsl:function>

  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="body/@epub:type"/>

  <xsl:template match="body/section">
    <xsl:variable name="partition" select="(f:tokens(../@epub:type)[. = $partitions], 'bodymatter')[1]"/>
    <xsl:variable name="types" select="(f:tokens(@epub:type), f:tokens(@class))"/>
    <xsl:variable name="division"
                  select="($types[. = $divisions], 'chapter'[$partition = 'bodymatter'])[1]"/>
    <xsl:variable name="heading" select="(*[matches(local-name(), '^h[1-6]$')], hgroup/*[matches(local-name(), '^h[1-6]$')])[1]"/>
    <xsl:copy>
      <xsl:apply-templates select="@* except (@role, @epub:type, @aria-labelledby)"/>
      <xsl:if test="$division = $roles">
        <xsl:attribute name="role" select="concat('doc-', $division)"/>
      </xsl:if>
      <xsl:attribute name="epub:type"
                     select="distinct-values(($partition, $division, f:tokens(@epub:type)[not(. = $partitions)]))"/>
      <xsl:choose>
        <xsl:when test="f:tokens($heading/@class) = 'aria-label'">
          <xsl:attribute name="aria-label" select="normalize-space($heading)"/>
        </xsl:when>
        <xsl:when test="$heading">
          <xsl:attribute name="aria-labelledby" select="($heading/@id, generate-id($heading))[1]"/>
        </xsl:when>
      </xsl:choose>
      <xsl:apply-templates select="node()">
        <xsl:with-param name="heading" select="$heading" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*[matches(local-name(), '^h[1-6]$')][f:tokens(@class) = 'aria-label']" priority="1"/>

  <xsl:template match="*[matches(local-name(), '^h[1-6]$')][not(@id)]">
    <xsl:param name="heading" tunnel="yes" as="element()?"/>
    <xsl:copy>
      <xsl:if test=". is $heading">
        <xsl:attribute name="id" select="generate-id()"/>
      </xsl:if>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
