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

  <xsl:template match="dtb:rearmatter">
    <xsl:variable name="language" select="('de',ancestor-or-self::*[@xml:lang|@lang]/(@xml:lang|@lang)[1])[last()]"/>
    <xsl:variable name="blurb" select="pf:i18n-translate('footnotes',$language,$translations)"/>
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates/>
      <xsl:if test="//dtb:note">
	<level1>
	  <h1><xsl:value-of select="$blurb"/></h1>
	  <xsl:copy-of select="//dtb:note"/>
	</level1>
      </xsl:if>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="dtb:book[not(dtb:rearmatter)]">
    <xsl:variable name="language" select="('de',ancestor-or-self::*[@xml:lang|@lang]/(@xml:lang|@lang)[1])[last()]"/>
    <xsl:variable name="blurb" select="pf:i18n-translate('footnotes',$language,$translations)"/>
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates/>
      <xsl:if test="//dtb:note">
	<rearmatter>
	  <level1>
	    <h1><xsl:value-of select="$blurb"/></h1>
	    <xsl:copy-of select="//dtb:note"/>
	  </level1>
	</rearmatter>
      </xsl:if>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="dtb:note"/>

</xsl:stylesheet>
