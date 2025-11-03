#!/usr/bin/env python3
"""
Demo client for testing the license server from a remote machine.
Can be used against localhost or the deployed Fly.io endpoint.

Usage:
    python scripts/demo_client.py --help
    python scripts/demo_client.py --url https://license-server-demo.fly.dev
    python scripts/demo_client.py --url http://localhost:8000 --user alice
"""

import argparse
import sys
import time
from typing import Optional
import requests


class LicenseClient:
    def __init__(self, base_url: str, user: str = "demo-user"):
        self.base_url = base_url.rstrip("/")
        self.user = user
        self.session = requests.Session()
        self.borrowed_licenses = {}  # tool -> license_id

    def check_status(self, tool: str) -> dict:
        """Check license status for a tool."""
        try:
            response = self.session.get(f"{self.base_url}/licenses/{tool}/status")
            response.raise_for_status()
            return response.json()
        except requests.RequestException as e:
            print(f"❌ Error checking status: {e}")
            return {}

    def list_all_status(self) -> list:
        """List status for all tools."""
        try:
            response = self.session.get(f"{self.base_url}/licenses/status")
            response.raise_for_status()
            return response.json()
        except requests.RequestException as e:
            print(f"❌ Error listing status: {e}")
            return []

    def borrow_license(self, tool: str) -> Optional[str]:
        """Borrow a license for a tool."""
        try:
            response = self.session.post(
                f"{self.base_url}/licenses/borrow",
                json={"tool": tool, "user": self.user}
            )
            response.raise_for_status()
            data = response.json()
            license_id = data.get("id")
            self.borrowed_licenses[tool] = license_id
            print(f"✅ Borrowed {tool} license (ID: {license_id})")
            return license_id
        except requests.HTTPException as e:
            if e.response.status_code == 409:
                print(f"⚠️  No available licenses for {tool}")
            else:
                print(f"❌ Error borrowing license: {e}")
            return None
        except requests.RequestException as e:
            print(f"❌ Error borrowing license: {e}")
            return None

    def return_license(self, license_id: str, tool: Optional[str] = None) -> bool:
        """Return a borrowed license."""
        try:
            response = self.session.post(
                f"{self.base_url}/licenses/return",
                json={"id": license_id}
            )
            response.raise_for_status()
            print(f"✅ Returned license (ID: {license_id})")
            if tool and tool in self.borrowed_licenses:
                del self.borrowed_licenses[tool]
            return True
        except requests.RequestException as e:
            print(f"❌ Error returning license: {e}")
            return False

    def simulate_usage(self, tool: str, duration: int = 5):
        """Simulate borrowing, using, and returning a license."""
        print(f"\n🎯 Simulating license usage for {tool}")
        print(f"   User: {self.user}")
        
        # Check status before
        status = self.check_status(tool)
        if status:
            print(f"   Available: {status['available']}/{status['total']}")
        
        # Borrow
        license_id = self.borrow_license(tool)
        if not license_id:
            return False
        
        # Simulate work
        print(f"   💼 Working with {tool} for {duration} seconds...")
        time.sleep(duration)
        
        # Return
        self.return_license(license_id, tool)
        
        # Check status after
        status = self.check_status(tool)
        if status:
            print(f"   Available: {status['available']}/{status['total']}")
        
        return True


def print_banner(url: str, user: str):
    print("=" * 70)
    print("🎫  License Server Demo Client")
    print("=" * 70)
    print(f"Server:  {url}")
    print(f"User:    {user}")
    print("=" * 70)
    print()


def interactive_mode(client: LicenseClient):
    """Interactive mode for manual testing."""
    print("\n📋 Interactive Mode")
    print("Commands:")
    print("  status [tool]  - Check license status")
    print("  borrow <tool>  - Borrow a license")
    print("  return <id>    - Return a license")
    print("  list           - List all borrowed licenses")
    print("  quit           - Exit")
    print()
    
    while True:
        try:
            cmd = input(">>> ").strip().split()
            if not cmd:
                continue
            
            action = cmd[0].lower()
            
            if action == "quit":
                break
            
            elif action == "status":
                if len(cmd) > 1:
                    tool = cmd[1]
                    status = client.check_status(tool)
                    if status:
                        print(f"Tool: {status['tool']}")
                        print(f"  Total: {status['total']}")
                        print(f"  Borrowed: {status['borrowed']}")
                        print(f"  Available: {status['available']}")
                        if 'in_commit' in status:
                            print(f"  In Commit: {status['in_commit']}")
                            print(f"  Overage: {status.get('overage', 0)}")
                else:
                    statuses = client.list_all_status()
                    for s in statuses:
                        print(f"{s['tool']}: {s['available']}/{s['total']} available")
            
            elif action == "borrow":
                if len(cmd) < 2:
                    print("Usage: borrow <tool>")
                    continue
                tool = cmd[1]
                client.borrow_license(tool)
            
            elif action == "return":
                if len(cmd) < 2:
                    print("Usage: return <license_id>")
                    continue
                license_id = cmd[1]
                client.return_license(license_id)
            
            elif action == "list":
                if client.borrowed_licenses:
                    print("Borrowed licenses:")
                    for tool, lid in client.borrowed_licenses.items():
                        print(f"  {tool}: {lid}")
                else:
                    print("No borrowed licenses")
            
            else:
                print(f"Unknown command: {action}")
        
        except KeyboardInterrupt:
            print("\n\nExiting...")
            break
        except Exception as e:
            print(f"Error: {e}")


def main():
    parser = argparse.ArgumentParser(
        description="Demo client for license server testing"
    )
    parser.add_argument(
        "--url",
        default="http://localhost:8000",
        help="Base URL of the license server (default: http://localhost:8000)"
    )
    parser.add_argument(
        "--user",
        default="demo-client",
        help="Username for borrowing licenses (default: demo-client)"
    )
    parser.add_argument(
        "--tool",
        help="Tool to test (default: runs simulation for all tools)"
    )
    parser.add_argument(
        "--duration",
        type=int,
        default=5,
        help="How long to hold the license in seconds (default: 5)"
    )
    parser.add_argument(
        "--interactive",
        "-i",
        action="store_true",
        help="Run in interactive mode"
    )
    parser.add_argument(
        "--loop",
        type=int,
        help="Run simulation in a loop N times"
    )
    
    args = parser.parse_args()
    
    print_banner(args.url, args.user)
    
    # Test connection
    try:
        response = requests.get(f"{args.url}/version", timeout=5)
        response.raise_for_status()
        version = response.json().get("version", "unknown")
        print(f"✅ Connected to server (version: {version})\n")
    except requests.RequestException as e:
        print(f"❌ Cannot connect to server: {e}")
        print(f"   Make sure the server is running at {args.url}")
        sys.exit(1)
    
    client = LicenseClient(args.url, args.user)
    
    if args.interactive:
        interactive_mode(client)
    else:
        # Get available tools
        statuses = client.list_all_status()
        if not statuses:
            print("❌ No tools available")
            sys.exit(1)
        
        tools = [s["tool"] for s in statuses] if not args.tool else [args.tool]
        
        loop_count = args.loop if args.loop else 1
        
        for iteration in range(loop_count):
            if loop_count > 1:
                print(f"\n{'=' * 70}")
                print(f"Iteration {iteration + 1}/{loop_count}")
                print('=' * 70)
            
            for tool in tools:
                client.simulate_usage(tool, args.duration)
            
            if iteration < loop_count - 1:
                time.sleep(2)  # Brief pause between iterations
    
    print("\n✅ Demo complete!")


if __name__ == "__main__":
    main()

