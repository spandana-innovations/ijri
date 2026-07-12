import { LegalPage, H } from "@/lib/legal";
import { IconScale } from "@/lib/icons";
export default function Copyright() {
  return (
    <LegalPage eyebrow="Copyright" title="Copyright & Licensing" icon={<IconScale size={22} />}>
      <p>Articles published in IJRI are protected by copyright. All rights are reserved unless otherwise stated.</p>
      <H>Rights</H>
      <p>Copyright in each article is held by the respective authors and the journal as recorded at publication. Full texts and PDFs are made available to subscribers and authorised users; redistribution without permission is not permitted.</p>
      <H>Permitted use</H>
      <p>Readers may cite published articles with appropriate attribution, including the journal name, volume, issue, and page numbers as shown on each article. Requests for reuse beyond fair dealing should be directed to the editorial office.</p>
    </LegalPage>
  );
}
