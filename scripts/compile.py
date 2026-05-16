import os
import subprocess
import sys
import shutil
from pathlib import Path

def compile_nimbus():
    project_root = Path(__file__).parent.parent.absolute()
    build_dir = project_root / "build"
    dist_dir = project_root / "dist"
    
    # Clean up previous builds
    if build_dir.exists(): shutil.rmtree(build_dir)
    if dist_dir.exists(): shutil.rmtree(dist_dir)
    
    dist_dir.mkdir(exist_ok=True)

    print("Starting Nuitka Compilation (this may take a few minutes)...")

    system = sys.platform
    if system == "darwin": system = "darwin"
    elif system == "win32": system = "windows"
    else: system = "linux"
    
    import platform
    machine = platform.machine().lower()
    if machine == "x86_64": machine = "amd64"

    # 1. Compile the Gateway
    gateway_cmd = [
        "uv", "run", "nuitka",
        "--standalone",
        "--onefile",
        "--remove-output",
        "--output-dir=dist",
        f"--output-filename=nimbus-gateway-{system}-{machine}",
        "--python-flag=no_docstrings",
        "--python-flag=-O",
        "--include-module=uvicorn.protocols.websockets.websockets_sansio_impl",
        "--include-module=uvicorn.protocols.http.h11_impl",
        "--include-module=uvicorn.logging",
        "--include-package=uvicorn",
        "src/nimbus_gateway/server.py"
    ]

    # 2. Compile the Orchestrator
    orchestrator_cmd = [
        "uv", "run", "nuitka",
        "--standalone",
        "--onefile",
        "--remove-output",
        "--output-dir=dist",
        f"--output-filename=nimbus-{system}-{machine}",
        "--python-flag=no_docstrings",
        "--python-flag=-O",
        "nimbus.py"
    ]

    print("Building Gateway binary...")
    subprocess.run(gateway_cmd, cwd=project_root, check=True)
    
    print("Building Orchestrator binary...")
    subprocess.run(orchestrator_cmd, cwd=project_root, check=True)

    print("\nCompilation Complete!")
    print(f"Binaries are in: {dist_dir}")
    print("You can now distribute the 'dist/' folder without any .py files.")

if __name__ == "__main__":
    # Ensure Nuitka is installed
    try:
        import nuitka
    except ImportError:
        print("Installing Nuitka...")
        # Try uv first, fallback to pip
        try:
            subprocess.run(["uv", "pip", "install", "nuitka", "zstandard"], check=True)
        except:
            subprocess.run([sys.executable, "-m", "pip", "install", "nuitka", "zstandard"], check=True)
        
    compile_nimbus()
