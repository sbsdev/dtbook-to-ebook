<?xml version="1.0" encoding="UTF-8"?>
<!-- XSLT 2.0 mock of common-utils i18n.xsl for XSpec testing (Saxon 9.5 does not support XSLT 3.0) -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:pf="http://www.daisy.org/ns/pipeline/functions"
                xmlns:d="http://www.daisy.org/ns/pipeline/data"
                exclude-result-prefixes="#all">

    <xsl:function name="pf:i18n-translate" as="xs:string">
        <xsl:param name="string" as="xs:string"/>
        <xsl:param name="language" as="xs:string"/>
        <xsl:param name="maps" as="element()*"/>
        <xsl:variable name="lang-prefix" select="lower-case(tokenize($language,'-')[1])"/>
        <xsl:variable name="exact"
            select="(for $map in $maps return $map//d:translation[@string=$string]/d:text[@xml:lang=$language])[1]"/>
        <xsl:variable name="generic"
            select="if ($exact) then () else (for $map in $maps return $map//d:translation[@string=$string]/d:text[starts-with(@xml:lang,$lang-prefix)])[1]"/>
        <xsl:variable name="any"
            select="if ($exact or $generic) then () else (for $map in $maps return $map//d:translation[@string=$string]/d:text[1])[1]"/>
        <xsl:value-of select="($exact, $generic, $any)[1]"/>
    </xsl:function>

    <xsl:function name="pf:normalize-lang" as="xs:string">
        <xsl:param name="language" as="xs:string"/>
        <xsl:value-of select="$language"/>
    </xsl:function>

</xsl:stylesheet>
