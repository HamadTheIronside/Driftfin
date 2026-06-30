package io.github.hamadtheironside.driftfin.objects

import AutoNextType
import PlayerSettings
import PlayerSettingsPigeon
import Screensaver
import SubtitleSettings
import androidx.compose.ui.graphics.Color
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.map
import io.github.hamadtheironside.driftfin.utility.toExoPlayerFit
import kotlin.time.DurationUnit
import kotlin.time.toDuration

object PlayerSettingsObject : PlayerSettingsPigeon {
    val settings: MutableStateFlow<PlayerSettings?> = MutableStateFlow(null)
    val subtitleSettings: MutableStateFlow<SubtitleSettings?> = MutableStateFlow(null)

    // Subtitle timing offset in milliseconds. Positive delays subtitles (shows
    // them later), negative shows them earlier. Read by the offset-aware text
    // renderer; not persisted.
    val subtitleDelayMs: MutableStateFlow<Long> = MutableStateFlow(0L)
    val skipMap = settings.map { it?.skipTypes ?: mapOf() }

    val forwardSpeed =
        settings.map {
            (it?.skipForward ?: 1L).toDuration(DurationUnit.MILLISECONDS)
        }
    val backwardSpeed = settings.map {
        (it?.skipBackward ?: 1L).toDuration(
            DurationUnit.MILLISECONDS
        )
    }

    val themeColor = settings.map { settings ->
        settings?.themeColor.let {
            if (it == null) null else Color(it)
        }
    }

    val autoNextType = settings.map { settings ->
        settings?.autoNextType ?: AutoNextType.OFF
    }

    val acceptedOrientations = settings.map { settings ->
        settings?.acceptedOrientations ?: emptyList()
    }

    val fillScreen = settings.map { settings -> settings?.fillScreen ?: false }

    val videoFit = settings.map { settings -> settings?.videoFit.toExoPlayerFit }

    val screenSaver = settings.map { settings -> settings?.screensaver ?: Screensaver.LOGO }
    override fun sendPlayerSettings(playerSettings: PlayerSettings) {
        settings.value = playerSettings
    }
}