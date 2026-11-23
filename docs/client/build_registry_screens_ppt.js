const pptxgen = require("pptxgenjs");
const path = require("path");

const ASSETS = path.join(__dirname, "ppt_assets");
const OUT = path.join(__dirname, "The_Registry_App_Screens.pptx");

const THEME = {
  name: "Regiday Client",
  headFontFace: "Calibri",
  bodyFontFace: "Calibri",
  colors: {
    dk1: "14213D",
    lt1: "FFFFFF",
    dk2: "1B2A4A",
    lt2: "F4F1EC",
    accent1: "4F46E5",
    accent2: "0F766E",
    accent3: "334155",
    accent4: "94A3B8",
    accent5: "C7D2FE",
    accent6: "99F6E4",
    hlink: "4F46E5",
    folHlink: "0F766E",
  },
};

const C = {
  navy: "14213D",
  ink: "1B2A4A",
  muted: "475569",
  soft: "64748B",
  cream: "F7F5F1",
  white: "FFFFFF",
  indigo: "4F46E5",
  teal: "0F766E",
  card: "FFFFFF",
  line: "E2E8F0",
  softIndigo: "EEF2FF",
  softTeal: "F0FDFA",
};

let ShapeType;

function phoneFrame(slide, imgPath, x, y, w, h) {
  slide.addShape(ShapeType.roundRect, {
    x: x - 0.04,
    y: y - 0.04,
    w: w + 0.08,
    h: h + 0.08,
    fill: { color: C.navy },
    shadow: { type: "outer", color: "000000", blur: 12, offset: 4, opacity: 0.18 },
    rectRadius: 0.18,
  });
  slide.addImage({
    path: imgPath,
    x,
    y,
    w,
    h,
    sizing: { type: "cover", w, h },
  });
}

function addFooter(slide, page, total) {
  slide.addText("The Registry  ·  App Screens Overview", {
    x: 0.5,
    y: 5.28,
    w: 7.5,
    h: 0.24,
    fontSize: 10,
    color: C.soft,
    margin: 0,
    isTextBox: true,
  });
  slide.addText(`${page} / ${total}`, {
    x: 8.6,
    y: 5.28,
    w: 0.9,
    h: 0.24,
    fontSize: 10,
    color: C.soft,
    align: "right",
    margin: 0,
    isTextBox: true,
  });
}

function sectionChip(slide, label) {
  slide.addShape(ShapeType.roundRect, {
    x: 0.5,
    y: 0.28,
    w: 1.7,
    h: 0.28,
    fill: { color: C.softIndigo },
    rectRadius: 0.08,
  });
  slide.addText(label, {
    x: 0.5,
    y: 0.28,
    w: 1.7,
    h: 0.28,
    fontSize: 10,
    bold: true,
    color: C.indigo,
    align: "center",
    valign: "middle",
    margin: 0,
    isTextBox: true,
  });
}

