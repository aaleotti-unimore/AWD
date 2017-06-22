import logging.config
from datetime import datetime
from watchdog.events import FileSystemEventHandler
from .models import *
from django.utils import timezone

logger = logging.getLogger(__name__)

from watchdog.observers import Observer
import time, os

MAXTIME = 45  # timeout


def watchdog(project):
    global ALIVE
    ALIVE = True
    filepath = os.path.dirname(project.matlab_file.name)

    # observer = Observer()
    observer = Observer()
    observer.setName("obsv-" + str(project.id))
    event_handler = MyHandler(project)
    path = settings.MEDIA_ROOT + "/" + filepath
    import subprocess
    logger.debug("path observed: " + path)

    observer.schedule(event_handler, path=path, recursive=True)
    observer.start()
    time.sleep(1)
    subprocess.call(['AWD_Zanasi/generate_output.sh', path])

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
    def __init__(self, project):
        object.__init__(self)
        project.launch_date = timezone.now()
        project.save()
        self.project = project

    def process(self, event):
        """
        event.event_type 
            'modified' | 'created' | 'moved' | 'deleted'
        event.is_directory
            True | False
        event.src_path
            path/to/observed/file
        """
        # the file will be processed

        if event.src_path.endswith(".txt"):
            root, text_file_path = event.src_path.split(settings.MEDIA_ROOT + "/")
            logger.debug("root " + root)
            logger.debug("out file path " + text_file_path)

            out, created = ProjectOutput.objects.get_or_create(project=self.project, text_file=text_file_path)

            if created:
                logger.debug(event.src_path + " saved to databse to project " + str(out.project))

        if event.src_path.endswith(".png"):
            root, img_file_path = event.src_path.split(settings.MEDIA_ROOT + "/")
            logger.debug("root " + root)
            logger.debug("out file path " + img_file_path)

            out, created = ProjectOutput.objects.get_or_create(project=self.project, image_file=img_file_path)

            if created:
                logger.debug(event.src_path + " saved to databse to project " + str(out.project))

        if event.src_path.endswith(".done"):
            logger.debug("done file found")
            global ALIVE
            ALIVE = False

        logger.debug(str(event.src_path) + " " + str(event.event_type))  # logger.debug now only for debug

    def on_modified(self, event):
        self.process(event)

    def on_created(self, event):
        self.process(event)
