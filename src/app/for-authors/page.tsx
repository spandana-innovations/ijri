import { T, Eyebrow } from "@/lib/ui";

const SECTIONS: { h: string; body: string; list?: string[] }[] = [
  { h: "Title", body: "The title must help researchers find and cite your article, so it should convey the meaning of the content precisely. Keep it appealing, concise, and clearly indicative of the subject matter presented." },
  { h: "Abstract", body: "The abstract should contain, specifically:", list: ["The stated purpose of the study or research", "A brief account of the methodology undertaken", "The findings of the study", "The conclusions of the research conducted", "Any trial registry name, registration number, or URL, as applicable"] },
  { h: "Keywords", body: "Keywords mirror the topic of the study and are mandatory; they allow identification of the core and principal concepts involved in the work." },
  { h: "Acknowledgements", body: "Credit must be acknowledged wherever it is due. Authors are required to follow the APA 7 style for referencing." },
  { h: "Author contributions statement", body: "State each author's contribution to the development of the article, whether the work has a single author or multiple authors." },
  { h: "Statements and declarations", body: "Declarations such as the 'No conflict of interest' statement must be signed by the sole author, or by each author in the case of multiple authors." },
];

export default function ForAuthors() {
  return (
    <main style={{ maxWidth: 760, margin: "0 auto", padding: "40px 20px" }}>
      <Eyebrow inverse>For Authors</Eyebrow>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(26px,4.4vw,38px)", margin: "14px 0 10px" }}>Guidelines for Authors</h1>
      <p style={{ fontFamily: T.serif, fontSize: 17, lineHeight: 1.55, color: "#333", margin: "0 0 26px" }}>
        Please prepare your manuscript according to the following requirements before submission. All submissions undergo double-blind peer review.
      </p>
      {SECTIONS.map((s) => (
        <section key={s.h} style={{ padding: "18px 0", borderTop: `1px solid ${T.rule}` }}>
          <h2 style={{ fontFamily: T.serif, fontSize: 21, margin: "0 0 8px" }}>{s.h}</h2>
          <p style={{ fontFamily: T.serif, fontSize: 16.5, lineHeight: 1.6, color: "#222", margin: 0 }}>{s.body}</p>
          {s.list && (
            <ul style={{ fontFamily: T.serif, fontSize: 16, lineHeight: 1.6, color: "#222", margin: "10px 0 0", paddingLeft: 22 }}>
              {s.list.map((li) => <li key={li} style={{ marginBottom: 4 }}>{li}</li>)}
            </ul>
          )}
        </section>
      ))}
      <p style={{ fontFamily: T.sans, fontSize: 12.5, color: T.muted, marginTop: 24, lineHeight: 1.6 }}>
        Referencing follows APA 7. Manuscripts are checked for similarity in line with UGC plagiarism guidelines before review.
      </p>
    </main>
  );
}
