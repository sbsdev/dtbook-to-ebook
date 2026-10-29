<?xml version="1.0" encoding="UTF-8"?>
<!--
    Page breaks as required by the Nordic Guidelines 2025-1 (ADR-0006),
    "Pagination". The class comes from addClasses.xsl.

    - aria-label is the page number; upstream pads it as " 5. "
    - a page break between blocks is a div
    - the entries of the page list are the page numbers as well
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

  <xsl:function name="f:page-number" as="xs:string">
    <xsl:param name="label" as="xs:string"/>
    <xsl:sequence select="replace(normalize-space($label), '\.$', '')"/>
  </xsl:function>

  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*[@role = 'doc-pagebreak']/@aria-label">
    <xsl:attribute name="aria-label" select="f:page-number(.)"/>
  </xsl:template>

  <xsl:template match="span[@role = 'doc-pagebreak'][parent::section | parent::article | parent::aside
                                                      | parent::body | parent::blockquote | parent::div]">
    <div>
      <xsl:apply-templates select="@*|node()"/>
    </div>
  </xsl:template>

  <xsl:template match="nav[tokenize(@epub:type, '\s+') = 'page-list']//a/text()">
    <xsl:value-of select="f:page-number(.)"/>
  </xsl:template>

</xsl:stylesheet>
