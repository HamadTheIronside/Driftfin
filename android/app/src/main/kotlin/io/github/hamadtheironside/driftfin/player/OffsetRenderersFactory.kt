package io.github.hamadtheironside.driftfin.player

import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.media3.common.text.CueGroup
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.Renderer
import androidx.media3.exoplayer.text.TextOutput
import androidx.media3.exoplayer.text.TextRenderer
import io.github.hamadtheironside.driftfin.objects.PlayerSettingsObject

/**
 * A [DefaultRenderersFactory] that wraps the subtitle [TextOutput] so cue
 * delivery can be shifted in time. Media3's [TextRenderer] is final and exposes
 * no subtitle-delay knob, so we intercept its output and re-dispatch cues on a
 * delay.
 *
 * This supports positive offsets (showing subtitles *later*), which is the
 * common sync need. Negative offsets (showing them *earlier*) aren't possible
 * post-hoc because future cues haven't been decoded yet; they fall back to no
 * shift. The libMPV backend (used on phones/desktop/iOS) handles both
 * directions natively.
 */
@UnstableApi
class OffsetRenderersFactory(context: Context) : DefaultRenderersFactory(context) {
    override fun buildTextRenderers(
        context: Context,
        output: TextOutput,
        outputLooper: Looper,
        extensionRendererMode: Int,
        out: ArrayList<Renderer>,
    ) {
        out.add(TextRenderer(OffsetTextOutput(output, Handler(outputLooper)), outputLooper))
    }
}

@UnstableApi
private class OffsetTextOutput(
    private val delegate: TextOutput,
    private val handler: Handler,
) : TextOutput {
    override fun onCues(cueGroup: CueGroup) {
        val delayMs = PlayerSettingsObject.subtitleDelayMs.value
        if (delayMs <= 0L) {
            delegate.onCues(cueGroup)
        } else {
            handler.postDelayed({ delegate.onCues(cueGroup) }, delayMs)
        }
    }
}
