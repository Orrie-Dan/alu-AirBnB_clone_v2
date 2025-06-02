#!/usr/bin/python3
"""
Fabric script for creating .tgz archives from web_static folder
"""

from fabric.api import local, quiet
from datetime import datetime
import os


def do_pack():
    """
    Generates a .tgz archive from the contents of the web_static folder.

    All files in the web_static folder are added to the final archive.
    Archives are stored in the versions folder (created if it doesn't exist).
    Archive name format: web_static_<year><month><day><hour><minute><second>.tgz

    Returns:
        str: Archive path if the archive has been correctly generated
        None: If the archive generation fails
    """
    try:
        # Create versions directory if it doesn't exist
        local("mkdir -p versions")
        
        # Generate timestamp for unique archive name
        now = datetime.now()
        timestamp = now.strftime("%Y%m%d%H%M%S")
        archive_name = "web_static_{}.tgz".format(timestamp)
        archive_path = "versions/{}".format(archive_name)
        
        # Check if web_static folder exists
        if not os.path.exists("web_static"):
            return None
        
        # Create the tar.gz archive containing all web_static files
        print("Packing web_static to {}".format(archive_path))
        with quiet():
            result = local("tar -cvzf {} web_static".format(archive_path))
        
        # Check if archive was created successfully
        if os.path.exists(archive_path) and os.path.getsize(archive_path) > 0:
            file_size = os.path.getsize(archive_path)
            print("web_static packed: {} -> {}Bytes".format(
                archive_path, file_size))
            return archive_path
        else:
            return None
            
    except Exception:
        return None


if __name__ == "__main__":
    # Test the function
    archive_path = do_pack()
    if archive_path:
        print("Success: Archive created at {}".format(archive_path))
    else:
        print("Failed: Archive creation failed")
