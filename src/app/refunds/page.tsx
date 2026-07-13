import { LegalPage, H } from "@/lib/legal";
import { IconScale } from "@/lib/icons";
export default function Refunds() {
  return (
    <LegalPage eyebrow="Refunds" title="Refund & Cancellation Policy" icon={<IconScale size={22} />}>
      <p>This policy governs refunds and cancellations for subscriptions and individual article purchases on ijrein.org.</p>
      <H>Subscriptions</H>
      <p>Subscriptions may be cancelled at any time; cancellation stops future renewals. A monthly subscription is refundable within 7 days of purchase if no full-text article or PDF has been accessed. Annual subscriptions are refundable on a pro-rata basis within 14 days of purchase, less any period already used, where no substantial access has occurred.</p>
      <H>Individual article purchases</H>
      <p>Because access to a purchased article is granted immediately, individual article purchases are non-refundable once the full text or PDF has been accessed. If a purchase was made in error and access has not occurred, contact the editorial office within 48 hours.</p>
      <H>Print subscriptions</H>
      <p>Print or print-and-digital subscriptions may be cancelled before an issue is dispatched. Once an issue has shipped, that issue is non-refundable, though future issues may be cancelled.</p>
      <H>How to request a refund</H>
      <p>Refund requests should be sent to the editorial office at editor@ijrein.org with the account email and transaction reference. Approved refunds are returned to the original payment method within 7–10 business days.</p>
      <p style={{ fontSize: 14, color: "#6b6b6b" }}>Please align these terms with the requirements of your payment gateway (for example Razorpay or Stripe) before enabling paid subscriptions.</p>
    </LegalPage>
  );
}
