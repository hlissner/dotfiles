# Everything that reads or generates documentation from a script's comment
# header: `hey help`, the one-line descriptions in `hey help --dump`, and the
# zsh completion specs derived from a subcommand's OPTIONS: and ARGUMENTS:
# sections.

(import spork/path)
(use ./lib)

(defn- header-lines
  ``Return FILE's leading comment block as lines, with leading "# " stripped.

  Returns nil if FILE isn't a readable script, and an empty array if it is one
  but has no comment header.``
  [file]
  (when (and file (= :file (os/stat file :mode)))
    (with [f (file/open file :rn)]
      (when (string/has-prefix? "#!/" (string (or (file/read f :line) "")))
        (def peg (peg! '(* "#" (between 0 1 " "))))
        (def out @[])
        (var line nil)
        (while (set line (file/read f :line))
          (unless (string/has-prefix? "#" (string line))
            (break))
          (array/push out (string/trimr (string (peg/replace peg "" line)))))
        out))))

(defn help [[file & _args] &opt output]
  # TODO: Parse these doc headings into table
  # TODO: Search sub-directory for extra subcommands.
  (unless (path/exists? file)
    (errorf "File does not exist: %s" (path/abbrev file)))
  (def lines (or (header-lines file)
                 (abort "Not a script: %s" (path/abbrev file))))
  (when (empty? lines)
    (abort "No documentation for %s" (path/abbrev file)))
  (with-dyns [*out* (or output stdout)]
    (echo (string/join lines "\n"))))

(defn with-doc
  ``Annotate a dispatch destination with a one-line description.

    (with-doc DOC DEST)
    (with-doc DOC NAME DEST)

  DEST may be a function, a string, or a command struct (see hey/cmd's cmd).
  NAME is a display name for rules whose pattern is a PEG, and so has no keyword
  to derive one from.``
  [docstring & rest]
  (def [name dest] (if (= 2 (length rest)) rest [nil (first rest)]))
  (assert dest "with-doc: no destination given")
  (if (dictionary? dest)
    (table/to-struct (merge dest {:doc docstring :name name}))
    {:fn dest :doc docstring :name name}))

(defn synopsis
  ``Return the one-line description on the second line of script FILE, or nil.
  This is the same convention config/zsh/completions/_hey's __hey_scan uses.``
  [file]
  (when-let [lines (header-lines file)
             desc (string/trim (get lines 0 ""))]
    (unless (or (empty? desc) (= desc "TODO"))
      desc)))

(defn- header-sections
  "Group LINES by their `ALL CAPS:` headings, into @{HEADING @[line ...]}."
  [lines]
  (def peg (peg! '(* (<- (some (+ (range "AZ") " "))) ":" (any " ") -1)))
  (def out @{})
  (var current nil)
  (each line lines
    (if-let [match (peg/match peg line)]
      (do (set current (string/trim (first match)))
          (put out current @[]))
      (when current
        (array/push (in out current) line))))
  out)

(defn script-path
  ``FILE as an absolute path. :current-file is relative to the project root
  while compiling and absolute while interpreting, and the macros that bake it
  in record it verbatim; this is the only place that knows which it got.``
  [file]
  (if (path/abspath? file) file (path :home file)))

(defn usage-lines
  "The lines of FILE's SYNOPSIS: section, trimmed, or nil if it has none."
  [file]
  (when-let [lines (header-lines file)
             block (get (header-sections lines) "SYNOPSIS")
             out (filter |(not (empty? $0)) (map string/trim block))]
    (unless (empty? out) out)))

(defn usage-abort
  "Abort with FILE's SYNOPSIS:, or a shrug if it hasn't got one."
  [file]
  (if-let [lines (usage-lines file)]
    (abort "Usage:\n  %s" (string/join lines "\n  "))
    (abort "Wrong arguments, and %s has no SYNOPSIS: to quote at you"
           (path/abbrev file))))

(defmacro usage
  ``Abort with this script's own SYNOPSIS:, so the header stays the only copy of
  it. The file is baked in while compiling, the way defcmd and dispatch do it.``
  []
  ~(,usage-abort (,script-path ,(dyn :current-file ""))))

(defn rule-pairs
  ``Partition RULES into [pattern destination] pairs, dropping the fallback.``
  [rules]
  (partition 2 (slice rules 0 (if (odd? (length rules)) -2 -1))))


## * ZSH Completion

# A script's comment header is the single source of truth for its flags and
# arguments. config/zsh/completions/_hey needs it to generate a _arguments call.

(defn- header-entries
  ``Group a section's LINES into [head [body ...]] pairs.``
  [lines]
  (def out @[])
  (each line lines
    (def text (string/trim line))
    (def indent (- (length line) (length (string/triml line))))
    (cond (empty? text) nil
          (<= indent 2) (array/push out [text @[]])
          (not (empty? out)) (array/push (in (last out) 1) text)))
  out)

(defn- head-tokens [head]
  (filter |(not (empty? $0))
          (string/split " " (->> head
                                 # "," delimit aliases of an option while "|"
                                 # delimit mutually exclusive options.
                                 (string/replace-all "," " , ")
                                 (string/replace-all "|" " | ")))))

(defn- esc-desc
  "Escape TEXT for an option description, which _arguments reads inside [...]."
  [text]
  (->> text
       (string/replace-all "\\" "\\\\")
       (string/replace-all "]" "\\]")))

(defn- esc-msg
  "Escape TEXT for a spec's colon-delimited message field."
  [text]
  (->> text
       (string/replace-all "\\" "\\\\")
       (string/replace-all ":" "\\:")))

(defn- esc-eval
  ``Escape TEXT for a value description inside ((val:"...")). zsh *evaluates*
  this field, so an unescaped backtick or $ in a comment header would run a
  command the moment the user hits TAB.``
  [text]
  (->> text
       (string/replace-all "\\" "\\\\")
       (string/replace-all "\"" "\\\"")
       (string/replace-all "$" "\\$")
       (string/replace-all "`" "\\`")))

(def- *completers*
  {"files" "_files" "default" "_default" "commands" "_command_names -e"})

(defn- completer
  "Resolve a @REF from a header to the zsh function or builtin it names."
  [ref]
  (def name (slice ref 1))
  (or (get *completers* name)
      (string "__hey_" (string/replace-all "-" "_" name))))

(defn- value-name?
  ``True if TEXT looks like an argument placeholder (HOST, FLAKE-URI), marking
  the option or positional as taking a value. Deliberately strict, so that the
  "," and "|" separators aren't mistaken for one.``
  [text]
  (and (peg/match (peg! '(* (some (+ (range "AZ" "09") (set "-_"))) -1)) text)
       (some |(<= 65 $0 90) text)
       true))

(defn- option->specs
  ``Turn one OPTIONS: entry into one _arguments spec per flag spelling.

  Two layouts are accepted: the flag alone on its line with the description
  indented beneath it, and bin/hey's single-line "FLAGS -- description". An
  entry with no flags, or with no description at all, is skipped -- both mean
  this isn't an option entry, and guessing produces specs that quietly complete
  the wrong thing.``
  [head body]
  (def i     (string/find " -- " head))
  (def toks  (head-tokens (if i (slice head 0 i) head)))
  (def flags (filter |(string/has-prefix? "-" $0) toks))
  (def desc  (string/trim (string/join [;(if i [(slice head (+ i 4))] []) ;body] " ")))
  (if (or (empty? flags) (empty? desc))
    []
    (let [ref    (find |(string/has-prefix? "@" $0) toks)
          value  (find |(and (not (string/has-prefix? "-" $0))
                             (not (string/has-prefix? "@" $0))
                             (value-name? $0))
                       toks)
          group  (if (> (length flags) 1)
                   (string "(" (string/join flags " ") ")")
                   "")
          action (if value
                   (string ":" (esc-msg (string/ascii-lower value)) ":"
                           (if ref (completer ref) " "))
                   "")]
      (map |(string group $0 "[" (esc-desc desc) "]" action) flags))))

(defn- esc-value
  ``Escape an enumerated value's name.

  zsh evaluates the whole ((...)) field and splits the name from its description
  on ":", so anything that isn't plainly a word character gets a backslash.
  Areas like "wm*" depend on this.``
  [text]
  (def word (peg! '(* (+ (range "az" "AZ" "09") (set "-_.+@/")) -1)))
  (string/join (seq [c :in text]
                 (let [s (string/from-bytes c)]
                   (if (peg/match word s) s (string "\\" s))))))

(defn- entry-value
  ``Split an enumerated value from its description. They may be separated by
  " -- " or, as path.janet's area table does, by column alignment.``
  [line]
  (def line (string/trim line))
  (if-let [i (string/find " -- " line)]
    [(string/trim (slice line 0 i)) (string/trim (slice line (+ i 4)))]
    (if-let [i (string/find "  " line)]
      [(string/trim (slice line 0 i)) (string/trim (slice line i))]
      [line nil])))

(defn- argument->spec
  "Turn one ARGUMENTS: entry into an _arguments positional spec."
  [head body]
  (def toks (head-tokens head))
  (def pos (first toks))
  # A position is a digit, "*" for the rest, or "**" for the rest with words and
  # CURRENT re-sliced (zsh's "*::"), which is what lets a subcommand dispatch
  # again into its own arguments.
  (when (peg/match (peg! '(* (+ (some (range "09")) (between 1 2 "*")) -1)) pos)
    (let [ref (find |(string/has-prefix? "@" $0) toks)
          name (or (find |(and (not (string/has-prefix? "@" $0)) (not= $0 pos)) toks)
                   "arg")
          values (seq [line :in body]
                   (let [[v d] (entry-value line)]
                     (string (esc-value v)
                             (if d (string ":\"" (esc-eval d) "\"") ""))))
          action (cond (not (empty? values)) (string "((" (string/join values " ") "))")
                       ref (completer ref)
                       " ")]
      (string (if (= pos "**") "*::" (string pos ":"))
              (esc-msg (string/ascii-lower name)) ":" action))))

(defn header->specs
  ``Generate zsh _arguments specs from the OPTIONS: and ARGUMENTS: sections of a
  script FILE's comment header. Returns an array of spec strings, empty if the
  header declares neither.``
  [file]
  (def sections (header-sections (or (header-lines file) [])))
  (def out @[])
  (each [head body] (header-entries (get sections "OPTIONS" []))
    (array/push out ;(option->specs head body)))
  (each [head body] (header-entries (get sections "ARGUMENTS" []))
    (when-let [spec (argument->spec head body)]
      (array/push out spec)))
  out)

(defn scan
  ``Describe the dispatchable scripts in DIRS as "name:description" pairs.

  File extensions are stripped from their names, dotfiles and _private files are
  skipped, and the first occurrence of a name wins so earlier DIRS shadow later
  ones.``
  [& dirs]
  (def seen @{})
  (def out  @[])
  (each dir dirs
    (when (and dir (not (empty? dir)) (= :directory (os/stat dir :mode)))
      (each entry (sort (os/dir dir))
        (def file (path/join dir entry))
        (def mode (os/stat file :mode))
        (when-let [name (cond
                          (= mode :directory)
                          (if (string/has-suffix? ".d" entry)
                            (slice entry 0 -3)
                            entry)
                          (and (= mode :file) (path/executable? file))
                          (path/no-ext entry ;*script-exts*))]
          (unless (or (string/has-prefix? "." name)
                      (string/has-prefix? "_" name)
                      (in seen name))
            (put seen name true)
            (def desc
              (if (= mode :directory)
                (let [docs (path/join file ".docs")]
                  (when (= :file (os/stat docs :mode))
                    (with [f (file/open docs :rn)]
                      (when-let [line (file/read f :line)]
                        (string/trim (string line))))))
                (synopsis file)))
            (array/push out (string name ":" (or desc ""))))))))
  out)

(defn print-scan [& dirs]
  (each pair (scan ;dirs) (echo pair)))

(defn print-specs [file]
  (each spec (header->specs file) (echo spec)))

(defn rules->entries
  ``Describe RULES as an array of structs:

    {:kind :command|:pattern :name STR :aliases (STR...) :doc STR}

  An entry's description is its :doc (see `with-doc`) or the second line of its
  script file. Rules with neither a keyword nor an explicit :name are omitted.``
  [rules]
  (def out @[])
  (each [pat dest] (rule-pairs rules)
    (let [info (if (dictionary? dest) dest {})
          docstring (or (get info :doc) (synopsis (get info :file)) "")
          names (cond (keyword? pat) [(string pat)]
                      (string? pat)  [pat]
                      (and (tuple? pat) (keyword? (first pat))) (map string pat))]
      (cond names
            (array/push out {:kind :command
                             :name (first names)
                             :aliases (tuple ;(slice names 1))
                             :doc docstring})
            (get info :name)
            (array/push out {:kind :pattern
                             :name (info :name)
                             :aliases []
                             :doc docstring}))))
  out)

(def- *builtin-rules*
  # For special commands implemented by dispatch-1
  [[:help :h] {:doc "Display documentation for a command."}
   :which     {:doc "Print a command's path (with arguments) without running it."}])

(defn- all-entries [rules]
  # Commands first, then the sigil patterns; each alphabetically.
  (sorted-by |(string (if (= ($0 :kind) :pattern) "1" "0") ($0 :name))
             [;(rules->entries *builtin-rules*) ;(rules->entries rules)]))

(defn print-commands
  ``Print commands as NAME:DESCRIPTION lines in three groups: commands, aliases,
  then sigils. Intended to be passed directly to zsh's _describe (see
  config/zsh/completions/_hey).``
  [rules]
  (def groups @[@[] @[] @[]])
  (each entry (all-entries rules)
    (array/push
      (groups (if (= (entry :kind) :pattern) 2 0))
      (string (entry :name) ":" (entry :doc)))
    (each alias (entry :aliases)
      (array/push (groups 1) (string alias ":alias for " (entry :name)))))
  (echo (string/join (map |(string/join $0 "\n") groups) "\n\n")))

(defn format-commands
  "Render RULES as an aligned `- NAME|ALIAS -- DESCRIPTION` list."
  [rules]
  (def entries (all-entries rules))
  (def labels  (map |(string/join [($0 :name) ;($0 :aliases)] "|") entries))
  (def width   (max 4 ;(map length labels)))
  (string/join
    (seq [i :range [0 (length entries)]]
      (let [label (in labels i)]
        (string "  - " label
                (string/repeat " " (- width (length label)))
                " -- " ((in entries i) :doc))))
    "\n"))
