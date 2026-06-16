<?xml version="1.0" encoding="UTF-8"?>
<!--
    Test-only wrapper around sbs:dtbook-to-ebook.
    Runs the full pipeline and exposes the generated EPUB's package.opf on the
    primary output port so that xprocspec scenarios can assert on EPUB content.
-->
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
                xmlns:px="http://www.daisy.org/ns/pipeline/xproc"
                xmlns:sbs="http://www.sbs.ch/pipeline"
                type="sbs:dtbook-to-ebook-test-wrapper" name="main" version="1.0">

    <p:input port="source" primary="true"/>
    <p:option name="output-dir" required="true"/>
    <p:option name="temp-dir" required="true"/>

    <p:output port="result" primary="true">
        <p:pipe step="unzip-opf" port="result"/>
    </p:output>
    <p:output port="status" primary="false">
        <p:pipe step="convert" port="status"/>
    </p:output>

    <p:import href="../../main/resources/xml/xproc/dtbook-to-ebook.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/zip-utils/library.xpl"/>

    <p:variable name="output-name"
        select="replace(replace(base-uri(/), '^.*/([^/]+)$', '$1'), '\.[^.]*$', '')"/>

    <sbs:dtbook-to-ebook name="convert">
        <p:with-option name="output-dir" select="$output-dir"/>
        <p:with-option name="temp-dir" select="$temp-dir"/>
    </sbs:dtbook-to-ebook>

    <px:unzip name="unzip-opf">
        <p:with-option name="href" select="concat($output-dir, $output-name, '.epub')"/>
        <p:with-option name="file" select="'EPUB/package.opf'"/>
    </px:unzip>

</p:declare-step>
