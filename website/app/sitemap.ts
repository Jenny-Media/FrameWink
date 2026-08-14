import type { MetadataRoute } from "next";

export default function sitemap(): MetadataRoute.Sitemap {
  const updated = new Date("2026-08-14T00:00:00-04:00");
  return ["", "/privacy", "/support", "/terms"].map((path) => ({
    url: `https://frame.jenny.media${path}`,
    lastModified: updated,
    changeFrequency: path ? "monthly" as const : "weekly" as const,
    priority: path ? 0.7 : 1,
  }));
}
