(ns conjure.meta
  (:require [clojure.string :as str]
            [clojure.java.shell :as shell]))

(def version (str/trimr (:out (shell/sh "cmd" "/C" "git describe --long --dirty --abbrev=10 --tags"))))
(def ns-version (str/replace version #"\." "v"))
