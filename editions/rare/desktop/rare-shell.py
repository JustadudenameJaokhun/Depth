import os
import sys
import subprocess
import webbrowser

def launch_desktop():
    index_path = "/home/jaokhun/Projects/Depth/editions/rare/desktop/index.html"
    if os.path.exists(index_path):
        print("\033[1m\033[38;2;230;25;25m[DEPTH RARE]\033[0m Starting Mint Abyss Desktop Environment...")
        print("\033[38;2;140;20;20m-> Theme: Deep Crimson & Pitch Black\033[0m")
        print("\033[38;2;140;20;20m-> Panel: Active\033[0m")
        print("\033[38;2;140;20;20m-> Menu: Ready\033[0m")
        url = f"file://{index_path}"
        try:
            webbrowser.open(url)
            print(f"\033[38;2;230;25;25m[SUCCESS]\033[0m Session opened in display server at {url}")
        except Exception:
            print(f"Display frame ready at {index_path}")
    else:
        print(f"Error: missing {index_path}")

if __name__ == "__main__":
    launch_desktop()
