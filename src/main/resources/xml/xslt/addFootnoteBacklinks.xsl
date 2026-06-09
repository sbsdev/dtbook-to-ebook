<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0"
                xmlns="http://www.daisy.org/z3986/2005/dtbook/"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:dtb="http://www.daisy.org/z3986/2005/dtbook/"
		xmlns:pf="http://www.daisy.org/ns/pipeline/functions"
                exclude-result-prefixes="dtb">

  <xsl:import href="copy.xsl"/>
  <xsl:import href="http://www.daisy.org/pipeline/modules/common-utils/i18n.xsl"/>

  <xsl:output method="xml" encoding="utf-8" indent="no"/>

  <xsl:variable name="translations" select="document('../i18n/translations.xml')/*"/>

  <xsl:template match="dtb:note">
    <xsl:variable name="language" select="('de',ancestor-or-self::*[@xml:lang|@lang]/(@xml:lang|@lang)[1])[last()]"/>
    <xsl:variable name="blurb" select="pf:i18n-translate('back',$language,$translations)"/>
    <xsl:variable name="backlink" select="//dtb:noteref[@idref=concat('#', current()/@id)]/preceding-sibling::dtb:a[1]/@id"/>
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates/>
      <p><a href="#{$backlink}"><xsl:value-of select="$blurb"/></a></p>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
