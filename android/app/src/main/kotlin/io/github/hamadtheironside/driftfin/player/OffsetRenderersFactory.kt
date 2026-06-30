package io.github.hamadtheironside.driftfin.player

import android.content.Context
import android.os.Looper
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.Renderer
import androidx.media3.exoplayer.text.TextOutput
import androidx.media3.exoplayer.text.TextRenderer
import io.github.hamadtheironside.driftfin.objects.PlayerSettingsObject

/**
 * A [DefaultRenderersFactory] that swaps in an [OffsetTextRenderer] so subtitle
 * timing can be shifted at runtime. Media3/ExoPlayer has no built-in subtitle
 * delay knob; shifting the position the text renderer renders at is the
 * supported way to achieve a bidirectional offset.
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
        out.add(OffsetTextRenderer(output, outputLooper))
    }
}

/**
 * Renders subtitles offset by [PlayerSettingsObject.subtitleDelayMs]. A positive
 * delay makes the renderer lag the playback clock (subtitles appear later); a
 * negative delay makes it lead (subtitles appear earlier).
 */
@UnstableApi
private class OffsetTextRenderer(
    output: TextOutput,
    outputLooper: Looper?,
) : TextRenderer(output, outputLooper) {
    override fun render(positionUs: Long, elapsedRealtimeUs: Long) {
        val offsetUs = PlayerSettingsObject.subtitleDelayMs.value * 1_000L
        super.render(positionUs - offsetUs, elapsedRealtimeUs)
    }
}
