import type { Metadata } from "next";

export function pageMetadata(
  title: string,
  description: string,
  path: string,
): Metadata {
  return {
    title,
    description,
    alternates: { canonical: path },
    openGraph: {
      type: "website",
      locale: "en_US",
      url: path,
      siteName: "FrameWink",
      title: `${title} · FrameWink`,
      description,
      images: [],
    },
    twitter: {
      card: "summary",
      title: `${title} · FrameWink`,
      description,
      images: [],
    },
  };
}
