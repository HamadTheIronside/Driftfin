# ProGuard / R8 rules for release builds.
#
# R8 is currently DISABLED (minifyEnabled false in app/build.gradle) because the
# release speedup comes from AOT compilation, not minification, and stripping the
# wrong class crashes the app at runtime. These are starter keep rules so that,
# once you flip minifyEnabled/shrinkResources back to true and verify on a device,
# the native- and reflection-heavy dependencies survive shrinking.

# Flutter embedding
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Pigeon-generated native bridge (channels: io_github_hamadtheironside_driftfin)
-keep class io.github.hamadtheironside.driftfin.** { *; }

# Media3 / ExoPlayer + the Jellyfin FFmpeg decoder and libass renderer.
# These load native code and resolve classes reflectively.
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**
-keep class org.jellyfin.media3.** { *; }
-keep class io.github.peerless2012.ass.** { *; }

# media_kit / mpv (default player backend) — JNI-facing surfaces.
-keep class com.alexmercerind.** { *; }
-keep class media.kit.** { *; }

# Sentry (crash reporting) resolves integrations by name.
-keep class io.sentry.** { *; }
-dontwarn io.sentry.**

# Keep annotations and generic signatures used by reflection-based deserialization.
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
