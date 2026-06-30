package io.github.hamadtheironside.driftfin.composables.dialogs

import androidx.annotation.OptIn
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import io.github.hamadtheironside.driftfin.objects.Localized
import io.github.hamadtheironside.driftfin.objects.PlayerSettingsObject
import io.github.hamadtheironside.driftfin.objects.Translate
import io.github.hamadtheironside.driftfin.objects.VideoPlayerObject
import io.github.hamadtheironside.driftfin.utility.clearSubtitleTrack
import io.github.hamadtheironside.driftfin.utility.setInternalSubtitleTrack

@OptIn(UnstableApi::class)
@Composable
fun SubtitlePicker(
    player: ExoPlayer,
    onDismissRequest: () -> Unit,
) {
    val selectedIndex by VideoPlayerObject.currentSubtitleTrackIndex.collectAsState()
    val subTitles by VideoPlayerObject.subtitleTracks.collectAsState(emptyList())
    val internalSubTracks by VideoPlayerObject.exoSubTracks.collectAsState(emptyList())
    val subtitleDelayMs by PlayerSettingsObject.subtitleDelayMs.collectAsState()

    if (subTitles.isEmpty()) return

    val focusRequesters = remember(subTitles) {
        subTitles.associateWith { FocusRequester() }
    }

    val listState = rememberLazyListState()

    LaunchedEffect(selectedIndex, subTitles) {
        val selectedSubIndex = subTitles.indexOfFirst { it.index == selectedIndex.toLong() }

        if (selectedSubIndex in subTitles.indices) {
            listState.scrollToItem(selectedSubIndex)
            focusRequesters[subTitles[selectedSubIndex]]?.requestFocus()
        }
    }

    CustomModalBottomSheet(
        onDismissRequest,
        maxWidth = 600.dp,
    ) {
        LazyColumn(
            state = listState,
            modifier = Modifier
                .wrapContentWidth()
                .padding(horizontal = 8.dp, vertical = 16.dp),
        ) {
            item {
                fun setDelay(value: Long) {
                    VideoPlayerObject.implementation.setSubtitleDelay(value)
                }

                val seconds = subtitleDelayMs / 1000.0
                val sign = if (subtitleDelayMs > 0) "+" else ""
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 8.dp, vertical = 8.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    OutlinedButton(onClick = { setDelay(subtitleDelayMs - 100L) }) {
                        Text("−")
                    }
                    Translate(Localized::subtitleSync) { label ->
                        Text(
                            modifier = Modifier.weight(1f),
                            textAlign = TextAlign.Center,
                            text = "$label  $sign${"%.1f".format(seconds)}s",
                        )
                    }
                    OutlinedButton(onClick = { setDelay(subtitleDelayMs + 100L) }) {
                        Text("+")
                    }
                    OutlinedButton(
                        onClick = { setDelay(0L) },
                        enabled = subtitleDelayMs != 0L,
                    ) {
                        Text("0")
                    }
                }
            }

            subTitles.forEachIndexed { index, serverSub ->
                val isOffTrack = index == 0
                val selected = serverSub.index == selectedIndex.toLong()

                item {
                    TrackButton(
                        modifier = Modifier
                            .fillMaxWidth()
                            .focusRequester(focusRequesters[serverSub]!!),
                        onClick = {
                            if (isOffTrack) {
                                VideoPlayerObject.setSubtitleTrackIndex(-1)
                                player.clearSubtitleTrack()
                            } else {
                                val internalTrackIndex = index - 1

                                val internalSubTrack =
                                    internalSubTracks.elementAtOrNull(internalTrackIndex)

                                if (internalSubTrack != null) {
                                    VideoPlayerObject.setSubtitleTrackIndex(serverSub.index.toInt())
                                    player.setInternalSubtitleTrack(internalSubTrack)
                                }
                            }
                        },
                        selected = selected,
                    ) {
                        if (isOffTrack) {
                            Translate(Localized::off) {
                                Text(it)
                            }
                        } else {
                            Text(
                                text = serverSub.name,
                            )
                        }
                    }
                }
            }
        }
    }
}