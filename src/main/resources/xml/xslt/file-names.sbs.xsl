<?xml version="1.0" encoding="UTF-8"?>
<!--
    File names as required by the Nordic Guidelines 2025-1 (ADR-0006),
    "File Naming Convention" and "EPUB 3 Navigation Document".

    Input: a wrapper element holding the package document and all content
    documents, each with an xml:base. Output: a d:fileset mapping the old
    names (@original-href) to the new ones (@href), for px:epub-rename-files.

    - content documents: [UID]-[XXX]-[role].xhtml, with XXX the position in
      the spine and role that of the top-level section, or the most specific
      epub:type
    - navigation document: nav.xhtml
-->
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:d="http://www.daisy.org/ns/pipeline/data"
    xmlns:opf="http://www.idpf.org/2007/opf"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:epub="http://www.idpf.org/2007/ops"
    xmlns:h="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="#all">

  <xsl:output method="xml" encoding="UTF-8"/>

  <xsl:template match="/*">
    <xsl:variable name="opf" select="opf:package"/>
    <xsl:variable name="uid" select="normalize-space($opf/opf:metadata/dc:identifier[@id = $opf/@unique-identifier])"/>
    <xsl:variable name="opf-uri" select="base-uri($opf)"/>
    <d:fileset>
      <xsl:for-each select="$opf/opf:spine/opf:itemref">
        <xsl:variable name="href" select="resolve-uri($opf/opf:manifest/opf:item[@id = current()/@idref]/@href, $opf-uri)"/>
        <xsl:variable name="section" select="root(.)/*/h:html[base-uri(.) = $href]/h:body/h:section[1]"/>
        <xsl:variable name="types" select="tokenize($section/@epub:type, '\s+')[. != '']"/>
        <xsl:variable name="role" select="(substring-after($section/@role, 'doc-')[. != ''], $types[last()], 'section')[1]"/>
        <d:file original-href="{$href}"
                href="{resolve-uri(concat($uid, '-', format-number(position(), '000'), '-', $role, '.xhtml'), $href)}"/>
      </xsl:for-each>
      <xsl:for-each select="$opf/opf:manifest/opf:item[tokenize(@properties, '\s+') = 'nav']">
        <xsl:variable name="href" select="resolve-uri(@href, $opf-uri)"/>
        <d:file original-href="{$href}" href="{resolve-uri('nav.xhtml', $href)}"/>
      </xsl:for-each>
    </d:fileset>
  </xsl:template>

</xsl:stylesheet>
