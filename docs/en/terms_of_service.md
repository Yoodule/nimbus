!!! note "English is the authoritative version of these Terms of Service"
    This document is published in English only. Translations, if any, are
    provided for convenience and do not have legal effect. In case of any
    discrepancy between a translation and the English text, the English
    version controls.

# Terms of Service

**Effective Date:** May 19, 2026

Welcome to **Nimbus** ("Software"), a containerized semantic orchestrator gateway, agent dashboard, and virtual workspace suite developed by **Yoodule** ("Yoodule," "we," "us," or "our").

By installing, running, or utilizing Nimbus, you ("User" or "you") agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, do not install or use the Software.

---

## 1. Description of Software & Architecture

Nimbus is an orchestration suite designed to run local and remote Model Context Protocol (MCP) servers, databases, and dashboard environments.

* **Containerized Isolation:** The Software runs containerized on your local host machine using Docker. Apart from explicitly mapped data directories (such as `~/.nimbus` or local repository folders for session storage, Qdrant indexes, and PostgreSQL data), the Software is isolated from your host operating system and host files.
* **Open-Source & Source-Available Components:** The core gateway and associated CLI are licensed under our project license (see `LICENSE` in the root repository).

## 2. Onboarding & Registration Telemetry

To initialize your workspace, Nimbus requires a first-time registration and consent flow.

* **Collected Data:** During onboarding, the CLI prompts you to enter your Full Name and Email Address. The CLI also automatically collects basic operational system metadata, specifically your operating system, CPU architecture, and local CLI version.
* **Purpose:** This registration data is securely transmitted to Yoodule's registration database to:
  1. Initialize your local dashboard administrator credentials.
  2. Send you security patches, developer notifications, and community update emails.
  3. Register your workspace instance for analytics and product improvements.
* **Uninstall Feedback:** If you run `nimbus uninstall`, the CLI provides an optional feedback form allowing you to share reasons for uninstalling and optionally consent to follow-up developer outreach.

## 3. Third-Party API Keys & Model Providers (OpenRouter, Gemini, Claude, OpenAI, etc.)

Nimbus relies on user-provided keys for external Large Language Models (LLMs) and cognitive task delegation.

* **User-Provided Keys:** To execute semantic tasks, you must supply your own valid API keys or credentials for external model endpoints or aggregators (including but not limited to **OpenRouter, Google Gemini, Anthropic Claude, OpenAI, and DeepSeek**).
* **Zero Transmission to Yoodule:** Your API keys are stored **strictly locally** on your host machine (within persistent local environment files or in-memory inside your local containers). Yoodule never intercepts, collects, logs, or transmits your API keys, model prompt text, system logs, or response payloads to our servers.
* **Billing, API Charges & Rate Limits:** You are entirely and solely responsible for all financial costs, billing charges, subscription fees, token usage limits, or platform rate-limiting incurred on your respective external developer accounts. Yoodule assumes no responsibility for any charges incurred on your third-party API accounts due to automated loops, continuous task execution, or agent operations triggered by Nimbus.
* **No Affiliation:** Nimbus is an independent open-source orchestration tool and is not officially affiliated, partnered, sponsored, or endorsed by OpenRouter, Anthropic, Google, OpenAI, or any other model provider. All product names, logos, and brands are the property of their respective owners.
* **Compliance & Usage Rules:** Your interactions with external APIs via Nimbus must strictly comply with the developer terms, use-case policies, and acceptable-use guidelines of each respective model provider.

## 4. Acceptable Use & Automated Browser Interactions

Nimbus provides built-in browser automation capabilities (e.g., Playwright/Patchright headless browser agents, automated LinkedIn or WhatsApp MCP servers).

* **Compliance:** You agree not to use the automated browser capabilities of Nimbus to engage in malicious spam, platform abuse, data scraping in violation of third-party policies, or any activity that violates local, state, national, or international laws.
* **Platform Penalties:** Because Nimbus performs automated browser interactions on your behalf, your account on third-party platforms could be subject to rate-limiting, temporary suspensions, or permanent bans (e.g., LinkedIn automated outreach policies). **Yoodule assumes absolutely no liability for any action taken against your accounts by third-party platforms as a result of using this Software.**

## 5. Disclaimer of Warranties

THE SOFTWARE IS PROVIDED "AS IS" AND "AS AVAILABLE", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT. IN NO EVENT SHALL YOODULE, THE AUTHORS, OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## 6. Limitation of Liability

IN NO EVENT SHALL YOODULE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR EXEMPLARY DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

## 7. Modifications to Terms

We reserve the right to modify these Terms at any time. When we make updates, we will update the version and effective date in this file. Your continued use of the Software after updates constitute your acceptance of the revised terms.
