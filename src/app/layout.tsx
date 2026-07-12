export const metadata = {
  title: "International Journal of Research and Innovation",
  description: "A multidisciplinary peer-reviewed research journal.",
};
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body style={{ margin: 0, fontFamily: "system-ui, sans-serif" }}>{children}</body>
    </html>
  );
}
