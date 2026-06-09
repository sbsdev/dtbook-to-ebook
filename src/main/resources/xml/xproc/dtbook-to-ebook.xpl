<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step
    xmlns:p="http://www.w3.org/ns/xproc"
    xmlns:px="http://www.daisy.org/ns/pipeline/xproc"
    xmlns:sbs="http://www.sbs.ch/pipeline"
    xmlns:c="http://www.w3.org/ns/xproc-step"
    xmlns:d="http://www.daisy.org/ns/pipeline/data"
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

    <!-- ===================== -->
    <!-- SBS preprocessing     -->
    <!-- ===================== -->

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

    <!-- Build a fileset wrapping the preprocessed DTBook in memory -->
    <p:wrap-sequence wrapper="c:result"/>
    <p:wrap-sequence wrapper="c:results"/>

    <px:dtbook-to-epub3 name="convert">
        <p:input port="source.fileset">
            <p:empty/>
        </p:input>
        <p:input port="source.in-memory">
            <p:pipe step="dtbook-preprocessed" port="result"/>
        </p:input>
        <p:input port="tts-config">
            <p:empty/>
        </p:input>
        <p:with-option name="output-dir" select="$output-dir"/>
        <p:with-option name="temp-dir" select="$temp-dir"/>
    </px:dtbook-to-epub3>

</p:declare-step>
