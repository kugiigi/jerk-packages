pragma Singleton

import QtQuick 2.12
import QtFeedback 5.0

Item {
    id: haptics

    property bool enabled: false

    function play() {
        if (enabled) normalHaptics.start()
    }

    function playSubtle() {
        if (enabled) subtleHaptics.start()
    }

    HapticsEffect {
        id: normalHaptics

        attackIntensity: 0.0
        attackTime: 50
        intensity: 1.0
        duration: 10
        fadeTime: 50
        fadeIntensity: 0.0
    }

    HapticsEffect {
        id: subtleHaptics

        attackIntensity: 0.0
        attackTime: 50
        intensity: 1.0
        duration: 3
        fadeTime: 50
        fadeIntensity: 0.0
    }
}
