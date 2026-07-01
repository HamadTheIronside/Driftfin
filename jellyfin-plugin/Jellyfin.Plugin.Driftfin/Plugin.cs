using System;
using System.Collections.Generic;
using System.Globalization;
using Jellyfin.Plugin.Driftfin.Configuration;
using MediaBrowser.Common.Configuration;
using MediaBrowser.Common.Plugins;
using MediaBrowser.Model.Plugins;
using MediaBrowser.Model.Serialization;

namespace Jellyfin.Plugin.Driftfin
{
    /// <summary>
    /// The Driftfin server plugin. Stores shared client integration settings
    /// (Jellyseerr, Sonarr, Radarr, Trakt) so Driftfin clients can pull one
    /// server-managed configuration instead of each user configuring their own.
    /// </summary>
    public class Plugin : BasePlugin<PluginConfiguration>, IHasWebPages
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="Plugin"/> class.
        /// </summary>
        /// <param name="applicationPaths">Instance of the <see cref="IApplicationPaths"/> interface.</param>
        /// <param name="xmlSerializer">Instance of the <see cref="IXmlSerializer"/> interface.</param>
        public Plugin(IApplicationPaths applicationPaths, IXmlSerializer xmlSerializer)
            : base(applicationPaths, xmlSerializer)
        {
            Instance = this;
        }

        /// <summary>Gets the current plugin instance.</summary>
        public static Plugin? Instance { get; private set; }

        /// <inheritdoc />
        public override string Name => "Driftfin";

        /// <inheritdoc />
        // Stable id — never change this; clients and Jellyfin track the plugin by it.
        public override Guid Id => Guid.Parse("a3b1e7c4-1d2f-4b8a-9c6e-7f0d2e5a9b11");

        /// <inheritdoc />
        public override string Description =>
            "Centralizes Driftfin client integration settings (Jellyseerr, Sonarr, Radarr, Trakt) on the server.";

        /// <inheritdoc />
        public IEnumerable<PluginPageInfo> GetPages()
        {
            return new[]
            {
                new PluginPageInfo
                {
                    Name = Name,
                    EmbeddedResourcePath = string.Format(
                        CultureInfo.InvariantCulture,
                        "{0}.Configuration.configPage.html",
                        GetType().Namespace)
                }
            };
        }
    }
}
