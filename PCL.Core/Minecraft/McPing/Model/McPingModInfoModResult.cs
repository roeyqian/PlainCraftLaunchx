using System.Text.Json.Serialization;

namespace PCL.Core.Minecraft.McPing.Model;

public record McPingModInfoModResult(
    [property: JsonPropertyName("modid")] string Id,
    [property: JsonPropertyName("version")] string Version);