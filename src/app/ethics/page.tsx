import { LegalPage, H } from "@/lib/legal";
import { IconShield } from "@/lib/icons";
export default function Ethics() {
  return (
    <LegalPage eyebrow="Publication Ethics" title="Publication Ethics & Malpractice Statement" icon={<IconShield size={22} />}>
      <p>IJRI is committed to upholding the highest standards of publication ethics and follows the principles set out by the Committee on Publication Ethics (COPE).</p>
      <H>Authors</H>
      <p>Authors must ensure that their work is original, that all sources are properly cited, and that the manuscript has not been published elsewhere or is under consideration by another journal. All listed authors must have made a genuine contribution, and any conflicts of interest must be declared.</p>
      <H>Plagiarism</H>
      <p>Submissions are screened for similarity in line with UGC plagiarism guidelines. Manuscripts found to contain plagiarised or fabricated content are rejected, and published articles found in violation are subject to correction or retraction.</p>
      <H>Editors and reviewers</H>
      <p>Editors evaluate manuscripts solely on scholarly merit, without regard to the authors&rsquo; identity, and maintain the confidentiality of the review process. Reviewers must disclose competing interests and decline review where a conflict exists.</p>
      <H>Corrections and retractions</H>
      <p>The journal will publish corrections, expressions of concern, or retractions where warranted, in a transparent and timely manner.</p>
    </LegalPage>
  );
}
