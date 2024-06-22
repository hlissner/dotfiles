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
  (resolve= :f [mock.d sub deeper]               ["mock.d/sub.d/deeper.zsh"])
  (resolve= :f [mock.d sub deeper foo]           ["mock.d/sub.d/deeper.zsh" "foo"])
  (resolve= :f [mock.d sub deeper deep foo]      ["mock.d/sub.d/deeper.d/deep.zsh" "foo"])

  # Invalid/404
  (deftest "Invalid paths"
    (resolve= :f [mock sub deeper])
    (resolve= :f [does not exist]))

  (deftest "Forwarding options"
    (resolve= :f [mock.d sub deeper -b]            ["mock.d/sub.d/deeper.zsh" "-b"])
    (resolve= :f [mock.d sub deeper --foo]         ["mock.d/sub.d/deeper.zsh" "--foo"])
    (resolve= :f [mock.d sub deeper -b deep]       ["mock.d/sub.d/deeper.zsh" "-b" "deep"])
    (resolve= :f [mock.d sub deeper --foo deep]    ["mock.d/sub.d/deeper.zsh" "--foo" "deep"])
    (resolve= :f [mock.d sub deeper deep --foo -b] ["mock.d/sub.d/deeper.d/deep.zsh" "--foo" "-b"])
    (resolve= :f [mock.d sub deeper deep -b]       ["mock.d/sub.d/deeper.d/deep.zsh" "-b"])))

# (deftest hey/help)

# (deftest hey/dispatcher-for)
