#!/usr/bin/env janet

(use judge)
(import hey)
(import spork/path)

(def- dir (slice (path/dirname (dyn :current-file)) 0 -2))

(defmacro* resolve= [type args &opt exp]
  (let [form ~(,(case type :f hey/resolve :d hey/resolve-dir)
                ,(path/join dir (string (first args)))
                ,;(map string (slice args 1)))]
    ~(test ,(if exp form ~(nil? ,form))
           ,(if exp ~[,(path/join dir (first exp)) ,;(slice exp 1)] true))))

(deftest hey/resolve
  (resolve= :f [hey.d sub deeper]               ["hey.d/sub.d/deeper.zsh"])
  (resolve= :f [hey.d sub deeper foo]           ["hey.d/sub.d/deeper.zsh" "foo"])
  (resolve= :f [hey.d sub deeper deep foo]      ["hey.d/sub.d/deeper.d/deep.zsh" "foo"])

  # Invalid/404
  (deftest "Invalid paths"
    (resolve= :f [mock sub deeper])
    (resolve= :f [does not exist]))

  # A bare name is a $PATH lookup, and a $PATH miss used to leave the base nil,
  # which killed os/stat.
  (deftest "Relative paths"
    (test (nil? (hey/resolve "definitely/not/here")) true)
    (test (nil? (hey/resolve "./definitely/not/here")) true)
    (test (nil? (hey/resolve "definitely-not-a-command-on-path")) true)
    (test (truthy? (hey/resolve "janet")) true))

  (deftest "Forwarding options"
    (resolve= :f [hey.d sub deeper -b]            ["hey.d/sub.d/deeper.zsh" "-b"])
    (resolve= :f [hey.d sub deeper --foo]         ["hey.d/sub.d/deeper.zsh" "--foo"])
    (resolve= :f [hey.d sub deeper -b deep]       ["hey.d/sub.d/deeper.zsh" "-b" "deep"])
    (resolve= :f [hey.d sub deeper --foo deep]    ["hey.d/sub.d/deeper.zsh" "--foo" "deep"])
    (resolve= :f [hey.d sub deeper deep --foo -b] ["hey.d/sub.d/deeper.d/deep.zsh" "--foo" "-b"])
    (resolve= :f [hey.d sub deeper deep -b]       ["hey.d/sub.d/deeper.d/deep.zsh" "-b"])))

# (deftest hey/help)

# (deftest hey/dispatcher-for)

(deftest hey/synopsis
  (defn doc-of [file]
    (hey/synopsis (path/join dir "hey.d" file)))

  (test (doc-of "described.janet") "A described script.")

  (deftest "Undescribed scripts"
    # A bare TODO is a placeholder, not a description.
    (test (nil? (doc-of "todo.janet")) true)
    (test (nil? (doc-of "bare.zsh")) true))

  (deftest "Missing files"
    (test (nil? (doc-of "does-not-exist.janet")) true)
    (test (nil? (hey/synopsis nil)) true)
    # A directory is not a script.
    (test (nil? (hey/synopsis (path/join dir "hey.d"))) true)))

