#!/usr/bin/python3
"""
Fabric script for creating .tgz archives from web_static folder
"""

from fabric.api import local
from datetime import datetime
import os


def do_pack():
    """
    Generates a .tgz archive from the contents of the web_static folder.
    
    Returns:
        str: Archive path if successful, None otherwise
    """
    try:
        # Create versions directory if it doesn't exist
        if not os.path.exists("versions"):
            local("mkdir -p versions")
        
        # Generate timestamp for archive name
        now = datetime.now()
        timestamp = now.strftime("%Y%m%d%H%M%S")
        archive_name = f"web_static_{timestamp}.tgz"
        archive_path = f"versions/{archive_name}"
        
        # Check if web_static folder exists
        if not os.path.exists("web_static"):
            print("Error: web_static folder does not exist")
            return None
        
        # Create the tar.gz archive
        print(f"Packing web_static to {archive_path}")
        result = local(f"tar -cvzf {archive_path} web_static", capture=True)
        
        # Check if archive was created successfully
        if os.path.exists(archive_path):
            file_size = os.path.getsize(archive_path)
            print(f"web_static packed: {archive_path} -> {file_size}Bytes")
            return archive_path
        else:
            print("Error: Archive was not created")
            return None
            
    except Exception as e:
        print(f"Error during packing: {e}")
        return None


if __name__ == "__main__":
    # Test the function
    archive_path = do_pack()
    if archive_path:
        print(f"Success: Archive created at {archive_path}")
    else:
        print("Failed: Archive creation failed")
