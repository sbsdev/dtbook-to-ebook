#!/usr/bin/env bb
;; Compare EPUB output between two daisyproducer2 servers (production vs. test).
;; Used to validate the switch to the dtbook-to-ebook module.
;; Modelled on dp2/scripts/compare-braille.bb.
;;
;; Usage:
;;   ./compare-epub.bb [CONFIG-FILE]
;;
;; CONFIG-FILE defaults to compare-epub-config.edn in the current directory.

(require '[babashka.fs :as fs]
         '[babashka.http-client :as http]
         '[babashka.process :as p]
         '[cheshire.core :as json]
         '[clojure.data.xml :as xml]
         '[clojure.edn :as edn]
         '[clojure.java.io :as io]
         '[clojure.string :as str]
         '[clojure.walk :as walk])

(import '[java.util.zip ZipInputStream])

;;; HTTP helpers

(defn auth-headers [token]
  {"Authorization" token
   "Accept"        "application/json"})

(defn json-request [method base-url path token body]
  (http/request {:method  method
                 :uri     (str base-url path)
                 :headers (merge (auth-headers token) {"Content-Type" "application/json"})
                 :body    (json/generate-string body)}))

(defn get-json [base-url path token]
  (let [resp (http/get (str base-url path) {:headers (auth-headers token)})]
    (when (= 200 (:status resp))
      (json/parse-string (:body resp) true))))

(defn get-text [base-url path]
  (let [resp (http/get (str base-url path))]
    (when (= 200 (:status resp))
      (:body resp))))

(defn get-bytes [base-url path token]
  (let [resp (http/get (str base-url path) {:headers (auth-headers token) :as :bytes})]
    (when (= 200 (:status resp))
      (:body resp))))

;;; Finding documents with EPUB products

(defn epub-products? [base-url token doc-id]
  ;; product type 2 => ebook
  (seq (get-json base-url (str "/api/documents/" doc-id "/products?type=2") token)))

(defn all-documents [base-url token]
  (println "  fetching all documents...")
  (loop [offset 0 acc []]
    (let [batch (get-json base-url (str "/api/documents?limit=500&offset=" offset) token)]
      (if (empty? batch)
        (do (println (str "  " (count acc) " documents total")) acc)
        (recur (+ offset 500) (into acc batch))))))

(defn find-epub-documents [base-url token limit]
  (let [newest-first (sort-by :id > (all-documents base-url token))]
    (println "  checking for EPUB products, newest first...")
    (loop [candidates (partition-all 50 newest-first) found []]
      (cond
        (>= (count found) limit) (vec (take limit found))
        (empty? candidates)      (vec found)
        :else
        (let [qualifying (->> (first candidates)
                              (pmap #(when (epub-products? base-url token (:id %)) %))
                              (filter some?)
                              vec)]
          (recur (rest candidates) (into found qualifying)))))))

;;; Document, version & image operations

(defn get-latest-version [base-url doc-id]
  (some-> (get-text base-url (str "/api/documents/" doc-id "/versions?latest=true"))
          (json/parse-string true)))

(defn get-document [base-url token doc-id]
  (get-json base-url (str "/api/documents/" doc-id) token))

(defn patch-identifier [xml new-identifier]
  (-> xml
      (str/replace #"(<meta name=\"dc:Identifier\" content=\")[^\"]*(\")" (str "$1" new-identifier "$2"))
      (str/replace #"(<meta name=\"dtb:uid\" content=\")[^\"]*(\")"       (str "$1" new-identifier "$2"))))

(defn delete-document [base-url token doc-id]
  (try
    (http/delete (str base-url "/api/documents/" doc-id) {:headers (auth-headers token)})
    (catch Exception e
      (println (str "    WARNING: failed to delete test doc " doc-id ": " (.getMessage e))))))

(defn create-document [base-url token doc]
  (let [body (->> (select-keys doc [:title :author :publisher :date :language
                                    :subject :description :source :source-date
                                    :source-edition :source-publisher :source-rights
                                    :production-series :production-series-number
                                    :production-source])
                  (remove (comp nil? val))
                  (into {}))
        resp (json-request :post base-url "/api/documents" token body)]
    (if (= 201 (:status resp))
      (-> resp :headers (get "location") (str/split #"/") last parse-long)
      (throw (ex-info (str "Failed to create document: HTTP " (:status resp))
                      {:status (:status resp) :body (:body resp)})))))

(defn temp-file
  "Write `content` (string or bytes) to a temp file. dp2 only accepts file parts backed by a file."
  [content]
  (let [tmp (fs/file (fs/create-temp-file))]
    (if (string? content) (spit tmp content) (io/copy content tmp))
    (.deleteOnExit tmp)
    tmp))

(defn upload-version [base-url token doc-id xml-content filename]
  (http/post (str base-url "/api/documents/" doc-id "/versions")
             {:headers   (auth-headers token)
              :multipart [{:name         "file"
                           :content      (temp-file xml-content)
                           :filename     filename
                           :content-type "application/xml"}
                          {:name    "comment"
                           :content "Imported for EPUB regression test"}]}))

(defn copy-images [prod-url token test-url test-doc-id prod-doc-id]
  (let [images (get-json prod-url (str "/api/documents/" prod-doc-id "/images") token)]
    (when (seq images)
      (println (str "    uploading " (count images) " images..."))
      (doseq [{:keys [content]} images]
        (http/post (str test-url "/api/documents/" test-doc-id "/images")
                   {:headers   (auth-headers token)
                    :multipart [{:name     "file"
                                 :content  (temp-file (get-bytes prod-url (str "/archive/" content) token))
                                 :filename (last (str/split content #"/"))}]})))))

;;; EPUB generation

(defn generate-epub [base-url token doc-id]
  (let [resp (http/get (str base-url "/api/documents/" doc-id "/preview/epub")
                       {:headers (auth-headers token) :throw false})]
    (if (= 201 (:status resp))
      (get-bytes base-url (get-in resp [:headers "location"]) token)
      (throw (ex-info (str "EPUB generation failed: HTTP " (:status resp))
                      {:url base-url :body (:body resp)})))))

;;; Reading & normalising EPUBs

(defn unzip
  "Return a map of entry name -> UTF-8 string for every entry in the EPUB."
  [^bytes epub]
  (with-open [zis (ZipInputStream. (io/input-stream epub))]
    (loop [acc {}]
      (if-let [entry (.getNextEntry zis)]
        (recur (assoc acc (.getName entry) (String. (.readAllBytes zis) "UTF-8")))
        acc))))

(defn parse-xml [s]
  (xml/parse-str s :support-dtd false :namespace-aware true))

(defn local-name [k] (when k (name k)))

(defn elements [tree]
  (filter map? (tree-seq #(seq (:content %)) :content tree)))

(defn attr [el a]
  (some (fn [[k v]] (when (= a (local-name k)) v)) (:attrs el)))

(defn text-of [el]
  (->> (tree-seq map? :content el) (filter string?) (apply str) (#(str/replace % #"\s+" " ")) str/trim))

(defn resolve-href [base href]
  (str (some-> (fs/parent base) str (str "/")) href))

(defn read-epub
  "Parse an unzipped EPUB into {:opf-path :opf :spine [[path tree] ...] :files #{...}}."
  [entries]
  (let [opf-path (->> (get entries "META-INF/container.xml") parse-xml elements
                      (some #(when (= "rootfile" (local-name (:tag %))) (attr % "full-path"))))
        opf      (parse-xml (get entries opf-path))
        manifest (into {} (for [el (elements opf) :when (= "item" (local-name (:tag el)))]
                            [(attr el "id") (attr el "href")]))
        spine    (for [el (elements opf) :when (= "itemref" (local-name (:tag el)))]
                   (resolve-href opf-path (manifest (attr el "idref"))))]
    {:opf-path opf-path
     :opf      opf
     :spine    (mapv (fn [path] [path (parse-xml (get entries path))]) spine)
     :files    (set (keys entries))}))

(def volatile-attrs
  ;; values are auto-generated ids or references to them; keep the attribute, drop the value
  #{"id" "aria-describedby" "aria-labelledby" "headers"})

(defn normalise-attr [k v]
  (let [n (local-name k)]
    (cond
      (volatile-attrs n) [n "*"]
      (= "href" n)       [n (str/replace v #"#.*" "#*")]
      :else              [n v])))

(defn normalised-lines
  "One line per tag/text node, indented, with ids and whitespace normalised. Diff-friendly."
  ([node] (normalised-lines node 0))
  ([node depth]
   (let [indent (apply str (repeat (* 2 depth) \space))]
     (cond
       (string? node)
       (let [t (str/trim (str/replace node #"\s+" " "))]
         (when-not (str/blank? t) [(str indent t)]))

       (map? node)
       (let [tag   (local-name (:tag node))
             attrs (->> (:attrs node)
                        (map (fn [[k v]] (normalise-attr k v)))
                        sort
                        (map (fn [[k v]] (format " %s=\"%s\"" k v)))
                        (apply str))]
         (concat [(str indent "<" tag attrs ">")]
                 (mapcat #(normalised-lines % (inc depth)) (:content node))
                 [(str indent "</" tag ">")]))))))

(defn normalised-content [{:keys [spine]}]
  (->> spine
       (mapcat (fn [[_ tree]] (normalised-lines tree)))
       (str/join \newline)))

;;; Comparison dimensions

(defn namespace-uri [k]
  ;; clojure.data.xml encodes the namespace URI in the keyword namespace
  (some-> (namespace k) (str/replace #"^xmlns\." "") java.net.URLDecoder/decode))

(def ignored-opf-meta #{"dcterms:modified" "date" "identifier"})

(defn opf-key [el]
  (or (attr el "property") (attr el "name") (local-name (:tag el))))

(defn opf-metadata [{:keys [opf]}]
  (set (for [el (elements opf)
             :let [n (local-name (:tag el))
                   key (opf-key el)]
             :when (or (= "meta" n) (= "http://purl.org/dc/elements/1.1/" (namespace-uri (:tag el))))
             :when (not (ignored-opf-meta key))]
         [key (or (attr el "content") (text-of el))])))

(defn normalised-epub
  "The package document followed by the content documents, with build dates masked."
  [epub]
  (let [opf (walk/postwalk #(if (and (map? %) (:tag %) (#{"dcterms:modified" "date"} (opf-key %)))
                              (-> % (assoc :content ["*"])
                                  ;; the old converter also writes it into a content attribute
                                  (update :attrs (fn [attrs] (into {} (for [[k v] attrs]
                                                                        [k (if (= "content" (local-name k)) "*" v)])))))
                              %)
                           (:opf epub))]
    (str (str/join \newline (normalised-lines opf)) \newline (normalised-content epub))))

(defn content-elements [epub]
  (mapcat (fn [[_ tree]] (elements tree)) (:spine epub)))

(defn producer-link? [el]
  ;; the boilerplate links to the producer, www.unitas.ch for Italian, www.sbs.ch otherwise
  (and (= "a" (local-name (:tag el)))
       (re-find #"//www\.(sbs|unitas)\.ch" (or (attr el "href") ""))))

(defn boilerplate-text
  "Text of the innermost section (or body) holding the producer link."
  [els]
  (let [sections (filter #(and (#{"section" "body"} (local-name (:tag %)))
                               (some producer-link? (elements %)))
                         els)]
    (when (seq sections)
      (text-of (apply min-key (comp count text-of) sections)))))

(defn figure-caption-first? [fig]
  (let [order (->> (elements fig) (map (comp local-name :tag)) (filter #{"figcaption" "img"}))]
    (or (not (some #{"figcaption"} order)) (= "figcaption" (first order)))))

(defn dimensions [epub]
  (let [els   (content-elements epub)
        imgs  (filter #(= "img" (local-name (:tag %))) els)
        meta  (opf-metadata epub)]
    {:spine-files            (mapv (comp str fs/file-name first) (:spine epub))
     :opf-metadata           meta
     ;; the old converter marks the notes section "footnotes", the plan expects "rearnotes"
     :notes-section          (boolean (some #(some->> (attr % "type") (re-find #"\b(footnotes|rearnotes|endnotes)\b")) els))
     :caption-before-image   (every? figure-caption-first? (filter #(= "figure" (local-name (:tag %))) els))
     :images-with-describedby (count (filter #(attr % "aria-describedby") imgs))
     :no-longdesc            (not-any? #(attr % "longdesc") imgs)
     :accessibility-metadata (every? (set (map first meta)) ["schema:accessMode" "schema:accessibilityFeature"])
     :boilerplate            (boilerplate-text els)
     :accessibility-css      (boolean (some #(str/ends-with? % "accessibility.css") (:files epub)))}))

;;; Per-document processing

(defn save-diff [output-dir doc-id prod-text test-text]
  (let [prod-file (io/file output-dir "prod" (str doc-id ".txt"))
        test-file (io/file output-dir "test" (str doc-id ".txt"))
        diff-file (io/file output-dir "diff" (str doc-id ".diff"))]
    (doseq [f [prod-file test-file diff-file]] (io/make-parents f))
    (spit prod-file prod-text)
    (spit test-file test-text)
    (spit diff-file (:out (p/sh "diff" "--unified" (str prod-file) (str test-file))))))

(defn save-epubs [output-dir doc-id prod-bytes test-bytes]
  (doseq [[dir bytes] [["prod" prod-bytes] ["test" test-bytes]]
          :let [f (io/file output-dir "epub" dir (str doc-id ".epub"))]]
    (io/make-parents f)
    (io/copy bytes f)))

(defn compare-epubs [output-dir doc-id prod-bytes test-bytes normalise-ids]
  (save-epubs output-dir doc-id prod-bytes test-bytes)
  (let [prod      (read-epub (unzip prod-bytes))
        test      (read-epub (unzip test-bytes))
        prod-text (normalise-ids (normalised-epub prod))
        test-text (normalise-ids (normalised-epub test))
        prod-dims (dimensions prod)
        test-dims (dimensions test)]
    (when (not= prod-text test-text)
      (save-diff output-dir doc-id prod-text test-text))
    {:doc-id     doc-id
     :identical? (= prod-text test-text)
     :mismatches (vec (for [k (keys prod-dims)
                            :when (not= (normalise-ids (pr-str (prod-dims k)))
                                        (normalise-ids (pr-str (test-dims k))))]
                        k))}))

(defn process-doc [prod-url test-url token output-dir doc]
  (let [doc-id (:id doc)]
    (try
      (let [version (get-latest-version prod-url doc-id)]
        (if-not version
          {:doc-id doc-id :error "no version found"}
          (let [version-content (:content version)
                xml-content     (get-text prod-url (str "/archive/" version-content))
                test-doc-id     (create-document test-url token doc)
                test-identifier (:identifier (get-document test-url token test-doc-id))]
            (try
              (upload-version test-url token test-doc-id
                              (patch-identifier xml-content test-identifier)
                              (last (str/split version-content #"/")))
              (copy-images prod-url token test-url test-doc-id doc-id)
              (println "    generating prod EPUB...")
              (let [prod-epub (generate-epub prod-url token doc-id)
                    _         (println "    generating test EPUB...")
                    test-epub (generate-epub test-url token test-doc-id)
                    normalise #(-> % (str/replace (:identifier doc) "IDENTIFIER")
                                   (str/replace test-identifier "IDENTIFIER"))]
                (compare-epubs output-dir doc-id prod-epub test-epub normalise))
              (finally
                (delete-document test-url token test-doc-id))))))
      (catch clojure.lang.ExceptionInfo e
        ;; never print the whole ex-data: http-client puts the request, incl. the token, in it
        (let [{:keys [status body uri]} (ex-data e)]
          {:doc-id doc-id :error (str (ex-message e) " " uri " " status " "
                                      (some-> body str (subs 0 (min 300 (count (str body))))))}))
      (catch Exception e
        {:doc-id doc-id :error (str e)}))))

;;; Summary report

(defn print-summary [output-dir results]
  (let [errors    (filter :error results)
        compared  (remove :error results)
        passing   (filter #(empty? (:mismatches %)) compared)
        failing   (remove #(empty? (:mismatches %)) compared)]
    (println "\n=== EPUB Comparison Results ===")
    (println (format "Documents processed      : %d" (count results)))
    (println (format "  All dimensions match   : %d" (count passing)))
    (println (format "    of which identical   : %d" (count (filter :identical? passing))))
    (println (format "  Dimension mismatches   : %d" (count failing)))
    (println (format "  Errors                 : %d" (count errors)))
    (when (seq failing)
      (println "\nDimension mismatches:")
      (doseq [{:keys [doc-id mismatches]} (sort-by :doc-id failing)]
        (println (format "  doc-id=%-8d %s" doc-id (str/join ", " (map name mismatches))))))
    (when (some (complement :identical?) compared)
      (println (str "\nContent diffs written to " output-dir "/diff/")))
    (when (seq errors)
      (println "\nErrors:")
      (doseq [{:keys [doc-id error]} errors]
        (println (format "  doc-id=%-8d %s" doc-id error))))))

;;; Config & entry point

(def default-config-file "compare-epub-config.edn")

(def usage
  (str/join \newline
            ["Usage: compare-epub.bb [CONFIG-FILE]"
             ""
             "CONFIG-FILE defaults to compare-epub-config.edn in the current directory."
             ""
             "Example config file:"
             ""
             "  {:prod-url     \"https://prod.sbszh.ch\""
             "   :test-url     \"https://test.sbszh.ch\""
             "   :token        \"Token <your-jwt-token>\""
             "   :output-dir   \"/tmp/epub-cmp\"   ; optional, this is the default"
             "   :limit        100                ; optional, this is the default"
             "   :document-ids [13165 13167]}     ; optional, overrides :limit"
             ""
             "Obtain a token via POST /api/login. The config file is gitignored."]))

(when (some #{"--help" "-h"} *command-line-args*)
  (println usage)
  (System/exit 0))

(defn load-config [path]
  (let [f (io/file path)]
    (when-not (.exists f)
      (println (str "Config file not found: " path))
      (println)
      (println usage)
      (System/exit 1))
    (edn/read-string (slurp f))))

(when (= *file* (System/getProperty "babashka.file"))
  (let [{:keys [prod-url test-url token output-dir limit document-ids]
         :or   {output-dir "/tmp/epub-cmp" limit 100}}
        (load-config (or (first *command-line-args*) default-config-file))]
    (when-not (and prod-url test-url token)
      (println "Error: config must contain :prod-url, :test-url and :token")
      (System/exit 1))
    (let [docs (if document-ids
                 (do (println (str "Fetching " (count document-ids) " specific documents..."))
                     (mapv #(get-document prod-url token %) document-ids))
                 (do (println (str "Finding up to " limit " documents with EPUB products..."))
                     (find-epub-documents prod-url token limit)))]
      (println (str "Processing " (count docs) " documents..."))
      (let [results (->> docs
                         (partition-all 5)
                         (mapcat (fn [batch]
                                   (pmap #(do (println (str "  doc " (:id %) " – " (:title %)))
                                              (process-doc prod-url test-url token output-dir %))
                                         batch)))
                         vec)]
        (print-summary output-dir results)))))
