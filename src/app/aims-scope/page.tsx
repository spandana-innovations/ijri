import { LegalPage, H } from "@/lib/legal";
import { IconLayers } from "@/lib/icons";
export default function AimsScope() {
  return (
    <LegalPage eyebrow="Aims & Scope" title="Aims & Scope" icon={<IconLayers size={22} />}>
      <p>IJRI aims to advance rigorous, original scholarship and to make it accessible to researchers, practitioners, and policymakers. As a multidisciplinary journal, it welcomes work that is methodologically sound and of clear significance to its field.</p>
      <H>Subject areas</H>
      <p>The journal publishes across areas including, but not limited to, computer and information science, medicine and public health, engineering, economics and management, materials science, and the social sciences.</p>
      <H>Article types</H>
      <p>Original research articles, systematic reviews, and scholarly commentary are considered. All submissions must be prepared in accordance with the journal&rsquo;s guidelines for authors and undergo double-blind peer review.</p>
    </LegalPage>
  );
}
