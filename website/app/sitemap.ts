import type { MetadataRoute } from "next";

export default function sitemap(): MetadataRoute.Sitemap {
  return ["", "/privacy", "/support", "/terms"].map((path) => ({
    url: `https://frame.jenny.media${path}`,
    changeFrequency: path ? "monthly" as const : "weekly" as const,
    priority: path ? 0.7 : 1,
  }));
}
