#!/usr/bin/env janet
# Change the default output or input audio device via Rofi.
#
# SYNOPSIS:
#   audiomenu

(use hey)
(use hey/cmd)
(import hey/sys)
(import hey/rofi)

(defn- dev-icon [dev &opt fallback]
  (or (get-in dev [:properties :api.bluez5.icon])
      fallback))

(defn set-default-input [dev]
  (when (do? $? pactl set-default-source ,(get dev :name))
    (sys/notify (get dev :description)
                :title "Default input device changed"
                :icon (dev-icon dev "audio-input-microphone")
                :sound "notify")))

(defn set-default-output [dev]
  (when (do? $? pactl set-default-sink ,(get dev :name))
    (sys/notify (get dev :description)
                :title "Default output device changed"
                :icon (dev-icon dev "audio-speakers")
                :sound "notify")))

(defn- audio-devices [type]
  (let [devs @{}]
    (each dev (json/decode ($<_ pactl -f json list ,(symbol type)) :keywords true)
      (put devs (get dev :name) dev))
    devs))

(defn- show-audio-menu []
  (let [default-output ($<_ pactl get-default-sink)
        default-input  ($<_ pactl get-default-source)
        inputs  (audio-devices :sources)
        outputs (audio-devices :sinks)]
    (rofi/chain [r :theme "audiomenu"
                 :message (fmt "<b>Default output:</b>\t%s\n<b>Default input:</b>\t%s"
                               (or (get-in outputs [default-output :description]) "n/a")
                               (or (get-in inputs  [default-input  :description]) "n/a"))]
      (eachp [name dev] outputs
        (unless (= name default-output)
          (:add r (fmt "<b>Output</b>\t%s"
                       (get dev :description))
                :icon (dev-icon dev "audio-speakers")
                :data |(set-default-output dev))))
      (eachp [name dev] inputs
        (unless (= name default-input)
          (:add r (fmt "<b>Input</b>\t%s"
                       (get dev :description))
                :icon (dev-icon dev "audio-input-microphone")
                :data |(set-default-input dev)))))))

(defmain [_ & args]
  (show-audio-menu))
