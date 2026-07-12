import { PrismaClient } from "@prisma/client";
const prisma = new PrismaClient();

const SECTIONS = [
  "Computer Science", "Medicine & Public Health", "Engineering",
  "Economics", "Materials Science", "Social Science",
];
const slug = (s: string) => s.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/(^-|-$)/g, "");

async function main() {
  for (const name of SECTIONS) {
    await prisma.section.upsert({
      where: { slug: slug(name) },
      update: {},
      create: { name, slug: slug(name) },
    });
  }

  await prisma.issue.upsert({
    where: { volume_number: { volume: 1, number: 1 } },
    update: { isCurrent: true },
    create: { volume: 1, number: 1, label: "July 2026", isCurrent: true, publishedAt: new Date() },
  });

  const staff = [
    { email: "admin@ijri.in", name: "IJRI Admin", role: "ADMIN" as const },
    { email: "snagaraj@iisc.ac.in", name: "Prof. S. Nagaraj", role: "CHIEF_EDITOR" as const, affiliation: "Indian Institute of Science" },
    { email: "arao@iisc.ac.in", name: "Dr. Ananya Rao", role: "EDITOR" as const, affiliation: "Indian Institute of Science" },
    { email: "riyer@iitm.ac.in", name: "Dr. Rohan Iyer", role: "EDITOR" as const, affiliation: "IIT Madras" },
  ];
  for (const u of staff) {
    await prisma.user.upsert({ where: { email: u.email }, update: { role: u.role }, create: u });
  }
  console.log("Seed complete: sections, current issue (Vol 1, Issue 1), staff users.");
}

main().catch((e) => { console.error(e); process.exit(1); }).finally(() => prisma.$disconnect());
