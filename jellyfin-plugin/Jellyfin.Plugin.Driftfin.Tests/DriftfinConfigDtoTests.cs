using Jellyfin.Plugin.Driftfin.Api;
using Jellyfin.Plugin.Driftfin.Configuration;
using Xunit;

namespace Jellyfin.Plugin.Driftfin.Tests
{
    public class DriftfinConfigDtoTests
    {
        [Fact]
        public void FromConfiguration_CopiesEveryIntegrationField()
        {
            var config = new PluginConfiguration
            {
                SeerrEnabled = true,
                SeerrUrl = "https://seerr.example.com",
                SeerrApiKey = "seerr-key",
                SonarrEnabled = true,
                SonarrUrl = "https://sonarr.example.com",
                SonarrApiKey = "sonarr-key",
                RadarrEnabled = false,
                RadarrUrl = "https://radarr.example.com",
                RadarrApiKey = "radarr-key",
                TraktEnabled = true,
                TraktClientId = "trakt-client-id",
                TraktClientSecret = "trakt-client-secret",
            };

            var dto = DriftfinConfigDto.FromConfiguration(config);

            Assert.True(dto.Seerr.Enabled);
            Assert.Equal("https://seerr.example.com", dto.Seerr.Url);
            Assert.Equal("seerr-key", dto.Seerr.ApiKey);

            Assert.True(dto.Sonarr.Enabled);
            Assert.Equal("https://sonarr.example.com", dto.Sonarr.Url);
            Assert.Equal("sonarr-key", dto.Sonarr.ApiKey);

            Assert.False(dto.Radarr.Enabled);
            Assert.Equal("https://radarr.example.com", dto.Radarr.Url);
            Assert.Equal("radarr-key", dto.Radarr.ApiKey);

            Assert.True(dto.Trakt.Enabled);
            Assert.Equal("trakt-client-id", dto.Trakt.ClientId);
            Assert.Equal("trakt-client-secret", dto.Trakt.ClientSecret);
        }

        [Fact]
        public void ApplyTo_RoundTripsThroughFromConfiguration()
        {
            var original = new PluginConfiguration
            {
                SeerrEnabled = true,
                SeerrUrl = "https://seerr.example.com",
                SeerrApiKey = "seerr-key",
                SonarrEnabled = false,
                SonarrUrl = "https://sonarr.example.com",
                SonarrApiKey = "sonarr-key",
                RadarrEnabled = true,
                RadarrUrl = "https://radarr.example.com",
                RadarrApiKey = "radarr-key",
                TraktEnabled = false,
                TraktClientId = "trakt-client-id",
                TraktClientSecret = "trakt-client-secret",
            };

            var dto = DriftfinConfigDto.FromConfiguration(original);

            var target = new PluginConfiguration();
            dto.ApplyTo(target);

            Assert.Equal(original.SeerrEnabled, target.SeerrEnabled);
            Assert.Equal(original.SeerrUrl, target.SeerrUrl);
            Assert.Equal(original.SeerrApiKey, target.SeerrApiKey);
            Assert.Equal(original.SonarrEnabled, target.SonarrEnabled);
            Assert.Equal(original.SonarrUrl, target.SonarrUrl);
            Assert.Equal(original.SonarrApiKey, target.SonarrApiKey);
            Assert.Equal(original.RadarrEnabled, target.RadarrEnabled);
            Assert.Equal(original.RadarrUrl, target.RadarrUrl);
            Assert.Equal(original.RadarrApiKey, target.RadarrApiKey);
            Assert.Equal(original.TraktEnabled, target.TraktEnabled);
            Assert.Equal(original.TraktClientId, target.TraktClientId);
            Assert.Equal(original.TraktClientSecret, target.TraktClientSecret);
        }

        [Fact]
        public void FromConfiguration_DefaultsToEmptyDto()
        {
            var dto = DriftfinConfigDto.FromConfiguration(new PluginConfiguration());

            Assert.False(dto.Seerr.Enabled);
            Assert.Equal(string.Empty, dto.Seerr.Url);
            Assert.False(dto.Sonarr.Enabled);
            Assert.False(dto.Radarr.Enabled);
            Assert.False(dto.Trakt.Enabled);
        }
    }
}