async function main() {
  const pres = new pptxgen();
  ShapeType = pres.ShapeType;
  pres.defineLayout({ name: "REG_16x9", width: 10, height: 5.625 });
  pres.layout = "REG_16x9";
  pres.author = "Shivam";
  pres.title = "The Registry — App Screens Overview";
  pres.subject = "Client walkthrough of built screens and features";
  // Avoid & in company — OOXML unescaped
  pres.company = "Regiday";
  pres.theme = {
    headFontFace: THEME.headFontFace,
    bodyFontFace: THEME.bodyFontFace,
  };

  const TOTAL = 17;
  let page = 0;
  const next = () => ++page;

  // 1. Title
  {
    const slide = pres.addSlide();
    next();
    slide.addShape(ShapeType.rect, {
      x: 0, y: 0, w: 10, h: 5.625, fill: { color: C.navy },
    });
    slide.addShape(ShapeType.ellipse, {
      x: 7.2, y: -1.2, w: 4.5, h: 4.5, fill: { color: "1E2F5A" },
    });
    slide.addShape(ShapeType.ellipse, {
      x: -1.4, y: 3.4, w: 3.8, h: 3.8, fill: { color: "0F766E" }, transparency: 78,
    });
    slide.addImage({
      path: path.join(ASSETS, "00_logo.png"),
      x: 0.55, y: 1.35, w: 0.95, h: 0.95,
    });
    slide.addText("THE REGISTRY", {
      x: 0.55, y: 2.45, w: 7, h: 0.55,
      fontSize: 36, bold: true, color: C.white, margin: 0, isTextBox: true,
    });
    slide.addText("Complete app screens walkthrough for client review", {
      x: 0.55, y: 3.05, w: 7, h: 0.35,
      fontSize: 16, color: "C7D2FE", margin: 0, isTextBox: true,
    });
    slide.addText("Documents  ·  Subscriptions  ·  Smart Scan  ·  Backup  ·  App Lock", {
      x: 0.55, y: 3.55, w: 8, h: 0.3,
      fontSize: 13, color: "94A3B8", margin: 0, isTextBox: true,
    });
    slide.addText("Prepared for Lahcene  ·  November 2026", {
      x: 0.55, y: 5.05, w: 6, h: 0.25,
      fontSize: 12, color: "94A3B8", margin: 0, isTextBox: true,
    });
  }

  // 2. Agenda / What is built
  {
    const slide = pres.addSlide(); next();
    slide.addShape(ShapeType.rect, {
      x: 0, y: 0, w: 10, h: 5.625, fill: { color: C.cream },
    });
    sectionChip(slide, "Overview");
    slide.addText("What this build includes", {
      x: 0.5, y: 0.7, w: 9, h: 0.45,
      fontSize: 28, bold: true, color: C.navy, margin: 0, isTextBox: true,
    });
    const items = [
      ["01", "Home & navigation", "Dashboard with search, attention queue, and bottom dock"],
      ["02", "Documents wallet", "Add, scan, review, renew, and store IDs/passports/certs"],
      ["03", "Subscriptions", "Add plans, monthly snapshot, cancel flow, calendar view"],
      ["04", "Optional helpers", "Gmail detection + Firebase AI scan (optional, not required)"],
      ["05", "Privacy & security", "Local storage, encrypted backup, biometric app lock"],
    ];
    items.forEach((it, i) => {
      const y = 1.35 + i * 0.7;
      slide.addShape(ShapeType.roundRect, {
        x: 0.5, y, w: 9, h: 0.58,
        fill: { color: C.white },
        shadow: { type: "outer", color: "000000", blur: 6, offset: 2, opacity: 0.08 },
        rectRadius: 0.1,
      });
      slide.addText(it[0], {
        x: 0.7, y: y + 0.08, w: 0.7, h: 0.42,
        fontSize: 18, bold: true, color: C.indigo, valign: "middle", margin: 0, isTextBox: true,
      });
      slide.addText(it[1], {
        x: 1.5, y: y + 0.05, w: 7.7, h: 0.28,
        fontSize: 15, bold: true, color: C.ink, margin: 0, isTextBox: true,
      });
      slide.addText(it[2], {
        x: 1.5, y: y + 0.3, w: 7.7, h: 0.22,
        fontSize: 12, color: C.muted, margin: 0, isTextBox: true,
      });
    });
    addFooter(slide, page, TOTAL);
  }

  // 3. Local-first note / API answer
  {
    const slide = pres.addSlide(); next();
    slide.addShape(ShapeType.rect, {
      x: 0, y: 0, w: 10, h: 5.625, fill: { color: C.cream },
    });
    sectionChip(slide, "Architecture");
    slide.addText("Local-first by design", {
      x: 0.5, y: 0.7, w: 9, h: 0.4,
      fontSize: 28, bold: true, color: C.navy, margin: 0, isTextBox: true,
    });
    slide.addText("Core app works fully offline. Optional cloud APIs are convenience features only.", {
      x: 0.5, y: 1.15, w: 9, h: 0.3,
      fontSize: 14, color: C.muted, margin: 0, isTextBox: true,
    });

    const cards = [
      {
        title: "Always local (no API)",
        bg: C.softTeal,
        titleColor: C.teal,
        points: [
          "SQLite storage on device",
          "Manual add document / subscription",
          "Reminders via device notifications",
          "Encrypted backup (.rgry) export/import",
          "Biometric / passcode App Lock",
        ],
      },
      {
        title: "Optional helpers only",
        bg: C.softIndigo,
        titleColor: C.indigo,
        points: [
          "Firebase AI: image → form fields",
          "Gmail API: detect billing emails",
          "User can skip both features",
          "App remains usable without them",
          "Can be removed if required",
        ],
      },
    ];
    cards.forEach((card, i) => {
      const x = 0.5 + i * 4.7;
      slide.addShape(ShapeType.roundRect, {
        x, y: 1.65, w: 4.4, h: 3.2,
        fill: { color: C.white },
        shadow: { type: "outer", color: "000000", blur: 8, offset: 2, opacity: 0.1 },
        rectRadius: 0.12,
      });
      slide.addShape(ShapeType.roundRect, {
        x: x + 0.25, y: 1.9, w: 3.9, h: 0.42,
        fill: { color: card.bg }, rectRadius: 0.08,
      });
      slide.addText(card.title, {
        x: x + 0.25, y: 1.9, w: 3.9, h: 0.42,
        fontSize: 14, bold: true, color: card.titleColor, align: "center",
        valign: "middle", margin: 0, isTextBox: true,
      });
      card.points.forEach((p, pi) => {
        slide.addText(p, {
          x: x + 0.4, y: 2.55 + pi * 0.38, w: 3.7, h: 0.32,
          fontSize: 13, color: C.ink, bullet: true, margin: 0, isTextBox: true,
        });
      });
    });
    addFooter(slide, page, TOTAL);
  }

  // Helper for phone + text slides
  function phoneTextSlide({ chip, title, subtitle, bullets, img, phoneRight = true }) {
    const slide = pres.addSlide(); next();
    slide.addShape(ShapeType.rect, {
      x: 0, y: 0, w: 10, h: 5.625, fill: { color: C.cream },
    });
    sectionChip(slide, chip);
    const textX = phoneRight ? 0.5 : 4.2;
    const phoneX = phoneRight ? 6.85 : 0.45;
    slide.addText(title, {
      x: textX, y: 0.7, w: 5.8, h: 0.45,
      fontSize: 24, bold: true, color: C.navy, margin: 0, isTextBox: true,
    });
    if (subtitle) {
      slide.addText(subtitle, {
        x: textX, y: 1.2, w: 5.8, h: 0.45,
        fontSize: 13, color: C.muted, margin: 0, isTextBox: true,
      });
    }
    bullets.forEach((b, i) => {
      const y = 1.8 + i * 0.48;
      slide.addShape(ShapeType.roundRect, {
        x: textX, y, w: 0.18, h: 0.18,
        fill: { color: C.indigo }, rectRadius: 0.04,
      });
      slide.addText(b, {
        x: textX + 0.35, y: y - 0.05, w: 5.4, h: 0.42,
        fontSize: 14, color: C.ink, margin: 0, isTextBox: true,
      });
    });
    phoneFrame(slide, path.join(ASSETS, img), phoneX, 0.45, 2.55, 4.55);
    addFooter(slide, page, TOTAL);
  }

  phoneTextSlide({
    chip: "Home",
    title: "Home screen",
    subtitle: "First view after launch — documents, subscriptions, and what needs attention.",
    bullets: [
      "Date header and search across the registry",
      "Attention banner + Documents / Subscriptions cards",
      "Coming up list with type filters",
      "Bottom dock: Home · Documents · + · Subscriptions · Profile",
    ],
    img: "02_home.png",
  });

  phoneTextSlide({
    chip: "Home",
    title: "Empty / first launch",
    subtitle: "Clear empty state that guides the first action.",
    bullets: [
      "Value message: documents + subscriptions together",
      "Primary CTA: Add your first document",
      "Secondary CTA: Add a subscription",
      "Highlights: important dates and renewal reviews",
    ],
    img: "01_launch_home_empty.png",
  });

  phoneTextSlide({
    chip: "Documents",
    title: "Add document — source",
    subtitle: "Step 1 of guided setup: choose how to capture the document.",
    bullets: [
      "Scan document: Take photo or Choose from gallery",
      "Enter manually: type fields step by step",
      "Nothing is saved until the user confirms",
      "AI scan is optional — manual entry always works",
    ],
    img: "03_add_document_source.png",
  });

  phoneTextSlide({
    chip: "Documents",
    title: "Documents wallet",
    subtitle: "Saved documents stay on device with status and expiry.",
    bullets: [
      "Search + filters: All / Action needed / Upcoming / Active / Overdue",
      "Document cards show type, title, status, and expiry",
      "Toast confirms local save: “saved on this device”",
      "Add Document CTA + floating + action",
    ],
    img: "07_documents_list.png",
  });

  phoneTextSlide({
    chip: "Documents",
    title: "Document detail",
    subtitle: "Full record view with renewal history and actions.",
    bullets: [
      "Digital pass style summary for the document",
      "Important dates and reminder preferences",
      "Record renewal without losing history",
      "Edit or delete from the same screen",
    ],
    img: "08_document_detail.png",
  });

  // OCR / AI slide with two phones
  {
    const slide = pres.addSlide(); next();
    slide.addShape(ShapeType.rect, {
      x: 0, y: 0, w: 10, h: 5.625, fill: { color: C.cream },
    });
    sectionChip(slide, "Smart Scan");
    slide.addText("Smart document entry (optional)", {
      x: 0.5, y: 0.7, w: 9, h: 0.4,
      fontSize: 24, bold: true, color: C.navy, margin: 0, isTextBox: true,
    });
    phoneFrame(slide, path.join(ASSETS, "03b_add_document_scan.png"), 0.45, 1.25, 2.2, 3.75);
    phoneFrame(slide, path.join(ASSETS, "21_ocr_review.png"), 2.9, 1.25, 2.2, 3.75);
    slide.addShape(ShapeType.roundRect, {
      x: 5.4, y: 1.25, w: 4.1, h: 3.75,
      fill: { color: C.white },
      shadow: { type: "outer", color: "000000", blur: 8, offset: 2, opacity: 0.1 },
      rectRadius: 0.12,
    });
    slide.addText("How it works", {
      x: 5.65, y: 1.5, w: 3.6, h: 0.35,
      fontSize: 16, bold: true, color: C.navy, margin: 0, isTextBox: true,
    });
    const aiPoints = [
      "User uploads / captures images",
      "Optional Firebase AI reads visible text",
      "Dynamic fields are pre-filled for review",
      "User edits before saving",
      "If Firebase is unavailable, manual entry still works",
    ];
    aiPoints.forEach((p, i) => {
      slide.addText(p, {
        x: 5.65, y: 2.05 + i * 0.45, w: 3.6, h: 0.4,
        fontSize: 13, color: C.ink, bullet: true, margin: 0, isTextBox: true,
      });
    });
    addFooter(slide, page, TOTAL);
  }

  phoneTextSlide({
    chip: "Subscriptions",
    title: "Subscriptions screen",
    subtitle: "Track active plans, estimated monthly cost, and status filters.",
    bullets: [
      "Monthly snapshot with estimated cost",
      "Filters: All / Action needed / Upcoming / Active / Overdue / Cancelled",
      "Plan cards with amount and cadence",
      "Add Subscription + quick + action",
    ],
    img: "11_subscriptions_list.png",
  });

  phoneTextSlide({
    chip: "Subscriptions",
    title: "Add subscription + detail",
    subtitle: "Guided billing form, review, then a dedicated plan detail page.",
    bullets: [
      "Name, amount, currency, billing cycle",
      "Reminder preferences before renewals",
      "Review screen before local save",
      "Detail screen for edit / cancel / history",
    ],
    img: "09_add_subscription.png",
  });

  // Gmail + cancelled combo (gmail without screenshot)
  {
    const slide = pres.addSlide(); next();
    slide.addShape(ShapeType.rect, {
      x: 0, y: 0, w: 10, h: 5.625, fill: { color: C.cream },
    });
    sectionChip(slide, "Subscriptions");
    slide.addText("Gmail detection & cancelled plans", {
      x: 0.5, y: 0.7, w: 5.8, h: 0.4,
      fontSize: 22, bold: true, color: C.navy, margin: 0, isTextBox: true,
    });
    slide.addShape(ShapeType.roundRect, {
      x: 0.5, y: 1.25, w: 5.9, h: 3.55,
      fill: { color: C.white },
      shadow: { type: "outer", color: "000000", blur: 8, offset: 2, opacity: 0.1 },
      rectRadius: 0.12,
    });
    slide.addText("Detect from Gmail (optional)", {
      x: 0.75, y: 1.45, w: 5.4, h: 0.32,
      fontSize: 15, bold: true, color: C.indigo, margin: 0, isTextBox: true,
    });
    const gmailPts = [
      "Button at top of Subscriptions → Connect Gmail",
      "Read-only OAuth (gmail.readonly)",
      "Scans billing / renewal / trial emails on device flow",
      "Shows Detected Subscriptions candidates to accept",
      "User can disconnect anytime; not required to use the app",
      "Also supports bank CSV import as a non-Gmail alternative",
    ];
    gmailPts.forEach((p, i) => {
      slide.addText(p, {
        x: 0.75, y: 1.9 + i * 0.4, w: 5.4, h: 0.38,
        fontSize: 13, color: C.ink, bullet: true, margin: 0, isTextBox: true,
      });
    });
    phoneFrame(slide, path.join(ASSETS, "13_cancelled.png"), 6.85, 0.55, 2.55, 4.45);
    addFooter(slide, page, TOTAL);
  }

  phoneTextSlide({
    chip: "Profile",
    title: "Profile — backup & restore",
    subtitle: "No cloud account. Records stay private on the device.",
    bullets: [
      "Export encrypted backup (.rgry) with user password",
      "Import backup after reinstall / new device",
      "App Lock with biometrics or device passcode",
    ],
    img: "14_profile_no_pro.png",
  });

  phoneTextSlide({
    chip: "Security",
    title: "Export backup",
    subtitle: "Password-protected archive you control — password is never stored by the app.",
    bullets: [
      "Includes documents, subscriptions, custom fields",
      "Includes renewal history, reminders, amounts, images",
      "Choose password → Choose where to save",
      "Lost password = backup cannot be restored",
    ],
    img: "15_export_backup.png",
  });

  // Notifications + CSV
  {
    const slide = pres.addSlide(); next();
    slide.addShape(ShapeType.rect, {
      x: 0, y: 0, w: 10, h: 5.625, fill: { color: C.cream },
    });
    sectionChip(slide, "More modules");
    slide.addText("Notifications & CSV import", {
      x: 0.5, y: 0.7, w: 9, h: 0.35,
      fontSize: 22, bold: true, color: C.navy, margin: 0, isTextBox: true,
    });
    const duo = [
      ["18_notification.png", "Local reminders", "Device notifications for expiries and renewals — no push server"],
      ["19_csv_import.png", "CSV import", "Import bank statement charges to discover subscriptions"],
    ];
    duo.forEach((t, i) => {
      const x = 1.5 + i * 3.8;
      phoneFrame(slide, path.join(ASSETS, t[0]), x + 0.45, 1.2, 1.95, 3.35);
      slide.addText(t[1], {
        x, y: 4.65, w: 2.9, h: 0.28,
        fontSize: 13, bold: true, color: C.navy, align: "center", margin: 0, isTextBox: true,
      });
      slide.addText(t[2], {
        x, y: 4.92, w: 2.9, h: 0.3,
        fontSize: 10, color: C.muted, align: "center", margin: 0, isTextBox: true,
      });
    });
    addFooter(slide, page, TOTAL);
  }

  // Billing slide for client
  {
    const slide = pres.addSlide(); next();
    slide.addShape(ShapeType.rect, {
      x: 0, y: 0, w: 10, h: 5.625, fill: { color: C.cream },
    });
    sectionChip(slide, "Billing");
    slide.addText("Will Firebase / Gmail APIs cost money?", {
      x: 0.5, y: 0.7, w: 9, h: 0.4,
      fontSize: 24, bold: true, color: C.navy, margin: 0, isTextBox: true,
    });

    const billCards = [
      {
        title: "Firebase AI (document scan)",
        lines: [
          "Firebase AI Logic SDK itself is free.",
          "Uses Gemini Developer API behind it.",
          "Free tier available on Spark plan (no billing card) with rate limits.",
          "Paid Blaze plan only if you need higher volume / more models.",
          "At our expected scan volume, free tier is usually enough.",
        ],
      },
      {
        title: "Gmail API (subscription detect)",
        lines: [
          "Standard Gmail API use is free today.",
          "App uses read-only access for billing emails.",
          "Very large daily quotas; consumer apps rarely hit them.",
          "Google may bill only above huge thresholds later in 2026.",
          "For this app’s usage, expected cost is $0.",
        ],
      },
    ];
    billCards.forEach((card, i) => {
      const x = 0.5 + i * 4.7;
      slide.addShape(ShapeType.roundRect, {
        x, y: 1.3, w: 4.4, h: 3.5,
        fill: { color: C.white },
        shadow: { type: "outer", color: "000000", blur: 8, offset: 2, opacity: 0.1 },
        rectRadius: 0.12,
      });
      slide.addText(card.title, {
        x: x + 0.25, y: 1.5, w: 3.9, h: 0.4,
        fontSize: 15, bold: true, color: C.indigo, margin: 0, isTextBox: true,
      });
      card.lines.forEach((line, li) => {
        slide.addText(line, {
          x: x + 0.25, y: 2.05 + li * 0.48, w: 3.9, h: 0.45,
          fontSize: 12, color: C.ink, bullet: true, margin: 0, isTextBox: true,
        });
      });
    });
    addFooter(slide, page, TOTAL);
  }

  // Closing / next steps
  {
    const slide = pres.addSlide();
    next();
    slide.addShape(ShapeType.rect, {
      x: 0, y: 0, w: 10, h: 5.625, fill: { color: C.navy },
    });
    slide.addText("Next steps", {
      x: 0.6, y: 1.2, w: 8.5, h: 0.5,
      fontSize: 32, bold: true, color: C.white, margin: 0, isTextBox: true,
    });
    const nexts = [
      "Review this screen walkthrough (no APK required)",
      "Confirm whether optional Firebase AI + Gmail helpers should stay, or be removed for a 100% offline build",
      "Share feedback on screens / copy / flows — we will implement changes",
      "If helpers stay: share Firebase project access so credentials move off the temporary personal project",
    ];
    nexts.forEach((n, i) => {
      slide.addText(`${i + 1}.  ${n}`, {
        x: 0.6, y: 2.0 + i * 0.55, w: 8.6, h: 0.45,
        fontSize: 15, color: "C7D2FE", margin: 0, isTextBox: true,
      });
    });
  }

  await pres.writeFile({ fileName: OUT });
  console.log("Wrote", OUT, "slides:", pres.slides.length);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
