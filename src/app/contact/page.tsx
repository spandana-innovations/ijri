import { LegalPage, H } from "@/lib/legal";
import { IconMail } from "@/lib/icons";
export default function Contact() {
  return (
    <LegalPage eyebrow="Contact" title="Contact" icon={<IconMail size={22} />}>
      <p>All correspondence relating to submissions, subscriptions, and editorial policy should be directed to the journal&rsquo;s editorial office.</p>
      <H>Editorial office</H>
      <p>Email: editor@ijrein.org<br />Web: ijrein.org</p>
      <p style={{ fontFamily: "inherit", fontSize: 14, color: "#6b6b6b" }}>Please update this address with your official editorial office contact and postal address before applying for the ISSN, as the ISSN office requires a verifiable publisher contact.</p>
    </LegalPage>
  );
}
