# pip install -U anthropic
# Exemple minimal avec Claude (Anthropic) : necessite une cle ANTHROPIC_API_KEY
# creee sur https://platform.claude.com (facturation separee de l'abonnement Claude.ai).
# Attention : ici les textes sont envoyes aux serveurs d'Anthropic (pas 100 % local).
import anthropic

client = anthropic.Anthropic()  # lit la cle dans ANTHROPIC_API_KEY

response = client.beta.messages.create(
    model="claude-opus-5-5",
    max_tokens=16000,
    # Si Claude refuse une demande, elle est relancee automatiquement sur un autre modele
    betas=["server-side-fallback-2026-07-01"],
    fallbacks="default",
    messages=[{"role": "user", "content": "Say 'Hello World!'"}],
)

if response.stop_reason == "refusal":
    print("Claude a refuse de repondre a cette demande.")
else:
    for block in response.content:
        if block.type == "text":
            print(block.text)
