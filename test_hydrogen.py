import os
import sys
from dotenv import load_dotenv
from google import genai

# Load environment variables from .env
load_dotenv()

api_key = os.environ.get("GEMINI_API_KEY")

if not api_key:
    print("Error: GEMINI_API_KEY environment variable is not set.")
    print("Please set it in your .env file or PowerShell: $env:GEMINI_API_KEY='your_key'")
    sys.exit(1)

print(f"Using API Key: {api_key[:4]}...{api_key[-4:] if len(api_key) > 8 else ''}")

client = genai.Client(api_key=api_key)

# The official Google model identifier for Hydrogen is 'gemini-4-hydrogen'
model_name = "gemini-4-hydrogen"
prompt = "Hello, analyze USD/INR market structure and provide key technical levels."

print(f"\nQuerying {model_name}...")
print("Waiting for Gemini Hydrogen response...\n")

try:
    # 1. Standard generate_content (fastest and most reliable)
    response = client.models.generate_content(
        model=model_name,
        contents=prompt,
        config={
            "thinking_level": "medium",  # Options: low, medium, high, xhigh
        }
    )
    print("=" * 50)
    print("Gemini 4 Hydrogen Output:")
    print("=" * 50)
    print(response.text)

except Exception as e:
    print(f"generate_content failed ({e}), trying interactions API...")
    try:
        # 2. Fallback to interactions API
        interaction = client.interactions.create(
            model=model_name,
            input=prompt
        )
        print("=" * 50)
        print("Gemini Interactions Output:")
        print("=" * 50)
        # Handle outputs in interaction response
        if hasattr(interaction, "output_text"):
            print(interaction.output_text)
        elif hasattr(interaction, "outputs"):
            for part in interaction.outputs:
                print(part)
        else:
            print(interaction)
    except Exception as e2:
        print(f"\nError: {e2}")