(deftest hey/rules->entries
  (def described (path/join dir "hey.d/described.janet"))

  (deftest "Names come from the rule's pattern"
    (test (map |($0 :name)
               (hey/rules->entries
                 ['(* "@")     (hey/with-doc "Sigil." "@*" |[:exec ;$&])
                  :keyword     (hey/with-doc "Keyword." |[:exec ;$&])
                  [:tuple :tu] (hey/with-doc "Tuple." |[:exec ;$&])
                  # No keyword and no :name, so it cannot be listed.
                  '(* "%")     |[:exec ;$&]]))
          @["@*" "keyword" "tuple"]))

  (deftest "Aliases are the tail of a keyword tuple"
    (test (map |($0 :aliases)
               (hey/rules->entries [:solo         "echo"
                                    [:many :m :n] "echo"]))
          @[[] ["m" "n"]]))

  (deftest "Patterns are distinguished from commands"
    (test (map |($0 :kind)
               (hey/rules->entries [:cmd     "echo"
                                    '(* "@") (hey/with-doc "Sigil." "@*" "echo")]))
          @[:command :pattern]))

  (deftest "A trailing fallback rule is not an entry"
    (test (length (hey/rules->entries [:cmd "echo" "fallback"])) 1))

  (deftest "Descriptions"
    # An explicit :doc wins over the destination's file.
    (test (map |($0 :doc)
               (hey/rules->entries
                 [:explicit (hey/with-doc "Explicit." {:cmd nil :file described})
                  :from-file {:cmd nil :file described}
                  :todo      {:cmd nil :file (path/join dir "hey.d/todo.janet")}
                  :fileless  |[:exec ;$&]]))
          @["Explicit." "A described script." "" ""])))

(deftest hey/header->specs
  (def specs (hey/header->specs (path/join dir "hey.d/specs.janet")))

  (deftest "Options"
    # A bracket and a backslash must be escaped, or the spec is unparsable and
    # zsh silently drops the entire completion.
    (test (in specs 0) "-a[A plain flag, with a bracket \\] and a back\\\\slash.]")
    # "," and "|" both yield one spec per spelling, sharing an exclusion group.
    (test (slice specs 1 3)
          ["(-l --list)-l[Two spellings of one option.]"
           "(-l --list)--list[Two spellings of one option.]"])
    (test (slice specs 3 6)
          ["(-e -f -d)-e[Three mutually exclusive options.]"
           "(-e -f -d)-f[Three mutually exclusive options.]"
           "(-e -f -d)-d[Three mutually exclusive options.]"])
    (test (in specs 6)
          "--host[An option taking a value, completed by a function.]:host:__hey_hosts"))

  (deftest "Arguments"
    # zsh evaluates the ((...)) field, so a backtick or $ reaching it unescaped
    # would run a command when the user hits TAB.
    (test (in specs 7)
          ``1:command:((one:"A description with \"quotes\", \$DOLLAR and a \`backtick\`." wm\*:"Column-aligned, and a value needing escapes."))``)
    (test (in specs 8) "2:plain: ")
    (test (in specs 9) "*:rest:__hey_sync_arg")
    (test (length specs) 10))

  (deftest "Headers declaring neither section"
    (test (hey/header->specs (path/join dir "hey.d/undocumented.janet")) @[])
    (test (hey/header->specs (path/join dir "hey.d/bare.zsh")) @[])
    (test (hey/header->specs (path/join dir "hey.d/does-not-exist")) @[])))

(deftest hey/header-matches-argspec
  (defn flags-in
    [spec]
    (def out @[])
    (def second (get spec 1))
    (var opts? (or (indexed? second)
                   (and (symbol? second) (string/has-prefix? "-" (string second)))))
    (var flag? false)
    (each item spec
      (cond
        (= item '&opts) (do (set opts? true) (set flag? false))
        (index-of item ['&args '&]) (set opts? false)
        (not opts?) nil
        # Options come in pairs: a binding name, then its spelling(s).
        flag? (do
                (set flag? false)
                (array/push out ;(filter |(string/has-prefix? "-" $0)
                                         (map string (if (indexed? item) item [item])))))
        (set flag? true)))
    out)

  (defn argspec-flags
    "Every option spelling FILE declares, including in nested cmdfn forms."
    [file]
    (def out @[])
    (defn walk [form]
      (when (indexed? form)
        (cond
          (index-of (first form) ['defcmd 'defcmd- 'defmain])
          (array/push out ;(flags-in (get form 2 [])))

          (= (first form) 'cmdfn)
          (array/push out ;(flags-in (get form 1 []))))
        (each item form (walk item))))
    (each form (parse-all (slurp file)) (walk form))
    (distinct out))

  (defn header-flags
    "The option spellings FILE's OPTIONS: header documents."
    [file]
    (def peg ~(* (? (* "(" (thru ")"))) (<- (* "-" (some (if-not "[" 1)))) "["))
    (seq [spec :in (hey/header->specs file)
          :let [match (peg/match peg spec)]
          :when match]
      (first match)))

  # Reported as one list rather than a test per file, so a failure names every
  # offender at once: [command documented-flags declared-flags]
  (def cmds (path/join dir "../../bin/hey.d"))
  (test (seq [name :in (sort (filter |(string/has-suffix? ".janet" $0) (os/dir cmds)))
              :let [file (path/join cmds name)
                    documented (sorted (header-flags file))
                    declared (sorted (argspec-flags file))]
              :when (not (deep= documented declared))]
          [name documented declared])
        @[]))

(deftest hey/specs-are-well-formed
  # _arguments dies on the *whole* call if any one spec is unparsable
  (def spec-peg
    ~{:esc (* "\\" 1)
      :group (* "(" (any (if-not ")" 1)) ")")
      :desc (any (+ :esc (if-not (set "[]") 1)))
      :field (any (+ :esc (if-not ":" 1)))
      :action (* ":" :field ":" (any 1))
      :option (* (? :group) "-" (some (if-not "[" 1)) "[" :desc "]" (? :action) -1)
      :positional (* (+ (some (range "09")) "*") (between 1 2 ":") :field ":" (any 1) -1)
      :main (+ :option :positional)})

  (defn dispatchable-scripts
    ``Return all dispatchable hey scripts that it can resolve to.``
    []
    (def out @[])
    (defn walk [dir]
      (each name (try (os/dir dir) ([_] []))
        (def file (path/join dir name))
        (case (os/stat file :mode)
          :directory (when (string/has-suffix? ".d" name) (walk file))
          :file (array/push out file))))
    (let [home (path/join dir "../..")]
      (walk (path/join home "bin"))
      (each area ["hosts" "config"]
        (each name (try (os/dir (path/join home area)) ([_] []))
          (walk (path/join home area name "bin"))))
      (sorted out)))

  (test (seq [file :in (dispatchable-scripts)
              spec :in (hey/header->specs file)
              :when (not (peg/match spec-peg spec))]
          [(path/basename file) spec])
        @[]))

(deftest hey/single-line-options
  (def specs (hey/header->specs (path/join dir "hey.d/oneline.janet")))
  (test specs
        @["-![Do a dry run.]"
          "(-? -??)-?[Enable debug mode, at increasing verbosity.]"
          "(-? -??)-??[Enable debug mode, at increasing verbosity.]"])

  (deftest "Scripts with no description are skipped"
    # "-q" has no description, and ignore "TODO"
    (test (length specs) 3)))

(deftest hey/scan
  (def fixtures (path/join dir "hey.d"))

  (deftest "Describes dispatchable scripts in a directory"
    # cmd.zsh has no description; sub.d is described by .docs; vars.zsh's second
    # line is a bare TODO, which synopsis treats as no description.
    # non-executable-cmd.zsh is skipped b/c it's not executable, and neither are
    # .janet fixtures.
    (test (hey/scan fixtures) @["cmd:" "sub:Hello world" "vars:"]))

  (deftest "Skip missing and empty directories are skipped"
    (test (hey/scan (path/join dir "does-not-exist")) @[])
    (test (hey/scan "") @[])
    (test (hey/scan nil) @[])
    # __hey_hooks passes a directory that does not exist on every host.
    (test (hey/scan (path/join dir "does-not-exist") fixtures)
          @["cmd:" "sub:Hello world" "vars:"]))

  (deftest "The first directory to define a name wins"
    (test (hey/scan fixtures (path/join fixtures "sub.d"))
          @["cmd:" "sub:Hello world" "vars:" "deeper:Test #2" "nested:"])
    (test (hey/scan (path/join fixtures "sub.d") fixtures)
          @["deeper:Test #2" "nested:" "cmd:" "sub:Hello world" "vars:"])))
