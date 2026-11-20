from google import genai
import os

# API Key तपासणी (Environment variable मधून किंवा थेट)
api_key = os.environ.get("GEMINI_API_KEY")

if not api_key:
    print("टीप: GEMINI_API_KEY environment variable सेट नाही.")
    print("कृपया प्रथम PowerShell मध्ये: $env:GEMINI_API_KEY='तुमची_API_KEY' सेट करा.")
else:
    client = genai.Client(api_key=api_key)
    try:
        response = client.interactions.create(
            model="gemini-4-hydrogen",
            input="Hello, analyze USD/INR market structure."
        )
        print("Gemini Output:")
        print(response.output_text)
    except Exception as e:
        print(f"Error: {e}")
