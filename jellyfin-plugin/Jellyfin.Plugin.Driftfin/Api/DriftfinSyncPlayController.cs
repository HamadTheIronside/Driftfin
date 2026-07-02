using System;
using System.Linq;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading;
using System.Threading.Tasks;
using MediaBrowser.Controller.Net;
using MediaBrowser.Controller.Session;
using MediaBrowser.Controller.SyncPlay;
using MediaBrowser.Controller.SyncPlay.Requests;
using MediaBrowser.Model.Session;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace Jellyfin.Plugin.Driftfin.Api
{
    /// <summary>
    /// Relays SyncPlay "Watch Together" chat/reaction/presence messages to every
    /// member of a group. Jellyfin's own <c>POST /Sessions/{id}/Message</c> only
    /// reaches sessions the caller may remote-control (typically administrators),
    /// so a normal user's chat message is otherwise a local echo only (see
    /// Driftfin issue #4). This controller runs with the plugin's own
    /// server-trusted access to <see cref="ISessionManager"/>, so it can fan a
    /// message out to every other group member's session regardless of who sent
    /// it — the authorization check below only requires the caller to actually
    /// be a participant of the target group, not to control the recipients.
    /// </summary>
    [ApiController]
    [Route("Driftfin/SyncPlay")]
    [Produces("application/json")]
    public class DriftfinSyncPlayController : ControllerBase
    {
        /// <summary>
        /// Marker used as the relayed <c>DisplayMessage</c>'s <c>Header</c> so
        /// Driftfin clients can tell a relayed payload (JSON in <c>Text</c>) apart
        /// from a genuine admin-authored broadcast message.
        /// </summary>
        public const string RelayHeader = "__driftfin.syncplay.relay__";

        private readonly ISessionManager _sessionManager;
        private readonly ISyncPlayManager _syncPlayManager;
        private readonly IAuthorizationContext _authContext;

        /// <summary>
        /// Initializes a new instance of the <see cref="DriftfinSyncPlayController"/> class.
        /// </summary>
        /// <param name="sessionManager">Instance of the <see cref="ISessionManager"/> interface.</param>
        /// <param name="syncPlayManager">Instance of the <see cref="ISyncPlayManager"/> interface.</param>
        /// <param name="authContext">Instance of the <see cref="IAuthorizationContext"/> interface.</param>
        public DriftfinSyncPlayController(
            ISessionManager sessionManager,
            ISyncPlayManager syncPlayManager,
            IAuthorizationContext authContext)
        {
            _sessionManager = sessionManager;
            _syncPlayManager = syncPlayManager;
            _authContext = authContext;
        }

        /// <summary>
        /// Relays a chat/reaction/presence message to every other member of the
        /// caller's SyncPlay group.
        /// </summary>
        /// <param name="groupId">The SyncPlay group id.</param>
        /// <param name="body">The message to relay.</param>
        /// <param name="cancellationToken">The cancellation token.</param>
        /// <returns>No content on success.</returns>
        [HttpPost("{groupId}/Messages")]
        // "DefaultAuthorization" = any logged-in Jellyfin user — this is the fix
        // for issue #4, which otherwise requires "RequiresElevation"-equivalent
        // remote-control rights on every recipient session.
        [Authorize(Policy = "DefaultAuthorization")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<ActionResult> PostMessage(
            [FromRoute] Guid groupId,
            [FromBody] SyncPlayRelayMessageDto body,
            CancellationToken cancellationToken)
        {
            if (body is null || string.IsNullOrWhiteSpace(body.Kind))
            {
                return BadRequest();
            }

            var authInfo = await _authContext.GetAuthorizationInfo(Request).ConfigureAwait(false);
            var callerSession = _sessionManager.Sessions
                .FirstOrDefault(s => s.UserId == authInfo.UserId && s.DeviceId == authInfo.DeviceId);
            if (callerSession is null)
            {
                return Unauthorized();
            }

            // Only relay within a group the caller is actually a member of — this
            // is what stops the endpoint from being used to message arbitrary
            // sessions the caller doesn't control.
            var groups = _syncPlayManager.ListGroups(callerSession, new ListGroupsRequest());
            var group = groups.FirstOrDefault(g => g.GroupId == groupId);
            if (group is null)
            {
                return NotFound();
            }

            var payload = JsonSerializer.Serialize(new SyncPlayRelayPayload
            {
                Kind = body.Kind,
                Sender = callerSession.UserName,
                Text = body.Text,
                Emoji = body.Emoji,
            });

            var command = new GeneralCommand
            {
                Name = GeneralCommandType.DisplayMessage,
                ControllingUserId = callerSession.UserId,
            };
            command.Arguments["Header"] = RelayHeader;
            command.Arguments["Text"] = payload;

            var recipients = _sessionManager.Sessions
                .Where(s => s.Id != callerSession.Id && group.Participants.Contains(s.UserName, StringComparer.OrdinalIgnoreCase))
                .ToList();

            await Task.WhenAll(recipients.Select(s =>
                _sessionManager.SendGeneralCommand(callerSession.Id, s.Id, command, cancellationToken)))
                .ConfigureAwait(false);

            return NoContent();
        }
    }

    /// <summary>Wire DTO for a client-submitted relay message.</summary>
    public class SyncPlayRelayMessageDto
    {
        /// <summary>Gets or sets the message kind ("chat", "reaction", "typing" or "buffering").</summary>
        [JsonPropertyName("kind")]
        public string Kind { get; set; } = string.Empty;

        /// <summary>Gets or sets the chat text (kind "chat" only).</summary>
        [JsonPropertyName("text")]
        public string? Text { get; set; }

        /// <summary>Gets or sets the reaction emoji (kind "reaction" only).</summary>
        [JsonPropertyName("emoji")]
        public string? Emoji { get; set; }
    }

    /// <summary>
    /// Wire payload relayed to other members, mirroring the client's
    /// <c>SyncRelayMessage</c> (short keys: this rides inside a
    /// <c>DisplayMessage</c>'s <c>Text</c>, which some clients render literally).
    /// </summary>
    public class SyncPlayRelayPayload
    {
        /// <summary>Gets or sets the message kind.</summary>
        [JsonPropertyName("k")]
        public string Kind { get; set; } = string.Empty;

        /// <summary>Gets or sets the sender's username, resolved server-side from the caller's session.</summary>
        [JsonPropertyName("s")]
        public string Sender { get; set; } = string.Empty;

        /// <summary>Gets or sets the chat text.</summary>
        [JsonPropertyName("t")]
        public string? Text { get; set; }

        /// <summary>Gets or sets the reaction emoji.</summary>
        [JsonPropertyName("e")]
        public string? Emoji { get; set; }
    }
}
