# Strategic License Recommendation for Nimbus

Selecting the right license for Nimbus involves balancing **maximum community adoption** with **monetization protection** and **brand control**. 

Below is a detailed analysis of the most suitable open-source and source-available licenses, followed by our final recommendation.

---

## ⚖️ License Comparison Matrix

| License Type | Permissiveness | Copyleft | Commercial Protection | Brand/Trademark Protection | Ideal For... |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **MIT** | 🟢 Extremely High | 🔴 None | 🔴 None (Anyone can resell your exact code) | 🟡 Basic | Pure community play, maximizing raw adoption |
| **Apache 2.0** | 🟢 High | 🔴 None | 🔴 None (Anyone can resell, but patents are granted) | 🟢 Strong (Explicit trademark protections) | Developers who want permissive use but strict brand protection |
| **AGPLv3** | 🟡 Moderate | 🟢 Strong (Network copyleft) | 🟡 Moderate (Competitors must open-source their SaaS modifications) | 🟢 Strong | Developer infrastructure where hosted versions must remain open |
| **BSL 1.1** *(e.g. Sentry/Qdrant)* | 🔴 Low (Initially) | 🔴 None | 🟢 Complete (Prevents hosting competitive SaaS products) | 🟢 Extremely Strong | Venture-backed/commercial startups protecting their SaaS revenue |

---

## 🔍 Detailed License Breakdown

### 1. Apache License 2.0 (Permissive & Protected)
* **How it works:** Allows users to copy, modify, distribute, and sell the software freely under any terms. However, it requires preserving attribution and copyright notices.
* **Why it's great:** Unlike MIT, Apache 2.0 contains **explicit clauses on patent grants and trademark usage**. Users cannot use the name "Nimbus" or "Yoodule" for their modified forks.
* **The Catch:** Anyone can fork the code, build a closed-source wrapper around your orchestrator gateway, and sell it commercially without contributing a single line back.

### 2. GNU Affero General Public License v3 (AGPLv3 - Strong Network Copyleft)
* **How it works:** If anyone modifies your code and runs it as a hosted service over the network (e.g., providing a hosted "Nimbus-as-a-Service"), **they are legally required to make the source code of their entire modified application publicly available under the AGPLv3**.
* **Why it's great:** It perfectly protects Nimbus from cloud giants or competitors taking your core gateway, putting a premium hosted UI on top of it, and charging users without giving back to the community.
* **The Catch:** AGPLv3 is sometimes frowned upon in conservative enterprise environments where legal teams fear the "viral copyleft" nature of the license.

### 3. Business Source License 1.1 (BSL 1.1 - The "Fair Code" Standard)
* **How it works:** You grant full access to the source code for copying, compiling, and self-hosting. However, you define a **Use Limit** (e.g., *"Cannot be used as a paid, multi-tenant hosted semantic gateway service"*). After a set period (usually 3 years), the code automatically transitions into a standard open-source license (like Apache 2.0).
* **Why it's great:** Used by industry leaders like **Qdrant** (the vector DB Nimbus uses), **Sentry**, and **CockroachDB**. It guarantees you remain the sole provider of "Nimbus Cloud" while keeping the code completely visible and modifiable for local self-hosted users.
* **The Catch:** It is technically a "source-available" license, not a OSI-approved "Open Source" license, which can impact developers who exclusively contribute to OSI-approved projects.

---

## 🏆 Selected Licensing Strategy: Business Source License 1.1 (BSL 1.1)

Nimbus has **officially adopted the Business Source License 1.1 (BSL 1.1)**. This licensing model perfectly balances Yoodule's commitment to community self-hosting with the protection of our commercial enterprise cloud channels.

### Why BSL 1.1 was Selected
1. **SaaS Revenue Protection:** BSL 1.1 legally blocks cloud providers or competitors from offering "Managed Nimbus Gateway" as a paid, multi-tenant commercial service.
2. **Local Developer Freedom:** Individual developers and enterprise teams have 100% free rights to download, modify, compile, run, and self-host the gateway locally for any internal production or non-production environment.
3. **Commitment to Open Source:** On **May 19, 2029** (the Change Date), the license automatically converts to the highly permissive **Apache License, Version 2.0**, ensuring Nimbus eventually becomes fully open-source.

---

### 🚀 Active BSL 1.1 Parameters
* **Licensor:** Yoodule Inc.
* **Licensed Work:** Nimbus (including Nimbus Gateway, Nimbus CLI, and all associated components, scripts, and documentation)
* **Change Date:** May 19, 2029
* **Change License:** Apache License, Version 2.0 (as published by the Apache Software Foundation)
* **Additional Use Grant:** You are hereby granted the right to make Production Use of the Licensed Work for any purpose, EXCEPT that you may not run the Licensed Work as a commercial, paid, multi-tenant hosted "Model Context Protocol (MCP) gateway-as-a-service" or "cognitive automation-as-a-service" where third-party customers pay for direct access to the hosted gateway or agent dashboard infrastructure managed by you. 
