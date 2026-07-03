using System.Text.Json.Serialization;
using Jellyfin.Plugin.Driftfin.Configuration;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace Jellyfin.Plugin.Driftfin.Api
{
    /// <summary>
    /// Serves the server-wide Driftfin integration config to clients. The mere
    /// existence of <c>GET /Driftfin/Config</c> is how the app detects that the
    /// plugin is installed (a 404 means "not installed" → the app uses its local
    /// per-device settings).
    /// </summary>
    [ApiController]
    [Route("Driftfin")]
    [Produces("application/json")]
    public class DriftfinConfigController : ControllerBase
    {
        /// <summary>Returns the current integration config. Any authenticated user may read it.</summary>
        /// <returns>The integration config.</returns>
        [HttpGet("Config")]
        // Any logged-in Jellyfin user may read it. Jellyfin 10.11 removed the
        // named "DefaultAuthorization" policy (referencing it throws
        // "AuthorizationPolicy ... was not found" -> HTTP 500), so plain
        // [Authorize] is the portable way to require an authenticated user.
        [Authorize]
        [ProducesResponseType(StatusCodes.Status200OK)]
        public ActionResult<DriftfinConfigDto> GetConfig()
        {
            var config = Plugin.Instance?.Configuration;
            if (config is null)
            {
                return NotFound();
            }

            return Ok(DriftfinConfigDto.FromConfiguration(config));
        }

        /// <summary>Updates the integration config. Admin only.</summary>
        /// <param name="body">The new config.</param>
        /// <returns>No content.</returns>
        [HttpPost("Config")]
        // "RequiresElevation" = Jellyfin administrators only.
        [Authorize(Policy = "RequiresElevation")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        public ActionResult UpdateConfig([FromBody] DriftfinConfigDto body)
        {
            var plugin = Plugin.Instance;
            if (plugin is null || body is null)
            {
                return NotFound();
            }

            body.ApplyTo(plugin.Configuration);
            plugin.SaveConfiguration();
            return NoContent();
        }
    }

    /// <summary>Wire DTO mirroring the Driftfin client's ServerIntegrationConfig.</summary>
    public class DriftfinConfigDto
    {
        /// <summary>Gets or sets the server-wide local (LAN) URL for reaching this Jellyfin server.</summary>
        [JsonPropertyName("localUrl")]
        public string LocalUrl { get; set; } = string.Empty;

        /// <summary>Gets or sets the Jellyseerr config.</summary>
        [JsonPropertyName("seerr")]
        public SeerrConfigDto Seerr { get; set; } = new();

        /// <summary>Gets or sets the Sonarr config.</summary>
        [JsonPropertyName("sonarr")]
        public ArrConfigDto Sonarr { get; set; } = new();

        /// <summary>Gets or sets the Radarr config.</summary>
        [JsonPropertyName("radarr")]
        public ArrConfigDto Radarr { get; set; } = new();

        /// <summary>Gets or sets the Trakt config.</summary>
        [JsonPropertyName("trakt")]
        public TraktConfigDto Trakt { get; set; } = new();

        /// <summary>Builds a DTO from stored plugin configuration.</summary>
        /// <param name="c">The plugin configuration.</param>
        /// <returns>The DTO.</returns>
        public static DriftfinConfigDto FromConfiguration(PluginConfiguration c) => new()
        {
            LocalUrl = c.LocalUrl,
            Seerr = new SeerrConfigDto { Enabled = c.SeerrEnabled, Url = c.SeerrUrl, ApiKey = c.SeerrApiKey },
            Sonarr = new ArrConfigDto { Enabled = c.SonarrEnabled, Url = c.SonarrUrl, ApiKey = c.SonarrApiKey },
            Radarr = new ArrConfigDto { Enabled = c.RadarrEnabled, Url = c.RadarrUrl, ApiKey = c.RadarrApiKey },
            Trakt = new TraktConfigDto
            {
                Enabled = c.TraktEnabled,
                ClientId = c.TraktClientId,
                ClientSecret = c.TraktClientSecret
            }
        };

        /// <summary>Copies DTO values into stored plugin configuration.</summary>
        /// <param name="c">The plugin configuration to mutate.</param>
        public void ApplyTo(PluginConfiguration c)
        {
            c.LocalUrl = LocalUrl;
            c.SeerrEnabled = Seerr.Enabled;
            c.SeerrUrl = Seerr.Url;
            c.SeerrApiKey = Seerr.ApiKey;
            c.SonarrEnabled = Sonarr.Enabled;
            c.SonarrUrl = Sonarr.Url;
            c.SonarrApiKey = Sonarr.ApiKey;
            c.RadarrEnabled = Radarr.Enabled;
            c.RadarrUrl = Radarr.Url;
            c.RadarrApiKey = Radarr.ApiKey;
            c.TraktEnabled = Trakt.Enabled;
            c.TraktClientId = Trakt.ClientId;
            c.TraktClientSecret = Trakt.ClientSecret;
        }
    }

    /// <summary>Jellyseerr config (URL + API key).</summary>
    public class SeerrConfigDto
    {
        /// <summary>Gets or sets a value indicating whether the integration is enabled.</summary>
        [JsonPropertyName("enabled")]
        public bool Enabled { get; set; }

        /// <summary>Gets or sets the base URL.</summary>
        [JsonPropertyName("url")]
        public string Url { get; set; } = string.Empty;

        /// <summary>Gets or sets the API key.</summary>
        [JsonPropertyName("apiKey")]
        public string ApiKey { get; set; } = string.Empty;
    }

    /// <summary>Shared shape for Sonarr/Radarr (base URL + API key).</summary>
    public class ArrConfigDto
    {
        /// <summary>Gets or sets a value indicating whether the integration is enabled.</summary>
        [JsonPropertyName("enabled")]
        public bool Enabled { get; set; }

        /// <summary>Gets or sets the base URL.</summary>
        [JsonPropertyName("url")]
        public string Url { get; set; } = string.Empty;

        /// <summary>Gets or sets the API key.</summary>
        [JsonPropertyName("apiKey")]
        public string ApiKey { get; set; } = string.Empty;
    }

    /// <summary>Trakt application credentials (client id + secret).</summary>
    public class TraktConfigDto
    {
        /// <summary>Gets or sets a value indicating whether the integration is enabled.</summary>
        [JsonPropertyName("enabled")]
        public bool Enabled { get; set; }

        /// <summary>Gets or sets the Trakt application client id.</summary>
        [JsonPropertyName("clientId")]
        public string ClientId { get; set; } = string.Empty;

        /// <summary>Gets or sets the Trakt application client secret.</summary>
        [JsonPropertyName("clientSecret")]
        public string ClientSecret { get; set; } = string.Empty;
    }
}
