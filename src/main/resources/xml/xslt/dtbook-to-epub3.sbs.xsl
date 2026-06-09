<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dtb="http://www.daisy.org/z3986/2005/dtbook/"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:epub="http://www.idpf.org/2007/ops"
    exclude-result-prefixes="dtb html">

  <xsl:output method="xml" encoding="UTF-8" indent="no"/>

  <!-- ============================================================ -->
  <!-- General DTBook → HTML mappings                               -->
  <!-- ============================================================ -->

  <xsl:template match="dtb:p">
    <p><xsl:apply-templates select="@*|node()"/></p>
  </xsl:template>

  <xsl:template match="dtb:blockquote">
    <blockquote><xsl:apply-templates select="@*|node()"/></blockquote>
  </xsl:template>

  <xsl:template match="dtb:h1"><h1><xsl:apply-templates select="node()"/></h1></xsl:template>
  <xsl:template match="dtb:h2"><h2><xsl:apply-templates select="node()"/></h2></xsl:template>
  <xsl:template match="dtb:h3"><h3><xsl:apply-templates select="node()"/></h3></xsl:template>
  <xsl:template match="dtb:h4"><h4><xsl:apply-templates select="node()"/></h4></xsl:template>
  <xsl:template match="dtb:h5"><h5><xsl:apply-templates select="node()"/></h5></xsl:template>
  <xsl:template match="dtb:h6"><h6><xsl:apply-templates select="node()"/></h6></xsl:template>

  <xsl:template match="dtb:span">
    <span><xsl:apply-templates select="node()"/></span>
  </xsl:template>

  <xsl:template match="dtb:em">
    <em><xsl:apply-templates select="node()"/></em>
  </xsl:template>

  <xsl:template match="dtb:strong">
    <strong><xsl:apply-templates select="node()"/></strong>
  </xsl:template>

  <xsl:template match="dtb:a">
    <a><xsl:apply-templates select="@*|node()"/></a>
  </xsl:template>

  <!-- lists: retain hd as a paragraph so its text is preserved -->
  <xsl:template match="dtb:list[@type='ul' or not(@type)]">
    <ul>
      <xsl:apply-templates select="dtb:hd"/>
      <xsl:apply-templates select="dtb:li"/>
    </ul>
  </xsl:template>

  <xsl:template match="dtb:list[@type='ol']">
    <ol>
      <xsl:apply-templates select="dtb:hd"/>
      <xsl:apply-templates select="dtb:li"/>
    </ol>
  </xsl:template>

  <!-- dtb:hd inside a list: render as p so its text is accessible -->
  <xsl:template match="dtb:list/dtb:hd">
    <p class="list-hd"><xsl:apply-templates select="node()"/></p>
  </xsl:template>

  <xsl:template match="dtb:li">
    <li><xsl:apply-templates select="node()"/></li>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- SBS-specific overrides                                       -->
  <!-- ============================================================ -->

  <!-- dtb:epigraph → html:blockquote (SBS requirement) -->
  <xsl:template match="dtb:epigraph">
    <blockquote>
      <xsl:apply-templates select="node()"/>
    </blockquote>
  </xsl:template>

  <!-- inline prodnote → span (SBS requirement) -->
  <xsl:template match="dtb:prodnote[@render='inline']">
    <span><xsl:apply-templates select="node()"/></span>
  </xsl:template>

  <!-- block prodnote → aside -->
  <xsl:template match="dtb:prodnote">
    <aside class="prodnote">
      <xsl:apply-templates select="node()"/>
    </aside>
  </xsl:template>

  <!-- fake frontmatter sections → div, not section (SBS requirement) -->
  <xsl:template match="dtb:level1[@class='frontmatter-placeholder']">
    <div>
      <xsl:apply-templates select="node()"/>
    </div>
  </xsl:template>

  <!-- poems without a header → div, not section (SBS requirement) -->
  <xsl:template match="dtb:poem[not(dtb:hd)]">
    <div epub:type="z3998:poem">
      <xsl:apply-templates select="node()"/>
    </div>
  </xsl:template>

  <xsl:template match="dtb:poem[dtb:hd]">
    <section epub:type="z3998:poem">
      <xsl:apply-templates select="node()"/>
    </section>
  </xsl:template>

  <xsl:template match="dtb:linegroup">
    <div class="linegroup"><xsl:apply-templates select="node()"/></div>
  </xsl:template>

  <xsl:template match="dtb:line">
    <p class="line"><xsl:apply-templates select="node()"/></p>
  </xsl:template>

  <!-- imggroup: caption before image (SBS requirement), no longdesc -->
  <xsl:template match="dtb:imggroup">
    <figure>
      <xsl:apply-templates select="dtb:caption"/>
      <xsl:apply-templates select="dtb:img"/>
      <xsl:apply-templates select="dtb:prodnote"/>
    </figure>
  </xsl:template>

  <!-- caption → figcaption -->
  <xsl:template match="dtb:caption">
    <figcaption><xsl:apply-templates select="node()"/></figcaption>
  </xsl:template>

  <!-- img → html:img without longdesc (SBS requirement) -->
  <xsl:template match="dtb:img">
    <img src="{@src}" alt="{@alt}">
      <xsl:if test="@id">
        <xsl:attribute name="id" select="@id"/>
      </xsl:if>
    </img>
  </xsl:template>

  <!-- suppress DTBook-specific attributes that have no HTML equivalent -->
  <xsl:template match="@imgref|@render|@smilref|@showin"/>

  <!-- pass through @class, @id, @xml:lang as-is -->
  <xsl:template match="@class|@id">
    <xsl:copy/>
  </xsl:template>

  <xsl:template match="@xml:lang">
    <xsl:attribute name="lang" select="."/>
  </xsl:template>

  <!-- text nodes pass through -->
  <xsl:template match="text()">
    <xsl:copy/>
  </xsl:template>

</xsl:stylesheet>
