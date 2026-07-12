export default function Home() {
  return (
    <main style={{ maxWidth: 640, margin: "80px auto", padding: "0 20px" }}>
      <h1>International Journal of Research and Innovation</h1>
      <p>Backend is running. Health check: <a href="/api/health">/api/health</a></p>
      <p style={{ color: "#666" }}>The reader UI (from the prototype) gets ported into this app next.</p>
    </main>
  );
}
