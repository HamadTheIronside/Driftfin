using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using Jellyfin.Plugin.Driftfin.Api;
using Xunit;

namespace Jellyfin.Plugin.Driftfin.Tests
{
    public class DriftfinSyncPlayControllerTests
    {
        [Fact]
        public void SelectRecipientIds_ExcludesCallerAndNonMembers()
        {
            var sessions = new[]
            {
                new RelaySession("caller-session", "alice"),
                new RelaySession("bob-session", "bob"),
                new RelaySession("eve-session", "eve"),
            };

            var recipients = DriftfinSyncPlayController.SelectRecipientIds(
                sessions,
                callerSessionId: "caller-session",
                groupParticipants: new List<string> { "alice", "bob" });

            Assert.Equal(new[] { "bob-session" }, recipients);
        }

        [Fact]
        public void SelectRecipientIds_MatchesUsernamesCaseInsensitively()
        {
            var sessions = new[]
            {
                new RelaySession("caller-session", "alice"),
                new RelaySession("bob-session", "BOB"),
            };

            var recipients = DriftfinSyncPlayController.SelectRecipientIds(
                sessions,
                callerSessionId: "caller-session",
                groupParticipants: new List<string> { "bob" });

            Assert.Equal(new[] { "bob-session" }, recipients);
        }

        [Fact]
        public void SelectRecipientIds_HandlesMultipleSessionsForSameUser()
        {
            // A user with two devices open should get the relay on both.
            var sessions = new[]
            {
                new RelaySession("caller-session", "alice"),
                new RelaySession("bob-phone", "bob"),
                new RelaySession("bob-tv", "bob"),
            };

            var recipients = DriftfinSyncPlayController.SelectRecipientIds(
                sessions,
                callerSessionId: "caller-session",
                groupParticipants: new List<string> { "alice", "bob" });

            Assert.Equal(new[] { "bob-phone", "bob-tv" }, recipients.OrderBy(id => id));
        }

        [Fact]
        public void SelectRecipientIds_ReturnsEmpty_WhenNoOtherParticipants()
        {
            var sessions = new[] { new RelaySession("caller-session", "alice") };

            var recipients = DriftfinSyncPlayController.SelectRecipientIds(
                sessions,
                callerSessionId: "caller-session",
                groupParticipants: new List<string> { "alice" });

            Assert.Empty(recipients);
        }

        [Fact]
        public void BuildPayload_CopiesKindTextAndEmojiWithSenderFromSession()
        {
            var body = new SyncPlayRelayMessageDto { Kind = "chat", Text = "hi", Emoji = null };

            var payload = DriftfinSyncPlayController.BuildPayload(body, "alice");

            Assert.Equal("chat", payload.Kind);
            Assert.Equal("alice", payload.Sender);
            Assert.Equal("hi", payload.Text);
            Assert.Null(payload.Emoji);
        }

        [Fact]
        public void SyncPlayRelayPayload_SerializesWithShortWireKeys()
        {
            var payload = DriftfinSyncPlayController.BuildPayload(
                new SyncPlayRelayMessageDto { Kind = "reaction", Emoji = "🎉" },
                "alice");

            var json = JsonSerializer.Serialize(payload);
            using var doc = JsonDocument.Parse(json);
            var root = doc.RootElement;

            Assert.Equal("reaction", root.GetProperty("k").GetString());
            Assert.Equal("alice", root.GetProperty("s").GetString());
            Assert.Equal("🎉", root.GetProperty("e").GetString());
        }
    }
}
