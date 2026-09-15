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
  (resolve= :f [hey.d sub deeper deep foo]      ["hey.d/sub.d/deeper.d/deep.zsh" "foo"])
  (resolve= :f [does not exist])

  # bin/hey's `.NAME` rule hands over config/$WM/bin, which a tty hasn't got.
  (deftest "A nil in the list is a place not to look, not an error"
    (test (deep= (hey/resolve [nil (path/join dir "hey.d")] "sub" "deeper")
                 (hey/resolve (path/join dir "hey.d") "sub" "deeper"))
          true))

  # A bare name is a $PATH lookup, and a $PATH miss used to leave the base nil,
  # which killed os/stat.
  (deftest "A $PATH miss is nil, not a crash"
    (test (nil? (hey/resolve "definitely-not-a-command-on-path")) true))

  # A flag stops the walk; whatever follows it is the script's.
  (deftest "Forwarding options"
    (resolve= :f [hey.d sub deeper --foo deep]    ["hey.d/sub.d/deeper.zsh" "--foo" "deep"])
    (resolve= :f [hey.d sub deeper deep --foo -b] ["hey.d/sub.d/deeper.d/deep.zsh" "--foo" "-b"])))

(deftest hey/exec-exit-status
  # os/execute hands back the status of the script hey dispatched to, but
  # nothing upstream read a dispatcher's return value, so anything that failed
  # came back as a clean exit 0. Harmless by hand; a lie to a cronjob.
  #
  # Spawned rather than called: the fix exits the process, which would take
  # judge with it.
  # Absolute: hey only recognises a bare path as one when it starts with ./ or
  # /, and anything else is a subcommand name it has never heard of.
  (def hey-bin (path/abspath (path/join dir "../../bin/hey")))
  (defn status [script]
    (os/execute [hey-bin (path/abspath (path/join dir "exec.d" script))] :p))

  (test (status "ok.zsh") 0)
  (test (status "fail.zsh") 42)
  # A rule that names $1 comes out 2-arity, but dispatch hands a rule one
  # argument when nothing follows the command -- `hey exec` used to die of a
  # janet arity error (exit 1) instead of saying which program it wanted (127).
  (test (os/execute [hey-bin "exec"] :p) 127)
  # A signal arrives here as 128+signum, the same way a shell reports it, so it
  # forwards without translation.
  (test (status "sig.zsh") 143))

(deftest hey/synopsis
  (defn doc-of [file]
    (hey/synopsis (path/join dir "hey.d" file)))

  (test (doc-of "described.janet") "A described script.")
  # A bare TODO is a placeholder, not a description.
  (test (nil? (doc-of "todo.janet")) true)
  (test (nil? (doc-of "does-not-exist.janet")) true)
  # A directory is not a script.
  (test (nil? (hey/synopsis (path/join dir "hey.d"))) true))

(deftest hey/rules->entries
  # Names come from the rule's pattern, aliases are the tail of a keyword
  # tuple, and a pattern is told apart from a command. A pattern with neither
  # keyword nor :name cannot be listed, and a trailing fallback isn't an entry.
  (test (map |[($0 :name) ($0 :aliases) ($0 :kind)]
             (hey/rules->entries
               ['(* "@")     (hey/with-doc "Sigil." "@*" |[:exec ;$&])
                [:many :m :n] "echo"
                '(* "%")     |[:exec ;$&]
                "fallback"]))
        @[["@*" [] :pattern] ["many" ["m" "n"] :command]]))

(deftest hey/header->specs
  # The whole grammar at once, since judge diffs the array. A bracket and a
  # backslash must be escaped, or the spec is unparsable and zsh silently
  # drops the entire completion. "," and "|" both yield one spec per spelling,
  # sharing an exclusion group. zsh evaluates the ((...)) field, so a backtick
  # or $ reaching it unescaped would run a command when the user hits TAB.
  (test (hey/header->specs (path/join dir "hey.d/specs.janet"))
        @["-a[A plain flag, with a bracket \\] and a back\\\\slash.]"
          "(-l --list)-l[Two spellings of one option.]"
          "(-l --list)--list[Two spellings of one option.]"
          "(-e -f -d)-e[Three mutually exclusive options.]"
          "(-e -f -d)-f[Three mutually exclusive options.]"
          "(-e -f -d)-d[Three mutually exclusive options.]"
          "--host[An option taking a value, completed by a function.]:host:hey.comp.hosts"
          ``1:command:((one:"A description with \"quotes\", \$DOLLAR and a \`backtick\`." wm\*:"Column-aligned, and a value needing escapes."))``
          "2:plain: "
          "*:rest:__hey_sync_arg"])

  # The single-line style. "-q" has no description and TODO is a placeholder,
  # so neither becomes a spec.
  (test (hey/header->specs (path/join dir "hey.d/oneline.janet"))
        @["-![Do a dry run.]"
          "(-? -??)-?[Enable debug mode, at increasing verbosity.]"
          "(-? -??)-??[Enable debug mode, at increasing verbosity.]"])

  (test (hey/header->specs (path/join dir "hey.d/undocumented.janet")) @[]))

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

(deftest hey/scan
  (def fixtures (path/join dir "hey.d"))

  # cmd.zsh has no description; sub.d is described by .docs; vars.zsh's second
  # line is a bare TODO, which synopsis treats as no description.
  # non-executable-cmd.zsh is skipped b/c it's not executable, and neither are
  # .janet fixtures.
  (test (hey/scan fixtures) @["cmd:" "sub:Hello world" "vars:"])

  # __hey_hooks passes a directory that does not exist on every host.
  (test (hey/scan (path/join dir "does-not-exist") fixtures)
        @["cmd:" "sub:Hello world" "vars:"])

  (deftest "The first directory to define a name wins"
    (test (hey/scan fixtures (path/join fixtures "sub.d"))
          @["cmd:" "sub:Hello world" "vars:" "deeper:Test #2" "nested:"])))
