<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step
    xmlns:p="http://www.w3.org/ns/xproc"
    xmlns:px="http://www.daisy.org/ns/pipeline/xproc"
    xmlns:sbs="http://www.sbs.ch/pipeline"
    xmlns:d="http://www.daisy.org/ns/pipeline/data"
    xmlns:c="http://www.w3.org/ns/xproc-step"
    exclude-inline-prefixes="#all"
    type="sbs:dtbook-to-ebook" name="main" version="1.0">

    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
        <h1 px:role="name">DTBook to E-Book (SBS)</h1>
        <p px:role="desc">Transforms a DTBook (DAISY 3 XML) document into an EPUB3 e-book using SBS-specific preprocessing.</p>
    </p:documentation>

    <p:input port="source" primary="true" px:name="source" px:media-type="application/x-dtbook+xml">
        <p:documentation>
            <h2 px:role="name">source</h2>
            <p px:role="desc">Input DTBook.</p>
        </p:documentation>
    </p:input>

    <p:option name="output-dir" required="true" px:output="result" px:type="anyDirURI">
        <p:documentation>
            <h2 px:role="name">output-dir</h2>
            <p px:role="desc">Directory for storing result files.</p>
        </p:documentation>
    </p:option>

    <p:option name="temp-dir" required="true" px:type="anyDirURI" px:output="temp">
        <p:documentation>
            <h2 px:role="name">temp-dir</h2>
            <p px:role="desc">Temporary directory for intermediate files.</p>
        </p:documentation>
    </p:option>

    <p:output port="status" px:media-type="application/vnd.pipeline.status+xml">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <h2 px:role="name">Status</h2>
            <p px:role="desc">Whether or not the conversion was successful.</p>
        </p:documentation>
        <p:pipe step="convert" port="status"/>
    </p:output>

    <p:import href="http://www.daisy.org/pipeline/modules/dtbook-to-epub3/library.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/epub-utils/library.xpl"/>

    <!-- Derive EPUB output name from the source document's filename (prologue variable) -->
    <p:variable name="output-name"
        select="replace(replace(base-uri(/), '^.*/([^/]+)$', '$1'), '\.[^.]*$', '')"/>

    <!-- ===================== -->
    <!-- Build source fileset  -->
    <!-- ===================== -->

    <p:identity name="dtbook-source"/>

    <p:xslt name="make-fileset">
        <p:input port="source"><p:pipe step="dtbook-source" port="result"/></p:input>
        <p:input port="parameters"><p:empty/></p:input>
        <p:input port="stylesheet">
            <p:inline>
                <xsl:stylesheet version="2.0"
                    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                    xmlns:d="http://www.daisy.org/ns/pipeline/data">
                    <xsl:template match="/">
                        <d:fileset>
                            <xsl:attribute name="xml:base">
                                <xsl:value-of select="replace(base-uri(.), '[^/]+$', '')"/>
                            </xsl:attribute>
                            <d:file media-type="application/x-dtbook+xml">
                                <xsl:attribute name="href">
                                    <xsl:value-of select="replace(base-uri(.), '^.*/([^/]+)$', '$1')"/>
                                </xsl:attribute>
                            </d:file>
                        </d:fileset>
                    </xsl:template>
                </xsl:stylesheet>
            </p:inline>
        </p:input>
    </p:xslt>
    <p:identity name="source-fileset"/>

    <!-- ===================== -->
    <!-- SBS preprocessing     -->
    <!-- ===================== -->

    <p:identity>
        <p:input port="source"><p:pipe step="dtbook-source" port="result"/></p:input>
    </p:identity>

    <p:xslt name="filter-brl-contraction-hints">
        <p:input port="parameters"><p:empty/></p:input>
        <p:input port="stylesheet">
            <p:document href="../xslt/filterBrlContractionhints.xsl"/>
        </p:input>
    </p:xslt>

    <p:xslt name="filter-processing-instructions">
        <p:input port="parameters"><p:empty/></p:input>
        <p:input port="stylesheet">
            <p:document href="../xslt/filterProcessingInstructions.xsl"/>
        </p:input>
    </p:xslt>

    <p:xslt name="filter-toc">
        <p:input port="parameters"><p:empty/></p:input>
        <p:input port="stylesheet">
            <p:document href="../xslt/filterTOC.xsl"/>
        </p:input>
    </p:xslt>

    <p:xslt name="filter-comments">
        <p:input port="parameters"><p:empty/></p:input>
        <p:input port="stylesheet">
            <p:document href="../xslt/filterComments.xsl"/>
        </p:input>
    </p:xslt>

    <p:xslt name="filter-linenum-spans">
        <p:input port="parameters"><p:empty/></p:input>
        <p:input port="stylesheet">
            <p:document href="../xslt/filterLinenumSpans.xsl"/>
        </p:input>
    </p:xslt>

    <p:xslt name="add-empty-headers">
        <p:input port="parameters"><p:empty/></p:input>
        <p:input port="stylesheet">
            <p:document href="../xslt/addEmptyHeaders.xsl"/>
        </p:input>
    </p:xslt>

    <p:xslt name="add-boilerplate">
        <p:input port="parameters"><p:empty/></p:input>
        <p:input port="stylesheet">
            <p:document href="../xslt/addBoilerplate.xsl"/>
        </p:input>
    </p:xslt>

    <p:xslt name="add-image-ids">
        <p:input port="parameters"><p:empty/></p:input>
        <p:input port="stylesheet">
            <p:document href="../xslt/addImageIds.xsl"/>
        </p:input>
    </p:xslt>

    <p:xslt name="add-image-refs">
        <p:input port="parameters"><p:empty/></p:input>
        <p:input port="stylesheet">
            <p:document href="../xslt/addImageRefs.xsl"/>
        </p:input>
    </p:xslt>

    <p:xslt name="add-image-description-boilerplate">
        <p:input port="parameters"><p:empty/></p:input>
        <p:input port="stylesheet">
            <p:document href="../xslt/addImageDescriptionBoilerplate.xsl"/>
        </p:input>
    </p:xslt>

    <p:xslt name="move-footnotes-to-rearmatter">
        <p:input port="parameters"><p:empty/></p:input>
        <p:input port="stylesheet">
            <p:document href="../xslt/moveFootnotesToRear.xsl"/>
        </p:input>
    </p:xslt>

    <p:xslt name="add-anchors-before-noterefs">
        <p:input port="parameters"><p:empty/></p:input>
        <p:input port="stylesheet">
            <p:document href="../xslt/addFootnoteAnchor.xsl"/>
        </p:input>
    </p:xslt>

    <p:xslt name="add-backlinks-to-footnotes">
        <p:input port="parameters"><p:empty/></p:input>
        <p:input port="stylesheet">
            <p:document href="../xslt/addFootnoteBacklinks.xsl"/>
        </p:input>
    </p:xslt>

    <p:identity name="dtbook-preprocessed"/>

    <!-- ======================== -->
    <!-- Standard DAISY Pipeline  -->
    <!-- conversion to EPUB3      -->
    <!-- ======================== -->

    <px:dtbook-to-epub3 name="convert">
        <p:input port="source.fileset">
            <p:pipe step="source-fileset" port="result"/>
        </p:input>
        <p:input port="source.in-memory">
            <p:pipe step="dtbook-preprocessed" port="result"/>
        </p:input>
        <p:input port="tts-config">
            <p:empty/>
        </p:input>
        <p:with-option name="audio" select="'false'"/>
        <p:with-option name="epub-stylesheet" select="resolve-uri('../../css/accessibility.css')"/>
        <p:with-option name="output-dir" select="concat($temp-dir,'epub3/')"/>
        <p:with-option name="output-name" select="$output-name"/>
        <p:with-option name="temp-dir" select="concat($temp-dir,'dtbook-to-epub3/')"/>
    </px:dtbook-to-epub3>

    <!-- ======================== -->
    <!-- SBS post-processing      -->
    <!-- ======================== -->

    <p:for-each name="postprocess">
        <p:iteration-source>
            <p:pipe step="convert" port="result.in-memory"/>
        </p:iteration-source>
        <p:output port="result" sequence="true"/>
        <p:choose>
            <p:when test="ends-with(base-uri(/*), '.opf')">
                <p:variable name="opf-uri" select="base-uri(/*)"/>
                <!-- the XSLT derives the features from the images in the content documents -->
                <p:wrap-sequence wrapper="c:wrapper">
                    <p:input port="source">
                        <p:pipe step="convert" port="result.in-memory"/>
                    </p:input>
                </p:wrap-sequence>
                <p:xslt>
                    <p:input port="parameters"><p:empty/></p:input>
                    <p:input port="stylesheet">
                        <p:document href="../xslt/package-doc.sbs.xsl"/>
                    </p:input>
                    <!-- keep the base URI so that the document still matches the fileset -->
                    <p:with-option name="output-base-uri" select="$opf-uri"/>
                    <p:with-param name="identifier"
                                  select="(/*/*:head/*:meta[lower-case(@name)=('dc:identifier','dtb:uid')]/@content)[1]">
                        <p:pipe step="dtbook-source" port="result"/>
                    </p:with-param>
                </p:xslt>
            </p:when>
            <p:otherwise>
                <p:identity/>
            </p:otherwise>
        </p:choose>
    </p:for-each>

    <!-- package-doc.sbs.xsl removes the link to the MODS record -->
    <p:delete name="drop-mods" match="d:file[ends-with(@href,'zedai-mods.xml')]">
        <p:input port="source">
            <p:pipe step="convert" port="result.fileset"/>
        </p:input>
    </p:delete>

    <!-- ======================== -->
    <!-- Store EPUB to output-dir -->
    <!-- ======================== -->

    <px:epub3-store name="store">
        <p:input port="fileset.in">
            <p:pipe step="drop-mods" port="result"/>
        </p:input>
        <p:input port="in-memory.in">
            <p:pipe step="postprocess" port="result"/>
        </p:input>
        <p:with-option name="href" select="concat($output-dir,$output-name,'.epub')"/>
    </px:epub3-store>

</p:declare-step>
