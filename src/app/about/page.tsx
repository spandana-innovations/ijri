import { LegalPage, H } from "@/lib/legal";
import { IconBook } from "@/lib/icons";
export default function About() {
  return (
    <LegalPage eyebrow="About" title="About the Journal" icon={<IconBook size={22} />}>
      <p>The International Journal of Research and Innovation (IJRI) is a multidisciplinary, double-blind peer-reviewed research journal. It publishes original research, reviews, and scholarly commentary across the sciences, engineering, management, and the social sciences.</p>
      <H>Peer review</H>
      <p>Every submission is evaluated under a double-blind process by members of the editorial board. Accepted articles are published by the Editor-in-Chief with the reviewing editors and bibliographic details recorded on each article.</p>
      <H>Access</H>
      <p>Abstracts and article metadata are freely available to all readers. Full texts are available to subscribers and to authorised members of the journal.</p>
      <H>Publisher</H>
      <p>IJRI is published online at ijrein.org. The journal maintains a permanent editorial office for all correspondence relating to submissions, subscriptions, and editorial policy.</p>
    </LegalPage>
  );
}
