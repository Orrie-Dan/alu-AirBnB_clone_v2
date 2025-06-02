#!/usr/bin/python3
"""
Fabric script that creates and distributes an archive to web servers
"""

import os
from datetime import datetime
from fabric.api import env, local, put, run, runs_once

# Set the web servers
env.hosts = ['<IP web-01>', '<IP web-02>']


def do_pack():
    """
    Generates a .tgz archive from the contents of the web_static folder
    """
    try:
        # Create versions directory if it doesn't exist
        if not os.path.exists("versions"):
            local("mkdir -p versions")

        # Create timestamp for archive name
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        archive_name = "web_static_{}.tgz".format(timestamp)
        archive_path = "versions/{}".format(archive_name)

        # Create the archive
        result = local("tar -cvzf {} web_static".format(archive_path))

        if result.succeeded:
            return archive_path
        else:
            return None

    except Exception:
        return None


def do_deploy(archive_path):
    """
    Distributes an archive to web servers
    """
    if not os.path.exists(archive_path):
        return False

    try:
        # Get the archive filename without extension
        archive_filename = os.path.basename(archive_path)
        archive_name = archive_filename.split('.')[0]

        # Upload the archive to /tmp/ directory
        put(archive_path, "/tmp/{}".format(archive_filename))

        # Create the target directory
        run("mkdir -p /data/web_static/releases/{}/".format(archive_name))

        # Uncompress the archive to the target directory
        run("tar -xzf /tmp/{} -C /data/web_static/releases/{}/".format(
            archive_filename, archive_name))

        # Delete the archive from /tmp/
        run("rm /tmp/{}".format(archive_filename))

        # Move contents from web_static folder to parent directory
        run("mv /data/web_static/releases/{}/web_static/* "
            "/data/web_static/releases/{}/".format(archive_name, archive_name))

        # Remove the empty web_static directory
        run("rm -rf /data/web_static/releases/{}/web_static".format(
            archive_name))

        # Delete the current symbolic link
        run("rm -rf /data/web_static/current")

        # Create a new symbolic link
        run("ln -s /data/web_static/releases/{} "
            "/data/web_static/current".format(archive_name))

        return True

    except Exception:
        return False


def deploy():
    """
    Creates and distributes an archive to web servers
    """
    # Call do_pack() and store the path of the created archive
    archive_path = do_pack()

    # Return False if no archive has been created
    if archive_path is None:
        return False

    # Call do_deploy() using the new path of the archive
    return do_deploy(archive_path)
