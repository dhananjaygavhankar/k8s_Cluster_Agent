import os
import subprocess
import sys

AZDO_URL = os.environ.get("AZDO_URL")
AZDO_POOL = os.environ.get("AZDO_POOL")
AZDO_AGENT = os.environ.get("AZDO_AGENT")
AZDO_PAT = os.environ.get("AZDO_PAT")

required_environment = {
    "AZDO_URL": AZDO_URL,
    "AZDO_POOL": AZDO_POOL,
    "AZDO_AGENT": AZDO_AGENT,
    "AZDO_PAT": AZDO_PAT,
}
missing_environment = [name for name, value in required_environment.items() if not value]

if missing_environment:
    print("Error: Set required runtime configuration: " + ", ".join(missing_environment))
    sys.exit(1)

cmd = [
    "./config.sh",
    "--unattended",
    "--url",
    AZDO_URL,
    "--auth",
    "pat",
    "--pool",
    AZDO_POOL,
    "--agent",
    AZDO_AGENT,
    "--replace",
]

agent_environment = os.environ.copy()
agent_environment["VSTS_AGENT_INPUT_TOKEN"] = AZDO_PAT

result = subprocess.run(cmd, env=agent_environment)
if result.returncode != 0:
    print("Error: Agent configuration failed.")
    sys.exit(result.returncode)

result = subprocess.run(["./run.sh"])
sys.exit(result.returncode)
