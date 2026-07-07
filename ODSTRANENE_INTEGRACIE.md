# Odstránené externé integrácie

Tento dokument popisuje všetky externé služby, ktoré boli odstránené z Maybe pri transformácii na vlastný budget tracker. Aplikácia teraz funguje **lokálne a offline** — bez napojenia na tretie strany.

---

## 1. Plaid (bankové prepojenie)

**Čo robilo:** Plaid umožňoval automatické prepojenie bankových účtov, kreditných kariet, investícií a pôžičiek. Sťahoval transakcie, zostatky a holdings priamo z bánk v reálnom čase cez Plaid Link widget.

**Odstránené:**
- Modely `PlaidItem`, `PlaidAccount` a celý sync pipeline
- Controller `PlaidItemsController` a Stimulus `plaid_controller.js`
- Webhook endpointy `/webhooks/plaid` a `/webhooks/plaid_eu`
- Gem `plaid` a inicializátor `config/initializers/plaid.rb`

**Nahradenie:** Účty a transakcie zadávaj manuálne alebo cez CSV import.

---

## 2. Stripe (predplatné a fakturácia)

**Čo robilo:** Stripe spravoval platené predplatné v „managed“ režime Maybe — free trial, checkout, fakturácia, zrušenie predplatného a webhooky pre stav platby.

**Odstránené:**
- Model `Subscription`, concern `Family::Subscribeable`
- Controllery `SubscriptionsController`, `Settings::BillingsController`
- Webhook endpoint `/webhooks/stripe`
- Gem `stripe`, onboarding trial stránka, upgrade banner v sidebar-e

**Nahradenie:** Žiadne predplatné — aplikácia je bezplatná a self-hosted.

---

## 3. OpenAI (AI asistent a automatizácia)

**Čo robilo:** OpenAI poháňal AI sidebar chat (otázky o financiách), automatickú kategorizáciu transakcií, detekciu obchodníkov (merchant) a návrhy pravidiel.

**Odstránené:**
- Modely `Chat`, `Message`, `Assistant`, `ToolCall`
- Controllery `ChatsController`, `MessagesController`
- Joby `AssistantResponseJob`, `AutoCategorizeJob`, `AutoDetectMerchantsJob`
- Pravý sidebar s AI chatom v layoute
- Gem `ruby-openai`

**Nahradenie:** Kategórie a pravidlá nastavuj manuálne alebo cez Rules engine (bez AI).

---

## 4. Synth (trhové dáta a kurzy)

**Čo robilo:** Synth API poskytoval historické výmenné kurzy mien a ceny cenných papierov (akcie, ETF). Používal sa pri multi-menových účtoch, investíciách a prepočte grafov do rodinnej meny.

**Odstránené:**
- Provider `Provider::Synth` a concept registry pre `:exchange_rates`, `:securities`
- Joby `ImportMarketDataJob`, `SecurityHealthCheckJob`
- Nastavenia Synth API kľúča v Settings → Hosting
- Scheduled import kurzov a cenných papierov

**Nahradenie:** Kurzy a ceny cenných papierov zadávaj manuálne alebo importuj cez CSV. Tabuľky `exchange_rates` a `security_prices` zostávajú pre lokálne dáta.

---

## 5. GitHub (changelog)

**Čo robilo:** Stránka `/changelog` sťahovala release notes z GitHub repozitára `maybe-finance/maybe` cez Octokit API.

**Odstránené:**
- Provider `Provider::Github`
- Gem `octokit`
- Route `/changelog`

**Nahradenie:** Changelog nie je potrebný pre vlastný fork.

---

## 6. Doorkeeper + REST API v1 (OAuth a mobilné API)

**Čo robilo:** Doorkeeper poskytoval OAuth2 pre mobilné aplikácie Maybe. REST API v1 umožňovalo externým klientom čítať/zapisovať účty, transakcie a chaty cez API kľúče alebo OAuth tokeny.

**Odstránené:**
- Celý namespace `/api/v1/` (auth, accounts, transactions, chats, usage)
- OAuth endpointy (`/oauth/authorize`, `/oauth/token`, …)
- Modely `ApiKey`, `MobileDevice`
- Settings → API Keys
- Gemy `doorkeeper`, `rack-attack`

**Nahradenie:** Webová aplikácia cez prehliadač — bez externého API.

---

## 7. Intercom (zákaznícka podpora)

**Čo robilo:** Intercom widget v aplikácii umožňoval používateľom kontaktovať Maybe support priamo z UI (tlačidlo „?“ v sidebar-e).

**Odstránené:**
- Gem `intercom-rails`
- Stimulus `intercom_controller.js`
- Inicializátor `config/initializers/intercom.rb`

**Nahradenie:** Žiadna externá podpora — vlastná aplikácia.

---

## 8. Sentry, Logtail, Skylight (monitoring)

**Čo robili:**
- **Sentry** — error tracking a reportovanie výnimiek do cloudu
- **Logtail** — centralizované logy v produkcii (Better Stack)
- **Skylight** — APM (Application Performance Monitoring)

**Odstránené:** Príslušné gemy a inicializátory.

**Nahradenie:** Štandardné Rails logy (`log/development.log`, `log/production.log`).

---

## 9. Externé presmerovania

**Čo robili:** Route `/privacy` a `/terms` presmerovávali na `maybefinance.com`.

**Odstradené:** Externé redirecty boli odstránené.

---

## Čo zostalo (jadro budget trackeru)

- **Manuálne účty** — všetky typy (checking, kreditka, investície, nehnuteľnosti, …)
- **Transakcie, transfery, trades, valuations**
- **Kategórie, tagy, rozpočty (budgets)**
- **Pravidlá (Rules)** — automatizácia bez AI
- **CSV import**
- **Grafy a reporty** (balance sheet, income statement)
- **Multi-mena** — s manuálne zadanými kurzmi
- **Autentifikácia** — sessions, MFA, pozvánky do rodiny
- **Sidekiq** — lokálne background joby (sync, import, pravidlá)
