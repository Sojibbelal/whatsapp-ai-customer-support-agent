{
  "name": "WhatsApp AI Customer Support Agent",
  "nodes": [
    {
      "parameters": {
        "updates": ["messages"]
      },
      "id": "node-wa-trigger",
      "name": "WhatsApp Trigger",
      "type": "n8n-nodes-base.whatsAppTrigger",
      "position": [80, 300],
      "typeVersion": 1,
      "webhookId": "whatsapp-support-webhook"
    },
    {
      "parameters": {
        "conditions": {
          "options": { "caseSensitive": false, "leftValue": "", "typeValidation": "loose" },
          "conditions": [
            {
              "id": "cond-has-text",
              "operator": { "type": "string", "operation": "exists" },
              "leftValue": "={{ $json.entry[0].changes[0].value.messages[0].text.body }}",
              "rightValue": ""
            }
          ],
          "combinator": "and"
        }
      },
      "id": "node-filter-text",
      "name": "Filter: Text messages only",
      "type": "n8n-nodes-base.if",
      "position": [280, 300],
      "typeVersion": 2
    },
    {
      "parameters": {
        "assignments": {
          "assignments": [
            {
              "id": "field-phone",
              "name": "phone",
              "value": "={{ $json.entry[0].changes[0].value.messages[0].from }}",
              "type": "string"
            },
            {
              "id": "field-message",
              "name": "message",
              "value": "={{ $json.entry[0].changes[0].value.messages[0].text.body }}",
              "type": "string"
            },
            {
              "id": "field-msg-id",
              "name": "messageId",
              "value": "={{ $json.entry[0].changes[0].value.messages[0].id }}",
              "type": "string"
            },
            {
              "id": "field-timestamp",
              "name": "timestamp",
              "value": "={{ $now.toISO() }}",
              "type": "string"
            },
            {
              "id": "field-name",
              "name": "customerName",
              "value": "={{ $json.entry[0].changes[0].value.contacts[0].profile.name }}",
              "type": "string"
            }
          ]
        },
        "options": {}
      },
      "id": "node-extract-fields",
      "name": "Extract: phone + message",
      "type": "n8n-nodes-base.set",
      "position": [480, 300],
      "typeVersion": 3.4
    },
    {
      "parameters": {
        "operation": "search",
        "base": { "__rl": true, "value": "YOUR_AIRTABLE_BASE_ID", "mode": "id" },
        "table": { "__rl": true, "value": "Conversations", "mode": "name" },
        "filterByFormula": "={Phone}=\"{{ $json.phone }}\"",
        "sort": [{ "field": "Timestamp", "direction": "desc" }],
        "maxRecords": 5,
        "options": {}
      },
      "id": "node-airtable-search",
      "name": "Airtable: Load conversation history",
      "type": "n8n-nodes-base.airtable",
      "position": [680, 300],
      "typeVersion": 2
    },
    {
      "parameters": {
        "assignments": {
          "assignments": [
            {
              "id": "field-history",
              "name": "conversationHistory",
              "value": "={{ $json.map(r => r.fields.Role + ': ' + r.fields.Message).join('\\n') }}",
              "type": "string"
            },
            {
              "id": "field-phone2",
              "name": "phone",
              "value": "={{ $('Extract: phone + message').item.json.phone }}",
              "type": "string"
            },
            {
              "id": "field-message2",
              "name": "message",
              "value": "={{ $('Extract: phone + message').item.json.message }}",
              "type": "string"
            },
            {
              "id": "field-name2",
              "name": "customerName",
              "value": "={{ $('Extract: phone + message').item.json.customerName }}",
              "type": "string"
            },
            {
              "id": "field-timestamp2",
              "name": "timestamp",
              "value": "={{ $('Extract: phone + message').item.json.timestamp }}",
              "type": "string"
            }
          ]
        },
        "options": {}
      },
      "id": "node-merge-context",
      "name": "Merge: context for AI",
      "type": "n8n-nodes-base.set",
      "position": [880, 300],
      "typeVersion": 3.4
    },
    {
      "parameters": {
        "agent": "openAiFunctionsAgent",
        "promptType": "define",
        "text": "={{ $json.message }}",
        "options": {
          "systemMessage": "You are a professional customer support agent for [COMPANY_NAME]. Your job is to help customers with their questions, issues, and requests.\n\nALWAYS respond in the same language the customer uses.\n\nCustomer name: {{ $json.customerName }}\nPhone: {{ $json.phone }}\n\nConversation history (last 5 messages):\n{{ $json.conversationHistory }}\n\nCurrent message: {{ $json.message }}\n\nYou must respond with a JSON object ONLY. No prose before or after. Format:\n{\n  \"reply\": \"Your response to the customer here\",\n  \"intent\": \"billing|refund|order|technical|general|complaint\",\n  \"urgencyScore\": 1-10,\n  \"urgencyReason\": \"brief reason why this is or isn't urgent\",\n  \"requiresHuman\": true/false\n}\n\nUrgency scoring guide:\n- 1-3: General question, browsing, low stakes\n- 4-6: Issue that needs attention but not critical\n- 7-8: Customer frustrated, issue impacting them now\n- 9-10: Angry, threatening, legal threat, data breach, payment failure, or safety issue\n\nSet requiresHuman = true if urgencyScore >= 7 OR if the issue cannot be resolved without account access.\n\nKeep replies concise, warm, and human. Never say you are an AI unless directly asked. Sign off as 'Support Team'."
        }
      },
      "id": "node-ai-agent",
      "name": "AI Agent: classify + reply",
      "type": "@n8n/n8n-nodes-langchain.agent",
      "position": [1080, 300],
      "typeVersion": 1.7
    },
    {
      "parameters": {
        "model": "gpt-4o",
        "options": {
          "temperature": 0.3,
          "maxTokens": 500
        }
      },
      "id": "node-openai-model",
      "name": "OpenAI GPT-4o",
      "type": "@n8n/n8n-nodes-langchain.lmChatOpenAi",
      "position": [1000, 480],
      "typeVersion": 1.2
    },
    {
      "parameters": {
        "sessionIdType": "customKey",
        "sessionKey": "={{ $('Extract: phone + message').item.json.phone }}",
        "contextWindowLength": 10
      },
      "id": "node-memory",
      "name": "Session Memory",
      "type": "@n8n/n8n-nodes-langchain.memoryBufferWindow",
      "position": [1160, 480],
      "typeVersion": 1.3
    },
    {
      "parameters": {
        "jsCode": "const raw = $input.item.json.output || $input.item.json.text || '{}';\nlet parsed;\ntry {\n  // Strip markdown code fences if present\n  const clean = raw.replace(/```json|```/g, '').trim();\n  parsed = JSON.parse(clean);\n} catch(e) {\n  // Fallback if AI doesn't return clean JSON\n  parsed = {\n    reply: raw,\n    intent: 'general',\n    urgencyScore: 3,\n    urgencyReason: 'Could not parse AI output',\n    requiresHuman: false\n  };\n}\n\nreturn {\n  ...parsed,\n  phone: $('Extract: phone + message').item.json.phone,\n  customerName: $('Extract: phone + message').item.json.customerName,\n  message: $('Extract: phone + message').item.json.message,\n  timestamp: $('Extract: phone + message').item.json.timestamp\n};"
      },
      "id": "node-parse-ai",
      "name": "Parse AI JSON output",
      "type": "n8n-nodes-base.code",
      "position": [1280, 300],
      "typeVersion": 2
    },
    {
      "parameters": {
        "conditions": {
          "options": { "caseSensitive": false, "leftValue": "", "typeValidation": "loose" },
          "conditions": [
            {
              "id": "cond-urgent",
              "operator": { "type": "boolean", "operation": "true" },
              "leftValue": "={{ $json.requiresHuman }}"
            }
          ],
          "combinator": "and"
        }
      },
      "id": "node-if-urgent",
      "name": "IF: Requires human?",
      "type": "n8n-nodes-base.if",
      "position": [1480, 300],
      "typeVersion": 2
    },
    {
      "parameters": {
        "resource": "ticket",
        "operation": "create",
        "additionalFields": {
          "subject": "Support Request - {{ $json.intent }} - {{ $json.customerName }}",
          "content": "Customer: {{ $json.customerName }}\\nPhone: {{ $json.phone }}\\nMessage: {{ $json.message }}\\n\\nUrgency Score: {{ $json.urgencyScore }}/10\\nReason: {{ $json.urgencyReason }}\\nIntent: {{ $json.intent }}\\n\\nAI suggested reply:\\n{{ $json.reply }}",
          "hs_ticket_priority": "={{ $json.urgencyScore >= 9 ? 'HIGH' : 'MEDIUM' }}"
        }
      },
      "id": "node-hubspot-ticket",
      "name": "HubSpot: Create ticket",
      "type": "n8n-nodes-base.hubspot",
      "position": [1680, 160],
      "typeVersion": 2
    },
    {
      "parameters": {
        "chatId": "YOUR_TELEGRAM_CHAT_ID",
        "text": "🚨 *URGENT SUPPORT REQUEST*\n\n👤 Customer: {{ $json.customerName }}\n📱 Phone: {{ $json.phone }}\n🏷️ Intent: {{ $json.intent }}\n⚠️ Urgency: {{ $json.urgencyScore }}/10\n💬 Reason: {{ $json.urgencyReason }}\n\n📝 Message:\n{{ $json.message }}\n\n🤖 AI Draft Reply:\n{{ $json.reply }}\n\n_Reply to customer directly on WhatsApp_",
        "additionalFields": { "parse_mode": "Markdown" }
      },
      "id": "node-telegram-alert",
      "name": "Telegram: Alert support team",
      "type": "n8n-nodes-base.telegram",
      "position": [1680, 320],
      "typeVersion": 1.2
    },
    {
      "parameters": {
        "operation": "sendMessage",
        "phoneNumberId": "YOUR_WHATSAPP_PHONE_NUMBER_ID",
        "recipientPhoneNumber": "={{ $json.phone }}",
        "textBody": "={{ $json.reply + '\\n\\n_Your request has been escalated to our team who will follow up shortly._' }}"
      },
      "id": "node-wa-reply-urgent",
      "name": "WhatsApp: Send reply (urgent)",
      "type": "n8n-nodes-base.whatsApp",
      "position": [1880, 240],
      "typeVersion": 1
    },
    {
      "parameters": {
        "operation": "sendMessage",
        "phoneNumberId": "YOUR_WHATSAPP_PHONE_NUMBER_ID",
        "recipientPhoneNumber": "={{ $json.phone }}",
        "textBody": "={{ $json.reply }}"
      },
      "id": "node-wa-reply-routine",
      "name": "WhatsApp: Send reply (routine)",
      "type": "n8n-nodes-base.whatsApp",
      "position": [1680, 480],
      "typeVersion": 1
    },
    {
      "parameters": {
        "operation": "create",
        "base": { "__rl": true, "value": "YOUR_AIRTABLE_BASE_ID", "mode": "id" },
        "table": { "__rl": true, "value": "Conversations", "mode": "name" },
        "columns": {
          "mappingMode": "defineBelow",
          "value": {
            "Phone": "={{ $json.phone }}",
            "CustomerName": "={{ $json.customerName }}",
            "Message": "={{ $json.message }}",
            "Role": "customer",
            "Intent": "={{ $json.intent }}",
            "UrgencyScore": "={{ $json.urgencyScore }}",
            "RequiredHuman": "={{ $json.requiresHuman }}",
            "AIReply": "={{ $json.reply }}",
            "Timestamp": "={{ $json.timestamp }}"
          }
        },
        "options": {}
      },
      "id": "node-airtable-log",
      "name": "Airtable: Log conversation",
      "type": "n8n-nodes-base.airtable",
      "position": [2080, 360],
      "typeVersion": 2
    }
  ],
  "connections": {
    "WhatsApp Trigger": {
      "main": [[{ "node": "Filter: Text messages only", "type": "main", "index": 0 }]]
    },
    "Filter: Text messages only": {
      "main": [
        [{ "node": "Extract: phone + message", "type": "main", "index": 0 }],
        []
      ]
    },
    "Extract: phone + message": {
      "main": [[{ "node": "Airtable: Load conversation history", "type": "main", "index": 0 }]]
    },
    "Airtable: Load conversation history": {
      "main": [[{ "node": "Merge: context for AI", "type": "main", "index": 0 }]]
    },
    "Merge: context for AI": {
      "main": [[{ "node": "AI Agent: classify + reply", "type": "main", "index": 0 }]]
    },
    "AI Agent: classify + reply": {
      "main": [[{ "node": "Parse AI JSON output", "type": "main", "index": 0 }]]
    },
    "OpenAI GPT-4o": {
      "ai_languageModel": [[{ "node": "AI Agent: classify + reply", "type": "ai_languageModel", "index": 0 }]]
    },
    "Session Memory": {
      "ai_memory": [[{ "node": "AI Agent: classify + reply", "type": "ai_memory", "index": 0 }]]
    },
    "Parse AI JSON output": {
      "main": [[{ "node": "IF: Requires human?", "type": "main", "index": 0 }]]
    },
    "IF: Requires human?": {
      "main": [
        [
          { "node": "HubSpot: Create ticket", "type": "main", "index": 0 },
          { "node": "Telegram: Alert support team", "type": "main", "index": 0 }
        ],
        [{ "node": "WhatsApp: Send reply (routine)", "type": "main", "index": 0 }]
      ]
    },
    "HubSpot: Create ticket": {
      "main": [[{ "node": "WhatsApp: Send reply (urgent)", "type": "main", "index": 0 }]]
    },
    "Telegram: Alert support team": {
      "main": [[{ "node": "WhatsApp: Send reply (urgent)", "type": "main", "index": 0 }]]
    },
    "WhatsApp: Send reply (urgent)": {
      "main": [[{ "node": "Airtable: Log conversation", "type": "main", "index": 0 }]]
    },
    "WhatsApp: Send reply (routine)": {
      "main": [[{ "node": "Airtable: Log conversation", "type": "main", "index": 0 }]]
    }
  },
  "pinData": {},
  "settings": {
    "executionOrder": "v1",
    "saveDataErrorExecution": "all",
    "saveDataSuccessExecution": "all",
    "saveManualExecutions": true,
    "callerPolicy": "workflowsFromSameOwner"
  },
  "staticData": null,
  "tags": ["customer-support", "whatsapp", "ai-agent", "hubspot", "airtable"],
  "versionId": "1.0.0",
  "meta": {
    "templateCredsSetupCompleted": false,
    "instanceId": "whatsapp-ai-support-v1"
  }
}
