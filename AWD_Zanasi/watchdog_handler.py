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
from django.core.exceptions import ObjectDoesNotExist

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
    filepath = settings.MEDIA_ROOT + separator + project.matlab_file.name

    observer = Observer() # nuovo oggetto observer
    observer.setName("obsv-" + str(project.id))

    event_handler = MyHandler(project) # gestore degli eventi per l'observer
    
    ## percosi delle cartelle da osservare  / da dare a matlab
    path = settings.MEDIA_ROOT + separator + os.path.dirname(project.matlab_file.name)
    logger.debug("scheduler path "+path)

    path = path.replace("/","\\")
    filepath = filepath.replace("/","\\")
    logger.debug("scheduler path "+path)
    #### 
    
    logger.debug("launching: " + filepath)
    observer.schedule(event_handler, path=path, recursive=True) # indica all'observer quale event handler usare, quale percorso osservare e di essere ricorsivo.
    observer.start() #lancio
    time.sleep(1) # attende
    
    chk = subprocess.check_output("C:\Apache24\htdocs\AWD\AWD_Zanasi\matlab_script.bat \"%s\" \"%s\" "%(path,filepath), shell=True) #lancia matlab
    logger.debug("%s" %chk)
    
            
    i = 0
    ## rallenta l'observer in mopdo che matlab possa eseguire i calcoli prima che l'observer termini la sua esecuzione
    while ALIVE:
        time.sleep(1)
        logger.debug(observer.getName() + ": still alive " + str(i))
        i += 1
        if (i > MAXTIME): 
            break #raggiunto tempo massimo.

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

    def add_output(self, event):
        """
        Tracks the project "out" folder for new .txt or .png files and terminates itself if a ".done" file is created or modified or the timout is reached.
        
        event.event_type 
            'modified' | 'created' | 'moved' | 'deleted'
        event.is_directory
            True | False
        event.src_path
            path/to/observed/file
        """
    
        #cerca nuovi file txt
        if event.src_path.endswith(".txt"):
            logger.debug("event src path " + event.src_path)
            logger.debug("media root " + settings.MEDIA_ROOT)
            root, text_file_path = event.src_path.split(settings.MEDIA_ROOT+"\\")
            logger.debug("out file path " + text_file_path)
            logger.debug("root "+root)

            out, created = ProjectOutput.objects.get_or_create(project=self.project, text_file=text_file_path) #cerca o ottiene un oggett database di tipo ProjectOutput

            if created:
                logger.debug(event.src_path + " saved to databse to project " + str(out.project.name))
            else:
                logger.debug(event.src_path + "update to databse to project " + str(out.project.name))
                
        if (event.src_path.endswith(".png") | event.src_path.endswith(".jpg")):
            #cerca nuovi file png
            logger.debug("event src path " + event.src_path)
            logger.debug("media root " + settings.MEDIA_ROOT)
            root, img_file_path = event.src_path.split(settings.MEDIA_ROOT+"\\")
            logger.debug("root " + root)
            logger.debug("out file path " + img_file_path)

            out, created = ProjectOutput.objects.get_or_create(project=self.project, image_file=img_file_path)

            if created:
                logger.debug(event.src_path + " saved to databse to project " + str(out.project.name))
            else:
                logger.debug(event.src_path + " updated to databse to project " + str(out.project.name))

        if (event.src_path.endswith(".zip")):
            #generic file
            logger.debug("event src path " + event.src_path)
            logger.debug("media root " + settings.MEDIA_ROOT)
            root, generic_file_path = event.src_path.split(settings.MEDIA_ROOT+"\\")
            logger.debug("root " + root)
            logger.debug("out file path " + generic_file_path)

            out, created = ProjectOutput.objects.get_or_create(project=self.project, generic_file=generic_file_path)
            
            if created:
                logger.debug(event.src_path + " saved to databse to project " + str(out.project.name))
            else:
                logger.debug(event.src_path + " updated to databse to project " + str(out.project.name))
        
        
        if event.src_path.endswith(".done"):
            #termina l'observer prima dei 45 secondi. indica che matlab ha finito.
            logger.debug(".done file found. terminating observer")
            global ALIVE
            ALIVE = False
            

        logger.debug(str(event.src_path) + " " + str(event.event_type))

    def rem_output(self,event):
        # generic file
        try:
            root, generic_file_path = event.src_path.split(settings.MEDIA_ROOT + "\\")
            out_object = ProjectOutput.objects.get(project=self.project, generic_file=generic_file_path)
            out_object.delete()
            logger.debug(event.src_path + " deleted from project " + str(out_object.project.name))
        except ObjectDoesNotExist as e:
            logger.error(e)

    def on_modified(self, event):
        self.add_output(event)

    def on_created(self, event):
        self.add_output(event)
        
    def on_deleted(self, event):
        self.rem_output(event)
