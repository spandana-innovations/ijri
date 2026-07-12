import { LegalPage, H } from "@/lib/legal";
import { IconLock } from "@/lib/icons";
export default function Privacy() {
  return (
    <LegalPage eyebrow="Privacy" title="Privacy Policy" icon={<IconLock size={22} />}>
      <p>This policy explains how IJRI handles personal information collected through ijrein.org.</p>
      <H>Information we collect</H>
      <p>We collect the information you provide when you register an account or submit a manuscript, such as your name, email address, and affiliation. We also collect limited technical information necessary to operate the site securely.</p>
      <H>How we use it</H>
      <p>Personal information is used to manage accounts, process submissions and subscriptions, and communicate with authors, reviewers, and subscribers. We do not sell personal information.</p>
      <H>Your rights</H>
      <p>You may request access to, correction of, or deletion of your personal information by contacting the editorial office.</p>
    </LegalPage>
  );
}
