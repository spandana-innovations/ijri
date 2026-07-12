import { LegalPage, H } from "@/lib/legal";
import { IconDoc } from "@/lib/icons";
export default function Terms() {
  return (
    <LegalPage eyebrow="Terms" title="Terms & Conditions" icon={<IconDoc size={22} />}>
      <p>By using ijrein.org you agree to these terms.</p>
      <H>Use of the site</H>
      <p>Content is provided for scholarly and personal use. Automated harvesting, redistribution of full texts, or circumvention of access controls is prohibited.</p>
      <H>Accounts and subscriptions</H>
      <p>You are responsible for maintaining the confidentiality of your account. Subscription access is granted to the account holder and may not be shared.</p>
      <H>Disclaimer</H>
      <p>The views expressed in published articles are those of the authors and do not necessarily reflect those of the journal or its editorial board.</p>
    </LegalPage>
  );
}
