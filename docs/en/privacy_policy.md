# Privacy Policy

**Effective Date:** May 19, 2026

At **Nimbus** ("Software"), built by **Yoodule** ("Yoodule," "we," "us," or "our"), we are deeply committed to protecting your privacy. This Privacy Policy explains our data practices, what information we collect, what remains entirely under your local control, and our alignment with global compliance standards (such as **GDPR** and **CCPA**).

---

## 1. Core Philosophy: "Local-First & Private-by-Design"

Nimbus is built on a **local-first architecture**. This means that almost all data generated, processed, or utilized by the Software remains **strictly on your host machine** inside isolated Docker containers.

* **No Cloud Hosting:** Yoodule does not run cloud databases, central storage logs, or tracking servers for your active workflows.
* **Credentials Isolation & Third-Party LLM Keys:** All user-provided API keys (including those for **OpenRouter, Google Gemini, Anthropic Claude, OpenAI, and DeepSeek**), OAuth tokens, vector database embeddings, local database tables, session states, and execution logs are kept in-memory or on local persistent disks (`~/.nimbus`) under your direct custody and control. **Yoodule does not host, transfer, view, or have access to any of your third-party API keys, nor do we intercept, log, or monitor your prompt contents or model request/response payloads.**

---

## 2. Information We Collect (Registration & Telemetry)

To help us administer the Software, push security patches, and monitor system health, Nimbus collects limited registration data with your explicit consent during first-time startup:

* **User-Provided Registration Data:** Full Name and Email Address.
* **System Metadata:** Operating System (OS), CPU Architecture, and CLI Version.
* **Outreach Consent:** Optional approval to contact you for product updates, newsletters, or security alerts.
* **Uninstall Feedback:** Optional feedback on the reason for uninstalling, with optional consent for free 1-on-1 developer support.

---

## 3. How We Use and Share Information

The limited telemetry we collect is used solely to:

* Set up your default local workspace dashboard administrator account.
* Notify you of critical security vulnerabilities or software updates.
* Optimize system compatibility across various operating systems (macOS, Linux, etc.) and CPU architectures (ARM64, AMD64).

**We DO NOT sell, rent, trade, or share your registration details or metadata with third-party advertising networks or commercial brokers.**

---

## 4. Global Compliance Standards (GDPR & CCPA Alignment)

Nimbus is fully aligned with modern international data privacy laws:

### 🇪🇺 General Data Protection Regulation (GDPR)

For users located in the European Economic Area (EEA), we act as the **Data Controller** for your registration data. Our processing is grounded in the following GDPR rights:

* **Article 6(1)(a) - Consent:** We only collect your name, email, and metadata after you give explicit consent during `nimbus start`.
* **Article 15 - Right of Access:** You can view all configuration values and stored registration details at any time by running `nimbus config list`.
* **Article 17 - Right to Erasure ("Right to be Forgotten"):** You have complete autonomy over your local data. Running `nimbus uninstall` completely destroys all local containers, databases, vector indexes, and configurations from your machine. If you wish to delete your registration email from Yoodule's secure mailing list, contact us at `support@yoodule.com`.
* **Article 25 - Data Protection by Design and by Default:** Our containerized local-first design minimizes data exposure to the maximum technical extent possible.

### 🇺🇸 California Consumer Privacy Act (CCPA)

For California residents, Nimbus is structured to maximize CCPA compliance:

* **No "Sale" of Personal Information:** We do not sell your personal data.
* **Right to Know & Access:** You have absolute visibility into your configuration via `nimbus config list`.
* **Right to Delete:** You can delete your workspace instantly by running `nimbus uninstall`.

### 🔒 Formal Certifications & Audits (SOC 2, HIPAA, ISO 27001)

* **No Central Audits:** Because Yoodule does not host your databases, run remote SaaS services, or store your credentials centrally, Yoodule **does not hold** formal third-party certifications (such as SOC 2, HIPAA, or ISO 27001) for Nimbus.
* **Compliance Inheritance:** Since Nimbus runs entirely locally within your container infrastructure, it **inherits the compliance posture of your host computer or enterprise network**. If your local network or workstation is HIPAA-compliant or SOC 2-compliant, your usage of Nimbus remains fully compliant within that secure boundary, as no private database tables, vector search queries, or API keys are ever transmitted to Yoodule.

---

## 5. Security of Local & Transmitted Data

* **Transport Encryption:** All telemetry sent to Yoodule is transmitted securely using HTTPS (TLS 1.3).
* **Local Security:** Because database files (PostgreSQL, Qdrant) reside on your local machine, securing those files and limiting physical/network access to your computer is your sole responsibility.

---

## 6. Children's Privacy

Our Software is intended solely for developers and professionals and is not directed at children under the age of 13. We do not knowingly collect personal information from children.

---

## 7. Contact Us

For any questions regarding this Privacy Policy or to request the manual deletion of your registration telemetry from our records, please contact us at:

* **Email:** <support@yoodule.com>
* **Website:** <https://nimbus.yoodule.com>
