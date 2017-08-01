"""
Watchdog Module
Handles the matlab script execution. 
"""

import os
import logging.config
import subprocess
from subprocess import Popen
from django.utils import timezone
from watchdog.events import FileSystemEventHandler

from .models import *

logger = logging.getLogger(__name__)

from watchdog.observers import Observer
import time, os

MAXTIME = 45  # watchdog timeout

separator="/"

def watchdog(project):
    """
    Called to launch a matlab execution from views.launch_project. 
    Uses a global variable to define when the watchdog observer has to terminate. 
    
    :param project: Project object
    :return: 0
    """
    global ALIVE  # observer life variable
    ALIVE = True
    # filepath = os.path.dirname(project.matlab_file.name)
    filepath = project.matlab_file.name
    
    observer = Observer()
    observer.setName("obsv-" + str(project.id))
    event_handler = MyHandler(project)
    path = settings.MEDIA_ROOT + separator + filepath
    logger.debug("scheduler path "+path)

   
    
    logger.debug("scheduler path "+path)

    
    logger.debug("path observed: " + filepath)
    observer.schedule(event_handler, path=path, recursive=True)
    observer.start()
    time.sleep(1)
    
    #subprocess.call("mys.cmd " + filepath, shell=True)
    STR="matlab -nosplash -nodesktop -minimize -logfile output.log -r \" Analizza_il_Sistema(\'"+filepath+"\')"
    logger.debug(STR)
    
    subprocess.call(".\AWD_Zanasi\matlab_script.bat "+filepath, shell=True)
    
            
    i = 0
    while ALIVE:
        time.sleep(1)
        logger.debug(observer.getName() + ": still alive " + str(i))
        i += 1
        if (i > MAXTIME):
            break

    logger.debug(observer.getName() + ": is dead")
    observer.stop()
    observer.join()
    return 0


class MyHandler(FileSystemEventHandler):
    """
    Handles the observer. 
    """

    def __init__(self, project):
        object.__init__(self)
        project.launch_date = timezone.now()
        project.save()
        self.project = project

    def process(self, event):
        """
        Tracks the project "out" folder for new .txt or .png files and terminates itself if a ".done" file is created or modified or the timout is reached.
        
        event.event_type 
            'modified' | 'created' | 'moved' | 'deleted'
        event.is_directory
            True | False
        event.src_path
            path/to/observed/file
        """

        if event.src_path.endswith(".txt"):
            root, text_file_path = event.src_path.split(settings.MEDIA_ROOT + separator)
            logger.debug("out file path " + text_file_path)

            out, created = ProjectOutput.objects.get_or_create(project=self.project, text_file=text_file_path)

            if created:
                logger.debug(event.src_path + " saved to databse to project " + str(out.project.name))
            else:
                logger.debug(event.src_path + "update to databse to project " + str(out.project.name))

        if event.src_path.endswith(".png"):
            root, img_file_path = event.src_path.split(settings.MEDIA_ROOT + separator)
            logger.debug("root " + root)
            logger.debug("out file path " + img_file_path)

            out, created = ProjectOutput.objects.get_or_create(project=self.project, image_file=img_file_path)

            if created:
                logger.debug(event.src_path + " saved to databse to project " + str(out.project.name))
            else:
                logger.debug(event.src_path + " updated to databse to project " + str(out.project.name))

        if event.src_path.endswith(".done"):
            logger.debug(".done file found. terminating observer")
            global ALIVE
            ALIVE = False

        logger.debug(str(event.src_path) + " " + str(event.event_type))

    def on_modified(self, event):
        self.process(event)

    def on_created(self, event):
        self.process(event)
