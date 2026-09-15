# Shared plumbing for the completion regression suites. Not a suite itself --
# bin/hey.d/test.janet skips _-prefixed directories, and judge is never pointed
# at this one.

(use sh)
(import hey)

(def- driver (hey/path :home "test/_lib/completion.zsh"))

(defn complete
  ``Run CASE against the completion for COMPLETION with WORDS, and return what
  it offered, one string per line.``
  [completion case & words]
  (def out @"")
  ($? zsh ,driver ,completion ,case ,;words > ,out > [stderr :null])
  (filter |(not (empty? $0)) (string/split "\n" (string/trim out))))

(defn offers?
  "True if any line of the completion OUT contains TEXT."
  [out text]
  (not= nil (some |(string/find text $0) out)))
