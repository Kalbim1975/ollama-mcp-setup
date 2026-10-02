# pip install -U "autogen-agentchat" "autogen-ext[openai]"
# Exemple minimal avec OpenAI (gpt-4o) : necessite une cle OPENAI_API_KEY.
# Attention : ici les textes sont envoyes aux serveurs d'OpenAI (pas 100 % local).
import asyncio
from autogen_agentchat.agents import AssistantAgent
from autogen_ext.models.openai import OpenAIChatCompletionClient

async def main() -> None:
    agent = AssistantAgent("assistant", OpenAIChatCompletionClient(model="gpt-4o"))
    print(await agent.run(task="Say 'Hello World!'"))

asyncio.run(main())
