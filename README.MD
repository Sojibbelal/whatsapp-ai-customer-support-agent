# WhatsApp AI Customer Support Agent

An AI-powered customer support automation built with n8n, WhatsApp Business API, OpenAI GPT-4o, Airtable, HubSpot, and Telegram.

## What This Workflow Does

When a customer sends a WhatsApp message:

1. Receives the message through WhatsApp Business API
2. Loads previous conversation history from Airtable
3. Sends context to OpenAI GPT-4o
4. Classifies intent and urgency
5. Generates a customer response
6. Automatically escalates urgent requests
7. Creates a HubSpot ticket for human follow-up
8. Sends Telegram alerts to the support team
9. Stores conversation history in Airtable

---

# Prerequisites

Before installing, create accounts for:

* n8n
* OpenAI
* Meta WhatsApp Business Platform
* Airtable
* HubSpot
* Telegram Bot

---

# Step 1: Install Docker

Install Docker:

https://docs.docker.com/get-docker/

Verify installation:

```bash
docker --version
docker compose version
```

---

# Step 2: Install n8n

Create a project folder:

```bash
mkdir whatsapp-ai-support
cd whatsapp-ai-support
```

Create a file named:

```text
docker-compose.yml
```

Paste:

```yaml
services:
  n8n:
    image: docker.n8n.io/n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped

    ports:
      - "5678:5678"

    environment:
      - GENERIC_TIMEZONE=UTC

    volumes:
      - ./n8n_data:/home/node/.n8n
```

Start n8n:

```bash
docker compose up -d
```

Open:

```text
http://localhost:5678
```

Create your admin account.

---

# Step 3: Import Workflow

1. Download the workflow JSON.
2. Open n8n.
3. Click Import Workflow.
4. Upload the JSON file.
5. Save the workflow.

---

# Step 4: Configure OpenAI

Create an OpenAI account.

Generate an API key.

Inside n8n:

Credentials → OpenAI

Add:

```text
API Key = your_openai_key
```

Connect the credential to:

OpenAI GPT-4o node

---

# Step 5: Configure Airtable

Create a new Airtable base.

Name:

```text
Customer Support
```

Create table:

```text
Conversations
```

Add fields:

| Field Name    | Type             |
| ------------- | ---------------- |
| Phone         | Single line text |
| CustomerName  | Single line text |
| Message       | Long text        |
| Role          | Single line text |
| Intent        | Single line text |
| UrgencyScore  | Number           |
| RequiredHuman | Checkbox         |
| AIReply       | Long text        |
| Timestamp     | Date/Time        |

Generate Airtable Personal Access Token.

Inside n8n:

Credentials → Airtable

Add:

```text
Access Token
```

Update:

```text
YOUR_AIRTABLE_BASE_ID
```

inside both Airtable nodes.

---

# Step 6: Configure WhatsApp Business API

Create:

* Meta Developer Account
* WhatsApp Business Account

Create an app.

Add:

```text
WhatsApp Product
```

Collect:

```text
Phone Number ID
Access Token
Webhook Verification Token
```

Update:

```text
YOUR_WHATSAPP_PHONE_NUMBER_ID
```

inside:

* WhatsApp Trigger
* WhatsApp Reply (Routine)
* WhatsApp Reply (Urgent)

Connect WhatsApp credentials in n8n.

---

# Step 7: Configure Telegram Alerts

Open Telegram.

Message:

@BotFather

Create a bot:

```text
/newbot
```

Save:

```text
BOT TOKEN
```

Get your chat ID.

Update:

```text
YOUR_TELEGRAM_CHAT_ID
```

inside:

Telegram Alert Support Team node.

Create Telegram credentials inside n8n.

---

# Step 8: Configure HubSpot

Create a HubSpot account.

Generate a Private App Token.

Inside n8n:

Credentials → HubSpot

Add:

```text
Private App Token
```

Connect it to:

HubSpot Create Ticket node.

---

# Step 9: Customize AI Instructions

Open:

AI Agent: classify + reply

Replace:

```text
[COMPANY_NAME]
```

with your company name.

Example:

```text
Acme Electronics
```

You may also customize:

* supported languages
* escalation rules
* response style
* support policies

---

# Step 10: Activate Workflow

Turn workflow ON.

Copy the webhook URL from:

WhatsApp Trigger

Configure it inside Meta Developer Dashboard.

Subscribe to:

```text
messages
```

events.

---

# Testing

Send a WhatsApp message:

```text
Hello
```

Expected result:

* AI generates response
* Reply sent back to WhatsApp
* Conversation saved in Airtable

---

# Escalation Test

Send:

```text
I have been charged twice and nobody is helping me.
```

Expected result:

* Urgency score increases
* HubSpot ticket created
* Telegram alert sent
* Customer receives escalation notice

---

# Troubleshooting

### Workflow does not trigger

Check:

* Meta webhook configuration
* Access token validity
* n8n execution logs

### AI not responding

Check:

* OpenAI API key
* OpenAI account credits

### Airtable errors

Check:

* Base ID
* Table name
* Access token permissions

### Telegram alerts not arriving

Check:

* Bot token
* Chat ID

### HubSpot ticket creation fails

Check:

* Private App permissions
* Ticket scope access

---

# License

MIT License

You are free to use, modify, and distribute this workflow.

