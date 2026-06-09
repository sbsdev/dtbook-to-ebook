<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0"
                xmlns="http://www.daisy.org/z3986/2005/dtbook/"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:dtb="http://www.daisy.org/z3986/2005/dtbook/"
		xmlns:pf="http://www.daisy.org/ns/pipeline/functions"
                exclude-result-prefixes="dtb">

  <xsl:import href="http://www.daisy.org/pipeline/modules/common-utils/i18n.xsl"/>

  <xsl:output method="xml" encoding="utf-8" indent="no"
              doctype-public="-//NISO//DTD dtbook 2005-3//EN"
              doctype-system="http://www.daisy.org/z3986/2005/dtbook-2005-3.dtd" />

  <xsl:variable name="translations" select="document('../i18n/translations.xml')/*"/>

  <xsl:template name="image-description">
    <xsl:variable name="language" select="('de',ancestor-or-self::*[@xml:lang|@lang]/(@xml:lang|@lang)[1])[last()]"/>
    <xsl:variable name="blurb" select="pf:i18n-translate('image-description',$language,$translations)"/>
    <p><xsl:value-of select="$blurb"/>:</p>
  </xsl:template>

  <!-- if a prodnote is inside an imggroup and refers to an image then
       add a para with the text "image-description" -->
  <xsl:template match="dtb:imggroup//dtb:prodnote[@imgref]">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:call-template name="image-description"/>
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- Copy all other elements and attributes -->
  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
