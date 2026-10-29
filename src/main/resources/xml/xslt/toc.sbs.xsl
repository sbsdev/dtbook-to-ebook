<?xml version="1.0" encoding="UTF-8"?>
<!--
    The book title is not listed in the table of contents (Nordic Guidelines
    2025-1, "EPUB 3 Navigation Document").

    Input: a wrapper element holding the document, followed by all content
    documents. Output: the document, without the entry of the section that
    holds the book title if it is the navigation document.
-->
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:f="http://www.sbs.ch/pipeline/functions"
    xmlns:epub="http://www.idpf.org/2007/ops"
    xmlns="http://www.w3.org/1999/xhtml"
    xpath-default-namespace="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="#all">

  <xsl:output method="xml" encoding="UTF-8"/>

  <!-- the ids are unique across the content documents, which upstream splits from one document -->
  <xsl:function name="f:title-sections" as="attribute()*">
    <xsl:param name="node" as="node()"/>
    <xsl:sequence select="root($node)/*/html[position() > 1]/body/section[*[tokenize(@epub:type, '\s+') = 'title']]/@id"/>
  </xsl:function>

  <xsl:template match="/*">
    <xsl:apply-templates select="html[1]"/>
  </xsl:template>

  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="nav[tokenize(@epub:type, '\s+') = 'toc']//li[a/substring-after(@href, '#') = f:title-sections(.)]"/>

</xsl:stylesheet>
