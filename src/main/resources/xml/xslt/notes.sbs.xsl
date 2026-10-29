<?xml version="1.0" encoding="UTF-8"?>
<!--
    Notes as required by the Nordic Guidelines 2025-1 (ADR-0006).

    Input: a wrapper element holding the content document, followed by all
    content documents of the EPUB, each with an xml:base, since a note
    reference can be in another file than its note. Output: the content
    document.

    - note references get an id
    - sequentially numbered notes are moved to an endnotes section at the
      end of their top-level section, as an ordered list
    - other notes stay in place as footnotes
    - every note gets a backlink to its note reference
-->
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:f="http://www.sbs.ch/pipeline/functions"
    xmlns:pf="http://www.daisy.org/ns/pipeline/functions"
    xmlns:epub="http://www.idpf.org/2007/ops"
    xmlns="http://www.w3.org/1999/xhtml"
    xpath-default-namespace="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="#all">

  <xsl:import href="http://www.daisy.org/pipeline/modules/common-utils/i18n.xsl"/>

  <xsl:output method="xml" encoding="UTF-8"/>

  <xsl:variable name="translations" select="document('../i18n/translations.xml')/*"/>
  <!-- the content document being processed -->
  <xsl:function name="f:current" as="element()">
    <xsl:param name="node" as="node()"/>
    <xsl:sequence select="root($node)/*/html[1]"/>
  </xsl:function>

  <xsl:function name="f:language" as="xs:string">
    <xsl:param name="node" as="node()"/>
    <xsl:sequence select="(f:current($node)/@xml:lang, f:current($node)/@lang, 'de')[1]"/>
  </xsl:function>

  <xsl:key name="noteref" match="a[tokenize(@epub:type, '\s+') = 'noteref']"
           use="substring-after(@href, '#')"/>

  <xsl:function name="f:file" as="xs:string">
    <xsl:param name="html" as="element()"/>
    <xsl:sequence select="tokenize(base-uri($html), '/')[last()]"/>
  </xsl:function>

  <xsl:function name="f:noteref-id" as="xs:string">
    <xsl:param name="noteref" as="element()"/>
    <xsl:sequence select="($noteref/@id, concat('ref-', substring-after($noteref/@href, '#')))[1]"/>
  </xsl:function>

  <!-- ponytail: a note with several references only links back to the first one; the
       guidelines want the note repeated for each reference -->
  <xsl:function name="f:noteref" as="element()?">
    <xsl:param name="note" as="element()"/>
    <!-- the content documents after the first one -->
    <xsl:sequence select="key('noteref', $note/@id, root($note))[not(ancestor::html is f:current($note))][1]"/>
  </xsl:function>

  <!-- the notes of a top-level section -->
  <xsl:function name="f:notes" as="element()*">
    <xsl:param name="section" as="element()"/>
    <xsl:sequence select="$section//aside[@id][f:noteref(.)]"/>
  </xsl:function>

  <!-- sequentially numbered notes are handled as endnotes -->
  <xsl:function name="f:sequential" as="xs:boolean">
    <xsl:param name="notes" as="element()*"/>
    <xsl:variable name="numbers" select="for $n in $notes return normalize-space(f:noteref($n))"/>
    <xsl:sequence select="exists($notes)
                          and (every $n in $numbers satisfies $n castable as xs:integer)
                          and (every $i in 2 to count($numbers)
                               satisfies xs:integer($numbers[$i]) = xs:integer($numbers[$i - 1]) + 1)"/>
  </xsl:function>

  <xsl:template match="/*">
    <xsl:apply-templates select="html[1]"/>
  </xsl:template>

  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="html/@xml:base"/>

  <xsl:template match="a[tokenize(@epub:type, '\s+') = 'noteref'][not(@id)]">
    <xsl:copy>
      <xsl:attribute name="id" select="f:noteref-id(.)"/>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="body/section">
    <xsl:variable name="notes" select="f:notes(.)"/>
    <xsl:choose>
      <xsl:when test="f:sequential($notes)">
        <xsl:variable name="rank" select="(*[matches(local-name(), '^h[1-6]$')]/xs:integer(substring(local-name(), 2)), 1)[1]"/>
        <xsl:variable name="first" select="xs:integer(normalize-space(f:noteref($notes[1])))"/>
        <xsl:copy>
          <xsl:apply-templates select="@*|node()" mode="endnotes"/>
          <section role="doc-endnotes" epub:type="endnotes">
            <xsl:element name="h{min(($rank + 1, 6))}">
              <xsl:value-of select="pf:i18n-translate('endnotes', f:language(.), $translations)"/>
            </xsl:element>
            <ol>
              <xsl:if test="$first != 1">
                <xsl:attribute name="start" select="$first"/>
              </xsl:if>
              <xsl:for-each select="$notes">
                <li id="{@id}">
                  <xsl:apply-templates select="node()"/>
                  <xsl:call-template name="backlink"/>
                </li>
              </xsl:for-each>
            </ol>
          </section>
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- the notes are moved to the endnotes section -->
  <xsl:template match="node()|@*" mode="endnotes">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="aside[@id][f:noteref(.)]" mode="endnotes"/>

  <xsl:template match="a[tokenize(@epub:type, '\s+') = 'noteref']" mode="endnotes">
    <xsl:apply-templates select="."/>
  </xsl:template>

  <xsl:template match="aside[@id][f:noteref(.)]">
    <aside role="doc-footnote" epub:type="footnote">
      <xsl:apply-templates select="@* except (@role, @epub:type)|node()"/>
      <xsl:call-template name="backlink"/>
    </aside>
  </xsl:template>

  <xsl:template name="backlink">
    <xsl:variable name="noteref" select="f:noteref(.)"/>
    <xsl:variable name="ref-file" select="f:file($noteref/ancestor::html)"/>
    <p>
      <a role="doc-backlink"
         href="{if ($ref-file = f:file(f:current(.))) then '' else $ref-file}#{f:noteref-id($noteref)}">
        <xsl:value-of select="replace(pf:i18n-translate('backlink', f:language(.), $translations),
                                      '#', normalize-space($noteref))"/>
      </a>
    </p>
  </xsl:template>

</xsl:stylesheet>
