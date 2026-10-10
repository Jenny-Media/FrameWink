import type { Metadata } from "next";

export const appStoreURL = "https://apps.apple.com/us/app/framewink/id6800849400";
export const duoProductPageURL = `${appStoreURL}?ppid=60c0e78e-a68c-4690-a87e-04b4fe6fd13a`;

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
