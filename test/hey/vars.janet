#1/usr/bin/env janet

(use judge)
(use hey)
(import hey/vars)

(def- vars (vars/new (:dir vars/temp :test)))

(defn- setup []
  ($ rm -rf ,(:dir vars)))  # Always start from scratch

(deftest get/set
  (setup)
  (test (:get vars :does-not-exist) nil)
  (test (:set vars :key 123) 123)
  (test (:get vars :key) 123)
  (test (:set vars :key nil) :key))

(deftest list
  (setup)
  (:set vars :foo 1)
  (:set vars :bar 2)
  (:set vars :baz 3)
  (test (length (:list vars)) 3)
  (:clear vars)
  (test (length (:list vars)) 0))

# TODO
# (deftest cache)
